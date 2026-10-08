"""Synthetic radio table/text cases; no game bytes or private inputs required."""
import unittest

from tools.extractors.extract_radio_dialogue import english_source, map_zone, parse_room, text_lines

FREQS = [0x85, 0x79, 0x33, 0x26, 0x91, 0x48, 0x13]


class RadioDialogueTests(unittest.TestCase):
    def test_room_records_decode_person_flags_and_end_bit(self):
        # Person 1 auto-tune (bit 3), then person 2 wait-call (bit 2) with the end bit.
        rom = bytes([0xFF, 0x18, 0x03, 0x25, 0x17, 0xFF])
        self.assertEqual(parse_room(rom, 1, FREQS), [
            {'person': 1, 'freq': 0x85, 'wait_call': False, 'auto_tune': True, 'text_id': 3},
            {'person': 2, 'freq': 0x79, 'wait_call': True, 'auto_tune': False, 'text_id': 0x17},
        ])

    def test_room_without_radio_and_invalid_person(self):
        self.assertEqual(parse_room(bytes([0x00, 0x11]), 0, FREQS), [])
        with self.assertRaises(ValueError):
            parse_room(bytes([0x81, 0x01]), 0, FREQS)

    def test_map_zone_nibbles(self):
        table = bytes([0x12, 0x5A])
        self.assertEqual([map_zone(table, room) for room in range(4)], [1, 2, 5, 10])

    def test_text_lines_split_on_fe_and_map_apostrophe(self):
        self.assertEqual(text_lines([[0x41, 0x97, 0x42, 0xFE, 0x5C], [0x30]]), [["A'B", '.'], ['0']])
        with self.assertRaises(ValueError):
            text_lines([[0x01]])

    def test_english_source_keeps_else_branch_and_folds_flags(self):
        source = '\n'.join([
            'Label:', 'IF (JAPANESE)', '\tdb 1', 'ELSE', '\tdb 2', 'ENDIF',
            '\tdb RADIO_A | RADIO_B, 3 ; comment',
        ])
        result = english_source({'RADIO_A': 0x10, 'RADIO_B': 8})('x.asm', source)
        lines = [line.strip() for line in result.splitlines() if line.strip()]
        self.assertEqual(lines, ['Label:', 'db 2', 'db 24, 3'])


if __name__ == '__main__':
    unittest.main()
