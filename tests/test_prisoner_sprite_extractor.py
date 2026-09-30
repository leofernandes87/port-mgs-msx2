"""
tests/test_prisoner_sprite_extractor.py

Testes unitários com dados sintéticos próprios para o extrator de sprites de Reféns e Prisioneiros.
Valida a descompressão RLE, composição modular de 16x32 com Color Compare do hardware MSX2
e escrita de PNGs RGBA 32-bit (48x128 px).
"""

import os
import struct
import tempfile
import unittest

from tools.extractors.extract_prisoner_sprites import (
    decompress_rle,
    composite_prisoner_frame,
    get_pattern,
    write_png,
    extract_all_prisoners,
    PALETTE_PRISONER,
    PALETTE_ELLEN
)

class PrisonerSpriteExtractorTests(unittest.TestCase):
    def test_decompress_rle(self):
        """Valida rotina RLE do Z80 com dados sintéticos."""
        # Sintético: 2 literais [11, 22], repetição 4x de [55], fim [0x00]
        data = [0x82, 11, 22, 0x04, 55, 0x00]
        res = decompress_rle(data)
        self.assertEqual(res, [11, 22, 55, 55, 55, 55])

    def test_composite_prisoner_frame(self):
        """Valida composição modular 16x32 e Color Compare de hardware."""
        # 10 padrões de 16x16 (320 bytes sintéticos)
        unpacked = [0] * 320

        # Padrões 0xD0 (idx 0), 0xD4 (idx 1), 0xE0 (idx 4), 0xE4 (idx 5)
        # Linha 0 de 0xD0: Ta = 0b11000000
        # Linha 0 de 0xD4: Tb = 0b10100000
        unpacked[0] = 0b11000000
        unpacked[32] = 0b10100000

        frame = composite_prisoner_frame(
            unpacked,
            0xD0, 0xD4, 0xE0, 0xE4,
            0x0D, 0x4B, 0x0D, 0x4B,
            PALETTE_PRISONER
        )

        self.assertEqual(len(frame), 32)
        self.assertEqual(len(frame[0]), 16)

        # Pixel 0: b0=1, b1=1 -> Color Compare (Cor 15 - Preto)
        self.assertEqual(frame[0][0], PALETTE_PRISONER[15])
        # Pixel 1: b0=1, b1=0 -> Cor 13 (Cáqui escuro)
        self.assertEqual(frame[0][1], PALETTE_PRISONER[13])
        # Pixel 2: b0=0, b1=1 -> Cor 11 (Cáqui claro)
        self.assertEqual(frame[0][2], PALETTE_PRISONER[11])
        # Pixel 3: b0=0, b1=0 -> Transparente
        self.assertEqual(frame[0][3], (0, 0, 0, 0))

    def test_write_png(self):
        """Valida geração de arquivo PNG com cabeçalho IHDR RGBA 32-bit correto."""
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as f:
            temp_path = f.name

        try:
            w, h = 48, 128
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
            self.assertEqual(width, 48)
            self.assertEqual(height, 128)
            self.assertEqual(bit_depth, 8)
            self.assertEqual(color_type, 6) # RGBA
        finally:
            if os.path.exists(temp_path):
                os.remove(temp_path)

    def test_extract_all_prisoners_synthetic(self):
        """Valida o fluxo completo de extração com arquivo ASM sintético."""
        with tempfile.TemporaryDirectory() as tmpdir:
            asm_path = os.path.join(tmpdir, "sprites_synth.asm")
            out_png = os.path.join(tmpdir, "prisoners_synth.png")

            # Cria arquivo sintético contendo os 4 rótulos, cada um gerando 320 bytes
            with open(asm_path, "w", encoding="utf-8") as f:
                for label in ["SprPrisoner", "SprPrisoner2", "SprElen", "SprMadnar"]:
                    # 127 bytes repetindo 1, depois 127 repetindo 2, depois 66 repetindo 3 -> 320 bytes
                    f.write(f"{label}:\n")
                    f.write("    db 7Fh, 1, 7Fh, 2, 42h, 3, 0\n\n")

            extract_all_prisoners(asm_path, out_png)
            self.assertTrue(os.path.exists(out_png))
            self.assertGreater(os.path.getsize(out_png), 100)

if __name__ == "__main__":
    unittest.main()
