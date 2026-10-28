"""Run the real draft writer against local git repositories and a stand-in gh."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "update-draft-pr.sh"


class DraftUpdateTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.remote = self.root / "origin.git"
        self.work = self.root / "work"
        self.work.mkdir()
        self.log = self.root / "gh.jsonl"
        self.env = os.environ.copy()
        self.env.update(
            GIT_CONFIG_GLOBAL="/dev/null",
            GIT_CONFIG_NOSYSTEM="1",
            GIT_AUTHOR_NAME="Test maintainer",
            GIT_AUTHOR_EMAIL="maintainer@example.test",
            GIT_COMMITTER_NAME="Test maintainer",
            GIT_COMMITTER_EMAIL="maintainer@example.test",
            GIT_AUTHOR_DATE="2026-10-28T12:00:00Z",
            GIT_COMMITTER_DATE="2026-10-28T12:00:00Z",
            GH_LOG=str(self.log),
            GH_OPEN_PR="48",
            ACTOR="test-maintainer",
            RUN_URL="https://example.test/actions/runs/123",
        )
        self.run_command("git", "init", "--bare", str(self.remote))
        self.git("init", "-b", "main")
        self.git("config", "core.hooksPath", "/dev/null")
        self.git("remote", "add", "origin", str(self.remote))
        self.write("DESCRIPTION", "Version: 2026.10.24\n")
        self.write("NEWS.md", "# realtalk 2026.10.24\n")
        self.write("README.md", "Published data: 100\n")
        self.write("data/index.rda", "baseline serialization\n")
        self.write("data-raw/processed/index.csv", "period,value\n2026m9,100\n")
        self.write("data-raw/raw/snapshots/index.csv", "period,value\n2026m9,100\n")
        self.write("man/figures/README-index.png", "baseline figure\n")
        self.git("add", ".")
        self.git("commit", "-m", "Published baseline")
        self.git("push", "-u", "origin", "main")

        binary = self.root / "bin"
        binary.mkdir()
        gh = binary / "gh"
        gh.write_text(
            f"#!{sys.executable}\n"
            "import json, os, pathlib, sys\n"
            "args = sys.argv[1:]\n"
            "entry = {'args': args}\n"
            "if '--body-file' in args:\n"
            "    entry['body'] = pathlib.Path(args[args.index('--body-file') + 1]).read_text()\n"
            "with open(os.environ['GH_LOG'], 'a') as log:\n"
            "    log.write(json.dumps(entry) + '\\n')\n"
            "if args[:2] == ['pr', 'list']:\n"
            "    print(os.environ.get('GH_OPEN_PR', ''))\n"
        )
        gh.chmod(0o755)
        self.env["PATH"] = str(binary) + os.pathsep + self.env["PATH"]

    def run_command(self, *args, env=None):
        return subprocess.run(
            args,
            cwd=self.work,
            env=self.env if env is None else env,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        ).stdout.strip()

    def git(self, *args):
        return self.run_command("git", *args)

    def write(self, relative, text):
        path = self.work / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    def build(self, value=101):
        self.write("DESCRIPTION", "Version: 2026.10.28\n")
        self.write("NEWS.md", "# realtalk 2026.10.28\n\nUpdated data.\n")
        self.write("README.md", f"Current data: {value}\n")
        self.write("data/index.rda", "new serialization, regardless of data values\n")
        self.write("data-raw/processed/index.csv", f"period,value\n2026m9,{value}\n")
        self.write("data-raw/raw/snapshots/index.csv", f"period,value\n2026m9,{value}\n")
        self.write("reports/change_memo.md", "**CPI update**\n\nNew CPI values.\n")

    def existing_draft(self):
        self.git("switch", "-c", "data-update")
        self.build()
        self.git("add", "DESCRIPTION", "NEWS.md", "README.md", "data", "data-raw")
        previous = self.env.copy()
        previous.update(
            GIT_AUTHOR_NAME="github-actions[bot]",
            GIT_COMMITTER_NAME="github-actions[bot]",
            GIT_AUTHOR_DATE="2026-10-27T12:00:00Z",
            GIT_COMMITTER_DATE="2026-10-27T12:00:00Z",
        )
        self.run_command("git", "commit", "-m", "Earlier data draft", env=previous)
        self.git("push", "-u", "origin", "data-update")
        head = self.remote_head()
        self.git("switch", "main")
        return head

    def remote_head(self):
        return self.git("ls-remote", "origin", "refs/heads/data-update").split()[0]

    def calls(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def run_writer(self, automatic=None):
        env = self.env.copy()
        if automatic is None:
            env.pop("AUTOMATIC", None)
        else:
            env["AUTOMATIC"] = "true" if automatic else "false"
        return self.run_command("bash", str(SCRIPT), env=env)

    def assert_bot_commit_on_main(self):
        head = self.remote_head()
        self.assertEqual(self.git("rev-parse", head + "^"), self.git("rev-parse", "main"))
        self.assertEqual(self.git("show", "-s", "--format=%an", head), "github-actions[bot]")
        self.assertEqual(self.git("rev-list", "--count", "main.." + head), "1")

    def test_unchanged_automatic_draft_preserves_commit_and_pr(self):
        previous = self.existing_draft()
        self.build()
        self.write("data/index.rda", "different bytes, identical processed values\n")
        output = self.run_writer(automatic=True)
        self.assertIn("Keeping it and its approval", output)
        self.assertEqual(self.remote_head(), previous)
        self.assertEqual([call["args"][:2] for call in self.calls()], [["pr", "list"]])

    def test_manual_run_refreshes_even_when_data_matches_open_draft(self):
        previous = self.existing_draft()
        self.build()
        self.run_writer()
        self.assertNotEqual(self.remote_head(), previous)
        self.assert_bot_commit_on_main()
        edit = next(call for call in self.calls() if call["args"][:2] == ["pr", "edit"])
        self.assertIn("--add-assignee", edit["args"])
        self.assertIn("Drafted by test-maintainer", edit["body"])

    def test_automatic_run_replaces_draft_when_values_change(self):
        previous = self.existing_draft()
        self.build(value=102)
        self.run_writer(automatic=True)
        self.assertNotEqual(self.remote_head(), previous)
        self.assert_bot_commit_on_main()
        self.assertIn("2026m9,102", self.git("show", "origin/data-update:data-raw/processed/index.csv"))
        edit = next(call for call in self.calls() if call["args"][:2] == ["pr", "edit"])
        self.assertNotIn("--add-assignee", edit["args"])
        self.assertIn("Automatically drafted", edit["body"])
        comment = next(call for call in self.calls() if call["args"][:2] == ["pr", "comment"])
        self.assertIn("Automatically redrafted", comment["args"][-1])

    def test_automatic_run_rebuilds_draft_when_main_changes(self):
        previous = self.existing_draft()
        self.write("R/fix.R", "# Updated processing code\n")
        self.git("add", "R/fix.R")
        self.git("commit", "-m", "Fix processing code")
        self.git("push", "origin", "main")
        self.build()
        self.run_writer(automatic=True)
        self.assertNotEqual(self.remote_head(), previous)
        self.assert_bot_commit_on_main()
        self.assertEqual(self.git("show", "origin/data-update:R/fix.R"), "# Updated processing code")

    def test_automatic_run_creates_new_pr_without_assigning_actor(self):
        self.env["GH_OPEN_PR"] = ""
        self.build()
        self.run_writer(automatic=True)
        self.assert_bot_commit_on_main()
        create = next(call for call in self.calls() if call["args"][:2] == ["pr", "create"])
        self.assertNotIn("--assignee", create["args"])
        self.assertIn("Automatically drafted", create["body"])

    def test_data_already_on_main_closes_existing_pr_without_pushing(self):
        previous = self.existing_draft()
        self.build(value=100)
        self.run_writer(automatic=True)
        self.assertEqual(self.remote_head(), previous)
        self.assertEqual([call["args"][:2] for call in self.calls()], [["pr", "list"], ["pr", "close"]])

    def test_data_already_on_main_without_pr_does_nothing(self):
        self.env["GH_OPEN_PR"] = ""
        self.build(value=100)
        self.run_writer(automatic=True)
        self.assertEqual(self.git("ls-remote", "origin", "refs/heads/data-update"), "")
        self.assertEqual([call["args"][:2] for call in self.calls()], [["pr", "list"]])


if __name__ == "__main__":
    unittest.main()
