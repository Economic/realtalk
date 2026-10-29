"""Check release targets against real git history without contacting GitHub."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "tag-release-plan.sh"


class TagReleasePlanTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.env = os.environ.copy()
        self.env.update(
            GIT_CONFIG_GLOBAL="/dev/null",
            GIT_CONFIG_NOSYSTEM="1",
            GIT_AUTHOR_NAME="Test maintainer",
            GIT_AUTHOR_EMAIL="maintainer@example.test",
            GIT_COMMITTER_NAME="Test maintainer",
            GIT_COMMITTER_EMAIL="maintainer@example.test",
            GITHUB_REPOSITORY="example/realtalk",
            GITHUB_OUTPUT=str(self.root / "outputs"),
            ACTOR="test-maintainer",
        )
        self.command("git", "init", "-b", "main")
        self.command("git", "config", "core.hooksPath", "/dev/null")
        (self.root / "DESCRIPTION").write_text("Version: 2026.10.29\n")
        (self.root / "NEWS.md").write_text("## Version 2026.10.29\n\nUpdated data.\n")
        self.command("git", "add", "DESCRIPTION", "NEWS.md")
        self.command("git", "commit", "-m", "Data update")
        baseline = self.command("git", "rev-parse", "HEAD").stdout.strip()
        # Enough history to exceed a pipe buffer when a search matches near HEAD.
        history = "".join(
            f"commit refs/heads/main\n"
            f"committer Test maintainer <maintainer@example.test> {1700000000 + i} +0000\n"
            "data 7\nHistory\n"
            + (f"from {baseline}\n" if i == 0 else "")
            + "\n"
            for i in range(1000)
        )
        self.command("git", "fast-import", input=history)
        self.command("git", "update-ref", "refs/remotes/origin/main", "HEAD")
        self.target = self.command("git", "rev-parse", "HEAD~1").stdout.strip()
        self.env["COMMIT"] = self.target

        binary = self.root / "bin"
        binary.mkdir()
        gh = binary / "gh"
        gh.write_text(
            f"#!{sys.executable}\n"
            "import sys\n"
            "args = sys.argv[1:]\n"
            "if args[0] == 'api' and args[1].endswith('/permission'):\n"
            "    print('maintain')\n"
            "elif args[:2] == ['release', 'view']:\n"
            "    if '--json' in args:\n"
            "        print('v2026.10.14')\n"
            "    else:\n"
            "        sys.exit(1)\n"
            "else:\n"
            "    sys.exit('Unexpected gh call: ' + repr(args))\n"
        )
        gh.chmod(0o755)
        self.env["PATH"] = str(binary) + os.pathsep + self.env["PATH"]

    def command(self, *args, check=True, input=None):
        return subprocess.run(
            args, cwd=self.root, env=self.env, check=check, input=input,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )

    def test_recent_main_commit_is_accepted_with_long_history(self):
        result = self.command("bash", str(SCRIPT), check=False)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("target=" + self.target, (self.root / "outputs").read_text())

    def test_side_branch_commit_is_rejected(self):
        self.command("git", "switch", "-c", "side", "HEAD~1")
        self.command("git", "commit", "--allow-empty", "-m", "Unmerged change")
        self.env["COMMIT"] = self.command("git", "rev-parse", "HEAD").stdout.strip()
        result = self.command("bash", str(SCRIPT), check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "outputs").exists())


if __name__ == "__main__":
    unittest.main()
