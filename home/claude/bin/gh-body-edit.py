"""Edit the body of a GitHub issue, pull request, or comment, with guards.

    gh-body-edit (issue|pr|comment) ID --replace OLD NEW
    gh-body-edit (issue|pr|comment) ID --append-after ANCHOR NEW
    gh-body-edit (issue|pr|comment) ID --delete OLD
    gh-body-edit pr ID --relink-commits

ID is a number or URL. For a comment, it is the comment's id, or its URL
(...#issuecomment-<id>); this covers comments on issues and the
conversation comments of pull requests.

OLD, NEW, and ANCHOR are files. The text of OLD or ANCHOR must occur
exactly once in the body, or the run aborts. The body is fetched again
right before writing and must still match the copy that was edited, or
the run aborts, since the person may edit on the web at the same time.
The body's line endings (CRLF after a web edit) are kept: the files are
read as LF and converted, and their final newline is not part of the
text. After writing, the body is fetched once more and compared with
what was written. Output is one line: OK, ABORT: <reason>, or FAIL.

--relink-commits points the body's links to the pull request's own
commits (.../pull/<N>/commits/<sha>) at the commits the pull request has
now, after a force push. Each old commit is matched to a current one by
subject, else by patch id; the short SHA shown in the link text changes
with the URL. The pairs are printed to stderr first, and if any old
commit has no match the run aborts and writes nothing.

It also repins links to a file at a commit (.../blob/<sha>/<path>, with
an optional #L<a> or #L<a>-L<b>) whose commit is neither in the pull
request nor on its base branch. The old commit is matched the same way,
and a link with lines is repinned only when those lines read the same at
the new commit; otherwise the run aborts, naming the link, and writes
nothing.
"""

import argparse
import difflib
import json
import re
import subprocess
import sys
from urllib.parse import quote, unquote


def run(cmd, stdin=None):
    proc = subprocess.run(cmd, input=stdin, capture_output=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode("utf-8", "replace"))
        sys.exit(proc.returncode)
    return proc.stdout


def gh(args, stdin=None):
    return run(["gh", *args], stdin)


def try_run(cmd, stdin=None):
    proc = subprocess.run(cmd, input=stdin, capture_output=True)
    return proc.stdout if proc.returncode == 0 else None


def comment_path(ident, repo):
    m = re.search(r"github\.com/([^/]+/[^/]+)/(?:issues|pull)/\d+"
                  r"#issuecomment-(\d+)", ident)
    if m:
        return f"repos/{m[1]}/issues/comments/{m[2]}"
    if not ident.isdigit():
        abort(f"not a comment id or comment URL: {ident}")
    # gh api fills {owner}/{repo} from the current directory's repository.
    return f"repos/{repo or '{owner}/{repo}'}/issues/comments/{ident}"


def fetch(kind, ident, repo):
    if kind == "comment":
        return json.loads(gh(["api", comment_path(ident, repo)]))["body"]
    flags = ["--repo", repo] if repo else []
    out = gh([kind, "view", ident, *flags, "--json", "body"])
    return json.loads(out)["body"]


def write(kind, ident, repo, body):
    if kind == "comment":
        gh(["api", "-X", "PATCH", comment_path(ident, repo),
            "-H", "Content-Type: application/json", "--input", "-"],
           stdin=json.dumps({"body": body}).encode("utf-8"))
        return
    flags = ["--repo", repo] if repo else []
    gh([kind, "edit", ident, *flags, "--body-file", "-"],
       stdin=body.encode("utf-8"))


def read_text(path, eol):
    text = open(path, "rb").read().decode("utf-8").replace("\r\n", "\n")
    if text.endswith("\n"):
        text = text[:-1]
    if not text:
        abort(f"{path} is empty")
    return text.replace("\n", eol)


def abort(reason):
    print(f"ABORT: {reason}")
    sys.exit(1)


def show_diff(old, new, old_name, new_name):
    lines = difflib.unified_diff(
        old.splitlines(keepends=True), new.splitlines(keepends=True),
        old_name, new_name)
    sys.stderr.writelines(lines)


