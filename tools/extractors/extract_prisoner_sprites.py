#!/usr/bin/env python3
"""
tools/extractors/extract_prisoner_sprites.py

Extrator reproduzível em Python 3 dos sprites autênticos de Reféns e Prisioneiros
do Metal Gear MSX2 original (RC750, Konami 1987).

Reconstitui a renderização de hardware do VDP TMS9918/V9938 (Sprite Mode 2 com Color Compare)
a partir dos padrões descompactados RLE em gfx/sprites.asm e das tabelas de atributos em
data/actorspriteattr.asm:
- SprPrisoner: Prisioneiro comum de guerra (Linha 0: Amarrado 1, Amarrado 2, Livre)
- SprPrisoner2: Agente Grey Fox (Linha 1: Amarrado 1, Amarrado 2, Livre)
- SprElen: Ellen Madnar (Linha 2: Amarrada 1, Amarrada 2, Livre)
- SprMadnar: Dr. Pettrovich Madnar / Falso Madnar (Linha 3: Amarrado 1, Amarrado 2, Livre)

Dimensões do spritesheet resultante: 48x128 pixels (3 colunas de 16px, 4 linhas de 32px).
Salva em: godot/assets/protected/sprites/prisoners_msx.png
"""

import argparse
import os
import re
import struct
import sys
import zlib

# Paletas Canônicas MSX2 V9938 (DefaultPalette + SprsetPal)
# SprsetPal3 (Prisioneiro comum): 0x0D = (182, 145, 109), 0x0B = (218, 218, 145)
PALETTE_PRISONER = {
    0: (0, 0, 0, 0),
    11: (218, 218, 145, 255),    # Cáqui claro / Rosto
    13: (182, 145, 109, 255),    # Cáqui amarronzado / Roupa
    15: (16, 16, 16, 255)        # Preto puro (contorno, cabelo, olhos)
}

# SprsetPal9 (Grey Fox): 0x0D = (145, 109, 72), 0x0E = (218, 218, 218), 0x0B = (218, 218, 145)
PALETTE_GREY_FOX = {
    0: (0, 0, 0, 0),
    11: (218, 218, 145, 255),    # Detalhes cáqui
    13: (145, 109, 72, 255),     # Tronco / Pele
    14: (218, 218, 218, 255),    # Calças / ataduras brancas
    15: (16, 16, 16, 255)        # Preto puro (cabelo, botas, contorno)
}

# SprsetPal8 (Ellen Madnar): 0x0D = (182, 145, 109), 0x0B = (145, 0, 36)
PALETTE_ELLEN = {
    0: (0, 0, 0, 0),
    11: (145, 0, 36, 255),       # Vestido vermelho carmesim
    13: (182, 145, 109, 255),    # Pele / Rosto
    15: (16, 16, 16, 255)        # Cabelo longo preto e contornos
}

# SprsetPal7 (Dr. Madnar): 0x02 = (72, 72, 36), 0x0D = (182, 145, 109)
PALETTE_MADNAR = {
    0: (0, 0, 0, 0),
    2: (72, 72, 36, 255),        # Jaleco cáqui-oliva
    13: (182, 145, 109, 255),    # Pele / Cabeça
    15: (16, 16, 16, 255)        # Preto puro (óculos, bigode, sapatos)
}

def write_png(filename: str, width: int, height: int, rgba_data: list) -> None:
    """Escreve um arquivo PNG RGBA de 32 bits usando zlib e struct da biblioteca padrão."""
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

def get_pattern(unpacked_sprites: list, pat_byte: int) -> list:
    """Extrai um padrão 16x16 (32 bytes) indexado por (pat_byte - 0xD0) // 4."""
    idx = (pat_byte - 0xD0) // 4
    start = idx * 32
    return unpacked_sprites[start : start + 32]

def composite_prisoner_frame(
    unpacked: list,
    p_top_a: int, p_top_b: int,
    p_bot_a: int, p_bot_b: int,
    col_t0: int, col_t1: int,
    col_b0: int, col_b1: int,
    palette: dict
) -> list:
    """
    Monta um quadro de prisioneiro 16x32 combinando Tronco (Y=0..15) e Pernas (Y=16..31).
    Aplica Color Compare onde os bits da Camada 0 e da Camada 1 se sobrepõem gerando Cor 15 (Preto).
    """
    grid = [[(0, 0, 0, 0) for _ in range(16)] for _ in range(32)]

    t_a = get_pattern(unpacked, p_top_a)
    t_b = get_pattern(unpacked, p_top_b)
    l_a = get_pattern(unpacked, p_bot_a)
    l_b = get_pattern(unpacked, p_bot_b)

    # 1. Tronco / Cabeça (linhas 0 a 15)
    c0 = col_t0 & 0x0F
    c1 = col_t1 & 0x0F
    c_both = c0 | c1 # Color Compare bitwise OR -> sempre 15 (Preto)
    for y in range(16):
        lb0, rb0 = t_a[y], t_a[y + 16]
        lb1, rb1 = t_b[y], t_b[y + 16]
        for bit in range(8):
            b0 = (lb0 >> (7 - bit)) & 1
            b1 = (lb1 >> (7 - bit)) & 1
            c = c_both if (b0 and b1) else (c0 if b0 else (c1 if b1 else 0))
            grid[y][bit] = palette.get(c, (0, 0, 0, 0))
        for bit in range(8):
            b0 = (rb0 >> (7 - bit)) & 1
            b1 = (rb1 >> (7 - bit)) & 1
            c = c_both if (b0 and b1) else (c0 if b0 else (c1 if b1 else 0))
            grid[y][8 + bit] = palette.get(c, (0, 0, 0, 0))

    # 2. Pernas / Pés (linhas 16 a 31)
    c0 = col_b0 & 0x0F
    c1 = col_b1 & 0x0F
    c_both = c0 | c1
    for y in range(16):
        lb0, rb0 = l_a[y], l_a[y + 16]
        lb1, rb1 = l_b[y], l_b[y + 16]
        for bit in range(8):
            b0 = (lb0 >> (7 - bit)) & 1
            b1 = (lb1 >> (7 - bit)) & 1
            c = c_both if (b0 and b1) else (c0 if b0 else (c1 if b1 else 0))
            grid[16 + y][bit] = palette.get(c, (0, 0, 0, 0))
        for bit in range(8):
            b0 = (rb0 >> (7 - bit)) & 1
            b1 = (rb1 >> (7 - bit)) & 1
            c = c_both if (b0 and b1) else (c0 if b0 else (c1 if b1 else 0))
            grid[16 + y][8 + bit] = palette.get(c, (0, 0, 0, 0))

    return grid

