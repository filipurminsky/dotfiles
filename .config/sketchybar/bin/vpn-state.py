#!/usr/bin/env python3
"""Incrementally read GlobalProtect transitions, scoped to the live daemon."""
import datetime
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile

LIMIT = 256 * 1024
TRANSITIONS = {
    "Set state to Connected": "Connected",
    "Set state to Disconnected": "Disconnected",
    "Set state to Restoring VPN Connection": "Restoring",
}


def daemon():
    result = subprocess.run(["pgrep", "-x", "PanGPS"], capture_output=True, text=True)
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


def read_state(log, cache, live):
    if live is None:
        return "Disconnected", {"state": "Disconnected"}
    pid, started = live
    with log.open("rb") as stream:
        stat = os.fstat(stream.fileno())
        identity = [stat.st_dev, stat.st_ino, pid, started]
        same = cache.get("identity") == identity and 0 <= cache.get("offset", -1) <= stat.st_size
        offset = cache["offset"] if same else max(0, stat.st_size - LIMIT)
        state = cache.get("state", "Unknown") if same else "Unknown"
        pending = cache.get("pending", "") if same else ""
        if stat.st_size - offset > LIMIT:
            offset, state, pending = max(0, stat.st_size - LIMIT), "Unknown", ""
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
        match = re.search(r"\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}", line)
        if not match:
            continue
        try:
            stamp = datetime.datetime.strptime(match[0], "%m/%d/%Y %H:%M:%S").timestamp()
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
            state, cache = read_state(Path("/Library/Logs/PaloAltoNetworks/GlobalProtect/PanGPS.log"),
                                      cache, daemon())
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
