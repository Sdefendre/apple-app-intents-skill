#!/usr/bin/env python3
"""Report developer.apple.com links in the skill that are broken, redirected, or beta.

Broken and redirected links fail the run. Beta symbols are listed for review
because preview APIs may change, but they do not fail the run. Uses only the
standard library and sends a generic User-Agent.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
from pathlib import Path
import re
import sys
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PATHS = [ROOT / "skills/apple-app-intents", ROOT / "docs"]
URL = re.compile(r"https://developer\.apple\.com/[^\s>\]\"'`]+")
HEADERS = {"User-Agent": "apple-link-check/1.0"}


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


OPENER = urllib.request.build_opener(NoRedirect)


def trim(match):
    """Drop a fragment, trailing punctuation, and Markdown's closing parenthesis."""
    url = match.split("#")[0].rstrip(".,;:")
    while url.endswith(")") and url.count(")") > url.count("("):
        url = url[:-1].rstrip(".,;:")
    return url


def collect(paths):
    """Map each Apple URL (fragment removed) to the files that cite it."""
    found = {}
    for base in paths:
        files = [base] if base.is_file() else sorted(base.rglob("*.md"))
        for path in files:
            for match in URL.findall(path.read_text()):
                url = trim(match)
                found.setdefault(url, set()).add(str(path.relative_to(ROOT) if path.is_relative_to(ROOT) else path))
    return found


def fetch(url, method="GET"):
    """Return (status, location header, body bytes) without following redirects."""
    request = urllib.request.Request(url, method=method, headers=HEADERS)
    try:
        with OPENER.open(request, timeout=30) as response:
            return response.status, None, response.read() if method == "GET" else b""
    except urllib.error.HTTPError as error:
        return error.code, error.headers.get("Location"), b""


def check(url, fetcher=fetch):
    """Return (problem or None, is_beta)."""
    status, location, _ = fetcher(url, "HEAD")
    if status in (301, 302, 303, 307, 308):
        return f"redirects ({status}) to {location}", False
    if status != 200:
        return f"HTTP {status}", False
    path = url.split("developer.apple.com", 1)[1].rstrip("/")
    if not path.startswith("/documentation/"):
        return None, False
    status, _, body = fetcher(f"https://developer.apple.com/tutorials/data{path.lower()}.json", "GET")
    if status != 200:
        return f"documentation data unavailable (HTTP {status})", False
    try:
        platforms = json.loads(body).get("metadata", {}).get("platforms", [])
    except ValueError:
        return "documentation data is not JSON", False
    return None, any(platform.get("beta") for platform in platforms)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path, help="Files or folders to scan (default: skill and docs)")
    args = parser.parse_args(argv)
    links = collect([path.resolve() for path in args.paths] or DEFAULT_PATHS)
    with ThreadPoolExecutor(max_workers=6) as pool:
        results = dict(zip(links, pool.map(check, links)))
    problems = {url: result[0] for url, result in results.items() if result[0]}
    beta = sorted(url for url, result in results.items() if result[1])
    for url, problem in sorted(problems.items()):
        print(f"FAIL {url}: {problem} (cited in {', '.join(sorted(links[url]))})")
    for url in beta:
        print(f"BETA {url} (cited in {', '.join(sorted(links[url]))})")
    print(f"Checked {len(links)} Apple links: {len(problems)} problem(s), {len(beta)} beta page(s).")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
