#!/usr/bin/env python3
"""
tools/extractors/extract_hud_assets.py

Extrator reprodutível em Python 3 dos gráficos do HUD (Heads-Up Display)
do Metal Gear MSX2 original (Konami 1987, RC750).

Extrai dados de:
- external/MetalGear/gfx/items.asm (GfxItems: 132 tiles 3bpp)
- external/MetalGear/data/itemgfxxy.asm (ItemGfxXY: coordenadas dos itens na VRAM)
- external/MetalGear/data/weapongfxxy.asm (WeaponGfxXY: coordenadas das armas na VRAM)
- external/MetalGear/gfx/font.asm (gfxCALL: 6 tiles 2bpp do sinal CALL, gfxFont, gfxSymbChars)
- external/MetalGear/Banks0123.asm (ColorsItems: paleta dos itens; DefaultPalette, RadioPalette)

Gera os assets em godot/assets/protected/sprites/hud/:
- hud_weapons.png (256x16 px: 8 armas de 32x16 px)
- hud_items.png (448x16 px: 28 itens de 16x16 px)
- hud_call.png (24x16 px: sinal CALL autêntico)
- hud_mockup.png (256x20 px: mockup de referência canônico do HUD MSX2)
"""

import os
import struct
import zlib

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
EXT_DIR = os.path.join(BASE_DIR, "external", "MetalGear")
OUT_DIR = os.path.join(BASE_DIR, "godot", "assets", "protected", "sprites", "hud")


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
    """Lê um arquivo .asm e extrai as sequências de bytes e words por rótulo (db e dw)."""
    if not os.path.exists(asm_path):
        return {}

    symbols = {}
    current_symbol = None
    in_japanese = False

    with open(asm_path, "r", encoding="latin-1") as f:
        for line in f:
            raw_line = line.split(";")[0].strip()
            if not raw_line:
                continue

            if "IF (JAPANESE)" in raw_line:
                in_japanese = True
                continue
            if "ELSE" in raw_line:
                in_japanese = False
                continue
            if "ENDIF" in raw_line:
                in_japanese = False
                continue
            if in_japanese:
                continue

            if ":" in raw_line and not raw_line.startswith("db") and not raw_line.startswith("dw"):
                parts = raw_line.split(":", 1)
                current_symbol = parts[0].strip()
                symbols[current_symbol] = []
                raw_line = parts[1].strip()

            if not current_symbol or not raw_line:
                continue

            if raw_line.startswith("db"):
                data_part = raw_line[2:].strip()
                items = [item.strip() for item in data_part.split(",") if item.strip()]
                for it in items:
                    if (it.startswith('"') and it.endswith('"')) or (it.startswith("'") and it.endswith("'")):
                        for ch in it[1:-1]:
                            symbols[current_symbol].append(ord(ch))
                    else:
                        val_str = it.rstrip("hH")
                        if val_str.startswith("#"):
                            val = int(val_str[1:], 16)
                        elif it.endswith("h") or it.endswith("H"):
                            val = int(val_str, 16)
                        else:
                            val = int(it)
                        symbols[current_symbol].append(val & 0xFF)

            elif raw_line.startswith("dw"):
                data_part = raw_line[2:].strip()
                items = [item.strip() for item in data_part.split(",") if item.strip()]
                for it in items:
                    val_str = it.rstrip("hH")
                    if val_str.startswith("#"):
                        val = int(val_str[1:], 16)
                    elif it.endswith("h") or it.endswith("H"):
                        val = int(val_str, 16)
                    else:
                        val = int(it)
                    symbols[current_symbol].append(val & 0xFFFF)

    return symbols


