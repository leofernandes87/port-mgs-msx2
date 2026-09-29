#!/usr/bin/env python3
"""
tools/extractors/extract_enemy_sprites.py

Extrator reprodutível em Python 3 dos sprites autênticos de Inimigos (Guardas e Cães de Guarda)
do Metal Gear MSX2 original (RC750).

Reconstitui a renderização de hardware do VDP TMS9918/V9938 (Sprite Mode 2 com Color Compare)
a partir dos padrões descompactados RLE em gfx/sprites.asm e das tabelas de atributos em
data/actorspriteattr.asm:
- SprGuard: Composição modular de Tronco (Y: -27/-26, X: -8) e Pernas (Y: -11, X: -8)
- SprDog: Composição vertical 16x32 (Up/Down), horizontal 32x16 (Left/Right) e 16x16 (Sleep/Listen)

Gera:
- godot/assets/protected/sprites/guard_msx.png (64x128 px, células de 16x32)
- godot/assets/protected/sprites/dog_msx.png (128x96 px, células de 32x32 padronizadas)
"""

import argparse
import os
import re
import struct
import sys
import zlib

# Paleta Canônica MSX2 V9938 para o Soldado Inimigo (Outer Heaven)
# Color 2 (Uniforme/Capacete): Azul militar #2e4b78
# Color 13 (Rosto/Pele/Cinto): Pele clara #da916d
# Color 15 (Black via Color Compare 2 | 13): Contorno, fivela, botas #101010
PALETTE_GUARD = {
    0: (0, 0, 0, 0),             # Transparente
    2: (46, 75, 120, 255),        # Farda azul-acinzentada militar
    13: (218, 145, 109, 255),     # Pele / Rosto
    15: (16, 16, 16, 255)         # Preto puro (contorno, botas, fivela)
}

# Paleta Canônica MSX2 V9938 para o Cão de Guarda (Doberman Pinscher)
# Padrão A: Detalhes em Bege/Caramelo (#da916d) - orelhas, patas, focinho
# Padrão B: Corpo/Silhueta em Preto Doberman (#101010)
# Overlap / Destaque: Preto ou castanho
PALETTE_DOG = {
    0: (0, 0, 0, 0),             # Transparente
    "tan": (218, 145, 109, 255),  # Patas, focinho, peito, orelhas
    "black": (16, 16, 16, 255),   # Corpo preto Doberman
    "red": (197, 28, 28, 255)     # Coleira / boca
}

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

