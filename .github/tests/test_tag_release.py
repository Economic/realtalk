"""Run the release script with local commits and a stand-in GitHub CLI."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "tag-release.sh"


class TagReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.log = self.root / "gh.jsonl"
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
            GH_LOG=str(self.log),
            GH_EXISTING_TAG="",
            GH_RELEASE_EXISTS="false",
            DRY_RUN="false",
        )
        self.command("git", "init", "-b", "main")
        self.command("git", "config", "core.hooksPath", "/dev/null")
        (self.root / "DESCRIPTION").write_text("Version: 2026.10.29\n")
        (self.root / "NEWS.md").write_text("## Version 2026.10.29\n\nUpdated data.\n")
        self.command("git", "add", "DESCRIPTION", "NEWS.md")
        self.command("git", "commit", "-m", "Data update")
        self.target = self.command("git", "rev-parse", "HEAD").stdout.strip()
        self.env["TARGET"] = self.target

        binary = self.root / "bin"
        binary.mkdir()
        gh = binary / "gh"
        gh.write_text(
            f"#!{sys.executable}\n"
            "import json, os, pathlib, sys\n"
            "args = sys.argv[1:]\n"
            "entry = {'args': args}\n"
            "if '--notes-file' in args:\n"
            "    entry['notes'] = pathlib.Path(args[args.index('--notes-file') + 1]).read_text()\n"
            "with open(os.environ['GH_LOG'], 'a') as log:\n"
            "    log.write(json.dumps(entry) + '\\n')\n"
            "if args[0] == 'api' and args[1].endswith('/pulls'):\n"
            "    print('')\n"
            "elif args[0] == 'api' and '/git/ref/tags/' in args[1]:\n"
            "    existing = os.environ['GH_EXISTING_TAG']\n"
            "    if existing:\n"
            "        print(existing)\n"
            "    else:\n"
            "        print(json.dumps({'message': 'Not Found', 'status': '404'}))\n"
            "        print('gh: Not Found (HTTP 404)', file=sys.stderr)\n"
            "        sys.exit(1)\n"
            "elif args[0] == 'api' and args[1].endswith('/git/refs'):\n"
            "    print('{}')\n"
            "elif args[:2] == ['release', 'view']:\n"
            "    sys.exit(0 if os.environ['GH_RELEASE_EXISTS'] == 'true' else 1)\n"
            "elif args[:2] != ['release', 'create']:\n"
            "    sys.exit('Unexpected gh call: ' + repr(args))\n"
        )
        gh.chmod(0o755)
        self.env["PATH"] = str(binary) + os.pathsep + self.env["PATH"]

    def command(self, *args, check=True):
        return subprocess.run(
            args, cwd=self.root, env=self.env, check=check,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )

    def run_release(self):
        return self.command("bash", str(SCRIPT), check=False)

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def tag_creations(self):
        return [call for call in self.calls() if call["args"][:2] == [
            "api", "repos/example/realtalk/git/refs",
        ]]

    def release_creations(self):
        return [call for call in self.calls() if call["args"][:2] == ["release", "create"]]

    def test_missing_tag_error_body_does_not_prevent_tag_and_release_creation(self):
        result = self.run_release()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        tags = self.tag_creations()
        self.assertEqual(len(tags), 1)
        self.assertIn("ref=refs/tags/v2026.10.29", tags[0]["args"])
        self.assertIn("sha=" + self.target, tags[0]["args"])
        releases = self.release_creations()
        self.assertEqual(len(releases), 1)
        self.assertIn("v2026.10.29", releases[0]["args"])
        self.assertIn("Updated data.", releases[0]["notes"])
        self.assertIn("version=2026.10.29", (self.root / "outputs").read_text())

    def test_matching_tag_is_reused_when_release_is_missing(self):
        self.env["GH_EXISTING_TAG"] = self.target
        result = self.run_release()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.tag_creations(), [])
        self.assertEqual(len(self.release_creations()), 1)

    def test_tag_on_another_commit_blocks_release(self):
        self.env["GH_EXISTING_TAG"] = "a" * 40
        result = self.run_release()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.tag_creations(), [])
        self.assertEqual(self.release_creations(), [])

    def test_existing_tag_and_release_are_reused(self):
        self.env["GH_EXISTING_TAG"] = self.target
        self.env["GH_RELEASE_EXISTS"] = "true"
        result = self.run_release()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.tag_creations(), [])
        self.assertEqual(self.release_creations(), [])


if __name__ == "__main__":
    unittest.main()
