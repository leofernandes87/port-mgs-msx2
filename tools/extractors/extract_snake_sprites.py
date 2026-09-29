#!/usr/bin/env python3
"""
tools/extractors/extract_snake_sprites.py

Extrator reprodutível em Python 3 dos sprites autênticos de Solid Snake do Metal Gear MSX2 (RC750).
Descompacta os dados RLE originais da tabela de sprites (data/playersprite.asm e gfx/sprites.asm),
aplica a composição de hardware VDP V9938 (Sprite Mode 2 com Color Compare) e compila um spritesheet
organizado em formato PNG para o Godot 4.
"""

import os
import re
import struct
import sys
import zlib

PALETTE = {
    0: (0, 0, 0, 0),             # Transparente
    7: (38, 111, 147, 255),      # Azul-petróleo (Uniforme)
    10: (218, 145, 109, 255),    # Bege/Pele (Rosto e braços)
    12: (74, 130, 90, 255),      # Verde-oliva militar (Calças)
    15: (16, 16, 16, 255)        # Preto puro (Cabelo, botas, contornos via Color Compare 7|10 e 7|12)
}

def write_png(filename: str, width: int, height: int, rgba_data: list) -> None:
    """Escreve um arquivo PNG RGBA de 32-bit usando apenas zlib e struct da stdlib."""
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

    # Expressão regular para capturar cada rótulo Spr* e seus db bytes
    pattern = re.compile(r"([A-Za-z0-9_]+):\s+(.*?)(?=\n[A-Za-z0-9_]+:|\Z)", re.DOTALL)
    sprites = {}
    for match in pattern.finditer(content):
        label = match.group(1)
        body = match.group(2)
        bytes_list = []
        for line in body.splitlines():
            line = line.strip()
            # Remove comentário inline se houver
            line = line.split(";")[0].strip()
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
    Descompressor RLE idêntico à rotina Z80 SetSnakeSprPatt (Banks0123.asm:5543-5580).
    - Se byte == 0x00 ou 0x80: fim dos dados.
    - Se bit 7 for 0 (< 0x80): repete o próximo byte (b) vezes.
    - Se bit 7 for 1 (>= 0x80): transfere os próximos (b & 0x7F) bytes literais.
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

def decode_frame_to_pixels(unpacked_bytes: list) -> list:
    """
    Decodifica 128 bytes descompactados em uma matriz 16x32 de pixels RGBA.
    MSX2 16x16 Sprite Mode 2:
    - Bytes 0..31: Plano 0 (Torso A, Cor 7)
    - Bytes 32..63: Plano 1 (Torso B, Cor 10 com CC)
    - Bytes 64..95: Plano 2 (Pernas A, Cor 7)
    - Bytes 96..127: Plano 3 (Pernas B, Cor 12 com CC)
    """
    if len(unpacked_bytes) < 128:
        # Preencher com zeros se for parcial
        unpacked_bytes = list(unpacked_bytes) + [0] * (128 - len(unpacked_bytes))

    grid = [[(0, 0, 0, 0) for _ in range(16)] for _ in range(32)]

    # 1. Metade superior (Torso - Y: 0 a 15)
    p0 = unpacked_bytes[0:32]
    p1 = unpacked_bytes[32:64]
    for y in range(16):
        lb0, rb0 = p0[y], p0[y + 16]
        lb1, rb1 = p1[y], p1[y + 16]
        for bit in range(8):
            x = 7 - bit
            b0 = (lb0 >> bit) & 1
            b1 = (lb1 >> bit) & 1
            col = 0
            if b0 and b1: col = 15      # Color Compare (7 OR 10 = 15, Preto)
            elif b0: col = 7            # Uniforme azul-petróleo
            elif b1: col = 10           # Pele/Rosto bege
            grid[y][x] = PALETTE[col]
        for bit in range(8):
            x = 15 - bit
            b0 = (rb0 >> bit) & 1
            b1 = (rb1 >> bit) & 1
            col = 0
            if b0 and b1: col = 15
            elif b0: col = 7
            elif b1: col = 10
            grid[y][x] = PALETTE[col]

    # 2. Metade inferior (Pernas - Y: 16 a 31)
    p2 = unpacked_bytes[64:96]
    p3 = unpacked_bytes[96:128]
    for y in range(16):
        lb2, rb2 = p2[y], p2[y + 16]
        lb3, rb3 = p3[y], p3[y + 16]
        for bit in range(8):
            x = 7 - bit
            b2 = (lb2 >> bit) & 1
            b3 = (lb3 >> bit) & 1
            col = 0
            if b2 and b3: col = 15      # Color Compare (7 OR 12 = 15, Preto)
            elif b2: col = 7            # Uniforme
            elif b3: col = 12           # Calça militar verde-oliva
            grid[16 + y][x] = PALETTE[col]
        for bit in range(8):
            x = 15 - bit
            b2 = (rb2 >> bit) & 1
            b3 = (rb3 >> bit) & 1
            col = 0
            if b2 and b3: col = 15
            elif b2: col = 7
            elif b3: col = 12
            grid[16 + y][x] = PALETTE[col]

    return grid

