#!/usr/bin/env python3
"""
tools/extractors/extract_door_sprites.py

Extrator reprodutível em Python 3 dos sprites e painéis de portas autênticos
do Metal Gear MSX2 original (RC750).

Reverte os dados gráficos em formato V9938 Screen 5 (4bpp planar/linear por tiles)
em external/MetalGear/gfx/doors.asm e a lógica de renderização em
external/MetalGear/logic/doors/drawdoors.asm:
- GfxDoorFront: Porta frontal militar com leitor de cartão (painel central 24x32 px)
- GfxDoorElevator: Porta de elevador de folhas duplas corrediças (painel central 24x32 px)
- GfxDoorDown: Soleira da porta sul (32x8 px)
- GfxDoorLeft: Porta oeste sheared em perspectiva 45° (8x60 px)
- GfxDoorRight: Porta leste sheared em perspectiva 45° (8x60 px)

Gera:
- godot/assets/protected/sprites/doors_msx.png (128x64 px, PNG 32-bit RGBA)
"""

import argparse
import os
import re
import struct
import sys
import zlib

DEFAULT_PALETTE_RAW = [
    0x00, 0x00, 0x00, 0x00, 0x11, 0x06, 0x33, 0x07,
    0x17, 0x01, 0x27, 0x03, 0x51, 0x01, 0x27, 0x06,
    0x71, 0x01, 0x73, 0x03, 0x61, 0x06, 0x64, 0x06,
    0x11, 0x04, 0x65, 0x02, 0x55, 0x05, 0x77, 0x07
]

def get_canonical_palette() -> list:
    """Calcula a paleta canônica RGB (DefaultPalette + PalMenuWeapon + RoomPalette0)."""
    pairs = [[DEFAULT_PALETTE_RAW[i], DEFAULT_PALETTE_RAW[i+1]] for i in range(0, 32, 2)]
    menu_patch = {0: (0, 0), 6: (0x70, 7), 8: (0x70, 0), 12: (0x33, 3), 14: (0x77, 7), 15: (0, 0)}
    for idx, p in menu_patch.items():
        pairs[idx] = list(p)
    room_patch = {1: (0x12, 2), 3: (0x01, 1), 5: (0x31, 2), 9: (0x20, 1)}
    for idx, p in room_patch.items():
        pairs[idx] = list(p)

    palette_rgb = []
    for rb, g in pairs:
        r = ((rb >> 4) & 7) * 255 // 7
        gr = (g & 7) * 255 // 7
        b = (rb & 7) * 255 // 7
        palette_rgb.append((r, gr, b))
    return palette_rgb