def edit(body, mode, anchor, new, eol):
    count = body.count(anchor)
    if count != 1:
        abort(f"anchor found {count} times")
    start = body.index(anchor)
    end = start + len(anchor)
    if mode == "replace":
        return body[:start] + new + body[end:]
    if mode == "delete":
        # Whole lines leave with their line break.
        at_line_start = start == 0 or body.endswith(eol, 0, start)
        if at_line_start and body.startswith(eol, end):
            end += len(eol)
        elif at_line_start and end == len(body) and start >= len(eol):
            start -= len(eol)
        return body[:start] + body[end:]
    # append-after: NEW becomes new lines after the line the anchor ends on.
    line_end = body.find(eol, end)
    if line_end < 0:
        line_end = len(body)
    return body[:line_end] + eol + new + body[line_end:]


def commit_subject(owner_repo, sha):
    # The old commits are usually still in the local repository after a
    # force push; GitHub keeps serving them by SHA as well.
    out = try_run(["git", "log", "-1", "--format=%s", sha])
    if out is not None:
        return out.decode("utf-8").strip()
    out = gh(["api", f"repos/{owner_repo}/commits/{sha}",
              "--jq", ".commit.message"])
    return out.decode("utf-8").split("\n", 1)[0].strip()


def patch_id(owner_repo, sha):
    diff = try_run(["git", "show", "--format=", sha])
    if diff is None:
        diff = gh(["api", "-H", "Accept: application/vnd.github.diff",
                   f"repos/{owner_repo}/commits/{sha}"])
    out = run(["git", "patch-id", "--stable"], stdin=diff).decode()
    return out.split()[0] if out.strip() else None


def file_at(owner_repo, sha, path):
    out = try_run(["git", "show", f"{sha}:{path}"])
    if out is None:
        out = try_run(["gh", "api", "-H", "Accept: application/vnd.github.raw",
                       f"repos/{owner_repo}/contents/{quote(path)}"
                       f"?ref={sha}"])
    return None if out is None else out.decode("utf-8", "replace")


def on_base(owner_repo, base, sha):
    # A link to code already on the base branch is not the pull request's
    # to repin, even though its commit is not one of the PR's commits.
    out = try_run(["gh", "api", f"repos/{owner_repo}/compare/{base}...{sha}",
                   "--jq", ".status"])
    return out is not None and out.decode().strip() in ("behind", "identical")


def match_commits(owner_repo, stale, current):
    pairs, subjects, taken, pids = {}, {}, set(), {}
    for sha in stale:
        subject = commit_subject(owner_repo, sha)
        subjects[sha] = subject
        same = [oid for oid, s in current.items()
                if s == subject and oid not in taken]
        if len(same) != 1:
            if not pids:
                pids = {oid: patch_id(owner_repo, oid) for oid in current}
            pid = patch_id(owner_repo, sha)
            same = [oid for oid, p in pids.items()
                    if pid and p == pid and oid not in taken]
        if len(same) == 1:
            pairs[sha] = same[0]
            taken.add(same[0])
    return pairs, subjects


def swap_sha(m, sha_group, new):
    # m[1] is the markdown link text with its "](", when there is one; a
    # short SHA in it is a prefix of the old one and changes with the URL.
    old = m[sha_group].lower()
    text = re.sub(
        r"\b[0-9a-f]{7,40}\b",
        lambda s: new[:len(s[0])] if old.startswith(s[0]) else s[0],
        m[1] or "")
    return text + m[0][len(m[1] or ""):].replace(m[sha_group], new, 1)


def lines(text, a, b):
    return text.split("\n")[a - 1:b] if text is not None else None


