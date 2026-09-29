#!/usr/bin/env python3
"""
tools/extractors/extract_title_intro_sprites.py

Extrator reprodutível em Python 3 dos sprites e gráficos autênticos da sequência
de abertura e tela de título do Metal Gear MSX2 original (Konami 1987, RC750).

Reverte os dados e lógicas dos arquivos de desmontagem em external/MetalGear/:
- logic/konamilogo.asm e gfx/konamilogo.asm:
    * Fita e texto do logotipo da Konami (1bpp, paleta KonamiLogoPal).
    * Fundo branco (VDP reg 7 = 0x0F) e dimensões da cortina (168x49 px).
- logic/mainmenu.asm e gfx/metalgearlogo.asm:
    * Logotipo metálico cromado "METAL GEAR" com frisos vermelhos/laranja (3bpp).
    * Composição de 'METAL' (104x32 px) e 'GEAR' (72x32 px).
- gfx/font.asm:
    * Fonte autêntica de 1987 (1bpp).
    * Símbolo de copyright (C), textos 'KONAMI 1987', 'PUSH SPACE KEY', 'PRESS START' e 'PLAY START'.

Gera os assets protegidos em godot/assets/protected/sprites/:
- intro_konami_logo.png (256x192 px, tela completa com fundo branco)
- intro_konami_ribbon.png (168x49 px, fita e texto transparentes para wipe)
- intro_metalgear_logo.png (176x40 px, logotipo metálico completo transparente)
- intro_title_full.png (256x192 px, tela de título composta)
- intro_copyright.png (104x8 px, '(C) KONAMI 1987')
- intro_press_start.png (88x8 px, 'PRESS START')
- intro_push_space.png (112x8 px, 'PUSH SPACE KEY')
- intro_play_start.png (80x8 px, 'PLAY START')
"""

import argparse
import os
import re
import struct
import sys
import zlib


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


