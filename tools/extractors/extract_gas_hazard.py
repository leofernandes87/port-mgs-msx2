"""Extract Gas Hazard and Gas Mask mechanics from the canonical Metal Gear MSX2 ROM.

GasRooms is located by its source bytes (logic/damagegas.asm:53), never by a fixed offset.
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

DEFAULT_OUTPUT = ROOT / "data" / "extracted" / "gas_hazard.json"
GAS_ROOMS_COUNT = 9

# Canonical rooms in ROM (damagegas.asm:53):
# GasRooms: db 29, 94, 96, 97, 98, 100, 101, 112, 114
CANONICAL_GAS_ROOMS = [29, 94, 96, 97, 98, 100, 101, 112, 114]
DAMAGE_INTERVAL_TICKS = 16  # 0x10 (damagegas.asm:34)
DAMAGE_PER_TICK = 2         # 2 HP (damagegas.asm:45)
PROTECTION_ITEM = "GAS_MASK"


def extract_gas_hazard(rom_bytes: bytes, offset: int) -> dict:
    if len(rom_bytes) < offset + GAS_ROOMS_COUNT:
        raise ValueError("ROM size too small for GasRooms table")

    extracted_rooms = list(rom_bytes[offset:offset + GAS_ROOMS_COUNT])

    if extracted_rooms != CANONICAL_GAS_ROOMS:
        raise ValueError(
            f"Extracted rooms {extracted_rooms} do not match canonical expectation {CANONICAL_GAS_ROOMS}"
        )

    return {
        "format_version": "1.0.0",
        "description": "Tabela de perigo de gás tóxico e proteção por Máscara de Gás (MSX2 RC750)",
        "source": f"damagegas.asm:53 GasRooms (ROM offset 0x{offset:04X})",
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
    parser = argparse.ArgumentParser(description="Extrair especificação de salas de gás da ROM canônica do Metal Gear MSX2")
    parser.add_argument("--rom", type=Path, help="ROM explícita; validada pelo hash canônico")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUTPUT, help="Caminho de saída do JSON")
    args = parser.parse_args()

    rom = resolve_canonical_rom(args.rom)
    ref = Reference(REFERENCE, rom.data)
    ref.literal("logic/damagegas.asm", "GasRooms")
    data = extract_gas_hazard(rom.data, ref.symbols["GasRooms"])
    data.update(rom.provenance(), evidence=ref.evidence("GasRooms", GAS_ROOMS_COUNT))
    rom.assert_unchanged()
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"GAS_HAZARD_EXTRACT_OK: {data['total_rooms']} salas de gás extraídas para {args.out}")


if __name__ == "__main__":
    main()
