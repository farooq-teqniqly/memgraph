#!/usr/bin/env python3
import argparse
import ast
import sys
from pathlib import Path

def transform_file(input_path: Path, output_path: Path) -> None:
    with input_path.open(encoding="utf-8") as inp, output_path.open("w", encoding="utf-8") as out:
        for lineno, raw in enumerate(inp, 1):
            line = raw.strip()
            if not line or line.lstrip().startswith("#"):
                continue  # skip blanks and full-line comments

            # Preserve whether the input line ended with a trailing comma
            had_trailing_comma = line.endswith(",")
            if had_trailing_comma:
                line = line[:-1].rstrip()

            try:
                record = ast.literal_eval(line)
            except Exception as e:
                print(f"Warning: could not parse line {lineno}: {raw.rstrip()}", file=sys.stderr)
                continue

            if not isinstance(record, list) or len(record) < 4:
                print(f"Warning: unexpected format on line {lineno}: {raw.rstrip()}", file=sys.stderr)
                continue

            # 1) Swap first and second items
            record[0], record[1] = record[1], record[0]

            # 2) Change 'NB' to 'SB' (3rd element)
            if isinstance(record[2], str) and record[2] == "NB":
                record[2] = "SB"

            if isinstance(record[2], str) and record[2] == "EB":
                record[2] = "WB"

            # 3) Write out, preserving trailing comma if it existed
            transformed = str(record) + ("," if had_trailing_comma else "")
            out.write(transformed + "\n")

def main():
    parser = argparse.ArgumentParser(
        description="Transform list-literal lines by swapping first two items and changing 'NB' to 'SB'."
    )
    parser.add_argument("input_file", type=Path, help="Path to the input text file")
    parser.add_argument("output_file", type=Path, help="Path to write the output text file")
    args = parser.parse_args()
    transform_file(args.input_file, args.output_file)

if __name__ == "__main__":
    main()
