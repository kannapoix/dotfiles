"""Package Claude Code skills for claude.ai and report which need uploading.

    claude-ai-skills pack SKILLS_DIR OUT_DIR NAME...
    claude-ai-skills status [BUNDLE_DIR]
    claude-ai-skills check [BUNDLE_DIR]

pack writes OUT_DIR/NAME/, the skill as claude.ai gets it, and
OUT_DIR/NAME.skill, that folder zipped, which the Claude desktop app
opens as an import. Frontmatter keys claude.ai rejects, such as
argument-hint, are dropped; the rest of SKILL.md is kept as written.
A skill claude.ai would refuse fails the run instead.

claude.ai has no upload API, so the upload stays a manual step. What
claude.ai holds is read back from two local copies of it: the desktop
app's, refreshed as soon as a skill is imported there, and Claude Code's
one-way sync into ~/.claude/skills/synced, which can lag by hours.
status prints each skill as current when either copy matches, outdated,
or missing, and exits 1 when any is not current. check does the same,
then offers to open the ones that are not current in Claude.
"""

import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

import yaml

# What claude.ai and the Skills API accept, per skill-creator's validator.
ALLOWED_KEYS = {
    "name", "description", "license", "allowed-tools", "metadata",
    "compatibility",
}
NAME = re.compile(r"[a-z0-9]+(-[a-z0-9]+)*")
DEFAULT_BUNDLES = Path.home() / ".local/share/claude-ai-skills"
SYNCED = Path.home() / ".claude/skills/synced"
DESKTOP = (
    Path.home() / "Library/Application Support/Claude"
    / "local-agent-mode-sessions/skills-plugin"
)


def split(text):
    if not text.startswith("---\n"):
        return None, text
    end = text.find("\n---\n", 3)
    if end < 0:
        return None, text
    return text[4:end + 1], text[end + 5:]


def strip_keys(frontmatter):
    kept, keep = [], True
    for line in frontmatter.splitlines(keepends=True):
        if line[:1] not in (" ", "\t", "-", "#", "\n"):
            keep = line.split(":", 1)[0].strip() in ALLOWED_KEYS
        if keep:
            kept.append(line)
    return "".join(kept)


def validate(name, meta, files):
    if not isinstance(meta, dict):
        return "frontmatter is not a mapping"
    if meta.get("name") != name:
        return "frontmatter name differs from the folder name"
    if not NAME.fullmatch(name) or len(name) > 64:
        return "name is not 1-64 lowercase letters, digits, and hyphens"
    if "anthropic" in name or "claude" in name:
        return "name contains a reserved word"
    description = meta.get("description")
    if not isinstance(description, str) or not description.strip():
        return "description is missing"
    if len(description) > 1024:
        return "description is over 1024 characters"
    if "<" in description or ">" in description:
        return "description contains an angle bracket"
    if any(Path(path).name == "SKILL.md" for path in files):
        return "a nested SKILL.md is rejected on upload"
    return None


def read_files(folder):
    return {
        path.relative_to(folder).as_posix(): path.read_bytes()
        for path in sorted(folder.rglob("*"))
        if path.is_file()
    }


def pack(skills_dir, out_dir, names):
    out_dir.mkdir(parents=True, exist_ok=True)
    for name in names:
        files = read_files(skills_dir / name)
        frontmatter, body = split(files.pop("SKILL.md").decode())
        if frontmatter is None:
            sys.exit(f"{name}: SKILL.md has no frontmatter")
        frontmatter = strip_keys(frontmatter)
        error = validate(name, yaml.safe_load(frontmatter), files)
        if error:
            sys.exit(f"{name}: {error}")
        files["SKILL.md"] = f"---\n{frontmatter}---\n{body}".encode()
        # Store files carry mtime 1, which zip cannot encode; a fixed date
        # also keeps the archive reproducible.
        with zipfile.ZipFile(out_dir / f"{name}.skill", "w") as archive:
            for path, data in sorted(files.items()):
                target = out_dir / name / path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
                info = zipfile.ZipInfo(f"{name}/{path}", (1980, 1, 1, 0, 0, 0))
                info.compress_type = zipfile.ZIP_DEFLATED
                info.external_attr = 0o644 << 16
                archive.writestr(info, data)


