"""
tests/test_shoot_gunner_sprite_extractor.py

Testes unitários com dados sintéticos próprios para o extrator de sprites do Boss Shoot Gunner
e tiros de escopeta do Metal Gear MSX2.
Valida a descompressão RLE, composição modular 16x32 com Color Compare do hardware MSX2,
decodificação de padrões monocromáticos 16x16 e escrita de PNGs RGBA 32-bit (64x64 px e 128x32 px).
"""

import os
import struct
import tempfile
import unittest

from tools.extractors.extract_shoot_gunner_sprites import (
    decompress_rle,
    composite_shotgunner_frame,
    composite_16x16_monochrome,
    get_pattern,
    write_png,
    extract_shoot_gunner_sprites,
    PALETTE_SHOOT_GUNNER,
)

class ShootGunnerSpriteExtractorTests(unittest.TestCase):
    def test_decompress_rle(self):
        """Valida rotina RLE do Z80 com dados sintéticos."""
        # Sintético: 2 literais [11, 22], repetição 4x de [55], fim [0x00]
        data = [0x82, 11, 22, 0x04, 55, 0x00]
        res = decompress_rle(data)
        self.assertEqual(res, [11, 22, 55, 55, 55, 55])

    def test_composite_shotgunner_frame(self):
        """Valida composição modular 16x32 e Color Compare de hardware (2 | 13 = 15)."""
        # 16 padrões de 16x16 (512 bytes sintéticos)
        unpacked = [0] * 512

        # Padrões 0x60 (idx 0), 0x64 (idx 1), 0x68 (idx 2), 0x6C (idx 3)
        # Linha 0 de 0x60 (t0): 0b11000000
        # Linha 0 de 0x64 (t1): 0b10100000
        unpacked[0] = 0b11000000
        unpacked[32] = 0b10100000

        frame = composite_shotgunner_frame(
            unpacked,
            0x60, 0x64, 0x68, 0x6C,
            PALETTE_SHOOT_GUNNER
        )

        self.assertEqual(len(frame), 32)
        self.assertEqual(len(frame[0]), 16)

        # Pixel 0: bit0=1, bit1=1 -> Color Compare (Cor 15 - Preto)
        self.assertEqual(frame[0][0], PALETTE_SHOOT_GUNNER[15])
        # Pixel 1: bit0=1, bit1=0 -> Cor 2 (Azul militar escuro)
        self.assertEqual(frame[0][1], PALETTE_SHOOT_GUNNER[2])
        # Pixel 2: bit0=0, bit1=1 -> Cor 13 (Cáqui / Pele)
        self.assertEqual(frame[0][2], PALETTE_SHOOT_GUNNER[13])
        # Pixel 3: bit0=0, bit1=0 -> Transparente
        self.assertEqual(frame[0][3], (0, 0, 0, 0))

    def test_composite_16x16_monochrome(self):
        """Valida decodificação de padrão monocromático 16x16 para tiros."""
        pattern_bytes = [0] * 32
        pattern_bytes[0] = 0b10000001
        pattern_bytes[16] = 0b01000010

        grid = composite_16x16_monochrome(pattern_bytes, 14, PALETTE_SHOOT_GUNNER)
        self.assertEqual(len(grid), 16)
        self.assertEqual(len(grid[0]), 16)

        # Linha 0: bit 0 e 7 na coluna esquerda (x=0, x=7)
        self.assertEqual(grid[0][0], PALETTE_SHOOT_GUNNER[14])
        self.assertEqual(grid[0][7], PALETTE_SHOOT_GUNNER[14])
        self.assertEqual(grid[0][1], (0, 0, 0, 0))

        # Coluna direita: bit 1 e 6 (x=8+1=9, x=8+6=14)
        self.assertEqual(grid[0][9], PALETTE_SHOOT_GUNNER[14])
        self.assertEqual(grid[0][14], PALETTE_SHOOT_GUNNER[14])
        self.assertEqual(grid[0][8], (0, 0, 0, 0))

    def test_write_png(self):
        """Valida geração de arquivo PNG com cabeçalho IHDR RGBA 32-bit correto."""
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
            temp_path = f.name

        try:
            w, h = 64, 64
            fake_rgba = [(255, 0, 0, 255)] * (w * h)
            write_png(temp_path, w, h, fake_rgba)

            with open(temp_path, "rb") as f:
                header = f.read(32)

            # Assinatura PNG
            self.assertEqual(header[:8], b"\x89PNG\r\n\x1a\n")
            # Chunk IHDR (tamanho 13, tipo IHDR)
            chunk_len, chunk_type = struct.unpack(">I4s", header[8:16])
            self.assertEqual(chunk_len, 13)
            self.assertEqual(chunk_type, b"IHDR")
            # Dimensões e formato
            width, height, bit_depth, color_type = struct.unpack(">IIBB", header[16:26])
            self.assertEqual(width, 64)
            self.assertEqual(height, 64)
            self.assertEqual(bit_depth, 8)
            self.assertEqual(color_type, 6)  # RGBA
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

    def test_extract_shoot_gunner_sprites_synthetic(self):
        """Valida o fluxo completo de extração com arquivo ASM sintético."""
        with tempfile.TemporaryDirectory() as tmpdir:
            asm_path = os.path.join(tmpdir, "sprites_synth.asm")
            boss_png = os.path.join(tmpdir, "boss_synth.png")
            bullet_png = os.path.join(tmpdir, "bullet_synth.png")

            # Cria arquivo sintético: SprShotGunner (512 bytes) e SprSGunnerShot (224 bytes)
            with open(asm_path, "w", encoding="utf-8") as f:
                # SprShotGunner: 4 blocos de 127 bytes + 1 de 4 bytes = 512 bytes
                f.write("SprShotGunner:\n")
                f.write("  db 7Fh, 1, 7Fh, 2, 7Fh, 3, 7Fh, 4, 04h, 5, 0\n\n")

                # SprSGunnerShot: 1 bloco de 127 bytes + 1 bloco de 97 bytes = 224 bytes
                f.write("SprSGunnerShot:\n")
                f.write("  db 7Fh, 10, 61h, 20, 0\n")

            extract_shoot_gunner_sprites(asm_path, boss_png, bullet_png)

            self.assertTrue(os.path.exists(boss_png))
            self.assertTrue(os.path.exists(bullet_png))

            # Verifica dimensões do boss PNG (64x64)
            with open(boss_png, "rb") as f:
                f.seek(16)
                bw, bh = struct.unpack(">II", f.read(8))
                self.assertEqual((bw, bh), (64, 64))

            # Verifica dimensões do bullet PNG (128x32)
            with open(bullet_png, "rb") as f:
                f.seek(16)
                sw, sh = struct.unpack(">II", f.read(8))
                self.assertEqual((sw, sh), (128, 32))

if __name__ == "__main__":
    unittest.main()
