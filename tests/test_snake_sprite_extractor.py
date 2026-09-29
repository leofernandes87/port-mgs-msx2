"""
tests/test_snake_sprite_extractor.py

Testes unitários com dados sintéticos próprios para o extrator de sprites de Solid Snake.
Valida o descompressor RLE (SetSnakeSprPatt), a decodificação dos 4 planos VDP V9938 com Color Compare
e a geração de arquivos PNG 32-bit RGBA.
"""

import os
import struct
import tempfile
import unittest
import zlib

from tools.extractors.extract_snake_sprites import (
    decompress_rle,
    decode_frame_to_pixels,
    decode_shadow_to_pixels,
    decode_water_to_pixels,
    write_png,
    PALETTE,
    WATER_SHADOW_PALETTE
)

class SnakeSpriteExtractorTests(unittest.TestCase):
    def test_decompress_rle_literal_and_repeat(self):
        # Sintético: 0x83 (3 bytes literais: 1, 2, 3), 0x04 (repete 4 vezes o byte 0xAA), 0x00 (fim)
        compressed = [0x83, 1, 2, 3, 0x04, 0xAA, 0x00]
        unpacked = decompress_rle(compressed)
        self.assertEqual(unpacked, [1, 2, 3, 0xAA, 0xAA, 0xAA, 0xAA])

    def test_decompress_rle_end_marker_80(self):
        # 0x80 deve encerrar a leitura imediatamente
        compressed = [0x82, 0x10, 0x20, 0x80, 0x05, 0x99]
        unpacked = decompress_rle(compressed)
        self.assertEqual(unpacked, [0x10, 0x20])

    def test_decode_frame_to_pixels_color_compare(self):
        # Cria 128 bytes sintéticos
        # Plano 0 (bytes 0..31): Torso A
        # Plano 1 (bytes 32..63): Torso B
        # Testar linha 0:
        # lb0 = 0b11000000, rb0 = 0
        # lb1 = 0b10100000, rb1 = 0
        raw = [0] * 128
        raw[0] = 0b11000000 # p0 linha 0 esquerda
        raw[32] = 0b10100000 # p1 linha 0 esquerda

        grid = decode_frame_to_pixels(raw)
        self.assertEqual(len(grid), 32)
        self.assertEqual(len(grid[0]), 16)

        # Pixel 0: b0=1, b1=1 -> Color Compare (Cor 15 - Preto)
        self.assertEqual(grid[0][0], PALETTE[15])
        # Pixel 1: b0=1, b1=0 -> Cor 7 (Uniforme azul)
        self.assertEqual(grid[0][1], PALETTE[7])
        # Pixel 2: b0=0, b1=1 -> Cor 10 (Pele bege)
        self.assertEqual(grid[0][2], PALETTE[10])
        # Pixel 3: b0=0, b1=0 -> Cor 0 (Transparente)
        self.assertEqual(grid[0][3], PALETTE[0])

    def test_decode_shadow_to_pixels(self):
        # Cria 64 bytes sintéticos para sombra subaquática
        raw = [0] * 64
        raw[0] = 0b11000000  # p0
        raw[32] = 0b10100000 # p1
        grid = decode_shadow_to_pixels(raw)
        self.assertEqual(len(grid), 32)
        self.assertEqual(len(grid[0]), 16)
        # Pixel 0: b0=1, b1=1 -> Cor 16 (Color Compare)
        self.assertEqual(grid[0][0], WATER_SHADOW_PALETTE[16])
        # Pixel 1: b0=1, b1=0 -> Cor 14 (Ondulação ciano)
        self.assertEqual(grid[0][1], WATER_SHADOW_PALETTE[14])
        # Pixel 2: b0=0, b1=1 -> Cor 15 (Silhueta escura)
        self.assertEqual(grid[0][2], WATER_SHADOW_PALETTE[15])
        # Linha inferior (16..31) deve ser transparente
        self.assertEqual(grid[20][0], (0, 0, 0, 0))

    def test_decode_water_to_pixels(self):
        # Cria 64 bytes sintéticos para Snake nadando na superfície
        raw = [0] * 64
        raw[0] = 0b11000000
        raw[32] = 0b10100000
        grid = decode_water_to_pixels(raw)
        self.assertEqual(len(grid), 32)
        self.assertEqual(len(grid[0]), 16)
        self.assertEqual(grid[0][0], PALETTE[15])
        self.assertEqual(grid[0][1], PALETTE[7])
        self.assertEqual(grid[0][2], PALETTE[10])
        self.assertEqual(grid[20][0], (0, 0, 0, 0))

    def test_write_png_format(self):
        # Teste de geração e leitura de cabeçalho PNG
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
            tmp_path = tmp.name

        try:
            rgba = [(255, 0, 0, 255), (0, 255, 0, 255), (0, 0, 255, 255), (0, 0, 0, 0)]
            write_png(tmp_path, 2, 2, rgba)

            with open(tmp_path, "rb") as f:
                header = f.read(8)
                self.assertEqual(header, b"\x89PNG\r\n\x1a\n")
                ihdr_len = struct.unpack(">I", f.read(4))[0]
                self.assertEqual(ihdr_len, 13)
                self.assertEqual(f.read(4), b"IHDR")
                w, h = struct.unpack(">II", f.read(8))
                self.assertEqual(w, 2)
                self.assertEqual(h, 2)
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

if __name__ == "__main__":
    unittest.main()
