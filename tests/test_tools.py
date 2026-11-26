import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


installer = module("installer", ROOT / "scripts/install.py")
doctor = module("doctor", ROOT / "skills/apple-app-intents/scripts/doctor.py")
validator = module("validator", ROOT / "scripts/validate.py")
links = module("links", ROOT / "scripts/check_apple_links.py")


class ToolsTests(unittest.TestCase):
    def test_validator_detects_broken_or_nonportable_resources(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill = root / "skills/apple-app-intents"
            skill.mkdir(parents=True)
            (root / "LICENSE").write_text("MIT example")
            (skill / "LICENSE").write_text("MIT example")
            frontmatter = "---\nname: apple-app-intents\ndescription: Build app intents.\n---\n"
            (skill / "guide.md").write_text("A local guide")
            (skill / "SKILL.md").write_text(frontmatter + "[Guide](guide.md)")
            self.assertEqual(validator.validate(root), [])
            (skill / "guide.md").unlink()
            self.assertTrue(any("Broken relative link" in error for error in validator.validate(root)))
            (root / "outside.md").write_text("Not installed with the skill")
            (skill / "SKILL.md").write_text(frontmatter + "[Guide](../../outside.md)")
            self.assertTrue(any("repository-external" in error for error in validator.validate(root)))

    def test_validator_enforces_documented_app_skill_bundle_rules(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            skill = root / "skills/apple-app-intents"
            app_skill = skill / "assets/Demo/Skills.skillsbundle/Skills/log-entry"
            app_skill.mkdir(parents=True)
            (root / "LICENSE").write_text("MIT example")
            (skill / "LICENSE").write_text("MIT example")
            (skill / "SKILL.md").write_text("---\nname: apple-app-intents\ndescription: Build app intents.\n---\nBody")
            valid = "---\nname: log-entry\ndescription: Logs an entry.\n---\nUse the log tool."
            (app_skill / "SKILL.md").write_text(valid)
            self.assertEqual(validator.validate(root), [])
            cases = {
                "name must match": valid.replace("name: log-entry", "name: other-entry"),
                "only name and description": valid.replace("---\nUse", "license: MIT\n---\nUse"),
                "1-1024 characters": valid.replace("Logs an entry.", "x" * 1025),
                "10,000 characters": valid + "x" * 10_001,
            }
            for expected, text in cases.items():
                (app_skill / "SKILL.md").write_text(text)
                self.assertTrue(any(expected in error for error in validator.validate(root)), expected)
            (app_skill / "SKILL.md").write_text(valid)
            (app_skill / "helper.py").write_text("print('no scripts')")
            self.assertTrue(any("only SKILL.md" in error for error in validator.validate(root)))
            (app_skill / "helper.py").unlink()
            app_skill.rename(app_skill.with_name("Log_Entry"))
            self.assertTrue(any("folder name" in error for error in validator.validate(root)))

    def test_link_checker_extracts_apple_urls_from_markdown(self):
        with tempfile.TemporaryDirectory() as temporary:
            page = Path(temporary) / "guide.md"
            page.write_text("[A](https://developer.apple.com/documentation/appintents/entityquery/entities(for:)), "
                            "see https://developer.apple.com/videos/play/wwdc2026/344/#t=10.\n"
                            "[B](https://developer.apple.com/documentation/appintents/toolintent#overview)")
            self.assertEqual(set(links.collect([page])), {
                "https://developer.apple.com/documentation/appintents/entityquery/entities(for:)",
                "https://developer.apple.com/videos/play/wwdc2026/344/",
                "https://developer.apple.com/documentation/appintents/toolintent",
            })

    def test_link_checker_flags_redirects_and_missing_pages_and_reports_beta(self):
        doc = "https://developer.apple.com/documentation/appintents/toolintent"
        def fake(status, location=None, body=b""):
            return lambda url, method: (status, location, body) if method == "HEAD" else (200, None, body)
        self.assertIn("redirects (301)", links.check(doc, fake(301, "/documentation/x"))[0])
        self.assertEqual(links.check(doc, fake(404))[0], "HTTP 404")
        beta = b'{"metadata": {"platforms": [{"name": "iOS", "beta": true}]}}'
        self.assertEqual(links.check(doc, fake(200, body=beta)), (None, True))
        self.assertEqual(links.check("https://developer.apple.com/videos/play/wwdc2026/344/", fake(200)), (None, False))
        missing_data = lambda url, method: (200, None, b"") if method == "HEAD" else (404, None, b"")
        self.assertIn("documentation data unavailable", links.check(doc, missing_data)[0])

    def test_generated_build_artifacts_do_not_block_or_enter_install(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source"
            source.mkdir()
            (source / "SKILL.md").write_text("A skill")
            (source / ".build").mkdir()
            (source / ".build/link").symlink_to(root / "elsewhere")
            installed = installer.install(source, root / "destination")
            self.assertEqual((installed / "SKILL.md").read_text(), "A skill")
            self.assertFalse((installed / ".build").exists())

    def test_install_cli_copies_complete_skill_to_path_with_spaces(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / "Agent Skills"
            result = subprocess.run([sys.executable, str(ROOT / "scripts/install.py"),
                                     "--skills-dir", str(target)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            installed = target / installer.NAME
            for source in installer.SOURCE.rglob("*"):
                if source.is_file() and not any(part in {"__pycache__", ".build", ".swiftpm", "DerivedData"} for part in source.parts) and source.suffix != ".pyc":
                    if any(part.endswith(".xcodeproj") for part in source.parts):
                        continue
                    self.assertEqual((installed / source.relative_to(installer.SOURCE)).read_bytes(), source.read_bytes())

    def test_existing_skill_is_preserved(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary)
            installed = installer.install(installer.SOURCE, target)
            custom = installed / "SKILL.md"
            custom.write_text("my customized instructions")
            with self.assertRaises(FileExistsError):
                installer.install(installer.SOURCE, target)
            self.assertEqual(custom.read_text(), "my customized instructions")

    def test_refuses_symlink_destination(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary)
            (target / installer.NAME).symlink_to(target / "missing")
            with self.assertRaises(FileExistsError):
                installer.install(installer.SOURCE, target)
            self.assertFalse((target / "missing").exists())

    def test_refuses_source_symlinks_and_recursive_destination(self):
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / "source"
            source.mkdir()
            (source / "SKILL.md").write_text("example")
            with self.assertRaises(ValueError):
                installer.install(source, source / "nested")
            self.assertFalse((source / "nested").exists())
            (source / "outside").symlink_to(Path(temporary) / "outside")
            with self.assertRaises(ValueError):
                installer.install(source, Path(temporary) / "destination")

    def test_inventory_reads_swift_and_skips_dependencies(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "Intent.swift").write_text('struct Create: AppIntent {}\nstruct Catalog: AppShortcutsProvider {}')
            (root / "notes.md").write_text("AppIntentsTesting")
            (root / "node_modules").mkdir()
            (root / "node_modules/Hidden.swift").write_text("AppIntentsTesting")
            report = doctor.inventory(root)
            self.assertEqual(report["swift_files"], 1)
            self.assertEqual(report["files_with_text_matches"]["intents"], 1)
            self.assertEqual(report["files_with_text_matches"]["shortcuts"], 1)
            self.assertEqual(report["files_with_text_matches"]["system_tests"], 0)


    def test_cli_documents_supported_agents(self):
        result = subprocess.run([sys.executable, str(ROOT / "scripts/install.py"), "--help"],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        for agent in ("codex", "claude", "cursor", "openclaw"):
            self.assertIn(agent, result.stdout)


if __name__ == "__main__":
    unittest.main()
