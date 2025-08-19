#!/usr/bin/env python3
import argparse
import re
from pathlib import Path

_comment_re = re.compile(r'(?<!\\)#.*$')  # strip unescaped trailing comments

def strip_comment(line: str) -> str:
    no_comment = _comment_re.sub("", line)
    return no_comment.replace(r"\#", "#").strip()

def convert(input_path: Path, output_path: Path) -> None:
    with input_path.open(encoding="utf-8") as f:
        stations = []
        seen = set()
        for raw in f:
            line = strip_comment(raw)
            if not line:
                continue
            key = line.casefold()          # case-insensitive de-dup key
            if key in seen:
                continue
            seen.add(key)
            stations.append(line)

    # Sort by code (case-insensitive), keep original casing in output
    stations.sort(key=lambda s: s.casefold())

    with output_path.open("w", encoding="utf-8") as out:
        for i, station in enumerate(stations):
            s = station.replace("'", "\\'")
            is_last = (i == len(stations) - 1)
            fragment = f"{{code:'{s}', name:'{s}'}}"
            out.write(fragment + ("" if is_last else ",") + "\n")

def main():
    parser = argparse.ArgumentParser(
        description="Convert station list into JSON-like fragments, ignoring # comments, de-duplicating, and sorting by code."
    )
    parser.add_argument("input_file", type=Path, help="Path to the input text file")
    parser.add_argument("output_file", type=Path, help="Path to write the output file")
    args = parser.parse_args()
    convert(args.input_file, args.output_file)

if __name__ == "__main__":
    main()
