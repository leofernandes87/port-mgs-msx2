"""Extract Electrified Floor & Power Switchboard/Panel data from MSX2 Metal Gear ROM (RC750).

Evidence:
- Routine ChkElectricFloor in ROM: offset 0x4C0D to 0x4C50
- Disassembly: logic/damageelectric.asm, logic/actors/powerswitch.asm, logic/damagetoenemy.asm, data/actorsinrooms.asm
- Rooms: 16, 37, 40, 110, 116
- Power Switch Actor ID: 0x2C (44)
- Damage per shock: 2 HP (DecrementLife_2)
- Shock delay timer: 8 ticks (DamageDelayTimer)
- Switch HP: 2 HP (idxActorLife[43])
- Weapon damages: Handgun/SMG = 0xFF (immune), Missile = 5 HP (MissileDamage[43])

Inputs are opened strictly read-only.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ROM = ROOT / "roms" / "Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom"
DEFAULT_PACKAGE = ROOT / "data" / "extracted" / "rc750-verified" / "package.json"
DEFAULT_OUTPUT = ROOT / "data" / "extracted" / "electrified_floor.json"

CHK_ELECTRIC_FLOOR_ROM_OFFSET = 0x4C0D
CHK_ELECTRIC_FLOOR_SIGNATURE = (
    b"\x3a\x30\xc1\xfe\x10\x01\x61\x60\x28\x15\xfe\x25\x28\x11\xfe\x6e\x28\x0d"
    b"\xfe\x28\x01\x46\x45\x28\x06\xfe\x74\x01\x41\x40\xc0"
)

ROOMS_METADATA = [
    {
        "room_id": 16,
        "name": "building_1_soldier_floor",
        "hazard_tile_ids": [0x60, 0x61],  # [96, 97]
        "power_panel": {
            "has_switch": True,
            "actor_type_id": 44,
            "x": 36,
            "y": 112,
            "hp": 2,
            "vulnerable_to": ["MISSILE"],
            "immune_to": ["HANDGUN", "SMG"],
        },
    },
    {
        "room_id": 37,
        "name": "building_1_switch_floor",
        "hazard_tile_ids": [0x60, 0x61],  # [96, 97]
        "power_panel": {
            "has_switch": True,
            "actor_type_id": 44,
            "x": 100,
            "y": 16,
            "hp": 2,
            "vulnerable_to": ["MISSILE"],
            "immune_to": ["HANDGUN", "SMG"],
        },
    },
    {
        "room_id": 40,
        "name": "roof_floor",
        "hazard_tile_ids": [0x45, 0x46],  # [69, 70]
        "power_panel": {
            "has_switch": True,
            "actor_type_id": 44,
            "x": 68,
            "y": 112,
            "hp": 2,
            "vulnerable_to": ["MISSILE"],
            "immune_to": ["HANDGUN", "SMG"],
        },
    },
    {
        "room_id": 110,
        "name": "building_2_switch_doors_floor",
        "hazard_tile_ids": [0x60, 0x61],  # [96, 97]
        "power_panel": {
            "has_switch": True,
            "actor_type_id": 44,
            "x": 68,
            "y": 16,
            "hp": 2,
            "vulnerable_to": ["MISSILE"],
            "immune_to": ["HANDGUN", "SMG"],
        },
    },
    {
        "room_id": 116,
        "name": "basement_metal_gear_floor",
        "hazard_tile_ids": [0x40, 0x41],  # [64, 65]
        "power_panel": {
            "has_switch": True,
            "actor_type_id": 44,
            "x": 32,
            "y": 16,
            "hp": 2,
            "vulnerable_to": ["MISSILE"],
            "immune_to": ["HANDGUN", "SMG"],
        },
    },
]


def extract_electrified_floor_data(rom_path: Path | None = None, package_path: Path | None = None) -> dict:
    source_info = "MSX2 Metal Gear RC750 Disassembly (logic/damageelectric.asm, logic/actors/powerswitch.asm)"

    if rom_path and rom_path.exists():
        with rom_path.open("rb") as f:
            rom_bytes = f.read()

        # Check signature at exact offset
        if len(rom_bytes) > CHK_ELECTRIC_FLOOR_ROM_OFFSET + len(CHK_ELECTRIC_FLOOR_SIGNATURE):
            actual_bytes = rom_bytes[
                CHK_ELECTRIC_FLOOR_ROM_OFFSET : CHK_ELECTRIC_FLOOR_ROM_OFFSET + len(CHK_ELECTRIC_FLOOR_SIGNATURE)
            ]
            if actual_bytes == CHK_ELECTRIC_FLOOR_SIGNATURE:
                source_info = f"ROM RC750 verified at offset {hex(CHK_ELECTRIC_FLOOR_ROM_OFFSET)}"

    # Load expanded tiles from package.json if available
    room_tiles_map: dict[int, list[int]] = {}
    if package_path and package_path.exists():
        with package_path.open("r", encoding="utf-8") as pf:
            pkg = json.load(pf)
            rooms = pkg.get("rooms", [])
            for r_entry in rooms:
                rid = r_entry.get("id")
                if rid is not None and "expanded_tiles" in r_entry:
                    room_tiles_map[rid] = r_entry["expanded_tiles"]

    rooms_data = []
    for meta in ROOMS_METADATA:
        rid = meta["room_id"]
        target_tile_ids = set(meta["hazard_tile_ids"])
        coords: list[list[int]] = []

        expanded_tiles = room_tiles_map.get(rid, [])
        for idx, t in enumerate(expanded_tiles):
            if t in target_tile_ids:
                coords.append([idx % 32, idx // 32])

        room_entry = {
            "room_id": rid,
            "name": meta["name"],
            "hazard_tile_ids": meta["hazard_tile_ids"],
            "hazard_tiles_count": len(coords),
            "hazard_tile_coords": coords,
            "power_panel": meta["power_panel"],
        }
        rooms_data.append(room_entry)

    data = {
        "format_version": "1.0.0",
        "description": "Dados canônicos de pisos eletrificados e painéis de força extraídos da ROM MSX2 RC750",
        "source": source_info,
        "damage_per_shock": 2,
        "shock_delay_ticks": 8,
        "sfx_id": 24,  # 0x18
        "total_electrified_rooms": len(rooms_data),
        "rooms": rooms_data,
    }
    return data


def main() -> None:
    parser = argparse.ArgumentParser(description="Extrai dados dos pisos eletrificados e painéis de força da ROM MSX2")
    parser.add_argument("--rom", type=Path, default=DEFAULT_ROM, help="Caminho para o binário da ROM")
    parser.add_argument("--package", type=Path, default=DEFAULT_PACKAGE, help="Caminho para package.json")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Destino do arquivo JSON")
    args = parser.parse_args()

    data = extract_electrified_floor_data(args.rom, args.package)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)

    print(f"Extração concluída com sucesso: {args.output}")
    print(f"Salas eletrificadas extraídas: {data['total_electrified_rooms']}")


if __name__ == "__main__":
    main()
