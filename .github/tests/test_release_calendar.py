"""Offline checks for the official calendar formats and daily release decision."""

from datetime import datetime, timezone
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
FIXTURES = Path(__file__).resolve().parent / "fixtures"
SPEC = importlib.util.spec_from_file_location("release_calendar", SCRIPTS / "release-calendar.py")
calendar = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(calendar)
NOW = datetime(2026, 10, 28, 14, 17, tzinfo=timezone.utc)


class ReleaseCalendarTests(unittest.TestCase):
    def setUp(self):
        self.bls = (FIXTURES / "bls.ics").read_text()
        self.bea = (FIXTURES / "bea.json").read_text()
        self.schedule = calendar.build_schedule(self.bls, self.bea, NOW)

    def test_official_formats_filter_past_unrelated_cancelled_and_duplicate_events(self):
        events = self.schedule["events"]
        self.assertEqual(len(events), 6)
        self.assertEqual({event["release"] for event in events}, set(calendar.RELEASES))
        cpi = [event["at"] for event in events if event["source"] == "bls"]
        self.assertEqual(cpi, ["2026-11-10T13:30:00+00:00", "2026-12-10T13:30:00+00:00"])
        self.assertFalse(calendar.due(self.schedule, NOW))

    def test_due_after_release_time_and_only_on_release_date(self):
        self.assertFalse(calendar.due(self.schedule, datetime(2026, 10, 29, 12, 29, tzinfo=timezone.utc)))
        self.assertTrue(calendar.due(self.schedule, datetime(2026, 10, 29, 12, 30, tzinfo=timezone.utc)))
        self.assertFalse(calendar.due(self.schedule, datetime(2026, 10, 30, 14, 17, tzinfo=timezone.utc)))

    def test_eastern_date_is_used_at_utc_midnight(self):
        # Oct 30 00:17 UTC is still Oct 29 in Eastern time.
        self.assertTrue(calendar.due(self.schedule, datetime(2026, 10, 30, 0, 17, tzinfo=timezone.utc)))

    def test_bls_eastern_timezone_observes_summer_and_winter_offsets(self):
        text = self.bls.replace("20261110T083000", "20260710T083000")
        events = calendar.bls_events(text)
        stamps = {stamp.isoformat() for _, _, stamp in events}
        self.assertIn("2026-07-10T12:30:00+00:00", stamps)
        self.assertIn("2026-12-10T13:30:00+00:00", stamps)

    def test_bls_utc_timestamp_and_iana_timezone_are_supported(self):
        utc = self.bls.replace("DTSTART;TZID=US-Eastern:20261110T083000", "DTSTART:20261110T133000Z")
        self.assertEqual(calendar.build_schedule(utc, self.bea, NOW), self.schedule)
        iana = self.bls.replace("TZID=US-Eastern", "TZID=America/New_York")
        self.assertEqual(calendar.build_schedule(iana, self.bea, NOW), self.schedule)

    def test_missing_required_bea_release_fails_refresh(self):
        feed = json.loads(self.bea)
        del feed["Gross Domestic Product"]
        with self.assertRaises(KeyError):
            calendar.build_schedule(self.bls, json.dumps(feed), NOW)

    def test_empty_or_exhausted_source_fails_validation(self):
        with self.assertRaisesRegex(ValueError, "no upcoming Consumer Price Index"):
            calendar.build_schedule(self.bls.replace("Consumer Price Index", "Other release").replace("Consumer Price In\n dex", "Other release"), self.bea, NOW)
        with self.assertRaisesRegex(ValueError, "no upcoming"):
            calendar.due(self.schedule, datetime(2027, 1, 1, tzinfo=timezone.utc))

    def test_invalid_and_timezone_free_timestamps_fail(self):
        for timestamp in ("invalid", "2026-10-29T08:30:00"):
            with self.subTest(timestamp=timestamp), self.assertRaises(ValueError):
                calendar.parse_timestamp(timestamp)

    def test_incomplete_bls_calendar_fails(self):
        with self.assertRaisesRegex(ValueError, "complete iCalendar"):
            calendar.build_schedule(self.bls.replace("END:VCALENDAR", ""), self.bea, NOW)

    def test_failed_download_or_invalid_feed_preserves_saved_file(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "schedule.json"
            output.write_text("previous schedule\n")
            for responses in ([OSError("BLS offline")], [self.bls, OSError("BEA offline")], [self.bls, "{}"]):
                with self.subTest(responses=type(responses[-1]).__name__), patch.object(calendar, "download", side_effect=responses):
                    with self.assertRaises((OSError, KeyError)):
                        calendar.refresh(output, NOW)
                    self.assertEqual(output.read_text(), "previous schedule\n")

    def test_successful_refresh_writes_the_validated_schedule(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "schedule.json"
            with patch.object(calendar, "download", side_effect=[self.bls, self.bea]):
                calendar.refresh(output, NOW)
            self.assertEqual(json.loads(output.read_text()), self.schedule)

    def test_due_cli_reports_missing_saved_schedule(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPTS / "release-calendar.py"), "due", "/nonexistent/realtalk-calendar.json"],
            capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertIn("Calendar error", result.stderr)


if __name__ == "__main__":
    unittest.main()