def newest(manifests):
    # One bucket per organization the account has synced from; the one
    # refreshed last is the organization in use.
    buckets = []
    for manifest in manifests:
        try:
            updated = json.loads(manifest.read_text())["lastUpdated"]
        except (OSError, ValueError, KeyError):
            continue
        buckets.append((updated, manifest.parent))
    return max(buckets)[1] if buckets else None


def synced_roots():
    # The CLI keeps each skill next to its bucket's manifest; the desktop
    # app nests buckets as org/account and keeps skills under skills/.
    roots = []
    cli = newest(SYNCED.glob("*/manifest.json"))
    if cli:
        roots.append(cli)
    desktop = newest(DESKTOP.glob("*/*/manifest.json"))
    if desktop:
        roots.append(desktop / "skills")
    return roots


def snapshot(folder):
    # claude.ai may rewrite the frontmatter (quoting, added keys), so it is
    # compared as data and only on the keys the bundle sets.
    if not (folder / "SKILL.md").is_file():
        return None
    files = read_files(folder)
    frontmatter, body = split(files.pop("SKILL.md").decode())
    meta = yaml.safe_load(frontmatter or "") or {}
    return meta, body.strip(), files


def matches(ours, theirs):
    return (
        {key: theirs[0].get(key) for key in ours[0]} == ours[0]
        and theirs[1:] == ours[1:]
    )


def statuses(bundles):
    roots = synced_roots()
    if not roots:
        print("no local copy of claude.ai's skills", file=sys.stderr)
    result = {}
    for skill in sorted(bundles.glob("*.skill")):
        name = skill.stem
        ours = snapshot(bundles / name)
        copies = [snapshot(root / name) for root in roots]
        copies = [copy for copy in copies if copy is not None]
        if not copies:
            result[name] = "missing"
        elif any(matches(ours, copy) for copy in copies):
            result[name] = "current"
        else:
            result[name] = "outdated"
    return result


def dialog(message, buttons):
    script = [
        "on run argv",
        "display dialog (item 1 of argv) with title \"claude.ai skills\""
        f" buttons {{{', '.join(json.dumps(b) for b in buttons)}}}"
        f" default button {json.dumps(buttons[-1])}",
        "end run",
    ]
    args = [arg for line in script for arg in ("-e", line)]
    proc = subprocess.run(
        ["osascript", *args, message], capture_output=True, text=True,
    )
    return proc.stdout.strip().removeprefix("button returned:")


def check(bundles, result):
    stale = [name for name, state in result.items() if state != "current"]
    if not stale:
        return
    lines = [f"{name} ({result[name]})" for name in stale]
    message = (
        "These skills differ from what claude.ai has:\n\n"
        + "\n".join(lines)
        + "\n\nThey open in Claude one at a time, each starting its upload."
    )
    choice = dialog(message, ["Later", "Show in Finder", "Open in Claude"])
    files = [str(bundles / f"{name}.skill") for name in stale]
    if choice == "Show in Finder":
        subprocess.run(["open", "-R", *files])
    if choice != "Open in Claude":
        return
    # Claude imports only the last of several files opened together, so each
    # one waits until the user is done with the one before.
    for i, name in enumerate(stale):
        if i and dialog(
            f"Finish importing {stale[i - 1]} in Claude, then open"
            f" {name} ({i + 1} of {len(stale)}).",
            ["Stop", "Open next"],
        ) != "Open next":
            return
        subprocess.run(["open", "-a", "Claude", files[i]])


def main():
    if len(sys.argv) >= 4 and sys.argv[1] == "pack":
        pack(Path(sys.argv[2]), Path(sys.argv[3]), sys.argv[4:])
        return
    if len(sys.argv) in (2, 3) and sys.argv[1] in ("status", "check"):
        bundles = Path(sys.argv[2]) if len(sys.argv) == 3 else DEFAULT_BUNDLES
        result = statuses(bundles)
        for name, state in result.items():
            print(f"{state:<9}{name}")
        if sys.argv[1] == "check":
            check(bundles, result)
        sys.exit(0 if all(s == "current" for s in result.values()) else 1)
    sys.exit(__doc__.split("\n\n")[1])


if __name__ == "__main__":
    main()