def parse_asm_doors(doors_asm_path: str) -> dict:
    """Lê external/MetalGear/gfx/doors.asm e extrai os bytes de cada símbolo."""
    with open(doors_asm_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    pattern = re.compile(r"([A-Za-z0-9_]+):\s+(.*?)(?=\n[A-Za-z0-9_]+:|\Z)", re.DOTALL)
    doors = {}
    for match in pattern.finditer(content):
        label = match.group(1)
        body = match.group(2)
        bytes_list = []
        for line in body.splitlines():
            line = line.strip().split(";")[0].strip()
            if not line.startswith("db"):
                continue
            line = line[2:].strip()
            for p in line.split(","):
                p = p.strip()
                if not p:
                    continue
                val = int(p[:-1], 16) if (p.endswith("h") or p.endswith("H")) else int(p)
                bytes_list.append(val)
        if bytes_list:
            doors[label] = bytes_list
    return doors

def decode_tile_block(bytes_list: list, tiles_x: int, tiles_y: int) -> list:
    """Decodifica blocos de tiles 8x8 px em formato 4bpp Screen 5."""
    w = tiles_x * 8
    h = tiles_y * 8
    grid = [[0 for _ in range(w)] for _ in range(h)]
    ptr = 0
    for ty in range(tiles_y):
        for tx in range(tiles_x):
            for py in range(8):
                if ptr + 4 <= len(bytes_list):
                    b0, b1, b2, b3 = bytes_list[ptr:ptr+4]
                    ptr += 4
                else:
                    b0 = b1 = b2 = b3 = 0
                nibs = [
                    (b0 >> 4) & 15, b0 & 15,
                    (b1 >> 4) & 15, b1 & 15,
                    (b2 >> 4) & 15, b2 & 15,
                    (b3 >> 4) & 15, b3 & 15
                ]
                for px in range(8):
                    grid[ty * 8 + py][tx * 8 + px] = nibs[px]
    return grid

def write_png(filename: str, width: int, height: int, rgba_data: list) -> None:
    """Escreve um arquivo PNG RGBA de 32 bits usando apenas zlib e struct da stdlib."""
    raw_bytes = bytearray()
    for y in range(height):
        raw_bytes.append(0)  # filter type 0: None
        for x in range(width):
            r, g, b, a = rgba_data[y * width + x]
            raw_bytes.extend([r, g, b, a])

    compressed = zlib.compress(bytes(raw_bytes), level=9)

    def chunk(chunk_type: bytes, data: bytes) -> bytes:
        c = chunk_type + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png_data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", compressed) + chunk(b"IEND", b"")

    os.makedirs(os.path.dirname(os.path.abspath(filename)), exist_ok=True)
    with open(filename, "wb") as f:
        f.write(png_data)

def assemble_door_sheet(doors_raw: dict, palette_rgb: list) -> tuple:
    """Compila os gráficos de portas no spritesheet 128x64 px."""
    sheet_w = 128
    sheet_h = 64
    sheet = [[(0, 0, 0, 0) for _ in range(sheet_w)] for _ in range(sheet_h)]

    grid_front = decode_tile_block(doors_raw.get("GfxDoorFront", []), 4, 4)
    grid_elevator = decode_tile_block(doors_raw.get("GfxDoorElevator", []), 4, 4)
    grid_down = decode_tile_block(doors_raw.get("GfxDoorDown", []), 4, 1)
    grid_left = decode_tile_block(doors_raw.get("GfxDoorLeft", []), 1, 4)
    grid_right = decode_tile_block(doors_raw.get("GfxDoorRight", []), 1, 4)

    # 1. Frame 0 (X: 0, Y: 0, 24x32): Porta Frontal Central (Norte)
    for y in range(32):
        for x in range(24):
            c_idx = grid_front[y][4 + x]
            rgb = palette_rgb[c_idx]
            sheet[y][x] = (rgb[0], rgb[1], rgb[2], 255)

    # 2. Frame 1 (X: 24, Y: 0, 24x32): Porta de Elevador Central
    for y in range(32):
        for x in range(24):
            c_idx = grid_elevator[y][4 + x]
            rgb = palette_rgb[c_idx]
            sheet[y][24 + x] = (rgb[0], rgb[1], rgb[2], 255)

    # 3. Frame 2 (X: 48, Y: 0, 32x8): Porta Sul (Soleira)
    for y in range(8):
        for x in range(32):
            c_idx = grid_down[y][x]
            rgb = palette_rgb[c_idx]
            sheet[y][48 + x] = (rgb[0], rgb[1], rgb[2], 255)

    # 4. Frame 3 (X: 80, Y: 0, 8x60): Porta Oeste em perspectiva (sheared)
    # Lógica canônica de DrawDoorWest2: cada coluna x é deslocada em Y por +4 px
    for x in range(8):
        dy = x * 4
        for y in range(32):
            c_idx = grid_left[y][x]
            rgb = palette_rgb[c_idx]
            sheet[dy + y][80 + x] = (rgb[0], rgb[1], rgb[2], 255)

    # 5. Frame 4 (X: 88, Y: 0, 8x60): Porta Leste em perspectiva (sheared)
    # Lógica canônica de DrawDoorEast2: cada coluna x é deslocada em Y por (7 - x) * 4 px
    for x in range(8):
        dy = (7 - x) * 4
        for y in range(32):
            c_idx = grid_right[y][x]
            rgb = palette_rgb[c_idx]
            sheet[dy + y][88 + x] = (rgb[0], rgb[1], rgb[2], 255)

    # Linha inferior (Y: 32..63) - Painéis completos e flats de referência
    # Frame 5 (X: 0, Y: 32, 32x32): Porta Frontal Completa com batente
    for y in range(32):
        for x in range(32):
            c_idx = grid_front[y][x]
            rgb = palette_rgb[c_idx]
            sheet[32 + y][x] = (rgb[0], rgb[1], rgb[2], 255)

    # Frame 6 (X: 32, Y: 32, 32x32): Elevador Completo
    for y in range(32):
        for x in range(32):
            c_idx = grid_elevator[y][x]
            rgb = palette_rgb[c_idx]
            sheet[32 + y][32 + x] = (rgb[0], rgb[1], rgb[2], 255)

    # Frame 7 (X: 64, Y: 32, 8x32): Porta Oeste plana (flat)
    for y in range(32):
        for x in range(8):
            c_idx = grid_left[y][x]
            rgb = palette_rgb[c_idx]
            sheet[32 + y][64 + x] = (rgb[0], rgb[1], rgb[2], 255)

    # Frame 8 (X: 72, Y: 32, 8x32): Porta Leste plana (flat)
    for y in range(32):
        for x in range(8):
            c_idx = grid_right[y][x]
            rgb = palette_rgb[c_idx]
            sheet[32 + y][72 + x] = (rgb[0], rgb[1], rgb[2], 255)

    flat_data = [sheet[y][x] for y in range(sheet_h) for x in range(sheet_w)]
    return sheet_w, sheet_h, flat_data

def main() -> int:
    parser = argparse.ArgumentParser(description="Extrator de spritesheets de portas MSX2 RC750")
    parser.add_argument("--asm", default="external/MetalGear/gfx/doors.asm", help="Caminho para doors.asm")
    parser.add_argument("--output", default="godot/assets/protected/sprites/doors_msx.png", help="Destino PNG")
    args = parser.parse_args()

    if not os.path.exists(args.asm):
        print(f"ERRO: Arquivo {args.asm} não encontrado.", file=sys.stderr)
        return 1

    doors_raw = parse_asm_doors(args.asm)
    palette = get_canonical_palette()
    w, h, rgba = assemble_door_sheet(doors_raw, palette)
    write_png(args.output, w, h, rgba)
    print(f"Sucesso: Spritesheet de portas gerado em {args.output} ({w}x{h} px)")
    return 0

if __name__ == "__main__":
    sys.exit(main())
