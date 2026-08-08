#!/usr/bin/env python3
"""Convert a flat binary (.bin) to iverilog $readmemh format (.mem).

Usage:
    python3 scripts/elf_to_mem.py build/sw/full_test.bin build/sw/full_test.mem
"""
import sys


def main():
    if len(sys.argv) != 3:
        print("Usage: elf_to_mem.py <input.bin> <output.mem>")
        sys.exit(1)

    with open(sys.argv[1], "rb") as f:
        data = f.read()

    # Pad to multiple of 4 bytes (word-aligned)
    while len(data) % 4 != 0:
        data += b"\x00"

    with open(sys.argv[2], "w") as f:
        for i in range(0, len(data), 4):
            word = int.from_bytes(data[i : i + 4], "little")
            f.write(f"{word:08X}\n")

    print(f"Wrote {len(data) // 4} words to {sys.argv[2]}")


if __name__ == "__main__":
    main()