def parse_asm_symbols(asm_path: str) -> dict:
    """Lê um arquivo .asm e extrai as sequências de bytes por rótulo."""
    if not os.path.exists(asm_path):
        return {}
    with open(asm_path, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    pattern = re.compile(r"([A-Za-z0-9_]+):\s+(.*?)(?=\n[A-Za-z0-9_]+:|\Z)", re.DOTALL)
    syms = {}
    for match in pattern.finditer(content):
        label = match.group(1)
        body = match.group(2)
        bytes_list = []
        for line in body.splitlines():
            line = line.strip().split(";")[0].strip()
            if not line.startswith("db"):
                continue
            line = line[2:].strip()
            # Divide respeitando strings entre aspas
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
                bytes_list.append(val)
        if bytes_list:
            syms[label] = bytes_list
    return syms


def to_rgb(r7: int, g7: int, b7: int, a: int = 255) -> tuple:
    """Converte valores RGB de 3 bits (0..7) do chip V9938 para 8 bits (0..255)."""
    return (r7 * 255 // 7, g7 * 255 // 7, b7 * 255 // 7, a)


def build_konami_logo(external_dir: str) -> tuple:
    """
    Decodifica os tiles 1bpp e monta o logotipo da Konami (fita + texto).
    Retorna:
      - full_screen: 256x192 RGBA (fundo branco)
      - ribbon_crop: 168x49 RGBA (transparente)
    """
    gfx_path = os.path.join(external_dir, "gfx", "konamilogo.asm")
    logic_path = os.path.join(external_dir, "logic", "konamilogo.asm")

    kgfx = parse_asm_symbols(gfx_path)
    klogic = parse_asm_symbols(logic_path)

    tiles = {}
    # Tiles 1..13: gfxKonamiLogo (fita laranja brilhante, cor 1)
    if "gfxKonamiLogo" in kgfx:
        raw = kgfx["gfxKonamiLogo"]
        for i in range(min(13, len(raw) // 8)):
            t_id = 1 + i
            tile = [[0] * 8 for _ in range(8)]
            for y in range(8):
                b = raw[i * 8 + y]
                for x in range(8):
                    if (b >> (7 - x)) & 1:
                        tile[y][x] = 1
            tiles[t_id] = tile

    # Tiles 14..26 (0x0e..0x1a): gfxKonamiLogo2 (fita laranja escura, cor 2)
    if "gfxKonamiLogo2" in kgfx:
        raw = kgfx["gfxKonamiLogo2"]
        for i in range(min(13, len(raw) // 8)):
            t_id = 14 + i
            tile = [[0] * 8 for _ in range(8)]
            for y in range(8):
                b = raw[i * 8 + y]
                for x in range(8):
                    if (b >> (7 - x)) & 1:
                        tile[y][x] = 2
            tiles[t_id] = tile

    # Tiles 27..52 (0x1b..0x34): gfxKonami (texto KONAMI cinza, cor 3)
    if "gfxKonami" in kgfx:
        raw = kgfx["gfxKonami"]
        for i in range(min(26, len(raw) // 8)):
            t_id = 27 + i
            tile = [[0] * 8 for _ in range(8)]
            for y in range(8):
                b = raw[i * 8 + y]
                for x in range(8):
                    if (b >> (7 - x)) & 1:
                        tile[y][x] = 3
            tiles[t_id] = tile

    # Paleta KonamiLogoPal
    pal = {
        0: (255, 255, 255, 255),  # Fundo branco (MSX2 VDP Reg 7 = 0x0F)
        1: to_rgb(7, 3, 0),        # Laranja vibrante
        2: to_rgb(6, 1, 0),        # Laranja/vermelho escuro
        3: to_rgb(4, 4, 4),        # Cinza para a palavra KONAMI
    }

    pal_transparent = {
        0: (0, 0, 0, 0),
        1: to_rgb(7, 3, 0),
        2: to_rgb(6, 1, 0),
        3: to_rgb(4, 4, 4),
    }

    # Grade 256x192
    grid = [[0] * 256 for _ in range(192)]
    tile_list = klogic.get("KonamiLogoTiles", [])

    idx = 0
    cur_x = 0x40  # 64
    cur_y = 0x40  # 64
    start_x = cur_x
    start_y = cur_y

    while idx < len(tile_list):
        val = tile_list[idx]
        idx += 1
        if val == 0xff:
            break
        if val == 0xfe:
            offset = tile_list[idx]
            idx += 1
            if offset >= 128:
                offset -= 256
            start_x += offset
            start_y += 8
            cur_x = start_x
            cur_y = start_y
            continue

        t = tiles.get(val)
        if t:
            for py in range(8):
                for px in range(8):
                    if 0 <= cur_y + py < 192 and 0 <= cur_x + px < 256:
                        c = t[py][px]
                        if c != 0:
                            grid[cur_y + py][cur_x + px] = c
        cur_x += 8

    full_screen = []
    for y in range(192):
        for x in range(256):
            c = grid[y][x]
            full_screen.append(pal.get(c, (255, 255, 255, 255)))

    # Recorte da fita: X = 40..208 (largura 168), Y = 64..113 (altura 49)
    ribbon_crop = []
    for y in range(64, 64 + 49):
        for x in range(40, 40 + 168):
            c = grid[y][x] if (0 <= y < 192 and 0 <= x < 256) else 0
            ribbon_crop.append(pal_transparent.get(c, (0, 0, 0, 0)))

    return full_screen, ribbon_crop


def build_font_tiles(external_dir: str) -> dict:
    """Decodifica a fonte MSX2 de gfx/font.asm (1bpp) para uso em textos."""
    font_path = os.path.join(external_dir, "gfx", "font.asm")
    font_asm = parse_asm_symbols(font_path)

    font_bytes = font_asm.get("gfxFont", []) + font_asm.get("gfxSymbChars", [])
    font_tiles = {}
    for i in range(len(font_bytes) // 8):
        tile = [[0] * 8 for _ in range(8)]
        for y in range(8):
            b = font_bytes[i * 8 + y]
            for x in range(8):
                if (b >> (7 - x)) & 1:
                    tile[y][x] = 14  # Branco
        font_tiles[i] = tile
    return font_tiles


def draw_char_on_grid(grid: list, font_tiles: dict, char_code: int, dx: int, dy: int) -> None:
    """Desenha um caractere na grade usando a fonte original."""
    if char_code == 0 or char_code == 32:
        return
    idx = char_code - 0x30
    if idx in font_tiles:
        t = font_tiles[idx]
        for y in range(8):
            for x in range(8):
                if t[y][x] != 0 and 0 <= dy + y < len(grid) and 0 <= dx + x < len(grid[0]):
                    grid[dy + y][dx + x] = t[y][x]


def render_text_image(font_tiles: dict, text: str, custom_chars: dict = None) -> tuple:
    """Renderiza uma string em uma imagem RGBA transparente com a fonte original."""
    w = len(text) * 8
    h = 8
    grid = [[0] * w for _ in range(h)]
    for i, ch in enumerate(text):
        if custom_chars and ch in custom_chars:
            code = custom_chars[ch]
        else:
            code = ord(ch)
        draw_char_on_grid(grid, font_tiles, code, i * 8, 0)

    rgba = []
    for y in range(h):
        for x in range(w):
            c = grid[y][x]
            if c != 0:
                rgba.append((255, 255, 255, 255))
            else:
                rgba.append((0, 0, 0, 0))
    return w, h, rgba


def build_metalgear_logo(external_dir: str) -> tuple:
    """
    Decodifica os tiles 3bpp de gfx/metalgearlogo.asm e compõe o logotipo 'METAL GEAR'.
    Retorna:
      - logo_rgba: 176x40 RGBA (transparente)
      - grid_metal: matriz de cores de 'METAL' (104x32)
      - grid_gear: matriz de cores de 'GEAR' (72x32)
      - pal: dicionário de cores RGB
    """
    gfx_path = os.path.join(external_dir, "gfx", "metalgearlogo.asm")
    logic_path = os.path.join(external_dir, "logic", "mainmenu.asm")

    mggfx = parse_asm_symbols(gfx_path)
    mglogic = parse_asm_symbols(logic_path)

    buffer_color = mglogic.get("MGLogoColors", [0, 2, 3, 4, 5, 9, 10, 14])
    raw_tiles = mggfx.get("gfxMetalGearLogo", [])
    num_tiles = len(raw_tiles) // 24

    tiles = {}
    for t in range(num_tiles):
        t_id = 1 + t
        tile = [[0] * 8 for _ in range(8)]
        offset = t * 24
        for line in range(8):
            e_byte = raw_tiles[offset + line * 3 + 0]
            d_byte = raw_tiles[offset + line * 3 + 1]
            c_byte = raw_tiles[offset + line * 3 + 2]
            for px in range(8):
                shift = 7 - px
                c_bit = (c_byte >> shift) & 1
                d_bit = (d_byte >> shift) & 1
                e_bit = (e_byte >> shift) & 1
                c_idx = (c_bit << 2) | (d_bit << 1) | e_bit
                pal_idx = buffer_color[c_idx] if c_idx < len(buffer_color) else 0
                tile[line][px] = pal_idx
        tiles[t_id] = tile

    pal = {
        0: (0, 0, 0, 0),
        2: to_rgb(3, 3, 3),
        3: to_rgb(2, 2, 2),
        4: to_rgb(5, 5, 5),
        5: to_rgb(6, 5, 2),
        9: to_rgb(6, 3, 0),
        10: to_rgb(6, 1, 1),
        14: to_rgb(7, 7, 7),
    }

    # "METAL": 13 cols x 4 rows = 104x32 px
    metal_tiles = mglogic.get("MetalTilesDat", [])
    grid_metal = [[0] * 104 for _ in range(32)]
    for r in range(4):
        for c in range(13):
            idx = r * 13 + c
            t_id = metal_tiles[idx] if idx < len(metal_tiles) else 0
            if t_id != 0 and t_id in tiles:
                t = tiles[t_id]
                for py in range(8):
                    for px in range(8):
                        grid_metal[r * 8 + py][c * 8 + px] = t[py][px]

    # "GEAR": 9 cols x 4 rows = 72x32 px
    gear_tiles = mglogic.get("GearTilesDat", [])
    grid_gear = [[0] * 72 for _ in range(32)]
    for r in range(4):
        for c in range(9):
            idx = r * 9 + c
            t_id = gear_tiles[idx] if idx < len(gear_tiles) else 0
            if t_id != 0 and t_id in tiles:
                t = tiles[t_id]
                for py in range(8):
                    for px in range(8):
                        grid_gear[r * 8 + py][c * 8 + px] = t[py][px]

    # Composição combinada em 176x40 px (METAL em (0, 0), GEAR em (104, 8))
    logo_w = 176
    logo_h = 40
    logo_grid = [[0] * logo_w for _ in range(logo_h)]

    for y in range(32):
        for x in range(104):
            c = grid_metal[y][x]
            if c != 0:
                logo_grid[y][x] = c

    for y in range(32):
        for x in range(72):
            c = grid_gear[y][x]
            if c != 0:
                logo_grid[8 + y][104 + x] = c

    logo_rgba = []
    for y in range(logo_h):
        for x in range(logo_w):
            c = logo_grid[y][x]
            logo_rgba.append(pal.get(c, (0, 0, 0, 0)))

    return logo_rgba, grid_metal, grid_gear, pal


def build_full_title_screen(grid_metal: list, grid_gear: list, font_tiles: dict, pal: dict) -> list:
    """Monta a tela de título completa de 256x192 px com fundo preto."""
    screen = [[0] * 256 for _ in range(192)]

    # METAL em X=32, Y=32
    for y in range(32):
        for x in range(104):
            c = grid_metal[y][x]
            if c != 0:
                screen[32 + y][32 + x] = c

    # GEAR em X=136, Y=40
    for y in range(32):
        for x in range(72):
            c = grid_gear[y][x]
            if c != 0:
                screen[40 + y][136 + x] = c

    # (C) KONAMI 1987
    draw_char_on_grid(screen, font_tiles, 0x3A, 78, 96)
    konami_txt = "KONAMI 1987"
    for i, ch in enumerate(konami_txt):
        draw_char_on_grid(screen, font_tiles, ord(ch), 88 + i * 8, 96)

    # PRESS START em (84, 136)
    press_txt = "PRESS START"
    for i, ch in enumerate(press_txt):
        draw_char_on_grid(screen, font_tiles, ord(ch), 84 + i * 8, 136)

    rgba = []
    for y in range(192):
        for x in range(256):
            c = screen[y][x]
            if c == 0:
                rgba.append((0, 0, 0, 255))
            else:
                rgba.append(pal.get(c, (255, 255, 255, 255)))
    return rgba


def main() -> int:
    parser = argparse.ArgumentParser(description="Extrator dos gráficos de abertura e título do Metal Gear MSX2")
    parser.add_argument("--external-dir", default="external/MetalGear", help="Diretório da desmontagem")
    parser.add_argument("--output-dir", default="godot/assets/protected/sprites", help="Diretório de saída dos assets")
    args = parser.parse_args()

    if not os.path.exists(args.external_dir):
        print(f"ERRO: Diretório {args.external_dir} não encontrado.", file=sys.stderr)
        return 1

    os.makedirs(args.output_dir, exist_ok=True)

    # 1. Logo Konami
    konami_full, konami_ribbon = build_konami_logo(args.external_dir)
    write_png(os.path.join(args.output_dir, "intro_konami_logo.png"), 256, 192, konami_full)
    write_png(os.path.join(args.output_dir, "intro_konami_ribbon.png"), 168, 49, konami_ribbon)
    print("Sucesso: Logotipo Konami gerado (256x192 e 168x49 px).")

    # 2. Logotipo Metal Gear
    mg_logo_rgba, grid_metal, grid_gear, pal = build_metalgear_logo(args.external_dir)
    write_png(os.path.join(args.output_dir, "intro_metalgear_logo.png"), 176, 40, mg_logo_rgba)
    print("Sucesso: Logotipo Metal Gear gerado (176x40 px).")

    # 3. Textos com a fonte autêntica
    font_tiles = build_font_tiles(args.external_dir)

    # (C) KONAMI 1987
    copy_w, copy_h, copy_rgba = render_text_image(font_tiles, "@ KONAMI 1987", {"@": 0x3A})
    write_png(os.path.join(args.output_dir, "intro_copyright.png"), copy_w, copy_h, copy_rgba)

    # PUSH SPACE KEY
    push_w, push_h, push_rgba = render_text_image(font_tiles, "PUSH SPACE KEY")
    write_png(os.path.join(args.output_dir, "intro_push_space.png"), push_w, push_h, push_rgba)

    # PRESS START
    press_w, press_h, press_rgba = render_text_image(font_tiles, "PRESS START")
    write_png(os.path.join(args.output_dir, "intro_press_start.png"), press_w, press_h, press_rgba)

    # PLAY START
    play_w, play_h, play_rgba = render_text_image(font_tiles, "PLAY START")
    write_png(os.path.join(args.output_dir, "intro_play_start.png"), play_w, play_h, play_rgba)

    # 4. Tela de título composta 256x192
    title_full_rgba = build_full_title_screen(grid_metal, grid_gear, font_tiles, pal)
    write_png(os.path.join(args.output_dir, "intro_title_full.png"), 256, 192, title_full_rgba)
    print("Sucesso: Tela de título completa gerada (256x192 px).")

    return 0


if __name__ == "__main__":
    sys.exit(main())
