"""
tests/test_door_sprite_extractor.py

Testes unitários com fixtures sintéticas próprias para o extrator de sprites de portas MSX2.
Valida decodificação 4bpp de tiles, montagem do spritesheet com projeção em perspectiva
(shearing de portas Oeste/Leste), cálculo da paleta canônica e escrita de arquivos PNG.
"""

import os
import struct
import tempfile
import unittest

from tools.extractors.extract_door_sprites import (
    decode_tile_block,
    get_canonical_palette,
    assemble_door_sheet,
    write_png
)

class DoorSpriteExtractorTests(unittest.TestCase):
    def test_decode_tile_block(self):
        # 1 tile 8x8 = 32 bytes (8 linhas x 4 bytes)
        # Linha 0: 0x12, 0x34, 0x56, 0x78 -> nibbles [1, 2, 3, 4, 5, 6, 7, 8]
        synthetic_bytes = [0] * 32
        synthetic_bytes[0] = 0x12
        synthetic_bytes[1] = 0x34
        synthetic_bytes[2] = 0x56
        synthetic_bytes[3] = 0x78

        grid = decode_tile_block(synthetic_bytes, 1, 1)
        self.assertEqual(len(grid), 8)
        self.assertEqual(len(grid[0]), 8)
        self.assertEqual(grid[0], [1, 2, 3, 4, 5, 6, 7, 8])
        # Linhas subsequentes zeradas
        self.assertEqual(grid[1], [0, 0, 0, 0, 0, 0, 0, 0])

    def test_canonical_palette(self):
        palette = get_canonical_palette()
        self.assertEqual(len(palette), 16)
        # Cada cor deve ser uma tupla de 3 componentes RGB no intervalo [0, 255]
        for c in palette:
            self.assertEqual(len(c), 3)
            for ch in c:
                self.assertTrue(0 <= ch <= 255)

    def test_assemble_door_sheet(self):
        # Cria dados sintéticos para os 5 tipos de portas
        # Front: 4x4 tiles = 16 * 32 = 512 bytes
        # Elevator: 4x4 tiles = 512 bytes
        # Down: 4x1 tiles = 128 bytes
        # Left: 1x4 tiles = 128 bytes
        # Right: 1x4 tiles = 128 bytes
        doors_raw = {
            "GfxDoorFront": [0x11] * 512,
            "GfxDoorElevator": [0x22] * 512,
            "GfxDoorDown": [0x33] * 128,
            "GfxDoorLeft": [0x44] * 128,
            "GfxDoorRight": [0x55] * 128,
        }
        palette = get_canonical_palette()
        w, h, rgba = assemble_door_sheet(doors_raw, palette)

        self.assertEqual(w, 128)
        self.assertEqual(h, 64)
        self.assertEqual(len(rgba), 128 * 64)

        # Verificar North Door central (24x32) em (0, 0): deve ter alpha = 255
        pixel_north = rgba[0 * 128 + 0]
        self.assertEqual(pixel_north[3], 255)

        # Verificar West Door sheared em (80, 0):
        # Na coluna x=0: dy = 0, y=0..31 preenchido (alpha=255), y=32..59 vazio (alpha=0)
        pixel_w0_top = rgba[0 * 128 + 80]
        self.assertEqual(pixel_w0_top[3], 255)
        pixel_w0_bot = rgba[35 * 128 + 80]
        self.assertEqual(pixel_w0_bot[3], 0)

        # Na coluna x=7: dy = 28, y=0..27 vazio (alpha=0), y=28..59 preenchido (alpha=255)
        pixel_w7_top = rgba[10 * 128 + (80 + 7)]
        self.assertEqual(pixel_w7_top[3], 0)
        pixel_w7_bot = rgba[40 * 128 + (80 + 7)]
        self.assertEqual(pixel_w7_bot[3], 255)

    def test_write_png(self):
        # Grava imagem sintética 2x2 px
        data = [
            (255, 0, 0, 255), (0, 255, 0, 255),
            (0, 0, 255, 255), (255, 255, 255, 255)
        ]
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
            temp_path = f.name

        try:
            write_png(temp_path, 2, 2, data)
            self.assertTrue(os.path.exists(temp_path))
            with open(temp_path, "rb") as f:
                header = f.read(8)
                self.assertEqual(header, b"\x89PNG\r\n\x1a\n")
                # Lê chunk IHDR
                ihdr_len = struct.unpack(">I", f.read(4))[0]
                ihdr_type = f.read(4)
                self.assertEqual(ihdr_type, b"IHDR")
                width, height, bit_depth, color_type = struct.unpack(">IIBB", f.read(10))
                self.assertEqual(width, 2)
                self.assertEqual(height, 2)
                self.assertEqual(bit_depth, 8)
                self.assertEqual(color_type, 6) # RGBA
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

if __name__ == "__main__":
    unittest.main()
