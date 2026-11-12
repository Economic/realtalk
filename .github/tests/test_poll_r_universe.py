"""Run the r-universe wait with stand-in curl and sleep commands."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "poll-r-universe.sh"
SYNC_URL = "https://economic.r-universe.dev/api/sync"
PACKAGE_URL = "https://economic.r-universe.dev/api/packages/realtalk"


class PollRUniverseTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.log = self.root / "calls.jsonl"
        self.env = os.environ.copy()
        self.env.update(
            CALL_LOG=str(self.log),
            VERSION="2026.11.10",
            # The version served on each poll; the last one repeats
            SERVED="2026.11.10",
            SYNC_EXIT="0",
        )

        binary = self.root / "bin"
        binary.mkdir()
        curl = binary / "curl"
        curl.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "args = sys.argv[1:]\n"
            "log = os.environ['CALL_LOG']\n"
            "polls = 0\n"
            "if os.path.exists(log):\n"
            "    with open(log) as lines:\n"
            "        polls = sum(json.loads(line)['command'] == 'poll' for line in lines)\n"
            "sync = 'PATCH' in args\n"
            "with open(log, 'a') as out:\n"
            "    out.write(json.dumps({'command': 'sync' if sync else 'poll', 'args': args}) + '\\n')\n"
            "if sync:\n"
            "    status = int(os.environ['SYNC_EXIT'])\n"
            "    if status:\n"
            "        print('curl: (22) The requested URL returned error: 500', file=sys.stderr)\n"
            "        sys.exit(status)\n"
            "    print('::error::r-universe response body')\n"
            "else:\n"
            "    served = os.environ['SERVED'].split(',')\n"
            "    print(json.dumps({'Version': served[min(polls, len(served) - 1)]}))\n"
        )
        curl.chmod(0o755)
        sleep = binary / "sleep"
        sleep.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "with open(os.environ['CALL_LOG'], 'a') as out:\n"
            "    out.write(json.dumps({'command': 'sleep', 'args': sys.argv[1:]}) + '\\n')\n"
        )
        sleep.chmod(0o755)
        self.env["PATH"] = str(binary) + os.pathsep + self.env["PATH"]

    def run_poll(self):
        return subprocess.run(
            ["bash", str(SCRIPT)], cwd=self.root, env=self.env, check=False,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )

    def calls(self, command=None):
        calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        return [call for call in calls if command in (None, call["command"])]

    def test_sync_is_requested_once_before_the_first_poll(self):
        result = self.run_poll()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([call["command"] for call in self.calls()], ["sync", "poll"])
        sync = self.calls("sync")[0]["args"]
        self.assertEqual(sync[sync.index("-X") + 1], "PATCH")
        self.assertEqual(sync[-1], SYNC_URL)
        self.assertEqual(self.calls("poll")[0]["args"][-1], PACKAGE_URL)
        self.assertIn("Asked r-universe to sync.", result.stdout)
        self.assertIn("r-universe serves realtalk 2026.11.10.", result.stdout)

    def test_sync_request_sends_no_credentials(self):
        self.env["GH_TOKEN"] = "token-that-must-not-be-sent"
        self.env["GITHUB_TOKEN"] = "token-that-must-not-be-sent"

        self.run_poll()

        sync = " ".join(self.calls("sync")[0]["args"])
        self.assertNotIn("token-that-must-not-be-sent", sync)
        self.assertNotIn("Authorization", sync)

    def test_sync_response_body_is_not_printed(self):
        result = self.run_poll()

        self.assertNotIn("r-universe response body", result.stdout)

    def test_failed_sync_request_warns_and_the_wait_still_succeeds(self):
        self.env["SYNC_EXIT"] = "22"

        result = self.run_poll()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("::warning::Couldn't ask r-universe to sync.", result.stdout)
        self.assertNotIn("Asked r-universe to sync.", result.stdout)
        self.assertIn("r-universe serves realtalk 2026.11.10.", result.stdout)

    def test_sync_is_not_repeated_while_waiting_for_the_build(self):
        self.env["SERVED"] = "2026.10.29,2026.10.29,2026.11.10"

        result = self.run_poll()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls("sync")), 1)
        self.assertEqual(len(self.calls("poll")), 3)
        self.assertEqual([call["args"] for call in self.calls("sleep")], [["300"], ["300"]])
        self.assertIn("Attempt 1: r-universe serves 2026.10.29; waiting for 2026.11.10.", result.stdout)

    def test_version_never_served_fails_after_three_hours(self):
        self.env["SERVED"] = "2026.10.29"

        result = self.run_poll()

        self.assertEqual(result.returncode, 1)
        self.assertEqual(len(self.calls("sync")), 1)
        self.assertEqual(len(self.calls("poll")), 36)
        self.assertEqual(len(self.calls("sleep")), 36)
        self.assertIn("::error::After 3 hours, r-universe still doesn't serve realtalk 2026.11.10.", result.stdout)


if __name__ == "__main__":
    unittest.main()