def extract_all_prisoners(asm_path: str, output_path: str) -> None:
    """Extrai e compila o spritesheet de 48x128 contendo os 4 prisioneiros."""
    sprites = load_asm_sprites(asm_path)

    # 3 Poses do assembly (data/actorspriteattr.asm:378-380):
    # Prisoner:     0xD0, 0xD4, 0xE0, 0xE4 (Tied Frame 1)
    # Prisoner2:    0xD8, 0xDC, 0xE0, 0xE4 (Tied Frame 2)
    # PrisonerFree: 0xE8, 0xEC, 0xF0, 0xF4 (Free)
    poses = [
        (0xD0, 0xD4, 0xE0, 0xE4),
        (0xD8, 0xDC, 0xE0, 0xE4),
        (0xE8, 0xEC, 0xF0, 0xF4),
    ]

    # 4 Personagens (Linha 0..3):
    # (Nome_Sprite_Asm, Col_Top_0, Col_Top_1, Col_Bot_0, Col_Bot_1, Paleta)
    characters = [
        # Linha 0: Prisioneiro comum (SprPrisoner, ActorSprColors14)
        ("SprPrisoner", 0x0D, 0x4B, 0x0D, 0x4B, PALETTE_PRISONER),
        # Linha 1: Grey Fox (SprPrisoner2, ActorSprColors15)
        ("SprPrisoner2", 0x0D, 0x4E, 0x0E, 0x4B, PALETTE_GREY_FOX),
        # Linha 2: Ellen Madnar (SprElen, ActorSprColors10 / SprsetPal8)
        ("SprElen", 0x0D, 0x4B, 0x0D, 0x4B, PALETTE_ELLEN),
        # Linha 3: Dr. Pettrovich Madnar / Falso Madnar (SprMadnar, ActorSprColors3 / SprsetPal7)
        ("SprMadnar", 2, 0x4D, 2, 0x4D, PALETTE_MADNAR),
    ]

    width = 16 * len(poses)        # 48 px
    height = 32 * len(characters)  # 128 px
    rgba_sheet = [(0, 0, 0, 0)] * (width * height)

    for row_idx, (spr_label, c_t0, c_t1, c_b0, c_b1, pal) in enumerate(characters):
        if spr_label not in sprites:
            raise KeyError(f"Símbolo {spr_label} não encontrado em {asm_path}")
        unpacked = decompress_rle(sprites[spr_label])
        if len(unpacked) != 320:
            raise ValueError(f"{spr_label}: esperado 320 bytes (10 padrões), obtido {len(unpacked)}")

        for col_idx, (pt0, pt1, pb0, pb1) in enumerate(poses):
            frame = composite_prisoner_frame(unpacked, pt0, pt1, pb0, pb1, c_t0, c_t1, c_b0, c_b1, pal)
            for y in range(32):
                for x in range(16):
                    dest_x = col_idx * 16 + x
                    dest_y = row_idx * 32 + y
                    rgba_sheet[dest_y * width + dest_x] = frame[y][x]

    write_png(output_path, width, height, rgba_sheet)
    print(f"PRISONERS_EXTRACTOR_OK: Spritesheet autêntico MSX2 salvo em '{output_path}' ({width}x{height} px).")

def main():
    parser = argparse.ArgumentParser(description="Extrator de sprites de prisioneiros do Metal Gear MSX2.")
    parser.add_argument("--asm", default="external/MetalGear/gfx/sprites.asm", help="Caminho para gfx/sprites.asm")
    parser.add_argument("--output", default="godot/assets/protected/sprites/prisoners_msx.png", help="Caminho de saída PNG")
    args = parser.parse_args()

    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
    asm_file = os.path.join(project_root, args.asm) if not os.path.isabs(args.asm) else args.asm
    out_file = os.path.join(project_root, args.output) if not os.path.isabs(args.output) else args.output

    if not os.path.exists(asm_file):
        print(f"ERRO: Arquivo não encontrado: {asm_file}")
        sys.exit(1)

    extract_all_prisoners(asm_file, out_file)

if __name__ == "__main__":
    main()
