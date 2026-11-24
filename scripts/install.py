#!/usr/bin/env python3
"""Copy the self-contained skill to an agent directory. No network or overwrites."""
import argparse
import fnmatch
import os
from pathlib import Path
import shutil
import sys

NAME = "apple-app-intents"
SOURCE = Path(__file__).resolve().parents[1] / "skills" / NAME
IGNORE = (".build", ".swiftpm", "__pycache__", "*.pyc", ".DS_Store", "*.xcodeproj", "DerivedData")


def ignored(name):
    return any(fnmatch.fnmatch(name, pattern) for pattern in IGNORE)


def install(source: Path, skills_dir: Path) -> Path:
    if not (source / "SKILL.md").is_file():
        raise ValueError(f"Not a skill directory: {source}")
    if source.is_symlink():
        raise ValueError("Skill source contains symlinks; use a regular release copy")
    for directory, names, files in os.walk(source, followlinks=False):
        names[:] = [name for name in names if not ignored(name)]
        if any((Path(directory) / name).is_symlink() for name in names + files if not ignored(name)):
            raise ValueError("Skill source contains symlinks; use a regular release copy")
    destination = skills_dir.expanduser().absolute() / NAME
    if destination.exists() or destination.is_symlink():
        raise FileExistsError(f"Already exists: {destination}. Preserve or move it before installing.")
    if destination.resolve().is_relative_to(source.resolve()):
        raise ValueError("Destination must be outside the source skill")
    destination.parent.mkdir(parents=True, exist_ok=True)
    # copytree refuses an existing destination, including a concurrently created one.
    shutil.copytree(source, destination, ignore=shutil.ignore_patterns(*IGNORE))
    return destination


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--agent", choices=["codex", "claude", "cursor", "openclaw"])
    group.add_argument("--skills-dir", type=Path, help="Custom agent's skills parent directory")
    args = parser.parse_args()
    locations = {
        "codex": Path.home() / ".agents" / "skills",
        "claude": Path.home() / ".claude" / "skills",
        "cursor": Path.home() / ".cursor" / "skills",
        "openclaw": Path.home() / ".openclaw" / "skills",
    }
    try:
        destination = install(SOURCE, args.skills_dir if args.skills_dir is not None else locations[args.agent])
    except (OSError, ValueError) as error:
        print(f"Install failed: {error}", file=sys.stderr)
        return 1
    print(f"Installed {destination}. Reload your agent's skills or restart its session.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
