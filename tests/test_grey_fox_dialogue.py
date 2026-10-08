"""Synthetic text/font cases; no game bytes or private inputs required."""
from pathlib import Path
import tempfile
import unittest

from tools.extractors.extract_grey_fox_dialogue import decode_pages, glyph_cell
from tools.extractors.extract_transceiver_sprites import parse_asm_symbols


class DialogueTests(unittest.TestCase):
    def test_expansion_preserves_pages_lines_and_narrow_glyphs(self):
        self.assertEqual(decode_pages([65, 151, 161, 253, 66, 255],
                                     {161: [67, 254, 68, 255]}),
                         [[65, 151, 67, 254, 68], [66]])

    def test_dictionary_is_not_recursively_expanded(self):
        self.assertEqual(decode_pages([161, 255], {161: [162, 255]}), [[162]])

    def test_rejects_incomplete_or_ambiguous_data(self):
        for message, dictionary in [([65], {}), ([255, 65], {}), ([161, 255], {}),
                                    ([161, 255], {161: [65]}),
                                    ([161, 255], {161: [255, 65, 255]})]:
            with self.subTest(message=message, dictionary=dictionary), self.assertRaises(ValueError):
                decode_pages(message, dictionary)

    def test_empty_page_is_not_lost(self):
        self.assertEqual(decode_pages([253, 65, 253, 255], {}), [[], [65], []])

    def test_raw_codes_map_to_correct_extracted_cells(self):
        self.assertEqual([glyph_cell(c) for c in [0, 65, 0x97, 0x5f, 0x3f]], [32, 65, 96, 44, 35])
        with self.assertRaises(KeyError):
            glyph_cell(0x99)

    def test_font_conditional_branches_are_not_concatenated(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'font.asm'
            path.write_text('glyph: db 1\n IF (JAPANESE)\n db 2,3\n ELSE\n db 4,5\n ENDIF\n db 6\n IF (JAPANESE)\n db 7\n ELSE\n db 8\n ENDIF\n')
            self.assertEqual(parse_asm_symbols(str(path))['glyph'], [1, 4, 5, 6, 8])