def get_default_palette() -> list:
    """
    Paleta padrão do MSX2 Yamaha V9938 com as correções de execução canônicas:
    - SnakePal (Banks0123.asm:2890): cor 7 vira chumbo metálico (1, 2, 2); cor 10 vira cáqui/papelão (6, 4, 3).
    - PalMenuWeapon (data/palettes.asm:7): cor 12 vira cinza médio metálico (3, 3, 3).
    """
    base_rgb = [
        (0, 0, 0),      # 0: Transparente / Preto
        (0, 0, 0),      # 1: Preto
        (1, 6, 1),      # 2: Verde médio
        (3, 7, 3),      # 3: Verde claro
        (1, 1, 7),      # 4: Azul escuro
        (2, 3, 7),      # 5: Azul claro
        (7, 7, 0),      # 6: Amarelo ouro vivo (PalMenuWeapon: db 6, 70h, 7 - miolo do Lucky Strike)
        (1, 2, 2),      # 7: Chumbo escuro metálico (SnakePal: db 7, 12h, 2)
        (7, 0, 0),      # 8: Vermelho vivo (PalMenuWeapon: db 8, 70h, 0)
        (7, 3, 3),      # 9: Vermelho claro
        (6, 4, 3),      # 10: Bege / Cáqui / Papelão (SnakePal: db 0Ah, 63h, 4)
        (6, 6, 4),      # 11: Amarelo claro
        (3, 3, 3),      # 12: Cinza médio metálico (PalMenuWeapon: db 0Ch, 33h, 3)
        (6, 2, 5),      # 13: Magenta
        (7, 7, 7),      # 14: Branco puro (PalMenuWeapon: db 0Eh, 77h, 7)
        (0, 0, 0),      # 15: Preto puro / sombras (PalMenuWeapon: db 0Fh, 0, 0)
    ]

    palette_rgba = []
    for r3, g3, b3 in base_rgb:
        r8 = round(r3 * 255.0 / 7.0)
        g8 = round(g3 * 255.0 / 7.0)
        b8 = round(b3 * 255.0 / 7.0)
        palette_rgba.append((r8, g8, b8, 255))
    return palette_rgba


MSX2_PALETTE = get_default_palette()
COLORS_ITEMS = [0, 6, 7, 8, 0x0A, 0x0C, 0x0E, 0x0F]
CALL_COLORS = [6, 8, 0x0E, 0x0F]

WEAPONS_INFO = [
    {"id": 1, "name": "HANDGUN", "vx": 0, "vy": 96, "vw": 32, "vh": 16, "off_x": 0},
    {"id": 2, "name": "SMG", "vx": 32, "vy": 96, "vw": 32, "vh": 16, "off_x": 0},
    {"id": 3, "name": "GRENADE_LAUNCHER", "vx": 64, "vy": 96, "vw": 32, "vh": 16, "off_x": 0},
    {"id": 4, "name": "ROCKET_LAUNCHER", "vx": 96, "vy": 96, "vw": 32, "vh": 16, "off_x": 0},
    {"id": 5, "name": "PLASTIC_BOMB", "vx": 128, "vy": 96, "vw": 16, "vh": 16, "off_x": 8},
    {"id": 6, "name": "LAND_MINE", "vx": 144, "vy": 96, "vw": 16, "vh": 16, "off_x": 8},
    {"id": 7, "name": "REMOTE_MISSILE", "vx": 160, "vy": 96, "vw": 16, "vh": 16, "off_x": 8},
    {"id": 8, "name": "SILENCER", "vx": 176, "vy": 96, "vw": 16, "vh": 16, "off_x": 8},
]

