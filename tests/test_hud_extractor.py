#!/usr/bin/env python3
"""
tests/test_hud_extractor.py

Testes unitários automatizados para o extrator dos gráficos do HUD MSX2.
Valida decodificação 3bpp, 2bpp, paleta de cores, dimensões e geração de PNG com fixtures sintéticas.
"""

import os
import tempfile
import unittest

from tools.extractors.extract_hud_assets import (
    MSX2_PALETTE,
    COLORS_ITEMS,
    CALL_COLORS,
    decode_3bpp_tile,
    decode_2bpp_tile,
    write_png,
    WEAPONS_INFO,
    ITEMS_INFO,
)


class TestHUDExtractor(unittest.TestCase):
    def test_msx2_palette_entries(self):
        self.assertEqual(len(MSX2_PALETTE), 16)
        # Cor 0 é preto VDP (0, 0, 0, 255)
        self.assertEqual(MSX2_PALETTE[0], (0, 0, 0, 255))
        # Cor 15 é preto puro no menu de armas/itens (PalMenuWeapon: db 0Fh, 0, 0)
        self.assertEqual(MSX2_PALETTE[15], (0, 0, 0, 255))
        # Cor 14 é branco puro (PalMenuWeapon: db 0Eh, 77h, 7)
        self.assertEqual(MSX2_PALETTE[14], (255, 255, 255, 255))
        # Cor 6 é amarelo ouro vivo (PalMenuWeapon: db 6, 70h, 7)
        self.assertEqual(MSX2_PALETTE[6], (255, 255, 0, 255))
        # Cor 8 é vermelho vivo (PalMenuWeapon: db 8, 70h, 0)
        self.assertEqual(MSX2_PALETTE[8], (255, 0, 0, 255))

    def test_colors_items_table(self):
        # ColorsItems em Banks0123.asm:2999: 0, 6, 7, 8, 0x0A, 0x0C, 0x0E, 0x0F
        expected = [0, 6, 7, 8, 0x0A, 0x0C, 0x0E, 0x0F]
        self.assertEqual(COLORS_ITEMS, expected)

    def test_call_colors(self):
        # 2bpp para gfxCALL usa cores 6, 8, 0x0E, 0x0F
        self.assertEqual(CALL_COLORS, [6, 8, 0x0E, 0x0F])

    def test_decode_3bpp_tile_synthetic(self):
        # 1 linha sintética de 8 pixels:
        # bit0 = 0b10101010, bit1 = 0b11001100, bit2 = 0b11110000
        # px0: b0=1, b1=1, b2=1 -> color_idx = 7 -> cor ColorsItems[7] = 0x0F
        # px7: b0=0, b1=0, b2=0 -> color_idx = 0 -> cor ColorsItems[0] = 0
        b0 = 0b10101010
        b1 = 0b11001100
        b2 = 0b11110000
        tile_bytes = [b0, b1, b2] * 8

        pixels = decode_3bpp_tile(tile_bytes, COLORS_ITEMS)
        self.assertEqual(len(pixels), 64)

        # Esperado para px 0..7:
        # px0: 1+2+4=7 -> COLORS_ITEMS[7] = 0x0F (15)
        # px1: 0+2+4=6 -> COLORS_ITEMS[6] = 0x0E (14)
        # px2: 1+0+4=5 -> COLORS_ITEMS[5] = 0x0C (12)
        # px3: 0+0+4=4 -> COLORS_ITEMS[4] = 0x0A (10)
        # px4: 1+2+0=3 -> COLORS_ITEMS[3] = 8
        # px5: 0+2+0=2 -> COLORS_ITEMS[2] = 7
        # px6: 1+0+0=1 -> COLORS_ITEMS[1] = 6
        # px7: 0+0+0=0 -> COLORS_ITEMS[0] = 0
        expected_row = [15, 14, 12, 10, 8, 7, 6, 0]
        self.assertEqual(pixels[:8], expected_row)

    def test_decode_2bpp_tile_synthetic(self):
        # gfxCALL usa 2bpp: bit0 e bit1
        # b0 = 0b10101010, b1 = 0b11001100
        # px0: b0=1, b1=1 -> 3 -> CALL_COLORS[3] = 0x0F
        # px1: b0=0, b1=1 -> 2 -> CALL_COLORS[2] = 0x0E
        # px2: b0=1, b1=0 -> 1 -> CALL_COLORS[1] = 8
        # px3: b0=0, b1=0 -> 0 -> CALL_COLORS[0] = 6
        b0 = 0b10101010
        b1 = 0b11001100
        tile_bytes = [b0, b1] * 8

        pixels = decode_2bpp_tile(tile_bytes, CALL_COLORS)
        self.assertEqual(len(pixels), 64)
        expected_row = [0x0F, 0x0E, 8, 6, 0x0F, 0x0E, 8, 6]
        self.assertEqual(pixels[:8], expected_row)

    def test_weapons_and_items_definitions(self):
        # 8 armas canônicas
        self.assertEqual(len(WEAPONS_INFO), 8)
        self.assertEqual(WEAPONS_INFO[0]["name"], "HANDGUN")
        self.assertEqual(WEAPONS_INFO[0]["vw"], 32)
        self.assertEqual(WEAPONS_INFO[4]["name"], "PLASTIC_BOMB")
        self.assertEqual(WEAPONS_INFO[4]["vw"], 16)

        # 27 itens canônicos
        self.assertEqual(len(ITEMS_INFO), 27)
        self.assertEqual(ITEMS_INFO[0]["name"], "ARMOR")
        self.assertEqual(ITEMS_INFO[13]["name"], "CARD_1")
        self.assertEqual(ITEMS_INFO[21]["name"], "RATION")
        self.assertEqual(ITEMS_INFO[24]["name"], "CARDBOARD_BOX")

    def test_write_png_synthetic(self):
        # Valida escrita de PNG sintético de 2x2 pixels
        pixels = [
            (255, 0, 0, 255), (0, 255, 0, 255),
            (0, 0, 255, 255), (255, 255, 255, 255)
        ]
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
            temp_path = f.name
        try:
            write_png(temp_path, 2, 2, pixels)
            self.assertTrue(os.path.exists(temp_path))
            with open(temp_path, "rb") as f:
                header = f.read(8)
                # Assinatura PNG: \x89PNG\r\n\x1a\n
                self.assertEqual(header, b"\x89PNG\r\n\x1a\n")
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)


if __name__ == "__main__":
    unittest.main()
