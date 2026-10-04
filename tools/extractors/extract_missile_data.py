"""Extração e validação dos dados canônicos da arma Remote-Controlled Missile (RC Missile).

Tabelas localizadas pelos bytes da fonte na ROM canônica, nunca por offset fixo:
- MissileIniSpeed (logic/weapon/missile.asm:80): velocidades direcionais (-4, 0, 4, 0, 0, -4, 0, 4)
- MaxAmmoLv1..MaxAmmoLv4 (logic/maxammo.asm:112-146): capacidade máxima de munição por patente
Inputs são abertos estritamente em modo somente leitura.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tools.rom import resolve_canonical_rom, REFERENCE
from tools.extractors.reference import Reference

DEFAULT_OUTPUT = ROOT / "data" / "extracted" / "missile_weapon.json"

SPEED_TABLE_LENGTH = 8
CANONICAL_SPEEDS = [-4, 0, 4, 0, 0, -4, 0, 4]

MAX_AMMO_TABLE_LENGTH = 4 * 16
MISSILE_AMMO_PER_RANK = {
    1: 5,
    2: 10,
    3: 15,
    4: 20
}

DAMAGE_VALUE = 5
EXPLOSION_DURATION_TICKS = 15  # 0x0F (missile.asm:165)


def extract_missile_data(rom_bytes: bytes, speed_offset: int, max_ammo_offset: int) -> dict:
    if len(rom_bytes) < speed_offset + SPEED_TABLE_LENGTH:
        raise ValueError("ROM size too small for MissileIniSpeed table")
    if len(rom_bytes) < max_ammo_offset + MAX_AMMO_TABLE_LENGTH:
        raise ValueError("ROM size too small for MaxAmmo tables")

    raw_speeds = rom_bytes[speed_offset:speed_offset + SPEED_TABLE_LENGTH]
    extracted_speeds = [struct.unpack("b", bytes([b]))[0] for b in raw_speeds]
    if extracted_speeds != CANONICAL_SPEEDS:
        raise ValueError(
            f"Velocidades extraídas {extracted_speeds} não conferem com o padrão canônico {CANONICAL_SPEEDS}"
        )

    # Estrutura: 4 níveis, cada um com 8 words (16 bytes). Índice 6 = MISSILE.
    extracted_capacities = {}
    for rank in range(1, 5):
        off = max_ammo_offset + (rank - 1) * 16 + (6 * 2)
        val = struct.unpack("<H", rom_bytes[off:off + 2])[0]
        # Converte representação BCD hex para inteiro decimal
        bcd_decimal = (val >> 8) * 100 + ((val & 0xF0) >> 4) * 10 + (val & 0x0F)
        extracted_capacities[rank] = bcd_decimal

    if extracted_capacities != MISSILE_AMMO_PER_RANK:
        raise ValueError(
            f"Capacidades extraídas {extracted_capacities} não conferem com o padrão canônico {MISSILE_AMMO_PER_RANK}"
        )

    return {
        "format_version": "1.0.0",
        "weapon_id": 7,
        "name": "MISSILE",
        "label": "Remote-Controlled Missile",
        "description": "Míssil teleguiado por controle remoto em tempo real (MSX2 RC750)",
        "source": "logic/weapon/missile.asm e logic/maxammo.asm",
        "rom_offsets": {
            "speed_table": f"0x{speed_offset:04X}",
            "max_ammo_table": f"0x{max_ammo_offset:04X}"
        },
        "directional_speeds": {
            "UP": {"speed_y": extracted_speeds[0], "speed_x": extracted_speeds[1]},
            "DOWN": {"speed_y": extracted_speeds[2], "speed_x": extracted_speeds[3]},
            "LEFT": {"speed_y": extracted_speeds[4], "speed_x": extracted_speeds[5]},
            "RIGHT": {"speed_y": extracted_speeds[6], "speed_x": extracted_speeds[7]}
        },
        "speed_pixels_per_tick": 4,
        "max_active_missiles": 1,
        "damage": DAMAGE_VALUE,
        "explosion_duration_ticks": EXPLOSION_DURATION_TICKS,
        "boundaries": {
            "min_x": 9,
            "max_x": 248,
            "min_y": 0,
            "max_y": 184
        },
        "ammo_capacity_per_rank": {
            "rank_1": extracted_capacities[1],
            "rank_2": extracted_capacities[2],
            "rank_3": extracted_capacities[3],
            "rank_4": extracted_capacities[4]
        },
        "primary_pickup_location": {
            "room_id": 149,
            "x": 160,
            "y": 32,
            "initial_units": 5
        }
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Extrair especificação da arma RC Missile da ROM canônica do Metal Gear MSX2")
    parser.add_argument("--rom", type=Path, help="ROM explícita; validada pelo hash canônico")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUTPUT, help="Caminho de saída do JSON")
    args = parser.parse_args()

    rom = resolve_canonical_rom(args.rom)
    ref = Reference(REFERENCE, rom.data)
    ref.literal("logic/weapon/missile.asm", "MissileIniSpeed")
    if len(ref.table("logic/maxammo.asm", "MaxAmmoLv1", "MaxAmmoVals")) != MAX_AMMO_TABLE_LENGTH:
        raise ValueError("MaxAmmoLv1..4 source tables changed size")
    data = extract_missile_data(rom.data, ref.symbols["MissileIniSpeed"], ref.symbols["MaxAmmoLv1"])
    data.update(rom.provenance(), evidence=[ref.evidence("MissileIniSpeed", SPEED_TABLE_LENGTH),
                                            ref.evidence("MaxAmmoLv1", MAX_AMMO_TABLE_LENGTH)])
    rom.assert_unchanged()
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"MISSILE_DATA_EXTRACT_OK: Dados do míssil teleguiado extraídos para {args.out}")


if __name__ == "__main__":
    main()