ITEMS_INFO = [
    {"id": 1, "name": "ARMOR", "vx": 192, "vy": 96},
    {"id": 2, "name": "SUIT", "vx": 208, "vy": 96},
    {"id": 3, "name": "LIGHT", "vx": 224, "vy": 96},
    {"id": 4, "name": "GOGGLES", "vx": 240, "vy": 96},
    {"id": 5, "name": "GAS_MASK", "vx": 0, "vy": 112},
    {"id": 6, "name": "CIGARETTES", "vx": 16, "vy": 112},
    {"id": 7, "name": "MINE_DETECTOR", "vx": 32, "vy": 112},
    {"id": 8, "name": "ANTENNA", "vx": 48, "vy": 112},
    {"id": 9, "name": "BINOCULARS", "vx": 64, "vy": 112},
    {"id": 10, "name": "OXYGEN_TANK", "vx": 80, "vy": 112},
    {"id": 11, "name": "COMPASS", "vx": 96, "vy": 112},
    {"id": 12, "name": "PARACHUTE", "vx": 112, "vy": 112},
    {"id": 13, "name": "ANTIDOTE", "vx": 128, "vy": 112},
    {"id": 14, "name": "CARD_1", "vx": 144, "vy": 112},
    {"id": 15, "name": "CARD_2", "vx": 144, "vy": 112},
    {"id": 16, "name": "CARD_3", "vx": 144, "vy": 112},
    {"id": 17, "name": "CARD_4", "vx": 144, "vy": 112},
    {"id": 18, "name": "CARD_5", "vx": 144, "vy": 112},
    {"id": 19, "name": "CARD_6", "vx": 144, "vy": 112},
    {"id": 20, "name": "CARD_7", "vx": 144, "vy": 112},
    {"id": 21, "name": "CARD_8", "vx": 144, "vy": 112},
    {"id": 22, "name": "RATION", "vx": 160, "vy": 112},
    {"id": 23, "name": "TRANSCEIVER", "vx": 176, "vy": 112},
    {"id": 24, "name": "UNIFORM", "vx": 192, "vy": 112},
    {"id": 25, "name": "CARDBOARD_BOX", "vx": 208, "vy": 112},
    {"id": 26, "name": "ITEM_BAG", "vx": 224, "vy": 112},
    {"id": 27, "name": "AMMO_CRATE", "vx": 240, "vy": 112},
]


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


def decode_2bpp_tile(tile_bytes: list, color_table: list) -> list:
    """
    Decodifica um tile de 8x8 pixels em 2bpp conforme Load2bppTile em Banks0123.asm:4550.
    16 bytes por tile (2 bytes por linha de 8 pixels: plano 0 e plano 1).
    """
    pixels = []
    for line in range(8):
        b0 = tile_bytes[line * 2]
        b1 = tile_bytes[line * 2 + 1]
        for px in range(8):
            shift = 7 - px
            bit0 = (b0 >> shift) & 1
            bit1 = (b1 >> shift) & 1
            c_idx = (bit1 << 1) | bit0
            vdp_color = color_table[c_idx]
            pixels.append(vdp_color)
    return pixels