WATER_SHADOW_PALETTE = {
    0: (0, 0, 0, 0),             # Transparente
    14: (38, 111, 147, 220),     # Ondulação ciano da água (translúcido)
    15: (18, 30, 40, 230),       # Silhueta escura de mergulho
    16: (10, 16, 22, 255),       # Color Compare (14 e 15 = Preto azulado subaquático)
}

def decode_shadow_to_pixels(unpacked_bytes: list) -> list:
    """Decodifica 64 bytes de silhueta subaquática/ondulações (SprWaterShadow) em grid 16x32."""
    if len(unpacked_bytes) < 64:
        unpacked_bytes = list(unpacked_bytes) + [0] * (64 - len(unpacked_bytes))
    grid = [[(0, 0, 0, 0) for _ in range(16)] for _ in range(32)]
    p0 = unpacked_bytes[0:32]
    p1 = unpacked_bytes[32:64]
    for y in range(16):
        lb0, rb0 = p0[y], p0[y + 16]
        lb1, rb1 = p1[y], p1[y + 16]
        for bit in range(8):
            x = 7 - bit
            b0 = (lb0 >> bit) & 1
            b1 = (lb1 >> bit) & 1
            col = 16 if (b0 and b1) else (14 if b0 else (15 if b1 else 0))
            grid[y][x] = WATER_SHADOW_PALETTE[col]
        for bit in range(8):
            x = 15 - bit
            b0 = (rb0 >> bit) & 1
            b1 = (rb1 >> bit) & 1
            col = 16 if (b0 and b1) else (14 if b0 else (15 if b1 else 0))
            grid[y][x] = WATER_SHADOW_PALETTE[col]
    return grid

def decode_water_to_pixels(unpacked_bytes: list) -> list:
    """Decodifica 64 bytes de Snake nadando na superfície (SprSnakeWater*) em grid 16x32."""
    if len(unpacked_bytes) < 64:
        unpacked_bytes = list(unpacked_bytes) + [0] * (64 - len(unpacked_bytes))
    grid = [[(0, 0, 0, 0) for _ in range(16)] for _ in range(32)]
    p0 = unpacked_bytes[0:32]
    p1 = unpacked_bytes[32:64]
    for y in range(16):
        lb0, rb0 = p0[y], p0[y + 16]
        lb1, rb1 = p1[y], p1[y + 16]
        for bit in range(8):
            x = 7 - bit
            b0 = (lb0 >> bit) & 1
            b1 = (lb1 >> bit) & 1
            col = 15 if (b0 and b1) else (7 if b0 else (10 if b1 else 0))
            grid[y][x] = PALETTE[col]
        for bit in range(8):
            x = 15 - bit
            b0 = (rb0 >> bit) & 1
            b1 = (rb1 >> bit) & 1
            col = 15 if (b0 and b1) else (7 if b0 else (10 if b1 else 0))
            grid[y][x] = PALETTE[col]
    return grid

