#!/usr/bin/env python3
"""Validate this repository's distributable skill and relative resource links."""
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills/apple-app-intents"
EXCLUDED = {".git", ".build", ".swiftpm", "__pycache__", "DerivedData", "dist"}


def validate(root=ROOT):
    errors = []
    skill = root / "skills/apple-app-intents"
    entry = skill / "SKILL.md"
    text = entry.read_text()
    match = re.match(r"\A---\n(.*?)\n---\n", text, re.S)
    if not match:
        return ["Missing YAML frontmatter"]
    front = match.group(1)
    name = re.search(r"^name: ([a-z0-9]+(?:-[a-z0-9]+)*)$", front, re.M)
    description = re.search(r"^description: (.+)$", front, re.M)
    if not name or name.group(1) != skill.name or len(name.group(1)) > 64:
        errors.append("Skill name must match its directory and Agent Skills syntax")
    if not description or not 1 <= len(description.group(1)) <= 1024:
        errors.append("Description missing or too long")
    if len(text.splitlines()) >= 500:
        errors.append("Entrypoint must remain below 500 lines")
    if (root / "LICENSE").read_bytes() != (skill / "LICENSE").read_bytes():
        errors.append("The standalone skill must contain the repository license")
    checked = 0
    for path in root.rglob("*.md"):
        if set(path.relative_to(root).parts) & EXCLUDED:
            continue
        # Ignore illustrative links in fenced code examples.
        content = re.sub(r"```.*?```", "", path.read_text(), flags=re.S)
        for target in re.findall(r"\[[^\]]*\]\(([^\s)]+)\)", content):
            url = urlsplit(target.strip("<>"))
            if url.scheme or target.startswith("#"):
                continue
            linked = (path.parent / unquote(url.path)).resolve()
            checked += 1
            if not linked.is_relative_to(root.resolve()) or not linked.exists():
                errors.append(f"Broken relative link in {path.relative_to(root)}: {target}")
            if path.is_relative_to(skill) and not linked.is_relative_to(skill.resolve()):
                errors.append(f"Installed skill depends on repository-external file: {target}")
    bundles = validate_app_skill_bundles(skill, errors)
    if not errors:
        print(f"Validated skill structure, bundled license, {checked} local links, and {bundles} Siri app skill bundle(s). "
              "No Swift or Siri validation implied.")
    return errors


APP_SKILL_NAME = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")


def validate_app_skill_bundles(skill, errors):
    """Check Apple's documented Skills.skillsbundle rules for example app skills."""
    bundles = sorted(skill.rglob("*.skillsbundle"))
    seen = {}
    for bundle in bundles:
        label = bundle.relative_to(skill)
        folder = bundle / "Skills"
        if not folder.is_dir():
            errors.append(f"{label}: missing Skills/ folder")
            continue
        extras = [item.name for item in bundle.iterdir() if item.name not in {"Skills", ".DS_Store"}]
        if extras:
            errors.append(f"{label}: unexpected items beside Skills/: {', '.join(sorted(extras))}")
        for entry in sorted(folder.iterdir()):
            if entry.name == ".DS_Store":
                continue
            where = f"{label}/Skills/{entry.name}"
            if not entry.is_dir():
                errors.append(f"{where}: Skills/ may contain only skill folders")
                continue
            if not APP_SKILL_NAME.fullmatch(entry.name) or len(entry.name) > 64:
                errors.append(f"{where}: folder name must be 1-64 lowercase letters, digits, and single hyphens")
            files = sorted(item.name for item in entry.iterdir() if item.name != ".DS_Store")
            if files != ["SKILL.md"]:
                errors.append(f"{where}: must contain only SKILL.md (found {', '.join(files) or 'nothing'})")
                if "SKILL.md" not in files:
                    continue
            match = re.match(r"\A---\n(.*?)\n---\n(.*)\Z", (entry / "SKILL.md").read_text(), re.S)
            if not match:
                errors.append(f"{where}/SKILL.md: missing --- delimited frontmatter")
                continue
            fields = {}
            for line in match.group(1).splitlines():
                key, separator, value = line.partition(":")
                if not separator or line[:1].isspace():
                    errors.append(f"{where}/SKILL.md: frontmatter must be single-line key: value pairs")
                    break
                fields[key.strip()] = value.strip()
            if set(fields) != {"name", "description"}:
                errors.append(f"{where}/SKILL.md: frontmatter must contain only name and description")
            if fields.get("name") != entry.name:
                errors.append(f"{where}/SKILL.md: name must match its folder")
            if not 1 <= len(fields.get("description", "")) <= 1024:
                errors.append(f"{where}/SKILL.md: description must be 1-1024 characters on one line")
            if len(match.group(2)) > 10_000:
                errors.append(f"{where}/SKILL.md: body exceeds 10,000 characters")
            if entry.name in seen:
                errors.append(f"{where}: skill name also used in {seen[entry.name]}")
            seen.setdefault(entry.name, label)
    return len(bundles)


if __name__ == "__main__":
    failures = validate()
    for failure in failures:
        print(failure, file=sys.stderr)
    raise SystemExit(bool(failures))
