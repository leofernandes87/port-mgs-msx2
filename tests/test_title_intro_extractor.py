"""
tests/test_title_intro_extractor.py

Testes unitários com fixtures sintéticas próprias para o extrator de telas
e sprites de abertura do Metal Gear MSX2 (Logo Konami, Logo Metal Gear e Fontes).
"""

import os
import struct
import tempfile
import unittest

from tools.extractors.extract_title_intro_sprites import (
    parse_asm_symbols,
    to_rgb,
    render_text_image,
    draw_char_on_grid,
    write_png,
)


class TitleIntroExtractorTests(unittest.TestCase):
    def test_to_rgb_conversion(self):
        # 0 -> 0
        r, g, b, a = to_rgb(0, 0, 0)
        self.assertEqual((r, g, b, a), (0, 0, 0, 255))

        # 7 -> 255
        r, g, b, a = to_rgb(7, 7, 7)
        self.assertEqual((r, g, b, a), (255, 255, 255, 255))

        # Meio tom: 3 -> 3 * 255 // 7 = 109
        r, g, b, a = to_rgb(3, 0, 7)
        self.assertEqual(r, 109)
        self.assertEqual(g, 0)
        self.assertEqual(b, 255)

    def test_parse_asm_symbols_synthetic(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            test_asm = os.path.join(tmpdir, "test.asm")
            with open(test_asm, "w", encoding="utf-8") as f:
                f.write(
                    "; Test comment\n"
                    "LabelOne: db 1, 2, 3, 0Ah, -8\n"
                    'LabelTwo: db "TEST", 0, 0FFh\n'
                )
            syms = parse_asm_symbols(test_asm)
            self.assertIn("LabelOne", syms)
            self.assertEqual(syms["LabelOne"], [1, 2, 3, 10, 0xF8])
            self.assertIn("LabelTwo", syms)
            self.assertEqual(syms["LabelTwo"], [ord("T"), ord("E"), ord("S"), ord("T"), 0, 0xFF])

    def test_draw_char_on_grid(self):
        # Cria uma fonte sintética com 1 tile para o caractere 'A' (ASCII 65, índice 65 - 0x30 = 17)
        # Tile 8x8 preenchido com 1
        font_tiles = {
            17: [[1] * 8 for _ in range(8)]
        }
        grid = [[0] * 16 for _ in range(8)]
        draw_char_on_grid(grid, font_tiles, ord("A"), 0, 0)

        # Primeiro bloco 8x8 deve ser 1
        for y in range(8):
            for x in range(8):
                self.assertEqual(grid[y][x], 1)
            # Segundo bloco 8x8 deve permanecer 0
            for x in range(8, 16):
                self.assertEqual(grid[y][x], 0)

    def test_render_text_image(self):
        font_tiles = {
            ord("X") - 0x30: [[1] * 8 for _ in range(8)]
        }
        w, h, rgba = render_text_image(font_tiles, "X")
        self.assertEqual(w, 8)
        self.assertEqual(h, 8)
        self.assertEqual(len(rgba), 64)
        # Todos os pixels devem ser brancos opacos
        for p in rgba:
            self.assertEqual(p, (255, 255, 255, 255))

    def test_write_png(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            out_png = os.path.join(tmpdir, "test.png")
            # 2x2 pixels RGBA
            pixels = [
                (255, 0, 0, 255), (0, 255, 0, 255),
                (0, 0, 255, 255), (255, 255, 255, 255)
            ]
            write_png(out_png, 2, 2, pixels)
            self.assertTrue(os.path.exists(out_png))

            # Valida header PNG
            with open(out_png, "rb") as f:
                header = f.read(8)
                self.assertEqual(header, b"\x89PNG\r\n\x1a\n")
                # Chunk IHDR
                ihdr_len = struct.unpack(">I", f.read(4))[0]
                ihdr_type = f.read(4)
                self.assertEqual(ihdr_type, b"IHDR")
                w, h = struct.unpack(">II", f.read(8))
                self.assertEqual((w, h), (2, 2))


if __name__ == "__main__":
    unittest.main()
