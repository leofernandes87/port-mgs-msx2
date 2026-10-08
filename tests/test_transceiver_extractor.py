#!/usr/bin/env python3
"""
tests/test_transceiver_extractor.py

Testes unitários automatizados para o extrator dos gráficos do transceptor MSX2.
Valida decodificação 3bpp, paleta de cores, dimensões e geração de PNG com fixtures sintéticas.
"""

import os
import unittest

from tools.extractors.extract_transceiver_sprites import (
    decode_1bpp_tile,
    decode_3bpp_tile,
    get_radio_palette,
    write_png,
)


class TestTransceiverExtractor(unittest.TestCase):
    def test_radio_palette_entries(self):
        palette = get_radio_palette()
        self.assertEqual(len(palette), 16)
        # Cor 15 deve ser preto (0, 0, 0, 255)
        self.assertEqual(palette[15], (0, 0, 0, 255))
        # Cor 14 deve ser branco (255, 255, 255, 255)
        self.assertEqual(palette[14], (255, 255, 255, 255))
        # Cor 8 deve ser vermelho vivo (#ff2424 -> 255, 36, 36, 255)
        self.assertEqual(palette[8], (255, 36, 36, 255))
        # Cor 3 deve ser verde brilhante de LED (182, 255, 182, 255)
        self.assertEqual(palette[3], (182, 255, 182, 255))

    def test_decode_3bpp_tile_synthetic(self):
        # 1 linha sintética de 8 pixels:
        # C = 0b10101010, D = 0b11001100, E = 0b11110000
        # Pixel 0: C=1, D=1, E=1 -> idx 7
        # Pixel 1: C=0, D=1, E=1 -> idx 3
        # Pixel 2: C=1, D=0, E=1 -> idx 5
        # Pixel 3: C=0, D=0, E=1 -> idx 1
        # Pixel 4: C=1, D=1, E=0 -> idx 6
        # Pixel 5: C=0, D=1, E=0 -> idx 2
        # Pixel 6: C=1, D=0, E=0 -> idx 4
        # Pixel 7: C=0, D=0, E=0 -> idx 0
        c = 0b10101010
        d = 0b11001100
        e = 0b11110000
        tile_bytes = [e, d, c] * 8

        color_table = [0, 1, 2, 3, 4, 5, 6, 7]
        pixels = decode_3bpp_tile(tile_bytes, color_table, flip_h=False)
        self.assertEqual(len(pixels), 64)
        expected_line = [7, 3, 5, 1, 6, 2, 4, 0]
        self.assertEqual(pixels[:8], expected_line)

        # Teste com flip horizontal
        pixels_flipped = decode_3bpp_tile(tile_bytes, color_table, flip_h=True)
        self.assertEqual(pixels_flipped[:8], list(reversed(expected_line)))

    def test_decode_1bpp_tile_synthetic(self):
        # Linha 0: 0b10000001 -> pixel 0 e 7 foreground, resto background
        tile_bytes = [0b10000001] * 8
        pixels = decode_1bpp_tile(tile_bytes, fg_color=8, bg_color=-1)
        self.assertEqual(len(pixels), 64)
        expected = [8, -1, -1, -1, -1, -1, -1, 8]
        self.assertEqual(pixels[:8], expected)

    def test_png_generation_synthetic(self):
        test_out = "/tmp/test_transceiver_synth.png"
        w, h = 8, 8
        rgba_data = [(255, 0, 0, 255)] * 64
        write_png(test_out, w, h, rgba_data)
        self.assertTrue(os.path.exists(test_out))
        self.assertGreater(os.path.getsize(test_out), 30)
        os.remove(test_out)

    def test_generate_msx_font_synthetic(self):
        from tools.extractors.extract_transceiver_sprites import generate_msx_font
        synth_syms = {
            "gfxFont": [0xFF] * (11 * 8),
            "gfxSymbChars": [0xAA] * (101 * 8),
        }
        test_out = "/tmp/test_msx_font_synth.png"
        generate_msx_font(synth_syms, test_out)
        self.assertTrue(os.path.exists(test_out))
        self.assertGreater(os.path.getsize(test_out), 100)
        os.remove(test_out)


if __name__ == "__main__":
    unittest.main()
