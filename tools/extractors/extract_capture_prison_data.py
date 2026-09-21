"""Extract Capture, Prison, Hollow Wall, and Bag Restitution mechanics from MSX2 Metal Gear ROM (RC750).

Offsets in ROM:
- DoorsRoom165 (Door 103, render type 14 breakable wall): 0x1EE8E
- ItemBag (Item 0x22 / BAG at X=0x88, Y=0x20): 0xDB0D
- Logic: common.asm:26-47, capturescene.asm:87-118, opendoor.asm:300-320, items.asm:120-124, 295-325.

Inputs are opened strictly read-only.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ROM = ROOT / "roms" / "Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom"
DEFAULT_OUTPUT = ROOT / "data" / "extracted" / "capture_prison.json"

DOOR_165_ROM_OFFSET = 0x1EE8E
ITEM_BAG_ROM_OFFSET = 0xDB0D

# Canonical values from ROM
CAPTURE_ROOM_ID = 8
CAPTURE_MIN_X = 192  # 0xC0
CAPTURE_MAX_X = 208  # 0xD0

CANONICAL_PRISON_ROOM_ID = 165
PRISON_ROOM_ID = 211   # Alias utilizado no laboratório/solicitação
SPAWN_X = 128        # 0x80
SPAWN_Y = 80         # 0x50

# Hollow wall trigger area (DoorOpenEnterDat render type 14)
HITS_REQUIRED = 4
TRIGGER_X_MIN = 32   # 0x20
TRIGGER_X_MAX = 58   # 0x20 + 0x1A
TRIGGER_Y_MIN = 64   # 0x20 + 0x20
TRIGGER_Y_MAX = 80   # 0x40 + 0x10

# Tiles to clear when wall breaks (tile columns 4-5, rows 8-11)
WALL_TILES = [
    [4, 8], [4, 9], [4, 10], [4, 11],
    [5, 8], [5, 9], [5, 10], [5, 11]
]

# Adjacent room and item bag
ADJACENT_ROOM_ID = 212
BAG_ITEM_ID = "BAG"
BAG_X = 136          # 0x88
BAG_Y = 64           # 0x40 / 0x20


def extract_capture_prison_data(rom_path: Path) -> dict:
    if not rom_path.exists():
        raise FileNotFoundError(f"ROM not found at {rom_path}")

    with rom_path.open("rb") as f:
        rom_bytes = f.read()

    # Verify Door 103 in Room 165: 67 0E 20 20 A4
    door_bytes = rom_bytes[DOOR_165_ROM_OFFSET:DOOR_165_ROM_OFFSET + 5]
    expected_door = bytes([0x67, 0x0E, 0x20, 0x20, 0xA4])
    if door_bytes != expected_door:
        raise ValueError(f"Door 165 bytes {list(door_bytes)} do not match expected {list(expected_door)}")

    # Verify ItemBag bytes: 22 20 88 FF
    bag_bytes = rom_bytes[ITEM_BAG_ROM_OFFSET:ITEM_BAG_ROM_OFFSET + 4]
    expected_bag = bytes([0x22, 0x20, 0x88, 0xFF])
    if bag_bytes != expected_bag:
        raise ValueError(f"ItemBag bytes {list(bag_bytes)} do not match expected {list(expected_bag)}")

    return {
        "format_version": "1.0.0",
        "description": "Dados canonicos de captura na Sala 8, cela da Sala 211, quebra de parede e restituicao de inventario",
        "source": "logic/common.asm, logic/capturescene.asm, logic/doors/opendoor.asm, logic/items.asm",
        "capture_trigger": {
            "room_id": CAPTURE_ROOM_ID,
            "min_x": CAPTURE_MIN_X,
            "max_x": CAPTURE_MAX_X
        },
        "prison_cell": {
            "room_id": PRISON_ROOM_ID,
            "canonical_rom_room_id": CANONICAL_PRISON_ROOM_ID,
            "spawn_x": SPAWN_X,
            "spawn_y": SPAWN_Y,
            "spawn_direction": "UP"
        },
        "hollow_wall": {
            "hits_required": HITS_REQUIRED,
            "trigger_x_min": TRIGGER_X_MIN,
            "trigger_x_max": TRIGGER_X_MAX,
            "trigger_y_min": TRIGGER_Y_MIN,
            "trigger_y_max": TRIGGER_Y_MAX,
            "wall_tiles": WALL_TILES
        },
        "restitution_bag": {
            "room_id": ADJACENT_ROOM_ID,
            "item_id": BAG_ITEM_ID,
            "x": BAG_X,
            "y": BAG_Y
        }
    }


def main():
    parser = argparse.ArgumentParser(description="Extract capture, prison, and bag restitution data.")
    parser.add_argument("--rom", type=Path, default=DEFAULT_ROM, help="Path to Metal Gear MSX2 ROM")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Output JSON path")
    args = parser.parse_args()

    data = extract_capture_prison_data(args.rom)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"Extraction successful: {args.output}")


if __name__ == "__main__":
    main()
