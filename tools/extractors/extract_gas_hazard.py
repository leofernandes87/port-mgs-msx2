"""Extract Gas Hazard and Gas Mask mechanics from MSX2 Metal Gear ROM (RC750).

Offset in ROM: 0x4C79 (GasRooms table, 9 rooms).
Inputs are opened strictly read-only.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ROM = ROOT / "roms" / "Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom"
DEFAULT_OUTPUT = ROOT / "data" / "extracted" / "gas_hazard.json"
GAS_ROOMS_ROM_OFFSET = 0x4C79
GAS_ROOMS_COUNT = 9

# Canonical rooms in ROM (damagegas.asm:53):
# GasRooms: db 29, 94, 96, 97, 98, 100, 101, 112, 114
CANONICAL_GAS_ROOMS = [29, 94, 96, 97, 98, 100, 101, 112, 114]
DAMAGE_INTERVAL_TICKS = 16  # 0x10 (damagegas.asm:34)
DAMAGE_PER_TICK = 2         # 2 HP (damagegas.asm:45)
PROTECTION_ITEM = "GAS_MASK"


def extract_gas_hazard(rom_path: Path) -> dict:
    if not rom_path.exists():
        raise FileNotFoundError(f"ROM not found at {rom_path}")

    with rom_path.open("rb") as f:
        rom_bytes = f.read()

    if len(rom_bytes) < GAS_ROOMS_ROM_OFFSET + GAS_ROOMS_COUNT:
        raise ValueError("ROM size too small for GasRooms table")

    extracted_rooms = list(rom_bytes[GAS_ROOMS_ROM_OFFSET:GAS_ROOMS_ROM_OFFSET + GAS_ROOMS_COUNT])

    if extracted_rooms != CANONICAL_GAS_ROOMS:
        raise ValueError(
            f"Extracted rooms {extracted_rooms} do not match canonical expectation {CANONICAL_GAS_ROOMS}"
        )

    return {
        "format_version": "1.0.0",
        "description": "Tabela de perigo de gás tóxico e proteção por Máscara de Gás (MSX2 RC750)",
        "source": "damagegas.asm:53 (ROM offset 0x4C79)",
        "damage_interval_ticks": DAMAGE_INTERVAL_TICKS,
        "damage_per_interval": DAMAGE_PER_TICK,
        "protection_item": PROTECTION_ITEM,
        "gas_mask_location": {
            "room_id": 138,
            "x": 72,
            "y": 32
        },
        "gas_rooms": extracted_rooms,
        "total_rooms": len(extracted_rooms)
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Extrair especificação de salas de gás da ROM do Metal Gear MSX2")
    parser.add_argument("--rom", type=Path, default=DEFAULT_ROM, help="Caminho para a ROM RC750")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUTPUT, help="Caminho de saída do JSON")
    args = parser.parse_args()

    data = extract_gas_hazard(args.rom)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"GAS_HAZARD_EXTRACT_OK: {data['total_rooms']} salas de gás extraídas para {args.out}")


if __name__ == "__main__":
    main()
