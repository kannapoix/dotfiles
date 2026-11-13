"""Edit the body of a GitHub issue, pull request, or comment, with guards.

    gh-body-edit (issue|pr|comment) ID --replace OLD NEW
    gh-body-edit (issue|pr|comment) ID --append-after ANCHOR NEW
    gh-body-edit (issue|pr|comment) ID --delete OLD

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

"""

import argparse
import difflib
import json
import re
import subprocess
import sys


def gh(args, stdin=None):
    proc = subprocess.run(["gh", *args], input=stdin, capture_output=True)
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode("utf-8", "replace"))
        sys.exit(proc.returncode)
    return proc.stdout


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
    args = parser.parse_args()

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