def extract_hud_assets() -> None:
    print("=== Extração de Gráficos do HUD MSX2 ===")
    os.makedirs(OUT_DIR, exist_ok=True)

    palette = get_default_palette()
    # ColorsItems (Banks0123.asm:2999): db 0, 6, 7, 8, 0Ah, 0Ch, 0Eh, 0Fh
    colors_items = [0, 6, 7, 8, 0x0A, 0x0C, 0x0E, 0x0F]

    # 1. Carregar GfxItems de gfx/items.asm
    items_syms = parse_asm_symbols(os.path.join(EXT_DIR, "gfx", "items.asm"))
    gfx_items = items_syms.get("GfxItems", [])
    print(f"GfxItems: {len(gfx_items)} bytes ({len(gfx_items) // 24} tiles de 3bpp)")

    # Decodificar todos os 132 tiles 3bpp de GfxItems
    num_tiles = len(gfx_items) // 24
    decoded_tiles = []
    for t in range(num_tiles):
        tile_bytes = gfx_items[t * 24:(t + 1) * 24]
        pix = decode_3bpp_tile(tile_bytes, colors_items, flip_h=False)
        decoded_tiles.append(pix)

    # Função auxiliar para extrair um bloco de (w_tiles x h_tiles) da VRAM Página 1
    # No MSX2, Load3bppTiles coloca 32 tiles por linha de scanlines (256 px).
    def get_vram_block(x_px: int, y_px: int, w_px: int, h_px: int) -> list:
        # y_px relativo ao topo dos itens (Y=96 na VRAM da Página 1)
        rel_y = y_px - 96
        block_rgba = [(0, 0, 0, 0)] * (w_px * h_px)
        w_tiles = w_px // 8
        h_tiles = h_px // 8
        base_tile_x = x_px // 8
        base_tile_y = rel_y // 8

        for ry in range(h_tiles):
            for rx in range(w_tiles):
                tile_idx = (base_tile_y + ry) * 32 + (base_tile_x + rx)
                if tile_idx < len(decoded_tiles):
                    tile_pixels = decoded_tiles[tile_idx]
                    for py in range(8):
                        for px in range(8):
                            c_idx = tile_pixels[py * 8 + px]
                            if c_idx != 0:  # Cor 0 é transparente
                                bx = rx * 8 + px
                                by = ry * 8 + py
                                block_rgba[by * w_px + bx] = palette[c_idx]
        return block_rgba

    # 2. Extrair Armas: 8 armas de 32x16 px (256x16 px total)
    # WeaponGfxXY (data/weapongfxxy.asm):
    # 1: 32x16 em (0, 96)   - Handgun
    # 2: 32x16 em (32, 96)  - SMG
    # 3: 32x16 em (64, 96)  - Grenade Launcher
    # 4: 32x16 em (96, 96)  - Rocket Launcher
    # 5: 16x16 em (128, 96) - Plastic Bomb (centralizado em célula 32x16 com offset X=8)
    # 6: 16x16 em (144, 96) - Land Mine (centralizado em célula 32x16 com offset X=8)
    # 7: 16x16 em (160, 96) - Remote Missile (centralizado em célula 32x16 com offset X=8)
    # 8: 16x16 em (176, 96) - Silencer (centralizado em célula 32x16 com offset X=8)
    weapons_w = 8 * 32  # 256 px
    weapons_h = 16
    weapons_rgba = [(0, 0, 0, 0)] * (weapons_w * weapons_h)

    weapons_info = [
        (0, 96, 32, 16, 0),    # 1: Handgun
        (32, 96, 32, 16, 0),   # 2: SMG
        (64, 96, 32, 16, 0),   # 3: Grenade
        (96, 96, 32, 16, 0),   # 4: Rocket
        (128, 96, 16, 16, 8),  # 5: Plastic Bomb (offset X=8)
        (144, 96, 16, 16, 8),  # 6: Land Mine (offset X=8)
        (160, 96, 16, 16, 8),  # 7: Remote Missile (offset X=8)
        (176, 96, 16, 16, 8),  # 8: Silencer (offset X=8)
    ]

    for w_idx, (vx, vy, vw, vh, off_x) in enumerate(weapons_info):
        block = get_vram_block(vx, vy, vw, vh)
        cell_x = w_idx * 32
        for py in range(vh):
            for px in range(vw):
                color = block[py * vw + px]
                if color[3] > 0:
                    weapons_rgba[py * weapons_w + (cell_x + off_x + px)] = color

    weapons_path = os.path.join(OUT_DIR, "hud_weapons.png")
    write_png(weapons_path, weapons_w, weapons_h, weapons_rgba)
    print(f"Salvo: {weapons_path} ({weapons_w}x{weapons_h} px, 8 armas)")

    # 3. Extrair Itens: 28 itens de 16x16 px (448x16 px total)
    # ItemGfxXY (data/itemgfxxy.asm):
    # 1: (192, 96) Body Armor
    # 2: (208, 96) Bomb Blast Suit
    # 3: (224, 96) Flashlight
    # 4: (240, 96) Infrared Goggles
    # 5: (0, 112) Gas Mask
    # 6: (16, 112) Cigarettes
    # 7: (32, 112) Mine Detector
    # 8: (48, 112) Antenna
    # 9: (64, 112) Binoculars
    # 10: (80, 112) Oxygen Tank (Bombe)
    # 11: (96, 112) Compass
    # 12: (112, 112) Parachute
    # 13: (128, 112) Antidote
    # 14..21: (144, 112) Card Key (mesma arte para todos os cartões)
    # 22: (160, 112) Combat Ration
    # 23: (176, 112) Transceiver
    # 24: (192, 112) Enemy Uniform
    # 25: (208, 112) Cardboard Box
    # 26: (224, 112) Item Bag
    # 27: (240, 112) Ammo Crate
    items_coords = [
        (192, 96),   # 1: Armor
        (208, 96),   # 2: Suit
        (224, 96),   # 3: Light
        (240, 96),   # 4: Goggles
        (0, 112),    # 5: Gas Mask
        (16, 112),   # 6: Cigarettes
        (32, 112),   # 7: Mine Detector
        (48, 112),   # 8: Antenna
        (64, 112),   # 9: Binoculars
        (80, 112),   # 10: Oxygen Tank
        (96, 112),   # 11: Compass
        (112, 112),  # 12: Parachute
        (128, 112),  # 13: Antidote
        (144, 112),  # 14: Card 1
        (144, 112),  # 15: Card 2
        (144, 112),  # 16: Card 3
        (144, 112),  # 17: Card 4
        (144, 112),  # 18: Card 5
        (144, 112),  # 19: Card 6
        (144, 112),  # 20: Card 7
        (144, 112),  # 21: Card 8
        (160, 112),  # 22: Ration
        (176, 112),  # 23: Transceiver
        (192, 112),  # 24: Uniform
        (208, 112),  # 25: Cardboard Box
        (224, 112),  # 26: Item Bag
        (240, 112),  # 27: Ammo Crate
    ]

    items_w = len(items_coords) * 16
    items_h = 16
    items_rgba = [(0, 0, 0, 0)] * (items_w * items_h)

    for i_idx, (vx, vy) in enumerate(items_coords):
        block = get_vram_block(vx, vy, 16, 16)
        cell_x = i_idx * 16
        for py in range(16):
            for px in range(16):
                color = block[py * 16 + px]
                if color[3] > 0:
                    items_rgba[py * items_w + (cell_x + px)] = color

    items_path = os.path.join(OUT_DIR, "hud_items.png")
    write_png(items_path, items_w, items_h, items_rgba)
    print(f"Salvo: {items_path} ({items_w}x{items_h} px, {len(items_coords)} itens)")

    # 4. Extrair Sinal "CALL" de gfx/font.asm (gfxCALL: 6 tiles de 2bpp, 24x16 px)
    font_syms = parse_asm_symbols(os.path.join(EXT_DIR, "gfx", "font.asm"))
    gfx_call = font_syms.get("gfxCALL", [])
    print(f"gfxCALL: {len(gfx_call)} bytes ({len(gfx_call) // 16} tiles de 2bpp)")

    # colorsCALL (logic/loadfont.asm:57): db 6, 8, 0Eh, 0Fh
    colors_call = [6, 8, 0x0E, 0x0F]
    call_w, call_h = 24, 16
    call_rgba = [(0, 0, 0, 0)] * (call_w * call_h)

    for t in range(6):
        tile_bytes = gfx_call[t * 16:(t + 1) * 16]
        pixels = decode_2bpp_tile(tile_bytes, colors_call)
        tx = (t % 3) * 8
        ty = (t // 3) * 8
        for py in range(8):
            for px in range(8):
                c_idx = pixels[py * 8 + px]
                # Apenas as letras do sinal CALL usam cor 8 (Vermelho vivo no MSX2).
                # A cor 15 (e 0, 6, 0x0E) representam o fundo e permanecem transparentes.
                if c_idx == 8:
                    call_rgba[(ty + py) * call_w + (tx + px)] = palette[8]

    call_path = os.path.join(OUT_DIR, "hud_call.png")
    write_png(call_path, call_w, call_h, call_rgba)
    print(f"Salvo: {call_path} ({call_w}x{call_h} px)")

    # 5. Renderizar Mockup Canônico do HUD MSX2 (256x20 px)
    hud_w, hud_h = 256, 20
    hud_rgba = [(0, 0, 0, 255)] * (hud_w * hud_h)

    all_font = font_syms.get("gfxFont", []) + font_syms.get("gfxSymbChars", [])

    def draw_hud_rect(x: int, y: int, nw: int, nh: int, c: tuple) -> None:
        for px in range(nw):
            hud_rgba[y * hud_w + (x + px)] = c
            hud_rgba[(y + nh - 1) * hud_w + (x + px)] = c
        for py in range(nh):
            hud_rgba[(y + py) * hud_w + x] = c
            hud_rgba[(y + py) * hud_w + (x + nw - 1)] = c

    def fill_hud_rect(x: int, y: int, nw: int, nh: int, c: tuple) -> None:
        for py in range(nh):
            for px in range(nw):
                hud_rgba[(y + py) * hud_w + (x + px)] = c

    def draw_hud_char(ch: str, dx: int, dy: int, c: tuple = (255, 255, 255, 255)) -> int:
        o = ord(ch)
        t_idx = 0
        if ord("0") <= o <= ord("9"):
            t_idx = o - ord("0")
        elif ord("A") <= o <= ord("Z"):
            t_idx = 17 + (o - ord("A"))
        elif ch == "★" or o == 11:
            t_idx = 11
        elif ch == ".":
            t_idx = 44
        else:
            return 8
        tb = all_font[t_idx * 8:(t_idx + 1) * 8]
        for py in range(8):
            b = tb[py]
            for px in range(8):
                if (b >> (7 - px)) & 1:
                    hud_rgba[(dy + py) * hud_w + (dx + px)] = c
        return 8

    def draw_hud_str(s: str, dx: int, dy: int) -> None:
        cx = dx
        for ch in s:
            if ch == " ":
                cx += 8
                continue
            draw_hud_char(ch, cx, dy)
            cx += 8

    # 5.1 LIFE: "LIFE" em (16, 1), Caixa em (49, 1, 50, 8), Barra em (50, 2, 48, 6)
    draw_hud_str("LIFE", 16, 1)
    draw_hud_rect(49, 1, 50, 8, (255, 255, 255, 255))
    fill_hud_rect(50, 2, 48, 6, palette[8])

    # 5.2 CLASS: "CLASS" em (8, 9), 4 Estrelas em (52, 9)
    draw_hud_str("CLASS", 8, 9)
    for i in range(4):
        draw_hud_char("★", 52 + i * 8, 9, (255, 215, 0, 255))

    # 5.3 CALL: em (120, 1), 24x16 px
    for cy in range(16):
        for cx in range(24):
            pixel = call_rgba[cy * 24 + cx]
            if pixel[3] > 0:
                hud_rgba[(1 + cy) * hud_w + (120 + cx)] = pixel

    # 5.4 WEAPON BOX: Caixa em (159, 1, 58, 18), Handgun em (160, 2), " 50" em (192, 8)
    draw_hud_rect(159, 1, 58, 18, (255, 255, 255, 255))
    for wy in range(16):
        for wx in range(32):
            pixel = weapons_rgba[wy * weapons_w + wx]
            if pixel[3] > 0:
                hud_rgba[(2 + wy) * hud_w + (160 + wx)] = pixel
    draw_hud_str(" 50", 192, 8)

    # 5.5 ITEM BOX: Caixa em (222, 1, 27, 18), Card 1 em (224, 2), "1" em (240, 8)
    draw_hud_rect(222, 1, 27, 18, (255, 255, 255, 255))
    card_offset_x = 13 * 16  # Card 1 é o 14º item (índice 13)
    for iy in range(16):
        for ix in range(16):
            pixel = items_rgba[iy * items_w + (card_offset_x + ix)]
            if pixel[3] > 0:
                hud_rgba[(2 + iy) * hud_w + (224 + ix)] = pixel
    draw_hud_char("1", 240, 8)

    mockup_path = os.path.join(OUT_DIR, "hud_mockup.png")
    write_png(mockup_path, hud_w, hud_h, hud_rgba)
    print(f"Salvo: {mockup_path} ({hud_w}x{hud_h} px)")
    print("=== Extração de Gráficos do HUD concluída com sucesso! ===")


if __name__ == "__main__":
    extract_hud_assets()
