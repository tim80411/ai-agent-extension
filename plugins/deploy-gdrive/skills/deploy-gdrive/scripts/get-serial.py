#!/usr/bin/env python3
"""Manage deploy serial numbers in ~/.config/gdrive-deploy/serial.json"""

import json
import os
import sys
from datetime import date
from pathlib import Path

SERIAL_FILE = Path.home() / ".config" / "gdrive-deploy" / "serial.json"


def main():
    if len(sys.argv) < 2:
        print("Usage: get-serial.py <project_name>", file=sys.stderr)
        sys.exit(1)

    project = sys.argv[1]
    today = date.today().strftime("%Y%m%d")
    key = f"{project}_{today}"

    SERIAL_FILE.parent.mkdir(parents=True, exist_ok=True)

    data = {}
    if SERIAL_FILE.exists():
        with open(SERIAL_FILE) as f:
            try:
                data = json.load(f)
            except json.JSONDecodeError:
                data = {}

    serial = data.get(key, 0) + 1
    data[key] = serial

    with open(SERIAL_FILE, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(serial)


if __name__ == "__main__":
    main()