def load_asm_sprites(asm_path: str) -> dict:
    """Lê o arquivo gfx/sprites.asm e divide os blocos de bytes por símbolo."""
    with open(asm_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    pattern = re.compile(r"([A-Za-z0-9_]+):\s+(.*?)(?=\n[A-Za-z0-9_]+:|\Z)", re.DOTALL)
    sprites = {}
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
                if p.endswith("h") or p.endswith("H"):
                    bytes_list.append(int(p[:-1], 16))
                else:
                    bytes_list.append(int(p))
        if bytes_list:
            sprites[label] = bytes_list
    return sprites

def decompress_rle(bytes_list: list) -> list:
    """
    Descompressor RLE idêntico à rotina Z80 do MSX2 (Banks0123.asm:5543-5580).
    - Se byte == 0x00 ou 0x80: fim dos dados.
    - Se bit 7 for 0 (< 0x80): repete o próximo byte (b) vezes.
    - Se bit 7 for 1 (>= 0x80): copia os próximos (b & 0x7F) bytes literais.
    """
    unpacked = []
    i = 0
    while i < len(bytes_list):
        b = bytes_list[i]
        i += 1
        cnt = b & 0x7F
        if cnt == 0:
            break
        if b < 0x80:
            rep_byte = bytes_list[i]
            i += 1
            unpacked.extend([rep_byte] * cnt)
        else:
            unpacked.extend(bytes_list[i : i + cnt])
            i += cnt
    return unpacked

# ---------------------------------------------------------------------------
# GUARDA (SprGuard)
# ---------------------------------------------------------------------------

def get_guard_pattern(unpacked_guard: list, pat_byte: int) -> list:
    """Extrai um padrão 16x16 (32 bytes) de SprGuard indexado por (pat_byte - 0x60) // 4."""
    idx = (pat_byte - 0x60) // 4
    start = idx * 32
    return unpacked_guard[start : start + 32]

def composite_guard_frame(unpacked_guard: list, torso_a: int, torso_b: int, legs_a: int, legs_b: int, torso_y_shift: int = 0) -> list:
    """
    Monta um quadro de guarda 16x32 combinando Tronco (Y=0..15 + shift) e Pernas (Y=16..31).
    Aplica Color Compare onde os bits de A (Cor 2) e B (Cor 13) se sobrepõem gerando Cor 15 (Preto).
    """
    grid = [[(0, 0, 0, 0) for _ in range(16)] for _ in range(32)]
    
    t_a = get_guard_pattern(unpacked_guard, torso_a)
    t_b = get_guard_pattern(unpacked_guard, torso_b)
    l_a = get_guard_pattern(unpacked_guard, legs_a)
    l_b = get_guard_pattern(unpacked_guard, legs_b)
    
    # 1. Renderiza Tronco (16x16) com deslocamento Y opcional (SprOffsets2 tem -26 vs -27 = 1 px abaixo)
    for y in range(16):
        dest_y = y + torso_y_shift
        if dest_y < 0 or dest_y >= 32:
            continue
        lb0, rb0 = t_a[y], t_a[y + 16]
        lb1, rb1 = t_b[y], t_b[y + 16]
        for bit in range(8):
            b0 = (lb0 >> (7 - bit)) & 1
            b1 = (lb1 >> (7 - bit)) & 1
            c = 15 if (b0 and b1) else (2 if b0 else (13 if b1 else 0))
            grid[dest_y][bit] = PALETTE_GUARD[c]
        for bit in range(8):
            b0 = (rb0 >> (7 - bit)) & 1
            b1 = (rb1 >> (7 - bit)) & 1
            c = 15 if (b0 and b1) else (2 if b0 else (13 if b1 else 0))
            grid[dest_y][8 + bit] = PALETTE_GUARD[c]
            
    # 2. Renderiza Pernas (16x16) nas linhas 16 a 31
    for y in range(16):
        dest_y = 16 + y
        if dest_y >= 32:
            continue
        lb0, rb0 = l_a[y], l_a[y + 16]
        lb1, rb1 = l_b[y], l_b[y + 16]
        for bit in range(8):
            b0 = (lb0 >> (7 - bit)) & 1
            b1 = (lb1 >> (7 - bit)) & 1
            c = 15 if (b0 and b1) else (2 if b0 else (13 if b1 else 0))
            grid[dest_y][bit] = PALETTE_GUARD[c]
        for bit in range(8):
            b0 = (rb0 >> (7 - bit)) & 1
            b1 = (rb1 >> (7 - bit)) & 1
            c = 15 if (b0 and b1) else (2 if b0 else (13 if b1 else 0))
            grid[dest_y][8 + bit] = PALETTE_GUARD[c]
            
    return grid

def generate_guard_spritesheet(unpacked_guard: list, output_path: str) -> None:
    """
    Gera o spritesheet canônico de soldados (64x128 px, grade 4x4 de 16x32).
    Linha 0: DOWN  (Stand, Walk1, Walk2, _)
    Linha 1: UP    (Stand, Walk1, Walk2, _)
    Linha 2: RIGHT (Stand, Walk1, Walk2, _)
    Linha 3: LEFT  (Stand, Walk1, Walk2, _)
    """
    # Definições exatas de data/actorspriteattr.asm:
    # GuardDown:       91h, 60h, 64h, 0A0h, 0A4h
    # GuardWalkDown1:  91h, 60h, 64h, 80h, 84h
    # GuardWalkDown2:  92h, 60h, 64h, 0C0h, 0C4h
    # GuardUp:         91h, 70h, 74h, 0B0h, 0B4h
    # GuardWalkUp1:    91h, 70h, 74h, 90h, 94h
    # GuardWalkUp2:    92h, 70h, 74h, 0D0h, 0D4h
    # GuardRight:      91h, 78h, 7Ch, 0B8h, 0BCh
    # GuardWalkRight1: 91h, 78h, 7Ch, 98h, 9Ch
    # GuardWalkRight2: 92h, 78h, 7Ch, 0D8h, 0DCh
    # GuardLeft:       91h, 68h, 6Ch, 0A8h, 0ACh
    # GuardWalkLeft1:  91h, 68h, 6Ch, 88h, 8Ch
    # GuardWalkLeft2:  92h, 68h, 6Ch, 0C8h, 0CCh

    grid_layout = [
        # Linha 0: DOWN (Stand, Walk1, Walk2)
        [ (0x60, 0x64, 0xA0, 0xA4, 0), (0x60, 0x64, 0x80, 0x84, 0), (0x60, 0x64, 0xC0, 0xC4, 1), None ],
        # Linha 1: UP (Stand, Walk1, Walk2)
        [ (0x70, 0x74, 0xB0, 0xB4, 0), (0x70, 0x74, 0x90, 0x94, 0), (0x70, 0x74, 0xD0, 0xD4, 1), None ],
        # Linha 2: RIGHT (Stand, Walk1, Walk2)
        [ (0x78, 0x7C, 0xB8, 0xBC, 0), (0x78, 0x7C, 0x98, 0x9C, 0), (0x78, 0x7C, 0xD8, 0xDC, 1), None ],
        # Linha 3: LEFT (Stand, Walk1, Walk2)
        [ (0x68, 0x6C, 0xA8, 0xAC, 0), (0x68, 0x6C, 0x88, 0x8C, 0), (0x68, 0x6C, 0xC8, 0xCC, 1), None ],
    ]

    cell_w, cell_h = 16, 32
    num_cols, num_rows = 4, len(grid_layout)
    sheet_w, sheet_h = num_cols * cell_w, num_rows * cell_h
    rgba_buffer = [(0, 0, 0, 0) for _ in range(sheet_w * sheet_h)]

    for row_idx, row in enumerate(grid_layout):
        for col_idx, spec in enumerate(row):
            if spec is None:
                continue
            ta, tb, la, lb, y_sh = spec
            frame_grid = composite_guard_frame(unpacked_guard, ta, tb, la, lb, y_sh)
            origin_x = col_idx * cell_w
            origin_y = row_idx * cell_h
            for y in range(cell_h):
                for x in range(cell_w):
                    rgba_buffer[(origin_y + y) * sheet_w + (origin_x + x)] = frame_grid[y][x]

    write_png(output_path, sheet_w, sheet_h, rgba_buffer)
    print(f"EXTRACTOR_OK: Spritesheet de Guardas salvo em '{output_path}' ({sheet_w}x{sheet_h} px).")

# ---------------------------------------------------------------------------
# CÃO DE GUARDA (SprDog)
# ---------------------------------------------------------------------------

def get_dog_pattern(unpacked_dog: list, pat_byte: int) -> list:
    """Extrai um padrão 16x16 (32 bytes) de SprDog indexado por (pat_byte - 0x60) // 4."""
    idx = (pat_byte - 0x60) // 4
    start = idx * 32
    return unpacked_dog[start : start + 32]

def render_dog_pair(unpacked_dog: list, pat_detail_byte: int, pat_body_byte: int) -> list:
    """
    Renderiza um par de padrões 16x16 de cão:
    - pat_body_byte: silhueta corporal (Preto)
    - pat_detail_byte: marcas/detalhes faciais e de patas (Bege/Tan)
    """
    grid = [[PALETTE_DOG[0] for _ in range(16)] for _ in range(16)]
    pa = get_dog_pattern(unpacked_dog, pat_detail_byte)
    pb = get_dog_pattern(unpacked_dog, pat_body_byte)
    for y in range(16):
        la0, ra0 = pa[y], pa[y + 16]
        lb0, rb0 = pb[y], pb[y + 16]
        for bit in range(8):
            b_detail = (la0 >> (7 - bit)) & 1
            b_body = (lb0 >> (7 - bit)) & 1
            if b_detail:
                grid[y][bit] = PALETTE_DOG["tan"]
            elif b_body:
                grid[y][bit] = PALETTE_DOG["black"]
        for bit in range(8):
            b_detail = (ra0 >> (7 - bit)) & 1
            b_body = (rb0 >> (7 - bit)) & 1
            if b_detail:
                grid[y][8 + bit] = PALETTE_DOG["tan"]
            elif b_body:
                grid[y][8 + bit] = PALETTE_DOG["black"]
    return grid

def composite_dog_cell(unpacked_dog: list, kind: str, patterns: tuple) -> list:
    """
    Compõe um quadro de cão em uma célula padronizada 32x32:
    - '16x16' (Sleep / Listen): centralizado em X=8..23, Y=8..23
    - '16x32' (Down / Up): centralizado em X=8..23, Y=0..31
    - '32x16' (Left / Right): centralizado em X=0..31, Y=8..23
    """
    canvas = [[PALETTE_DOG[0] for _ in range(32)] for _ in range(32)]
    if kind == "16x16":
        p_det, p_bod = patterns[0], patterns[1]
        g = render_dog_pair(unpacked_dog, p_det, p_bod)
        for y in range(16):
            for x in range(16):
                canvas[8 + y][8 + x] = g[y][x]
    elif kind == "16x32":
        # SprOffsets15: metade superior Y=0..15, metade inferior Y=16..31
        top_g = render_dog_pair(unpacked_dog, patterns[0], patterns[1])
        bot_g = render_dog_pair(unpacked_dog, patterns[2], patterns[3])
        for y in range(16):
            for x in range(16):
                canvas[y][8 + x] = top_g[y][x]
                canvas[16 + y][8 + x] = bot_g[y][x]
    elif kind == "32x16":
        # SprOffsets16: metade esquerda X=0..15, metade direita X=16..31
        left_g = render_dog_pair(unpacked_dog, patterns[0], patterns[1])
        right_g = render_dog_pair(unpacked_dog, patterns[2], patterns[3])
        for y in range(16):
            for x in range(16):
                canvas[8 + y][x] = left_g[y][x]
                canvas[8 + y][16 + x] = right_g[y][x]
    return canvas

def generate_dog_spritesheet(unpacked_dog: list, output_path: str) -> None:
    """
    Gera o spritesheet padronizado de cães de guarda (128x96 px, grade 4x3 de 32x32).
    Linha 0: DOWN 1, DOWN 2, UP 1, UP 2
    Linha 1: LEFT 1, LEFT 2, RIGHT 1, RIGHT 2
    Linha 2: SLEEP, LISTEN, _, _
    """
    # Definições canônicas de data/actorspriteattr.asm:
    # DogDown1:     9Fh,  60h,  64h,  68h,  6Ch
    # DogDown2:     9Fh,  70h,  74h,  78h,  7Ch
    # DogUp1:       9Fh, 0A0h, 0A4h, 0A8h, 0ACh
    # DogUp2:       9Fh, 0B0h, 0B4h, 0B8h, 0BCh
    # DogLeft1:    0A0h,  80h,  84h,  88h,  8Ch
    # DogLeft2:    0A0h,  90h,  94h,  98h,  9Ch
    # DogRight1:   0A0h, 0C0h, 0C4h, 0C8h, 0CCh
    # DogRight2:   0A0h, 0D0h, 0D4h, 0D8h, 0DCh
    # DogLying:     95h, 0E0h, 0E4h, 0E0h, 0E4h
    # DogListening: 95h, 0E8h, 0ECh, 0E8h, 0ECh

    grid_layout = [
        # Linha 0: Down1, Down2, Up1, Up2
        [
            ("16x32", (0x60, 0x64, 0x68, 0x6C)),
            ("16x32", (0x70, 0x74, 0x78, 0x7C)),
            ("16x32", (0xA0, 0xA4, 0xA8, 0xAC)),
            ("16x32", (0xB0, 0xB4, 0xB8, 0xBC)),
        ],
        # Linha 1: Left1, Left2, Right1, Right2
        [
            ("32x16", (0x80, 0x84, 0x88, 0x8C)),
            ("32x16", (0x90, 0x94, 0x98, 0x9C)),
            ("32x16", (0xC0, 0xC4, 0xC8, 0xCC)),
            ("32x16", (0xD0, 0xD4, 0xD8, 0xDC)),
        ],
        # Linha 2: Sleep, Listen, _, _
        [
            ("16x16", (0xE0, 0xE4)),
            ("16x16", (0xE8, 0xEC)),
            None,
            None,
        ]
    ]

    cell_w, cell_h = 32, 32
    num_cols, num_rows = 4, len(grid_layout)
    sheet_w, sheet_h = num_cols * cell_w, num_rows * cell_h
    rgba_buffer = [(0, 0, 0, 0) for _ in range(sheet_w * sheet_h)]

    for row_idx, row in enumerate(grid_layout):
        for col_idx, item in enumerate(row):
            if item is None:
                continue
            kind, patterns = item
            frame_grid = composite_dog_cell(unpacked_dog, kind, patterns)
            origin_x = col_idx * cell_w
            origin_y = row_idx * cell_h
            for y in range(cell_h):
                for x in range(cell_w):
                    rgba_buffer[(origin_y + y) * sheet_w + (origin_x + x)] = frame_grid[y][x]

    write_png(output_path, sheet_w, sheet_h, rgba_buffer)
    print(f"EXTRACTOR_OK: Spritesheet de Cães de Guarda salvo em '{output_path}' ({sheet_w}x{sheet_h} px).")

def extract_enemy_sprites(asm_path: str, output_dir: str) -> None:
    """Extrai e gera ambos os spritesheets de guardas e cães."""
    sprites = load_asm_sprites(asm_path)
    if "SprGuard" not in sprites:
        raise ValueError(f"Símbolo 'SprGuard' não encontrado em '{asm_path}'.")
    if "SprDog" not in sprites:
        raise ValueError(f"Símbolo 'SprDog' não encontrado em '{asm_path}'.")

    unpacked_guard = decompress_rle(sprites["SprGuard"])
    unpacked_dog = decompress_rle(sprites["SprDog"])

    guard_png = os.path.join(output_dir, "guard_msx.png")
    dog_png = os.path.join(output_dir, "dog_msx.png")

    generate_guard_spritesheet(unpacked_guard, guard_png)
    generate_dog_spritesheet(unpacked_dog, dog_png)

def main():
    parser = argparse.ArgumentParser(description="Extrator de Sprites de Inimigos do Metal Gear MSX2.")
    parser.add_argument("--asm", default="external/MetalGear/gfx/sprites.asm", help="Caminho para gfx/sprites.asm")
    parser.add_argument("--out-dir", default="godot/assets/protected/sprites", help="Diretório de destino dos PNGs")
    args = parser.parse_args()

    root_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    asm_full = os.path.join(root_dir, args.asm) if not os.path.isabs(args.asm) else args.asm
    out_full = os.path.join(root_dir, args.out_dir) if not os.path.isabs(args.out_dir) else args.out_dir

    if not os.path.exists(asm_full):
        print(f"ERRO: Arquivo de entrada '{asm_full}' não encontrado.", file=sys.stderr)
        sys.exit(1)

    extract_enemy_sprites(asm_full, out_full)

if __name__ == "__main__":
    main()
