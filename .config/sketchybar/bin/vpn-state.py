#!/usr/bin/env python3
"""Incrementally read AWS VPN Client transitions, scoped to the live GUI process.

The client writes one GUI log per UTC day (aws_vpn_client_gui_YYYYMMDD.log).
The tunnel lives and dies with the GUI app, so its process start time bounds
which log lines count. State carries across daily rotation while the same
process runs; the renderer's 3-minute "Profile connected/disconnected"
heartbeat corrects any drift.
"""
import datetime
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

LIMIT = 256 * 1024
LOG_DIR = Path.home() / ".config/AWSVPNClient/logs"
PROCESS = "/Applications/AWS VPN Client/AWS VPN Client.app/Contents/MacOS/AWS VPN Client"
TRANSITIONS = {
    "Tray state changed to connected": "Connected",
    "Tray state changed to connecting": "Restoring",
    "Tray state changed to none": "Disconnected",
    "[poll] Profile connected:": "Connected",
    "[poll] Profile disconnected:": "Disconnected",
}
STAMP = re.compile(r"^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})")


def client():
    result = subprocess.run(["pgrep", "-xf", re.escape(PROCESS)], capture_output=True, text=True)
    if result.returncode:
        return None
    pid = result.stdout.splitlines()[0]
    result = subprocess.run(["ps", "-p", pid, "-o", "lstart="], capture_output=True,
                            text=True, env={**os.environ, "LC_ALL": "C"})
    try:
        started = datetime.datetime.strptime(result.stdout.strip(), "%a %b %d %H:%M:%S %Y").timestamp()
    except ValueError:
        return None
    return pid, started


def latest_log():
    logs = sorted(LOG_DIR.glob("aws_vpn_client_gui_*.log"))
    if not logs:
        raise FileNotFoundError(LOG_DIR)
    return logs[-1]


def read_state(cache, live):
    if live is None:
        return "Disconnected", {"state": "Disconnected"}
    pid, started = live
    log = latest_log()
    with log.open("rb") as stream:
        stat = os.fstat(stream.fileno())
        identity = [stat.st_dev, stat.st_ino, pid, started]
        same = cache.get("identity") == identity and 0 <= cache.get("offset", -1) <= stat.st_size
        same_process = cache.get("identity", [None] * 4)[2:] == [pid, started]
        offset = cache["offset"] if same else max(0, stat.st_size - LIMIT)
        # A new day's log under the same process starts from the known state.
        state = cache.get("state", "Unknown") if same or same_process else "Unknown"
        pending = cache.get("pending", "") if same else ""
        if stat.st_size - offset > LIMIT:
            offset, pending = max(0, stat.st_size - LIMIT), ""
            state = state if same_process else "Unknown"
            same = False
        stream.seek(offset)
        raw = stream.read(LIMIT)
        end = stream.tell()
    # If bounded initialization starts within a line, discard that fragment.
    if offset and not same:
        raw = raw.partition(b"\n")[2]
    lines = (pending + raw.decode("utf-8", errors="replace")).split("\n")
    pending = lines.pop()
    for line in lines:
        match = STAMP.match(line)
        if not match:
            continue
        try:
            stamp = datetime.datetime.strptime(match[1], "%Y-%m-%dT%H:%M:%S").replace(
                tzinfo=datetime.timezone.utc).timestamp()
        except ValueError:
            continue
        if stamp < started:
            continue
        for text, value in TRANSITIONS.items():
            if text in line:
                state = value
    return state, {"identity": identity, "offset": end, "pending": pending, "state": state}


def main():
    root = Path.home() / ".cache/sketchybar"
    root.mkdir(parents=True, exist_ok=True)
    target = root / "vpn-state.json"
    with (root / "vpn-state.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            cache = json.loads(target.read_text())
            if not isinstance(cache, dict):
                cache = {}
        except (OSError, ValueError):
            cache = {}
        try:
            state, cache = read_state(cache, client())
        except (OSError, ValueError, TypeError):
            state, cache = "Unknown", {}
        fd, tmp = tempfile.mkstemp(dir=root, prefix=".vpn-state-")
        try:
            with os.fdopen(fd, "w") as stream:
                json.dump(cache, stream)
            os.replace(tmp, target)
        finally:
            if os.path.exists(tmp):
                os.unlink(tmp)
        print(state)


if __name__ == "__main__":
    main()
