#!/usr/bin/env python3
"""Refresh the saved BLS/BEA calendar, or check whether a release is due today."""

import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import sys
import tempfile
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo


EASTERN = ZoneInfo("America/New_York")
BLS_URL = "https://www.bls.gov/schedule/news_release/bls.ics"
BEA_URL = "https://apps.bea.gov/API/signup/release_dates.json"
RELEASES = {
    "Consumer Price Index": "bls",
    "Gross Domestic Product": "bea",
    "Personal Income and Outlays": "bea",
}


def download(url):
    # BLS rejects the default urllib request without these headers.
    request = Request(url, headers={"User-Agent": "Mozilla/5.0", "Accept": "*/*"})
    with urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8-sig")


def parse_timestamp(value):
    stamp = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if stamp.utcoffset() is None:
        raise ValueError(f"Release timestamp has no timezone: {value}")
    return stamp.astimezone(timezone.utc)


def bls_events(text):
    """Read the event properties used by BLS, including folded ICS lines."""
    lines = []
    for line in text.splitlines():
        if line.startswith((" ", "\t")) and lines:
            lines[-1] += line[1:]
        else:
            lines.append(line)
    if not lines or lines[0] != "BEGIN:VCALENDAR" or lines[-1] != "END:VCALENDAR":
        raise ValueError("BLS did not return a complete iCalendar file.")

    events = []
    event = None
    for line in lines:
        if line == "BEGIN:VEVENT":
            event = {}
        elif line == "END:VEVENT":
            if event is None:
                raise ValueError("BLS calendar has an unmatched event ending.")
            if event.get("SUMMARY", (None, ""))[1] == "Consumer Price Index" and event.get(
                "STATUS", (None, "")
            )[1] != "CANCELLED":
                properties, value = event["DTSTART"]
                stamp = datetime.strptime(value.rstrip("Z"), "%Y%m%dT%H%M%S")
                if value.endswith("Z"):
                    stamp = stamp.replace(tzinfo=timezone.utc)
                else:
                    tzid = properties.get("TZID", "").strip('"')
                    # This is the name of BLS's embedded Eastern VTIMEZONE.
                    zone = "America/New_York" if tzid == "US-Eastern" else tzid
                    if not zone:
                        raise ValueError("BLS CPI release has no timezone.")
                    stamp = stamp.replace(tzinfo=ZoneInfo(zone))
                events.append(("bls", "Consumer Price Index", stamp.astimezone(timezone.utc)))
            event = None
        elif event is not None:
            key, separator, value = line.partition(":")
            if separator:
                name, *parameters = key.split(";")
                properties = dict(parameter.split("=", 1) for parameter in parameters)
                event[name] = (properties, value)
    if event is not None:
        raise ValueError("BLS calendar has an unfinished event.")
    return events


def bea_events(text):
    feed = json.loads(text)
    events = []
    for release in ("Gross Domestic Product", "Personal Income and Outlays"):
        for value in feed[release]["release_dates"]:
            events.append(("bea", release, parse_timestamp(value)))
    return events


def validate_schedule(schedule, now):
    parse_timestamp(schedule["refreshed_at"])
    events = []
    for event in schedule["events"]:
        if RELEASES.get(event["release"]) != event["source"]:
            raise ValueError("Saved calendar contains an unrecognized release.")
        events.append((event["release"], parse_timestamp(event["at"])))
    today = now.astimezone(EASTERN).date()
    for release in RELEASES:
        if not any(name == release and stamp.astimezone(EASTERN).date() >= today for name, stamp in events):
            raise ValueError(
                f"Calendar has no upcoming {release} release. Run Calendar refresh."
            )
    return events


def build_schedule(bls_text, bea_text, now):
    today = now.astimezone(EASTERN).date()
    events = sorted(
        {
            (source, release, stamp)
            for source, release, stamp in bls_events(bls_text) + bea_events(bea_text)
            if stamp.astimezone(EASTERN).date() >= today
        },
        key=lambda event: (event[2], event[1]),
    )
    schedule = {
        "refreshed_at": now.astimezone(timezone.utc).isoformat(),
        "events": [
            {"source": source, "release": release, "at": stamp.isoformat()}
            for source, release, stamp in events
        ],
    }
    validate_schedule(schedule, now)
    return schedule


def refresh(output, now):
    schedule = build_schedule(download(BLS_URL), download(BEA_URL), now)
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    # Keep an existing schedule intact if either feed or its validation fails.
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=output.parent, delete=False) as handle:
        temporary = Path(handle.name)
        json.dump(schedule, handle, indent=2)
        handle.write("\n")
    temporary.replace(output)


def due(schedule, now):
    events = validate_schedule(schedule, now)
    today = now.astimezone(EASTERN).date()
    return any(stamp.astimezone(EASTERN).date() == today and stamp <= now for _, stamp in events)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    refresh_parser = commands.add_parser("refresh", help="Download and validate both agency calendars")
    refresh_parser.add_argument("--output", required=True)
    due_parser = commands.add_parser("due", help="Print true if a release is due today, otherwise false")
    due_parser.add_argument("schedule")
    args = parser.parse_args()
    now = datetime.now(timezone.utc)
    try:
        if args.command == "refresh":
            refresh(args.output, now)
        else:
            schedule = json.loads(Path(args.schedule).read_text(encoding="utf-8"))
            print("true" if due(schedule, now) else "false")
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"Calendar error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
