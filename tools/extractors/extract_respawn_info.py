"""Extract reinforcement respawn table (RespawnInfo) from MSX2 Metal Gear ROM.

Offset in ROM: 0xC445 (Bank 6, offset 0x445).
Structure per room (189 rooms, 0 to 188):
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
DEFAULT_ROM = ROOT / "roms" / "Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom"
DEFAULT_OUTPUT = ROOT / "data" / "extracted" / "respawn_info.json"
RESPAWN_INFO_ROM_OFFSET = 0xC445
TOTAL_ROOMS = 189

ENEMY_NAMES = {
    0: "NONE",
    10: "GUARD_ALERT",
    11: "GUARD_REDALERT",
    22: "GUARD_JETPACK",
}


def extract_respawn_info(rom_path: Path) -> dict:
    if not rom_path.exists():
        raise FileNotFoundError(f"ROM not found at {rom_path}")

    with rom_path.open("rb") as f:
        rom_bytes = f.read()

    if len(rom_bytes) < RESPAWN_INFO_ROM_OFFSET + TOTAL_ROOMS * 3:
        raise ValueError("ROM size too small for RespawnInfo table")

    rooms = []
    for room_id in range(TOTAL_ROOMS):
        offset = RESPAWN_INFO_ROM_OFFSET + room_id * 3
        enemy_id = rom_bytes[offset]
        loc1 = rom_bytes[offset + 1]
        loc2 = rom_bytes[offset + 2]

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
    parser = argparse.ArgumentParser(description="Extract RespawnInfo from Metal Gear MSX2 ROM")
    parser.add_argument("--rom", type=Path, default=DEFAULT_ROM, help="Path to input ROM")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Path to output JSON")
    args = parser.parse_args()

    data = extract_respawn_info(args.rom)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)

    print(f"Extracted RespawnInfo for {len(data['rooms'])} rooms to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
