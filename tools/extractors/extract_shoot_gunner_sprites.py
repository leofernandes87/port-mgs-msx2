#!/usr/bin/env python3
"""
tools/extractors/extract_shoot_gunner_sprites.py

Extrator reproduzível em Python 3 dos sprites autênticos do Boss Shoot Gunner
e dos disparos de escopeta do Metal Gear MSX2 original (RC750, Konami 1987).

Reconstitui a renderização de hardware do VDP TMS9918/V9938 (Sprite Mode 2 com Color Compare)
a partir dos padrões descompactados RLE em gfx/sprites.asm e das tabelas de atributos em
data/actorspriteattr.asm e data/palettes.asm:
- SprShotGunner: Boss Shoot Gunner (64x64 px: 4 colunas de 16x32 px, 2 linhas virado dir/esq)
- SprSGunnerShot: Projétil / Spray da escopeta (128x32 px: 4 células uniformes de 32x32 px)

Salva em:
- godot/assets/protected/sprites/shoot_gunner_msx.png
- godot/assets/protected/sprites/shotgun_shot_msx.png
"""

import argparse
import os
import re
import struct
import sys
import zlib

# Paleta Canônica MSX2 V9938 para Shoot Gunner (SprsetPal10, Sala 57)
# Cor 2: (36, 36, 72) -> Azul escuro camuflado
# Cor 13: (145, 109, 72) -> Cáqui / Pele
# Cor 14: (235, 235, 235) -> Prata / Branco brilhante dos chumbos (ActorSprColors12)
# Cor 15: (16, 16, 16) -> Preto puro resultante do Color Compare (2 | 13 = 15)
PALETTE_SHOOT_GUNNER = {
    0: (0, 0, 0, 0),
    2: (36, 36, 72, 255),
    13: (145, 109, 72, 255),
    14: (235, 235, 235, 255),
    15: (16, 16, 16, 255),
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
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

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

def get_pattern(unpacked_sprites: list, pat_byte: int, base_pat: int) -> list:
    """Extrai um padrão 16x16 (32 bytes) indexado por (pat_byte - base_pat) // 4."""
    idx = (pat_byte - base_pat) // 4
    start = idx * 32
    return unpacked_sprites[start : start + 32]

def composite_16x16_monochrome(pattern_bytes: list, color_idx: int, palette: dict) -> list:
    """Decodifica um padrão 16x16 monocromático de 32 bytes."""
    grid = [[(0, 0, 0, 0) for _ in range(16)] for _ in range(16)]
    col = palette.get(color_idx, (255, 255, 255, 255))
    for y in range(16):
        lb = pattern_bytes[y]
        rb = pattern_bytes[y + 16]
        for bit in range(8):
            if (lb >> (7 - bit)) & 1:
                grid[y][bit] = col
        for bit in range(8):
            if (rb >> (7 - bit)) & 1:
                grid[y][8 + bit] = col
    return grid

def composite_shotgunner_frame(
    unpacked: list,
    p_top_0: int, p_top_1: int,
    p_bot_0: int, p_bot_1: int,
    palette: dict
) -> list:
    """
    Monta um quadro 16x32 do Shoot Gunner combinando Top (Y=0..15) e Bot (Y=16..31).
    Aplica Color Compare onde os bits da Camada 0 (Cor 2) e da Camada 1 (Cor 13)
    se sobrepõem gerando Cor 15 (Preto).
    """
    grid = [[(0, 0, 0, 0) for _ in range(16)] for _ in range(32)]

    t0 = get_pattern(unpacked, p_top_0, 0x60)
    t1 = get_pattern(unpacked, p_top_1, 0x60)
    b0 = get_pattern(unpacked, p_bot_0, 0x60)
    b1 = get_pattern(unpacked, p_bot_1, 0x60)

    c0 = 2
    c1 = 13
    c_both = c0 | c1  # 15 (Preto)

    # 1. Metade superior (linhas 0 a 15)
    for y in range(16):
        lb0, rb0 = t0[y], t0[y + 16]
        lb1, rb1 = t1[y], t1[y + 16]
        for bit in range(8):
            bit0 = (lb0 >> (7 - bit)) & 1
            bit1 = (lb1 >> (7 - bit)) & 1
            c = c_both if (bit0 and bit1) else (c0 if bit0 else (c1 if bit1 else 0))
            grid[y][bit] = palette.get(c, (0, 0, 0, 0))
        for bit in range(8):
            bit0 = (rb0 >> (7 - bit)) & 1
            bit1 = (rb1 >> (7 - bit)) & 1
            c = c_both if (bit0 and bit1) else (c0 if bit0 else (c1 if bit1 else 0))
            grid[y][8 + bit] = palette.get(c, (0, 0, 0, 0))

    # 2. Metade inferior (linhas 16 a 31)
    for y in range(16):
        lb0, rb0 = b0[y], b0[y + 16]
        lb1, rb1 = b1[y], b1[y + 16]
        for bit in range(8):
            bit0 = (lb0 >> (7 - bit)) & 1
            bit1 = (lb1 >> (7 - bit)) & 1
            c = c_both if (bit0 and bit1) else (c0 if bit0 else (c1 if bit1 else 0))
            grid[16 + y][bit] = palette.get(c, (0, 0, 0, 0))
        for bit in range(8):
            bit0 = (rb0 >> (7 - bit)) & 1
            bit1 = (rb1 >> (7 - bit)) & 1
            c = c_both if (bit0 and bit1) else (c0 if bit0 else (c1 if bit1 else 0))
            grid[16 + y][8 + bit] = palette.get(c, (0, 0, 0, 0))

    return grid

def extract_shoot_gunner_sprites(asm_path: str, boss_output: str, bullet_output: str) -> None:
    """Extrai os spritesheets do boss Shoot Gunner e dos tiros de escopeta."""
    sprites = load_asm_sprites(asm_path)
    if "SprShotGunner" not in sprites:
        raise ValueError("Símbolo SprShotGunner não encontrado no arquivo ASM")
    if "SprSGunnerShot" not in sprites:
        raise ValueError("Símbolo SprSGunnerShot não encontrado no arquivo ASM")

    # 1. Processa SprShotGunner (512 bytes = 16 padrões de 16x16)
    unpacked_boss = decompress_rle(sprites["SprShotGunner"])
    if len(unpacked_boss) != 512:
        raise ValueError(f"SprShotGunner descompactou {len(unpacked_boss)} bytes (esperado 512)")

    # 4 quadros: Stand, Roll 1, Roll 2, Roll 3
    frames_config = [
        (0x60, 0x64, 0x68, 0x6C),  # Stand (5Dh)
        (0x70, 0x74, 0x78, 0x7C),  # Roll 1 (5Eh)
        (0x80, 0x84, 0x88, 0x8C),  # Roll 2 (5Fh)
        (0x90, 0x94, 0x98, 0x9C),  # Roll 3 (60h)
    ]

    boss_frames = []
    for cfg in frames_config:
        boss_frames.append(composite_shotgunner_frame(unpacked_boss, cfg[0], cfg[1], cfg[2], cfg[3], PALETTE_SHOOT_GUNNER))

    # Spritesheet Boss: 64x64 px (Row 0 = Right, Row 1 = Left / Flipped)
    boss_w, boss_h = 64, 64
    boss_pixels = [(0, 0, 0, 0)] * (boss_w * boss_h)

    for col, frame in enumerate(boss_frames):
        # Row 0: Normal (Facing Right)
        for y in range(32):
            for x in range(16):
                boss_pixels[y * boss_w + (col * 16 + x)] = frame[y][x]
        # Row 1: Flipped Horizontally (Facing Left)
        for y in range(32):
            for x in range(16):
                boss_pixels[(32 + y) * boss_w + (col * 16 + x)] = frame[y][15 - x]

    write_png(boss_output, boss_w, boss_h, boss_pixels)
    print(f"[OK] Shoot Gunner spritesheet gerado: {boss_output} ({boss_w}x{boss_h} px)")

    # 2. Processa SprSGunnerShot (224 bytes = 7 padrões de 16x16)
    unpacked_bullet = decompress_rle(sprites["SprSGunnerShot"])
    if len(unpacked_bullet) != 224:
        raise ValueError(f"SprSGunnerShot descompactou {len(unpacked_bullet)} bytes (esperado 224)")

    # Spritesheet Projétil: 128x32 px (4 células de 32x32 px)
    # Cell 0: ShotGunShot1 (0xA0 centrado em 8, 8)
    # Cell 1: ShotGunShot2 (0xA4 centrado em 8, 8)
    # Cell 2: ShotGunShot3 (0xA8 centrado em 8, 8)
    # Cell 3: ShotGunShot4 (0xAC, 0xB0, 0xB4, 0xB8 em grade 2x2 preenchendo 32x32)
    bullet_w, bullet_h = 128, 32
    bullet_pixels = [(0, 0, 0, 0)] * (bullet_w * bullet_h)

    # Frame 1: 0xA0
    p1 = composite_16x16_monochrome(get_pattern(unpacked_bullet, 0xA0, 0xA0), 14, PALETTE_SHOOT_GUNNER)
    for y in range(16):
        for x in range(16):
            bullet_pixels[(8 + y) * bullet_w + (0 * 32 + 8 + x)] = p1[y][x]

    # Frame 2: 0xA4
    p2 = composite_16x16_monochrome(get_pattern(unpacked_bullet, 0xA4, 0xA0), 14, PALETTE_SHOOT_GUNNER)
    for y in range(16):
        for x in range(16):
            bullet_pixels[(8 + y) * bullet_w + (1 * 32 + 8 + x)] = p2[y][x]

    # Frame 3: 0xA8
    p3 = composite_16x16_monochrome(get_pattern(unpacked_bullet, 0xA8, 0xA0), 14, PALETTE_SHOOT_GUNNER)
    for y in range(16):
        for x in range(16):
            bullet_pixels[(8 + y) * bullet_w + (2 * 32 + 8 + x)] = p3[y][x]

    # Frame 4: 0xAC (TL), 0xB0 (TR), 0xB4 (BL), 0xB8 (BR)
    p4_tl = composite_16x16_monochrome(get_pattern(unpacked_bullet, 0xAC, 0xA0), 14, PALETTE_SHOOT_GUNNER)
    p4_tr = composite_16x16_monochrome(get_pattern(unpacked_bullet, 0xB0, 0xA0), 14, PALETTE_SHOOT_GUNNER)
    p4_bl = composite_16x16_monochrome(get_pattern(unpacked_bullet, 0xB4, 0xA0), 14, PALETTE_SHOOT_GUNNER)
    p4_br = composite_16x16_monochrome(get_pattern(unpacked_bullet, 0xB8, 0xA0), 14, PALETTE_SHOOT_GUNNER)

    for y in range(16):
        for x in range(16):
            # Top-Left (0..15, 0..15)
            bullet_pixels[y * bullet_w + (3 * 32 + x)] = p4_tl[y][x]
            # Top-Right (16..31, 0..15)
            bullet_pixels[y * bullet_w + (3 * 32 + 16 + x)] = p4_tr[y][x]
            # Bottom-Left (0..15, 16..31)
            bullet_pixels[(16 + y) * bullet_w + (3 * 32 + x)] = p4_bl[y][x]
            # Bottom-Right (16..31, 16..31)
            bullet_pixels[(16 + y) * bullet_w + (3 * 32 + 16 + x)] = p4_br[y][x]

    write_png(bullet_output, bullet_w, bullet_h, bullet_pixels)
    print(f"[OK] Shotgun Bullet spritesheet gerado: {bullet_output} ({bullet_w}x{bullet_h} px)")

def main() -> None:
    parser = argparse.ArgumentParser(description="Extrai sprites de Shoot Gunner e tiros do MSX2 RC750")
    parser.add_argument("--asm", default="external/MetalGear/gfx/sprites.asm", help="Caminho para gfx/sprites.asm")
    parser.add_argument(
        "--boss-output",
        default="godot/assets/protected/sprites/shoot_gunner_msx.png",
        help="Caminho de saída para spritesheet do boss"
    )
    parser.add_argument(
        "--bullet-output",
        default="godot/assets/protected/sprites/shotgun_shot_msx.png",
        help="Caminho de saída para spritesheet do tiro"
    )
    args = parser.parse_args()

    extract_shoot_gunner_sprites(args.asm, args.boss_output, args.bullet_output)

if __name__ == "__main__":
    main()
