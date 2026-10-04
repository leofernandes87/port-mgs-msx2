"""Extract Electrified Floor & Power Switchboard/Panel data from the canonical Metal Gear MSX2 ROM.

Evidence:
- Routine ChkElectricFloor (logic/damageelectric.asm): reviewed instruction signature, located once in the ROM
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
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tools.rom import resolve_canonical_rom, REFERENCE
from tools.extractors.reference import Reference

DEFAULT_PACKAGE = ROOT / "data" / "extracted" / "rc750-verified" / "package.json"
DEFAULT_OUTPUT = ROOT / "data" / "extracted" / "electrified_floor.json"

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


def extract_electrified_floor_data(rom_bytes: bytes, routine_offset: int, package: dict) -> dict:
    actual_bytes = rom_bytes[routine_offset:routine_offset + len(CHK_ELECTRIC_FLOOR_SIGNATURE)]
    if actual_bytes != CHK_ELECTRIC_FLOOR_SIGNATURE:
        raise ValueError("ChkElectricFloor signature not found at the resolved offset")
    source_info = f"ROM verified: ChkElectricFloor at offset {hex(routine_offset)}"

    room_tiles_map: dict[int, list[int]] = {}
    for r_entry in package.get("rooms", []):
        rid = r_entry.get("id")
        if rid is not None and "expanded_tiles" in r_entry:
            room_tiles_map[rid] = r_entry["expanded_tiles"]
    missing = [meta["room_id"] for meta in ROOMS_METADATA if meta["room_id"] not in room_tiles_map]
    if missing:
        raise ValueError(f"Package lacks expanded tiles for electrified rooms {missing}")

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
    parser.add_argument("--rom", type=Path, help="ROM explícita; validada pelo hash canônico")
    parser.add_argument("--package", type=Path, default=DEFAULT_PACKAGE, help="Caminho para package.json")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="Destino do arquivo JSON")
    args = parser.parse_args()

    rom = resolve_canonical_rom(args.rom)
    package = json.loads(args.package.read_text(encoding="utf-8"))
    if package.get("manifest", {}).get("input_sha256") != rom.sha256:
        raise ValueError(f"{args.package} was not extracted from the canonical ROM; re-extract it first")
    ref = Reference(REFERENCE, rom.data)
    ref.signature("logic/damageelectric.asm", "ChkElectricFloor", CHK_ELECTRIC_FLOOR_SIGNATURE)
    data = extract_electrified_floor_data(rom.data, ref.symbols["ChkElectricFloor"], package)
    data.update(rom.provenance(), evidence=ref.evidence("ChkElectricFloor", len(CHK_ELECTRIC_FLOOR_SIGNATURE)))
    rom.assert_unchanged()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=True)

    print(f"Extração concluída com sucesso: {args.output}")
    print(f"Salas eletrificadas extraídas: {data['total_electrified_rooms']}")


if __name__ == "__main__":
    main()