def generate_spritesheet(asm_path: str, output_path: str) -> None:
    """Extrai e compila o spritesheet padronizado de Solid Snake."""
    sprites = load_asm_sprites(asm_path)

    # Definição do layout da grade do spritesheet (Linhas e Colunas de 16x32)
    # Linhas 0-3: Desarmado (Down, Up, Right, Left) x (Stand, Walk1, Walk2)
    # Linhas 4-7: Armado (Down, Up, Right, Left) x (Stand, Walk1, Walk2)
    # Linha 8: Socos (Down, Up, Right, Left)
    # Linha 9: Especiais 1 (Box, Dead1, Dead2, Climb1)
    # Linha 10: Especiais 2 (Climb2, Water Shadow 1, Water Shadow 2, Vazio)
    # Linha 11: Nado Superfície (Down, Up, Right, Left)
    layout = [
        # Linhas Desarmado
        ["SprSnakeDown", "SprSnakeDown1", "SprSnakeDown2", ""],
        ["SprSnakeUp", "SprSnakeUp1", "SprSnakeUp2", ""],
        ["SprSnakeRight", "SprSnakeRight1", "SprSnakeRight2", ""],
        ["SprSnakeLeft", "SprSnakeLeft1", "SprSnakeLeft2", ""],
        # Linhas Armado
        ["SprSnakeDownW", "SprSnakeDown1W", "SprSnakeDown2W", ""],
        ["SprSnakeUpW", "SprSnakeUp1W", "SprSnakeUp2W", ""],
        ["SprSnakeRightW", "SprSnakeRight1W", "SprSnakeRight2W", ""],
        ["SprSnakeLeftW", "SprSnakeLeft1W", "SprSnakeLeft2W", ""],
        # Linha Socos
        ["SprSnakePunchD", "SprSnakePunchU", "SprSnakePunchR", "SprSnakePunchL"],
        # Linha Especiais 1
        ["SprBox", "SprSnakeLeaned", "SprSnakeDead", "SprSnakeClimb1"],
        # Linha Especiais 2 (Climb2, Water Shadow 1/2)
        ["SprSnakeClimb2", "SprWaterShadow", "SprWaterShadow2", ""],
        # Linha Nado Superfície
        ["SprSnakeWaterD", "SprSnakeWaterU", "SprSnakeWaterR", "SprSnakeWaterL"]
    ]

    num_cols = 4
    num_rows = len(layout)
    cell_w = 16
    cell_h = 32
    sheet_w = num_cols * cell_w
    sheet_h = num_rows * cell_h

    rgba_buffer = [(0, 0, 0, 0) for _ in range(sheet_w * sheet_h)]

    for row_idx, row in enumerate(layout):
        for col_idx, sprite_name in enumerate(row):
            if not sprite_name or sprite_name not in sprites:
                continue
            compressed = sprites[sprite_name]
            unpacked = decompress_rle(compressed)
            if sprite_name.startswith("SprWaterShadow"):
                frame_grid = decode_shadow_to_pixels(unpacked)
            elif sprite_name.startswith("SprSnakeWater"):
                frame_grid = decode_water_to_pixels(unpacked)
            else:
                frame_grid = decode_frame_to_pixels(unpacked)

            origin_x = col_idx * cell_w
            origin_y = row_idx * cell_h

            for y in range(cell_h):
                for x in range(cell_w):
                    pixel_color = frame_grid[y][x]
                    buf_idx = (origin_y + y) * sheet_w + (origin_x + x)
                    rgba_buffer[buf_idx] = pixel_color

    write_png(output_path, sheet_w, sheet_h, rgba_buffer)
    print(f"EXTRACTOR_OK: Spritesheet de Solid Snake extraído e salvo com sucesso em '{output_path}' ({sheet_w}x{sheet_h} px).")

def main():
    root_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    asm_path = os.path.join(root_dir, "external", "MetalGear", "gfx", "sprites.asm")
    out_path = os.path.join(root_dir, "godot", "assets", "protected", "sprites", "snake_msx.png")

    if not os.path.exists(asm_path):
        print(f"ERRO: Arquivo de entrada '{asm_path}' não encontrado.", file=sys.stderr)
        sys.exit(1)

    generate_spritesheet(asm_path, out_path)

if __name__ == "__main__":
    main()
