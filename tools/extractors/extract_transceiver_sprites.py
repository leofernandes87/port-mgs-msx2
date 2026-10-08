#!/usr/bin/env python3
"""
tools/extractors/extract_transceiver_sprites.py

Extrator reprodutível em Python 3 dos gráficos da interface do Transceptor / Radio / Codec
do Metal Gear MSX2 original (Konami 1987, RC750).

Extrai dados de:
- external/MetalGear/gfx/radio.asm (gfxRadio, gfxRadio2)
- external/MetalGear/gfx/snakeportrait.asm (gfxSnakePortrait, gfxSnakePortrait2)
- external/MetalGear/data/tileblocks.asm (RadioTilesMap, SnakeTilesMap, SnakePicture0/1/2)
- external/MetalGear/gfx/font.asm (gfxFreqDigits, gfxFont)
- external/MetalGear/Banks0123.asm (RedDigitTiles, ColorsTileset, ColSnakePic, DefaultPalette)
- external/MetalGear/data/palettes.asm (RadioPalette)

Gera os assets em godot/assets/protected/sprites/transceiver/:
- transceiver_chassis.png (144x72 px, chassi completo do transceptor)
- transceiver_snake_portrait.png (96x32 px, 3 quadros de 32x32: normal, piscar de olhos, falar)
- transceiver_digits.png (80x16 px, dígitos vermelhos 0-9 para display digital)
- transceiver_120.png (32x16 px, prefixo '120.')
- transceiver_leds.png (24x8 px, pares de LEDs: apagado, meio aceso, totalmente aceso)
- transceiver_mockup.png (256x192 px, tela completa de referência em Screen 5)
"""

import os
import re
import struct
import sys
import zlib

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
EXT_DIR = os.path.join(BASE_DIR, "external", "MetalGear")
OUT_DIR = os.path.join(BASE_DIR, "godot", "assets", "protected", "sprites", "transceiver")


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