def relink(ident, repo):
    flags = ["--repo", repo] if repo else []
    pr = json.loads(gh(["pr", "view", ident, *flags, "--json",
                        "body,url,number,commits,baseRefName"]))
    owner_repo = re.search(r"github\.com/([^/]+/[^/]+)/pull/",
                           pr["url"])[1]
    text = r"(\[[^\]\n]*\]\()?"
    commit_link = re.compile(
        text + r"(https://github\.com/" + re.escape(owner_repo) +
        r"/pull/" + str(pr["number"]) + r"/commits/)([0-9a-f]{40})",
        re.IGNORECASE)
    # Groups: 3 SHA, 4 path, 6 and 7 the first and last line.
    blob_link = re.compile(
        text + r"(https://github\.com/" + re.escape(owner_repo) +
        r"/blob/)([0-9a-f]{40})(/[^\s)#?]+)"
        r"(#L(\d+)(?:C\d+)?(?:-L(\d+)(?:C\d+)?)?)?",
        re.IGNORECASE)
    body = pr["body"]
    current = {c["oid"]: c["messageHeadline"] for c in pr["commits"]}
    commit_olds = list(dict.fromkeys(
        m[3].lower() for m in commit_link.finditer(body)
        if m[3].lower() not in current))
    blob_olds = list(dict.fromkeys(
        m[3].lower() for m in blob_link.finditer(body)
        if m[3].lower() not in current))
    blob_olds = [sha for sha in blob_olds
                 if not on_base(owner_repo, pr["baseRefName"], sha)]
    stale = list(dict.fromkeys(commit_olds + blob_olds))
    if not stale:
        print("OK: no change")
        sys.exit(0)

    pairs, subjects = match_commits(owner_repo, stale, current)
    unmatched = [f"{sha[:7]} ({subjects[sha]})" for sha in stale
                 if sha not in pairs]
    for sha in commit_olds:
        if sha in pairs:
            sys.stderr.write(
                f"{sha[:7]} -> {pairs[sha][:7]}  {subjects[sha]}\n")
    if unmatched:
        abort("no current commit matches " + ", ".join(unmatched))

    targets = {sha: pairs[sha] for sha in blob_olds}
    problems = []
    for m in blob_link.finditer(body):
        old = m[3].lower()
        if old not in targets:
            continue
        new = targets[old]
        path = unquote(m[4][1:])
        where = path + (m[5] or "")
        new_file = file_at(owner_repo, new, path)
        if new_file is None:
            problems.append(f"{where} is missing at {new[:7]}")
            continue
        if m[6]:
            a = int(m[6])
            b = int(m[7] or a)
            before = lines(file_at(owner_repo, old, path), a, b)
            if before is None or before != lines(new_file, a, b):
                problems.append(f"{where} differs at {new[:7]}")
                continue
            note = "lines unchanged"
        else:
            note = "file link"
        sys.stderr.write(
            f"{old[:7]} -> {new[:7]}  {where}  {note}  ({subjects[old]})\n")
    if problems:
        abort("; ".join(problems) + "; fix these links by hand")

    body_new = commit_link.sub(
        lambda m: swap_sha(m, 3, pairs[m[3].lower()])
        if m[3].lower() in pairs else m[0], body)
    body_new = blob_link.sub(
        lambda m: swap_sha(m, 3, targets[m[3].lower()])
        if m[3].lower() in targets else m[0], body_new)
    return body, body_new


def main():
    parser = argparse.ArgumentParser(
        prog="gh-body-edit",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("kind", choices=["issue", "pr", "comment"])
    parser.add_argument("ident", metavar="ID", help="number or URL")
    parser.add_argument("-R", "--repo", metavar="OWNER/REPO")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--replace", nargs=2, metavar=("OLD", "NEW"))
    group.add_argument("--append-after", nargs=2, metavar=("ANCHOR", "NEW"))
    group.add_argument("--delete", metavar="OLD")
    group.add_argument("--relink-commits", action="store_true")
    args = parser.parse_args()

    if args.relink_commits:
        if args.kind != "pr":
            abort("--relink-commits works on a pull request only")
        base, body = relink(args.ident, args.repo)
    else:
        if args.replace:
            mode, files = "replace", args.replace
        elif args.append_after:
            mode, files = "append-after", args.append_after
        else:
            mode, files = "delete", [args.delete]
        base = fetch(args.kind, args.ident, args.repo)
        eol = "\r\n" if "\r\n" in base else "\n"
        anchor = read_text(files[0], eol)
        new = read_text(files[1], eol) if len(files) > 1 else ""
        body = edit(base, mode, anchor, new, eol)
    if body == base:
        print("OK: no change")
        return

    again = fetch(args.kind, args.ident, args.repo)
    if again != base:
        show_diff(base, again, "fetched", "now")
        abort("body changed since fetch")
    write(args.kind, args.ident, args.repo, body)
    after = fetch(args.kind, args.ident, args.repo)
    if after != body:
        show_diff(body, after, "written", "fetched")
        print("FAIL: body after write differs from what was written")
        sys.exit(1)
    print("OK")


if __name__ == "__main__":
    main()
