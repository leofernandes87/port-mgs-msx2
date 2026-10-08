"""
tests/test_enemy_sprite_extractor.py

Testes unitários com dados sintéticos próprios para o extrator de sprites de Inimigos (Guardas e Cães).
Valida a descompressão RLE, composição modular de torso e pernas de guardas, composição multi-quadro
de cães e escrita de PNGs RGBA 32-bit.
"""

import os
import struct
import tempfile
import unittest

from tools.extractors.extract_enemy_sprites import (
    decompress_rle,
    composite_guard_frame,
    composite_dog_cell,
    generate_guard_spritesheet,
    generate_dog_spritesheet,
    write_png,
    PALETTE_GUARD,
    PALETTE_DOG
)

class EnemySpriteExtractorTests(unittest.TestCase):
    def test_decompress_rle(self):
        # Dados sintéticos: 2 literais [10, 20], repetição de 3x [99], fim [0]
        data = [0x82, 10, 20, 0x03, 99, 0x00]
        res = decompress_rle(data)
        self.assertEqual(res, [10, 20, 99, 99, 99])

    def test_composite_guard_frame(self):
        # Cria um buffer sintético para SprGuard com pelo menos 64 padrões (2048 bytes)
        unpacked_guard = [0] * 2048
        
        # Padrão 0x60 (Tronco A): idx 0
        # Padrão 0x64 (Tronco B): idx 1
        # Padrão 0x80 (Pernas A): idx 8
        # Padrão 0x84 (Pernas B): idx 9
        idx_ta = (0x60 - 0x60) // 4 # 0
        idx_tb = (0x64 - 0x60) // 4 # 1
        idx_la = (0x80 - 0x60) // 4 # 8
        idx_lb = (0x84 - 0x60) // 4 # 9
        
        # Na linha 0 do tronco:
        # Ta: 0b11000000
        # Tb: 0b10100000
        unpacked_guard[idx_ta * 32] = 0b11000000
        unpacked_guard[idx_tb * 32] = 0b10100000
        
        frame = composite_guard_frame(unpacked_guard, 0x60, 0x64, 0x80, 0x84, 0)
        self.assertEqual(len(frame), 32)
        self.assertEqual(len(frame[0]), 16)
        
        # Pixel 0: b0=1, b1=1 -> Color Compare (Cor 15 - Preto)
        self.assertEqual(frame[0][0], PALETTE_GUARD[15])
        # Pixel 1: b0=1, b1=0 -> Cor 2 (Farda azul militar)
        self.assertEqual(frame[0][1], PALETTE_GUARD[2])
        # Pixel 2: b0=0, b1=1 -> Cor 13 (Pele bege)
        self.assertEqual(frame[0][2], PALETTE_GUARD[13])
        # Pixel 3: b0=0, b1=0 -> Transparente
        self.assertEqual(frame[0][3], PALETTE_GUARD[0])

    def test_composite_dog_cell(self):
        # Buffer sintético para SprDog
        unpacked_dog = [0] * 2048
        
        # DogLying: 0xE0 (detail), 0xE4 (body)
        idx_det = (0xE0 - 0x60) // 4
        idx_bod = (0xE4 - 0x60) // 4
        
        # Linha 0:
        # Detail tem 0b10000000 (pixel 0)
        # Body tem 0b11000000 (pixel 0 e 1)
        unpacked_dog[idx_det * 32] = 0b10000000
        unpacked_dog[idx_bod * 32] = 0b11000000
        
        cell = composite_dog_cell(unpacked_dog, "16x16", (0xE0, 0xE4))
        self.assertEqual(len(cell), 32)
        self.assertEqual(len(cell[0]), 32)
        
        # Posição centralizada: Y=8..23, X=8..23
        # No pixel (x=8, y=8): detail=1 -> PALETTE_DOG["tan"]
        self.assertEqual(cell[8][8], PALETTE_DOG["tan"])
        # No pixel (x=9, y=8): detail=0, body=1 -> PALETTE_DOG["black"]
        self.assertEqual(cell[8][9], PALETTE_DOG["black"])
        # No pixel fora (x=0, y=0): transparente
        self.assertEqual(cell[0][0], PALETTE_DOG[0])

    def test_generate_guard_spritesheet_format(self):
        unpacked_guard = [0] * 2048
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
            tmp_path = tmp.name
        try:
            generate_guard_spritesheet(unpacked_guard, tmp_path)
            with open(tmp_path, "rb") as f:
                f.seek(16)
                w, h = struct.unpack(">II", f.read(8))
                self.assertEqual(w, 64)
                self.assertEqual(h, 128)
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    def test_generate_dog_spritesheet_format(self):
        unpacked_dog = [0] * 2048
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
            tmp_path = tmp.name
        try:
            generate_dog_spritesheet(unpacked_dog, tmp_path)
            with open(tmp_path, "rb") as f:
                f.seek(16)
                w, h = struct.unpack(">II", f.read(8))
                self.assertEqual(w, 128)
                self.assertEqual(h, 96)
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

if __name__ == "__main__":
    unittest.main()
