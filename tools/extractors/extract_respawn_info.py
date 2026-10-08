"""Extract reinforcement respawn table (RespawnInfo) from the canonical Metal Gear MSX2 ROM.

RespawnInfo is located by its source bytes (data/respawninfo.asm:13); the entry count
comes from that table, never from a fixed offset or length.
Structure per room:
  Byte 0: Enemy ID (0=No respawn, 0x0A=Guard Alert, 0x0B=Guard Red Alert, 0x16=Jetpack)
  Byte 1: Location 1 nibbles: Y = loc & 0xF0, X = (loc & 0x0F) * 16
  Byte 2: Location 2 nibbles: Y = loc & 0xF0, X = (loc & 0x0F) * 16

Inputs are opened strictly read-only.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tools.rom import resolve_canonical_rom, REFERENCE, canonical_data_dir
from tools.extractors.reference import Reference

DEFAULT_OUTPUT = canonical_data_dir() / "respawn_info.json"
ENTRY_SIZE = 3

ENEMY_NAMES = {
    0: "NONE",
    10: "GUARD_ALERT",
    11: "GUARD_REDALERT",
    22: "GUARD_JETPACK",
}


def extract_respawn_info(rom_bytes: bytes, offset: int, total_rooms: int) -> dict:
    if len(rom_bytes) < offset + total_rooms * ENTRY_SIZE:
        raise ValueError("ROM size too small for RespawnInfo table")

    rooms = []
    for room_id in range(total_rooms):
        entry = offset + room_id * ENTRY_SIZE
        enemy_id = rom_bytes[entry]
        loc1 = rom_bytes[entry + 1]
        loc2 = rom_bytes[entry + 2]

        y1 = loc1 & 0xF0
        x1 = (loc1 & 0x0F) * 16
        y2 = loc2 & 0xF0
        x2 = (loc2 & 0x0F) * 16

        rooms.append({
            "room_id": room_id,
            "enemy_id": enemy_id,
            "enemy_name": ENEMY_NAMES.get(enemy_id, f"ENEMY_{enemy_id}"),
            "spawn_points": [
                {"x": x1, "y": y1},
                {"x": x2, "y": y2},
            ],
        })

    return {
        "format_version": "1.0.0",
        "rooms": rooms,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract RespawnInfo from the canonical Metal Gear MSX2 ROM")
    parser.add_argument("--rom", type=Path, help="Explicit ROM path; validated against the canonical hash")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Path to output JSON")
    args = parser.parse_args()

    rom = resolve_canonical_rom(args.rom)
    ref = Reference(REFERENCE, rom.data)
    table = ref.literal("data/respawninfo.asm", "RespawnInfo")
    if len(table) % ENTRY_SIZE:
        raise ValueError("RespawnInfo source table is not a whole number of entries")
    data = extract_respawn_info(rom.data, ref.symbols["RespawnInfo"], len(table) // ENTRY_SIZE)
    data.update(rom.provenance(), evidence=ref.evidence("RespawnInfo", len(table)))
    rom.assert_unchanged()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

    print(f"Extracted RespawnInfo for {len(data['rooms'])} rooms to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
