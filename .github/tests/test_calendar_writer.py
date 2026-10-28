"""Exercise calendar persistence with real local git and a stand-in GitHub CLI."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
WRITER = ROOT / ".github/scripts/update-calendar.sh"
NOTICE = ROOT / ".github/scripts/calendar-refresh-notice.sh"

GH_STUB = """#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys
args = sys.argv[1:]
entry = {"args": args}
if "--body-file" in args:
    entry["body"] = Path(args[args.index("--body-file") + 1]).read_text()
with open(os.environ["GH_LOG"], "a") as log:
    log.write(json.dumps(entry) + "\\n")
if args[:2] == ["issue", "list"]:
    print(os.environ.get("GH_STUB_ISSUE", ""))
"""


class GithubScriptTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        bindir = self.directory / "bin"
        bindir.mkdir()
        gh = bindir / "gh"
        gh.write_text(GH_STUB)
        gh.chmod(0o755)
        self.log = self.directory / "gh.jsonl"
        self.env = {
            **os.environ,
            "PATH": f"{bindir}{os.pathsep}{os.environ['PATH']}",
            "GH_LOG": str(self.log),
            "GH_STUB_ISSUE": "",
            "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_CONFIG_NOSYSTEM": "1",
        }

    def calls(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]


class CalendarWriterTests(GithubScriptTest):
    def setUp(self):
        super().setUp()
        self.remote = self.directory / "remote.git"
        self.checkout = self.directory / "checkout"
        self.git("init", "--quiet", "--bare", str(self.remote))
        self.git("init", "--quiet", "--initial-branch=main", str(self.checkout))
        self.git("config", "user.name", "Test maintainer", cwd=self.checkout)
        self.git("config", "user.email", "test@example.invalid", cwd=self.checkout)
        (self.checkout / "package-code").write_text("main stays unchanged\n")
        self.git("add", ".", cwd=self.checkout)
        self.git("commit", "--quiet", "-m", "main", cwd=self.checkout)
        self.git("remote", "add", "origin", str(self.remote), cwd=self.checkout)
        self.git("push", "--quiet", "origin", "main", cwd=self.checkout)
        self.main = self.git("rev-parse", "main", cwd=self.checkout)
        self.schedule = self.directory / "schedule.json"
        self.schedule.write_text(json.dumps({"refreshed_at": "2026-10-28T12:00:00Z", "events": []}))

    def git(self, *args, cwd=None):
        result = subprocess.run(
            ["git", *args], cwd=cwd, env=self.env,
            check=True, capture_output=True, text=True,
        )
        return result.stdout.strip()

    def write(self, schedule=None, check=True):
        return subprocess.run(
            ["bash", str(WRITER), str(schedule or self.schedule)],
            cwd=self.checkout, env=self.env,
            check=check, capture_output=True, text=True,
        )

    def calendar_head(self):
        return self.git("--git-dir", str(self.remote), "rev-parse", "calendar")

    def test_first_save_creates_only_calendar_file_and_leaves_main_unchanged(self):
        self.write()
        self.assertEqual(
            self.git("--git-dir", str(self.remote), "ls-tree", "--name-only", "calendar"),
            "schedule.json",
        )
        self.assertEqual(
            self.git("--git-dir", str(self.remote), "show", "calendar:schedule.json"),
            self.schedule.read_text(),
        )
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "main"), self.main)
        self.assertEqual(self.git("rev-parse", "HEAD", cwd=self.checkout), self.main)
        self.assertEqual(self.git("status", "--porcelain", cwd=self.checkout), "")

    def test_later_save_updates_existing_calendar_without_changing_main(self):
        self.write()
        previous = self.calendar_head()
        self.schedule.write_text(json.dumps({"refreshed_at": "2026-11-02T10:17:00Z", "events": []}))
        self.write()
        self.assertNotEqual(self.calendar_head(), previous)
        self.assertEqual(
            self.git("--git-dir", str(self.remote), "rev-parse", "calendar^"), previous,
        )
        self.assertEqual(self.git("--git-dir", str(self.remote), "rev-parse", "main"), self.main)

    def test_identical_save_does_not_add_a_commit(self):
        self.write()
        previous = self.calendar_head()
        self.write()
        self.assertEqual(self.calendar_head(), previous)

    def test_missing_artifact_does_not_replace_previous_calendar(self):
        self.write()
        previous = self.calendar_head()
        result = self.write(self.directory / "missing.json", check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calendar_head(), previous)

    def test_git_connection_failure_does_not_replace_previous_calendar(self):
        self.write()
        previous = self.calendar_head()
        self.git("remote", "set-url", "origin", str(self.directory / "unavailable.git"), cwd=self.checkout)
        result = self.write(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calendar_head(), previous)


class CalendarNoticeTests(GithubScriptTest):
    def notice(self, success, issue=""):
        env = {
            **self.env,
            "SUCCESS": "true" if success else "false",
            "RUN_URL": "https://example.invalid/run/123",
            "GH_STUB_ISSUE": issue,
        }
        subprocess.run(["bash", str(NOTICE)], env=env, check=True, capture_output=True, text=True)

    def test_failure_opens_warning_that_mentions_maintainers_and_retained_schedule(self):
        self.notice(False)
        create = next(call for call in self.calls() if call["args"][:2] == ["issue", "create"])
        self.assertIn("@economic/realtalk-maintainers", create["body"])
        self.assertIn("previously saved schedule remains in use", create["body"])
        self.assertIn("https://example.invalid/run/123", create["body"])

    def test_repeated_failure_comments_on_existing_warning(self):
        self.notice(False, "48")
        calls = self.calls()
        self.assertTrue(any(call["args"][:3] == ["issue", "comment", "48"] for call in calls))
        self.assertFalse(any(call["args"][:2] == ["issue", "create"] for call in calls))

    def test_recovery_closes_existing_warning(self):
        self.notice(True, "48")
        self.assertTrue(any(call["args"][:3] == ["issue", "close", "48"] for call in self.calls()))

    def test_success_without_warning_writes_nothing(self):
        self.notice(True)
        self.assertEqual(len(self.calls()), 1)
        self.assertEqual(self.calls()[0]["args"][:2], ["issue", "list"])


if __name__ == "__main__":
    unittest.main()
