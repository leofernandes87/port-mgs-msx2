"""Extração e validação dos dados canônicos da arma Remote-Controlled Missile (RC Missile).

Offsets na ROM MSX2 RC750:
- 0x48DE: Tabela de velocidades direcionais (MissileIniSpeed: -4, 0, 4, 0, 0, -4, 0, 4)
- 0x51D6: Tabelas de capacidade máxima de munição por patente (MaxAmmoLv1..4)
Inputs são abertos estritamente em modo somente leitura.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ROM = ROOT / "roms" / "Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom"
DEFAULT_OUTPUT = ROOT / "data" / "extracted" / "missile_weapon.json"

SPEED_TABLE_ROM_OFFSET = 0x48DE
SPEED_TABLE_LENGTH = 8
CANONICAL_SPEEDS = [-4, 0, 4, 0, 0, -4, 0, 4]

MAX_AMMO_ROM_OFFSET = 0x51D6
MISSILE_AMMO_PER_RANK = {
    1: 5,
    2: 10,
    3: 15,
    4: 20
}

DAMAGE_VALUE = 5
EXPLOSION_DURATION_TICKS = 15  # 0x0F (missile.asm:165)


def extract_missile_data(rom_path: Path) -> dict:
    if not rom_path.exists():
        raise FileNotFoundError(f"ROM not found at {rom_path}")

    with rom_path.open("rb") as f:
        rom_bytes = f.read()

    # 1. Validar velocidades direcionais na ROM (0x48DE)
    if len(rom_bytes) < SPEED_TABLE_ROM_OFFSET + SPEED_TABLE_LENGTH:
        raise ValueError("ROM size too small for MissileIniSpeed table")

    raw_speeds = rom_bytes[SPEED_TABLE_ROM_OFFSET:SPEED_TABLE_ROM_OFFSET + SPEED_TABLE_LENGTH]
    extracted_speeds = [struct.unpack("b", bytes([b]))[0] for b in raw_speeds]
    if extracted_speeds != CANONICAL_SPEEDS:
        raise ValueError(
            f"Velocidades extraídas {extracted_speeds} não conferem com o padrão canônico {CANONICAL_SPEEDS}"
        )

    # 2. Validar capacidades de munição por rank (0x51D6)
    # Estrutura: 4 níveis, cada um com 8 words (16 bytes). Índice 6 = MISSILE.
    extracted_capacities = {}
    for rank in range(1, 5):
        off = MAX_AMMO_ROM_OFFSET + (rank - 1) * 16 + (6 * 2)
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
            "speed_table": f"0x{SPEED_TABLE_ROM_OFFSET:04X}",
            "max_ammo_table": f"0x{MAX_AMMO_ROM_OFFSET:04X}"
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
    parser = argparse.ArgumentParser(description="Extrair especificação da arma RC Missile da ROM do Metal Gear MSX2")
    parser.add_argument("--rom", type=Path, default=DEFAULT_ROM, help="Caminho para a ROM RC750")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUTPUT, help="Caminho de saída do JSON")
    args = parser.parse_args()

    data = extract_missile_data(args.rom)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"MISSILE_DATA_EXTRACT_OK: Dados do míssil teleguiado extraídos para {args.out}")


if __name__ == "__main__":
    main()