def parse_asm_symbols(asm_path: str) -> dict:
    """Lê um arquivo .asm e extrai as sequências de bytes por rótulo (db e dw)."""
    if not os.path.exists(asm_path):
        return {}
    with open(asm_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    # gfx/font.asm:29-33,63-67: mutually exclusive regional glyphs.
    # Concatenating both branches shifts every tile after the question mark.
    content = re.sub(r"(?im)^\s*IF\s*\(JAPANESE\)\s*$.*?^\s*ELSE\s*$(.*?)^\s*ENDIF\s*$",
                     lambda match: match[1], content, flags=re.DOTALL)

    pattern = re.compile(r"([A-Za-z0-9_]+):\s+(.*?)(?=\n[A-Za-z0-9_]+:|\Z)", re.DOTALL)
    syms = {}
    for match in pattern.finditer(content):
        label = match.group(1)
        body = match.group(2)
        bytes_list = []
        for line in body.splitlines():
            line = line.strip().split(";")[0].strip()
            if not line:
                continue
            is_dw = False
            if line.startswith("db "):
                line = line[3:].strip()
            elif line.startswith("db\t"):
                line = line[3:].strip()
            elif line.startswith("dw "):
                is_dw = True
                line = line[3:].strip()
            elif line.startswith("dw\t"):
                is_dw = True
                line = line[3:].strip()
            else:
                continue

            parts = []
            cur = ""
            in_q = False
            for ch in line:
                if ch == '"':
                    in_q = not in_q
                    cur += ch
                elif ch == "," and not in_q:
                    parts.append(cur.strip())
                    cur = ""
                else:
                    cur += ch
            if cur.strip():
                parts.append(cur.strip())

            for p in parts:
                if not p:
                    continue
                if p.startswith('"') and p.endswith('"'):
                    bytes_list.extend(list(p[1:-1].encode("ascii")))
                    continue
                neg = False
                if p.startswith("-"):
                    neg = True
                    p = p[1:]
                val = int(p[:-1], 16) if (p.endswith("h") or p.endswith("H")) else int(p)
                if neg:
                    val = (-val) & 0xff
                if is_dw:
                    bytes_list.extend([val & 0xff, (val >> 8) & 0xff])
                else:
                    bytes_list.append(val)
        if bytes_list:
            syms[label] = bytes_list
    return syms


def get_radio_palette() -> list:
    """
    Retorna a paleta RGBA de 16 cores (0..15) do transceptor no MSX2 Screen 5.
    Combina DefaultPalette com as substituições de RadioPalette (data/palettes.asm:15).
    """
    # DefaultPalette (RGB de 3 bits 0..7)
    base_rgb = [
        (0, 0, 0),      # 0
        (0, 0, 0),      # 1
        (1, 6, 1),      # 2
        (3, 7, 3),      # 3
        (1, 1, 7),      # 4
        (2, 3, 7),      # 5
        (5, 1, 1),      # 6
        (2, 6, 7),      # 7
        (7, 1, 1),      # 8: Vermelho vivo (#ff2424)
        (7, 3, 3),      # 9
        (6, 6, 1),      # 10
        (6, 6, 4),      # 11
        (1, 4, 1),      # 12
        (6, 2, 5),      # 13
        (5, 5, 5),      # 14
        (7, 7, 7),      # 15
    ]

    # RadioPalette sobrescreve:
    # 1: 10h, 2 -> R=1, G=2, B=0
    # 2: 42h, 3 -> R=4, G=3, B=2
    # 3: 55h, 7 -> R=5, G=7, B=5 (LED ON)
    # 4: 31h, 2 -> R=3, G=2, B=1
    # 5: 40h, 0 -> R=4, G=0, B=0
    # 9: 23h, 2 -> R=2, G=2, B=3 (LED OFF)
    # 11: 20h, 1 -> R=2, G=1, B=0
    # 12: 33h, 3 -> R=3, G=3, B=3
    # 13: 5, 2 -> R=0, G=2, B=5
    # 14: 77h, 7 -> R=7, G=7, B=7
    # 15: 0, 0 -> R=0, G=0, B=0
    overrides = {
        1: (1, 2, 0),
        2: (4, 3, 2),
        3: (5, 7, 5),
        4: (3, 2, 1),
        5: (4, 0, 0),
        9: (2, 2, 3),
        11: (2, 1, 0),
        12: (3, 3, 3),
        13: (0, 2, 5),
        14: (7, 7, 7),
        15: (0, 0, 0),
    }

    palette_rgba = []
    for i in range(16):
        r3, g3, b3 = overrides.get(i, base_rgb[i])
        r8 = round(r3 * 255.0 / 7.0)
        g8 = round(g3 * 255.0 / 7.0)
        b8 = round(b3 * 255.0 / 7.0)
        a8 = 255
        palette_rgba.append((r8, g8, b8, a8))

    return palette_rgba


def decode_3bpp_tile(tile_bytes: list, color_table: list, flip_h: bool = False) -> list:
    """
    Decodifica um tile de 8x8 pixels em 3bpp conforme Decode3bpp em Banks0123.asm:5204.
    Cada linha de 8 pixels usa 3 bytes: E, D, C (24 bytes total por tile).
    bit 2 vem de C, bit 1 de D, bit 0 de E.
    Retorna lista de 64 índices de cores VDP (0..15).
    """
    pixels = []
    for line in range(8):
        offset = line * 3
        e = tile_bytes[offset]
        d = tile_bytes[offset + 1]
        c = tile_bytes[offset + 2]
        line_pixels = []
        for bit_idx in range(8):
            shift = 7 - bit_idx
            bit_c = (c >> shift) & 1
            bit_d = (d >> shift) & 1
            bit_e = (e >> shift) & 1
            color_idx = (bit_c << 2) | (bit_d << 1) | bit_e
            vdp_color = color_table[color_idx]
            line_pixels.append(vdp_color)
        if flip_h:
            line_pixels.reverse()
        pixels.extend(line_pixels)
    return pixels


def decode_1bpp_tile(tile_bytes: list, fg_color: int, bg_color: int = -1) -> list:
    """Decodifica um tile 1bpp de 8x8 pixels (8 bytes total)."""
    pixels = []
    for line in range(8):
        b = tile_bytes[line]
        for bit_idx in range(8):
            shift = 7 - bit_idx
            val = (b >> shift) & 1
            pixels.append(fg_color if val else bg_color)
    return pixels


def generate_msx_font(font_syms: dict, out_path: str) -> None:
    """
    Gera o spritesheet da fonte de texto bitmap 8x8 do MSX2 (Screen 5)
    com base em external/MetalGear/gfx/font.asm (gfxFont e gfxSymbChars).
    Gera imagem RGBA de 128x64 px (16 colunas x 8 linhas = 128 glifos ASCII 0..127).
    Pixels ligados são branco puro (255, 255, 255, 255); desligados são transparentes (0, 0, 0, 0).
    """
    gfx_font = font_syms.get("gfxFont", [])
    gfx_symb = font_syms.get("gfxSymbChars", [])
    all_font_bytes = gfx_font + gfx_symb
    raw_tiles = {}
    for i in range(len(all_font_bytes) // 8):
        raw_tiles[i] = all_font_bytes[i * 8:(i + 1) * 8]

    # Glifos padrão auxiliares para pontuação e símbolos 8x8
    aux_glyphs = {
        ord("/"): [0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x00],
        ord(":"): [0x00, 0x00, 0x18, 0x18, 0x00, 0x18, 0x18, 0x00],
        ord("("): [0x08, 0x10, 0x20, 0x20, 0x20, 0x10, 0x08, 0x00],
        ord(")"): [0x20, 0x10, 0x08, 0x08, 0x08, 0x10, 0x20, 0x00],
        ord("["): [0x38, 0x20, 0x20, 0x20, 0x20, 0x20, 0x38, 0x00],
        ord("]"): [0x38, 0x08, 0x08, 0x08, 0x08, 0x08, 0x38, 0x00],
        ord("+"): [0x00, 0x10, 0x10, 0x7C, 0x10, 0x10, 0x00, 0x00],
        ord("="): [0x00, 0x00, 0x7C, 0x00, 0x7C, 0x00, 0x00, 0x00],
        ord("_"): [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF],
    }

    width = 128  # 16 colunas * 8 px
    height = 64  # 8 linhas * 8 px
    rgba_data = [(0, 0, 0, 0)] * (width * height)

    for ascii_code in range(128):
        tile_bytes = [0] * 8
        if ord("0") <= ascii_code <= ord("9"):
            tile_bytes = raw_tiles.get(ascii_code - ord("0"), [0] * 8)
        elif ord("A") <= ascii_code <= ord("Z"):
            tile_bytes = raw_tiles.get(17 + (ascii_code - ord("A")), [0] * 8)
        elif ord("a") <= ascii_code <= ord("z"):
            tile_bytes = raw_tiles.get(17 + (ascii_code - ord("a")), [0] * 8)
        elif ascii_code == ord("!"):
            tile_bytes = raw_tiles.get(13, [0] * 8)
        elif ascii_code == ord('"'):
            tile_bytes = raw_tiles.get(14, [0] * 8)
        elif ascii_code == ord("#"):
            tile_bytes = raw_tiles.get(15, [0] * 8)
        elif ascii_code == ord("'"):
            tile_bytes = raw_tiles.get(103, [0] * 8)
        elif ascii_code == ord("*"):
            tile_bytes = raw_tiles.get(11, [0] * 8)  # Estrela ★
        elif ascii_code == ord(","):
            tile_bytes = raw_tiles.get(47, [0] * 8)
        elif ascii_code == ord("-"):
            tile_bytes = raw_tiles.get(16, [0] * 8)
        elif ascii_code == ord("."):
            tile_bytes = raw_tiles.get(44, [0] * 8)
        elif ascii_code == ord("?"):
            tile_bytes = raw_tiles.get(43, [0] * 8)
        elif ascii_code == ord("@"):
            tile_bytes = raw_tiles.get(10, [0] * 8)  # Copyright ©
        elif ascii_code == ord("<"):
            tile_bytes = raw_tiles.get(105, [0] * 8)  # Seta esquerda ⬅
        elif ascii_code == ord(">"):
            tile_bytes = raw_tiles.get(12, [0] * 8)  # Seta direita ➔
        elif ascii_code == ord("^"):
            tile_bytes = raw_tiles.get(106, [0] * 8)  # Seta cima ⬆
        elif ascii_code == ord("`"):
            tile_bytes = raw_tiles.get(103, [0] * 8)
        elif ascii_code in (13, 17, ord("~")):
            tile_bytes = raw_tiles.get(15, [0] * 8)  # Símbolo Enter ⏎
        elif ascii_code in aux_glyphs:
            tile_bytes = aux_glyphs[ascii_code]

        grid_col = ascii_code % 16
        grid_row = ascii_code // 16
        gx = grid_col * 8
        gy = grid_row * 8

        for py in range(8):
            b = tile_bytes[py]
            for px in range(8):
                if (b >> (7 - px)) & 1:
                    rgba_data[(gy + py) * width + (gx + px)] = (255, 255, 255, 255)

    write_png(out_path, width, height, rgba_data)
    print(f"Salvo: {out_path} ({width}x{height} px, 128 glifos)")


def extract_transceiver_assets() -> None:
    print("=== Extração de Gráficos do Transmissor MSX2 ===")
    os.makedirs(OUT_DIR, exist_ok=True)

    # 1. Carregar símbolos de todos os arquivos relevantes
    radio_syms = parse_asm_symbols(os.path.join(EXT_DIR, "gfx", "radio.asm"))
    snake_syms = parse_asm_symbols(os.path.join(EXT_DIR, "gfx", "snakeportrait.asm"))
    tileblocks_syms = parse_asm_symbols(os.path.join(EXT_DIR, "data", "tileblocks.asm"))
    font_syms = parse_asm_symbols(os.path.join(EXT_DIR, "gfx", "font.asm"))

    gfx_radio = radio_syms.get("gfxRadio", [])
    gfx_radio2 = radio_syms.get("gfxRadio2", [])
    gfx_snake = snake_syms.get("gfxSnakePortrait", [])
    gfx_snake2 = snake_syms.get("gfxSnakePortrait2", [])
    gfx_freq_digits = font_syms.get("gfxFreqDigits", [])
    gfx_font = font_syms.get("gfxFont", [])

    print("Bytes encontrados:")
    print(f"  gfxRadio: {len(gfx_radio)} bytes ({len(gfx_radio)//24} tiles)")
    print(f"  gfxRadio2: {len(gfx_radio2)} bytes ({len(gfx_radio2)//24} tiles)")
    print(f"  gfxSnakePortrait: {len(gfx_snake)} bytes ({len(gfx_snake)//24} tiles)")
    print(f"  gfxSnakePortrait2: {len(gfx_snake2)} bytes ({len(gfx_snake2)//24} tiles)")
    print(f"  gfxFreqDigits: {len(gfx_freq_digits)} bytes ({len(gfx_freq_digits)//8} tiles)")
    print(f"  gfxFont: {len(gfx_font)} bytes ({len(gfx_font)//8} tiles)")

    palette_rgba = get_radio_palette()

    # Tabelas de cores de Banks0123.asm:2998-3002
    colors_tileset = [1, 3, 5, 8, 9, 0x0C, 0x0E, 0x0F]
    col_snake_pic = [2, 4, 8, 0x0B, 0x0D, 0x0C, 0x0E, 0x0F]

    # Dicionário de tiles decodificados para o rádio:
    # Tile 0x40: tile preto
    # Tiles 0x41..0x58: 24 tiles de gfxRadio (unflipped)
    # Tiles 0x59..0x5F: 7 tiles de gfxRadio2 (unflipped)
    # Tiles 0x60..0x66: 7 tiles de gfxRadio2 (com flip horizontal)
    radio_tiles_vdp = {}
    radio_tiles_vdp[0x40] = [15] * 64  # preto puro

    for t in range(24):
        t_bytes = gfx_radio[t * 24:(t + 1) * 24]
        radio_tiles_vdp[0x41 + t] = decode_3bpp_tile(t_bytes, colors_tileset, flip_h=False)

    for t in range(7):
        t_bytes = gfx_radio2[t * 24:(t + 1) * 24]
        radio_tiles_vdp[0x59 + t] = decode_3bpp_tile(t_bytes, colors_tileset, flip_h=False)
        radio_tiles_vdp[0x60 + t] = decode_3bpp_tile(t_bytes, colors_tileset, flip_h=True)

    # 2. Extrair Chassi do Transmissor (RadioTilesMap: 18x9 tiles = 144x72 px)
    radio_map = tileblocks_syms.get("RadioTilesMap", [])
    if len(radio_map) >= 164:
        # byte 0 = 9, byte 1 = 18
        grid_tiles = radio_map[2:2 + 9 * 18]
    else:
        # Fallback canônico
        grid_tiles = [
            0x48, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x44, 0x4C, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46, 0x4F, 0x44, 0x4E,
            0x5B, 0x52, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x55, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x57, 0x56, 0x62,
            0x5B, 0x52, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x55, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x57, 0x56, 0x62,
            0x5B, 0x56, 0x51, 0x51, 0x51, 0x51, 0x51, 0x51, 0x50, 0x45, 0x45, 0x45, 0x45, 0x45, 0x45, 0x4D, 0x56, 0x62,
            0x5B, 0x40, 0x40, 0x40, 0x40, 0x56, 0x64, 0x53, 0x49, 0x5D, 0x56, 0x47, 0x47, 0x47, 0x47, 0x47, 0x47, 0x62,
            0x5B, 0x40, 0x40, 0x40, 0x40, 0x56, 0x5A, 0x54, 0x54, 0x61, 0x56, 0x58, 0x4A, 0x58, 0x4A, 0x58, 0x4A, 0x62,
            0x5B, 0x51, 0x51, 0x51, 0x51, 0x56, 0x5E, 0x54, 0x54, 0x65, 0x56, 0x58, 0x4A, 0x58, 0x4A, 0x58, 0x4A, 0x62,
            0x5B, 0x56, 0x47, 0x47, 0x47, 0x56, 0x59, 0x5F, 0x66, 0x60, 0x56, 0x56, 0x56, 0x56, 0x56, 0x56, 0x56, 0x62,
            0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x5C, 0x63, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B,
        ]

    chassis_w, chassis_h = 18 * 8, 9 * 8
    chassis_rgba = [(0, 0, 0, 255)] * (chassis_w * chassis_h)
    for ty in range(9):
        for tx in range(18):
            t_id = grid_tiles[ty * 18 + tx]
            tile_p = radio_tiles_vdp.get(t_id, [15] * 64)
            for py in range(8):
                for px in range(8):
                    v_color = tile_p[py * 8 + px]
                    chassis_rgba[(ty * 8 + py) * chassis_w + (tx * 8 + px)] = palette_rgba[v_color]

    chassis_path = os.path.join(OUT_DIR, "transceiver_chassis.png")
    write_png(chassis_path, chassis_w, chassis_h, chassis_rgba)
    print(f"Salvo: {chassis_path} ({chassis_w}x{chassis_h} px)")

    # 3. Extrair Retrato do Solid Snake (SnakeTilesMap: 4x4 tiles = 32x32 px)
    # Tiles 0x10..0x1F (16 tiles de gfxSnakePortrait)
    # Tiles 0x30..0x32 (3 tiles de gfxSnakePortrait2)
    snake_tiles_vdp = {}
    for t in range(16):
        t_bytes = gfx_snake[t * 24:(t + 1) * 24]
        snake_tiles_vdp[0x10 + t] = decode_3bpp_tile(t_bytes, col_snake_pic, flip_h=False)

    for t in range(3):
        t_bytes = gfx_snake2[t * 24:(t + 1) * 24]
        snake_tiles_vdp[0x30 + t] = decode_3bpp_tile(t_bytes, col_snake_pic, flip_h=False)

    # 3 frames do retrato:
    # Frame 0: Normal (SnakePicture0: 15h, 16h em cima; 19h, 1Ah embaixo)
    # Frame 1: Piscar (SnakePicture1: 30h, 31h em cima; 19h, 1Ah embaixo)
    # Frame 2: Falar  (SnakePicture2: 15h, 16h em cima; 32h, 1Ah embaixo)
    def render_snake_frame(pic_top_left: int, pic_top_right: int, pic_bot_left: int, pic_bot_right: int) -> list:
        grid = [
            0x10, 0x11, 0x12, 0x13,
            0x14, pic_top_left, pic_top_right, 0x17,
            0x18, pic_bot_left, pic_bot_right, 0x1B,
            0x1C, 0x1D, 0x1E, 0x1F,
        ]
        rgba = [(0, 0, 0, 255)] * (32 * 32)
        for ty in range(4):
            for tx in range(4):
                t_id = grid[ty * 4 + tx]
                tile_p = snake_tiles_vdp.get(t_id, [15] * 64)
                for py in range(8):
                    for px in range(8):
                        v_color = tile_p[py * 8 + px]
                        rgba[(ty * 8 + py) * 32 + (tx * 8 + px)] = palette_rgba[v_color]
        return rgba

    frame_norm = render_snake_frame(0x15, 0x16, 0x19, 0x1A)
    frame_blink = render_snake_frame(0x30, 0x31, 0x19, 0x1A)
    frame_talk = render_snake_frame(0x15, 0x16, 0x32, 0x1A)

    # Combinar os 3 quadros em uma fita de 96x32 px
    strip_w, strip_h = 32 * 3, 32
    portrait_strip = [(0, 0, 0, 255)] * (strip_w * strip_h)
    frames = [frame_norm, frame_blink, frame_talk]
    for f_idx, f_rgba in enumerate(frames):
        for y in range(32):
            for x in range(32):
                portrait_strip[y * strip_w + (f_idx * 32 + x)] = f_rgba[y * 32 + x]

    portrait_path = os.path.join(OUT_DIR, "transceiver_snake_portrait.png")
    write_png(portrait_path, strip_w, strip_h, portrait_strip)
    print(f"Salvo: {portrait_path} ({strip_w}x{strip_h} px, 3 frames)")

    # 4. Extrair Dígitos Vermelhos Digitais (gfxFreqDigits: 13 tiles de 1bpp)
    # RedDigitTiles mapeia dígitos 0-9 para pares de tiles (topo, base):
    red_digit_pairs = [
        (0xA4, 0xA5),  # 0
        (0xA6, 0xA7),  # 1
        (0xA8, 0xA9),  # 2
        (0xAA, 0xAB),  # 3
        (0xAC, 0xA7),  # 4
        (0xAD, 0xAB),  # 5
        (0xAD, 0xA5),  # 6
        (0xAE, 0xA7),  # 7
        (0xAF, 0xA5),  # 8
        (0xAF, 0xAB),  # 9
    ]

    freq_tiles_1bpp = {}
    for t in range(13):
        t_bytes = gfx_freq_digits[t * 8:(t + 1) * 8]
        # cor 8 = vermelho no Screen 5
        freq_tiles_1bpp[0xA3 + t] = decode_1bpp_tile(t_bytes, fg_color=8, bg_color=-1)

    # Dígitos 0-9: 10 dígitos de 8x16 px = 80x16 px
    digits_w, digits_h = 10 * 8, 16
    digits_rgba = [(0, 0, 0, 0)] * (digits_w * digits_h)
    for d_idx, (t_top, t_bot) in enumerate(red_digit_pairs):
        top_p = freq_tiles_1bpp[t_top]
        bot_p = freq_tiles_1bpp[t_bot]
        for py in range(8):
            for px in range(8):
                c_top = top_p[py * 8 + px]
                if c_top != -1:
                    digits_rgba[py * digits_w + (d_idx * 8 + px)] = palette_rgba[c_top]
                c_bot = bot_p[py * 8 + px]
                if c_bot != -1:
                    digits_rgba[(8 + py) * digits_w + (d_idx * 8 + px)] = palette_rgba[c_bot]

    digits_path = os.path.join(OUT_DIR, "transceiver_digits.png")
    write_png(digits_path, digits_w, digits_h, digits_rgba)
    print(f"Salvo: {digits_path} ({digits_w}x{digits_h} px)")

    # Prefixo "120." (32x16 px):
    # '1': A6, A7
    # '2': A8, A9
    # '0': A4, A5
    # '.': A3 na metade inferior
    p120_w, p120_h = 32, 16
    p120_rgba = [(0, 0, 0, 0)] * (p120_w * p120_h)
    prefix_chars = [
        (0xA6, 0xA7),  # 1
        (0xA8, 0xA9),  # 2
        (0xA4, 0xA5),  # 0
    ]
    for d_idx, (t_top, t_bot) in enumerate(prefix_chars):
        top_p = freq_tiles_1bpp[t_top]
        bot_p = freq_tiles_1bpp[t_bot]
        for py in range(8):
            for px in range(8):
                c_top = top_p[py * 8 + px]
                if c_top != -1:
                    p120_rgba[py * p120_w + (d_idx * 8 + px)] = palette_rgba[c_top]
                c_bot = bot_p[py * 8 + px]
                if c_bot != -1:
                    p120_rgba[(8 + py) * p120_w + (d_idx * 8 + px)] = palette_rgba[c_bot]

    # Ponto decimal na coluna 3 (X=24..31), Y=8..15 (tile 0xA3)
    dot_p = freq_tiles_1bpp[0xA3]
    for py in range(8):
        for px in range(8):
            c_dot = dot_p[py * 8 + px]
            if c_dot != -1:
                p120_rgba[(8 + py) * p120_w + (24 + px)] = palette_rgba[c_dot]

    p120_path = os.path.join(OUT_DIR, "transceiver_120.png")
    write_png(p120_path, p120_w, p120_h, p120_rgba)
    print(f"Salvo: {p120_path} ({p120_w}x{p120_h} px)")

    # 5. Extrair Tiles dos LEDs de Sinal (24x8 px: 0x41, 0x42, 0x43)
    leds_w, leds_h = 24, 8
    leds_rgba = [(0, 0, 0, 255)] * (leds_w * leds_h)
    led_tiles = [0x41, 0x42, 0x43]
    for idx, t_id in enumerate(led_tiles):
        tile_p = radio_tiles_vdp[t_id]
        for py in range(8):
            for px in range(8):
                v_color = tile_p[py * 8 + px]
                leds_rgba[py * leds_w + (idx * 8 + px)] = palette_rgba[v_color]

    leds_path = os.path.join(OUT_DIR, "transceiver_leds.png")
    write_png(leds_path, leds_w, leds_h, leds_rgba)
    print(f"Salvo: {leds_path} ({leds_w}x{leds_h} px)")

    # 5.1 Gerar Spritesheet da Fonte Bitmap 8x8 do MSX2 (128x64 px, 128 glifos ASCII)
    font_path = os.path.join(OUT_DIR, "msx_font.png")
    generate_msx_font(font_syms, font_path)

    # 6. Renderizar Mockup Canônico Completo (Screen 5: 256x192 px)
    mockup_w, mockup_h = 256, 192
    mockup_rgba = [(0, 0, 0, 255)] * (mockup_w * mockup_h)

    # 6.1 Desenhar Chassi em (48, 24)
    for cy in range(chassis_h):
        for cx in range(chassis_w):
            mockup_rgba[(24 + cy) * mockup_w + (48 + cx)] = chassis_rgba[cy * chassis_w + cx]

    # 6.2 Desenhar Retrato do Solid Snake em (200, 40)
    for sy in range(32):
        for sx in range(32):
            mockup_rgba[(40 + sy) * mockup_w + (200 + sx)] = frame_norm[sy * 32 + sx]

    # 6.3 Desenhar Frequência "120.85" em (120, 33)
    # Prefixo "120." (X=120..151)
    for py in range(16):
        for px in range(32):
            pixel = p120_rgba[py * 32 + px]
            if pixel[3] > 0:
                mockup_rgba[(33 + py) * mockup_w + (120 + px)] = pixel

    # Dígito '8' em (152, 33) e '5' em (160, 33)
    d8_top, d8_bot = red_digit_pairs[8]
    d5_top, d5_bot = red_digit_pairs[5]
    for d_offset_x, (top_t, bot_t) in [(152, (d8_top, d8_bot)), (160, (d5_top, d5_bot))]:
        top_p = freq_tiles_1bpp[top_t]
        bot_p = freq_tiles_1bpp[bot_t]
        for py in range(8):
            for px in range(8):
                c_top = top_p[py * 8 + px]
                if c_top != -1:
                    mockup_rgba[(33 + py) * mockup_w + (d_offset_x + px)] = palette_rgba[c_top]
                c_bot = bot_p[py * 8 + px]
                if c_bot != -1:
                    mockup_rgba[(33 + 8 + py) * mockup_w + (d_offset_x + px)] = palette_rgba[c_bot]

    # 6.4 Desenhar 12 LEDs de sinal totalmente acesos (tile 0x43) em (64, 32) e (64, 40)
    # 6 pares de LEDs a cada 8 pixels de X, com 2 andares de altura (16 px):
    t43_p = radio_tiles_vdp[0x43]
    for pair_idx in range(6):
        lx = 64 + pair_idx * 8
        for py in range(8):
            for px in range(8):
                c = palette_rgba[t43_p[py * 8 + px]]
                mockup_rgba[(32 + py) * mockup_w + (lx + px)] = c
                mockup_rgba[(40 + py) * mockup_w + (lx + px)] = c

    # 6.5 Desenhar Título "TRANSCEIVER" em (80, 8) e "RECV" em (56, 64) usando a fonte 1bpp
    gfx_symb = font_syms.get("gfxSymbChars", [])
    all_font_bytes = gfx_font + gfx_symb
    font_tiles = {}
    for i in range(len(all_font_bytes) // 8):
        font_tiles[i] = decode_1bpp_tile(all_font_bytes[i * 8:(i + 1) * 8], fg_color=14, bg_color=-1)

    def get_tile_for_char(ch: str):
        c = ord(ch)
        if ord("0") <= c <= ord("9"):
            return font_tiles.get(c - ord("0"))
        elif ord("A") <= c <= ord("Z"):
            return font_tiles.get(17 + (c - ord("A")))
        elif ord("a") <= c <= ord("z"):
            return font_tiles.get(17 + (c - ord("a")))
        elif ch == ".":
            return font_tiles.get(44)
        elif ch == "!":
            return font_tiles.get(13)
        elif ch == "?":
            return font_tiles.get(43)
        elif ch == ",":
            return font_tiles.get(46)
        elif ch == "-":
            return font_tiles.get(16)
        elif ch == "'":
            return font_tiles.get(47)
        return None

    def draw_text_1bpp(text_str: str, start_x: int, start_y: int) -> None:
        cur_x = start_x
        for ch in text_str:
            if ch == " ":
                cur_x += 8
                continue
            t_p = get_tile_for_char(ch)
            if t_p:
                for py in range(8):
                    for px in range(8):
                        c = t_p[py * 8 + px]
                        if c != -1:
                            mockup_rgba[(start_y + py) * mockup_w + (cur_x + px)] = palette_rgba[c]
            cur_x += 4 if ch == "'" else 8

    draw_text_1bpp("TRANSCEIVER", 80, 8)
    draw_text_1bpp("RECV", 56, 64)

    # 6.6 Desenhar Caixa de Diálogo em (32, 116, 200, 72)
    # Moldura externa em branco/cinza claro (cor 14), fundo preto (cor 15)
    box_x, box_y, box_w, box_h = 32, 116, 200, 72
    for by in range(box_h):
        for bx in range(box_w):
            is_border = (bx == 0 or bx == box_w - 1 or by == 0 or by == box_h - 1)
            mockup_rgba[(box_y + by) * mockup_w + (box_x + bx)] = palette_rgba[14] if is_border else palette_rgba[15]

    # Texto do diálogo em (36, 120) conforme briefing original:
    lines = [
        "THIS IS BIG BOSS...",
        "OPERATION INTRUDE N313."
    ]
    for l_idx, line_str in enumerate(lines):
        draw_text_1bpp(line_str, 36, 120 + l_idx * 12)

    # Ícone do Enter ⏎ piscante em (212, 168) (tile 15)
    enter_tile = font_tiles.get(15)
    if enter_tile:
        for py in range(8):
            for px in range(8):
                c = enter_tile[py * 8 + px]
                if c != -1:
                    mockup_rgba[(168 + py) * mockup_w + (212 + px)] = palette_rgba[c]

    mockup_path = os.path.join(OUT_DIR, "transceiver_mockup.png")
    write_png(mockup_path, mockup_w, mockup_h, mockup_rgba)
    print(f"Salvo: {mockup_path} ({mockup_w}x{mockup_h} px)")
    print("=== Extração concluída com sucesso! ===")


if __name__ == "__main__":
    extract_transceiver_assets()
