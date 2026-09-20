"""Synthetic fixtures only: no copyrighted data or ROM needed."""
import hashlib
import unittest
import zlib
from tools.reverse_engineering.analyze import (
    bank_offset, data_segment, expand_metatiles, hits, literal_block, number, ram_map,
)


class AnalysisTests(unittest.TestCase):
    def test_checksum_known_vector(self):
        data = b'123456789'
        self.assertEqual(zlib.crc32(data), 0xCBF43926)
        self.assertEqual(hashlib.sha1(data).hexdigest(), 'f7c3bc1d808e04732adf679965ccc34ca7ae3441')
        self.assertEqual(hashlib.sha256(data).hexdigest(), '15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225')

    def test_literals(self):
        for token, expected in [('10',10), ('0FFh',255), ('#c000',49152), ('1100b',12), ('-5',-5)]:
            self.assertEqual(number(token), expected)
        with self.assertRaises(ValueError):
            number('1+2')

    def test_forward_reference_and_little_endian(self):
        payload, symbols, locations = data_segment([('a.asm', 'Index: dw Later\n db -1\nLater: db 3,4')], 0x6000)
        self.assertEqual(payload, bytes([3,0x60,255,3,4]))
        self.assertEqual(symbols['Later'], 0x6003)
        self.assertEqual(locations['Later']['line'], 3)

    def test_parser_rejects_unsupported_or_invalid(self):
        for source in ['db Missing', 'db 256', 'db -129', 'dw 65536', 'IF 1\ndb 2\nENDIF', 'x: db 0\nx: db 1', 'org #6000']:
            with self.subTest(source=source), self.assertRaises(ValueError):
                data_segment([('fixture', source)], 0)

    def test_literal_probe_stops_at_next_label(self):
        payload, line = literal_block('; comment\na: db 1,2\n db 3\nb: db 4', 'a')
        self.assertEqual(payload, bytes([1,2,3]))
        self.assertEqual(line, 2)
        with self.assertRaises(ValueError):
            literal_block('a: db Undefined', 'a')

    def test_match_reports_ambiguity(self):
        self.assertEqual(hits(b'ababa', b'aba'), [0,2])
        self.assertEqual(hits(b'abc', b'xyz'), [])
        with self.assertRaises(ValueError):
            hits(b'abc', b'')

    def test_bank_mapping_boundaries(self):
        self.assertEqual(bank_offset(13,0x6000,0x6000,0x20000),0x1A000)
        self.assertEqual(bank_offset(15,0xBFFF,0xA000,0x20000),0x1FFFF)
        for bank in range(16):
            for displacement in (0,1,8191):
                offset = bank_offset(bank,0x8000+displacement,0x8000,0x20000)
                self.assertEqual(divmod(offset,8192), (bank,displacement))
        for args in [(16,0x6000,0x6000,0x20000), (0,0x8000,0x6000,0x20000), (-1,0x6000,0x6000,0x20000)]:
            with self.assertRaises(ValueError):
                bank_offset(*args)

    def test_ram_layout_and_optional_colon(self):
        symbols = ram_map('map #c000\nFirst: # 2\nSecond # 10h')
        self.assertEqual(symbols['Second']['address'],0xC002)
        self.assertEqual(symbols['Second']['size'],16)
        with self.assertRaises(ValueError):
            ram_map('map #c000\nunknown syntax')

    def test_metatile_placement_not_only_length(self):
        room = bytes([1,2] * 24)
        definitions = bytes(range(16)) + bytes(range(16,32))
        result = expand_metatiles(room,definitions)
        self.assertEqual(len(result),768)
        self.assertEqual(result[:8],bytes([0,1,2,3,16,17,18,19]))
        self.assertEqual(result[32:40],bytes([4,5,6,7,20,21,22,23]))
        self.assertEqual(result[128:136],result[:8])
        self.assertEqual(result[-4:],bytes([28,29,30,31]))
        self.assertEqual(hashlib.sha256(result).digest(),hashlib.sha256(expand_metatiles(room,definitions)).digest())

    def test_metatile_probe_rejects_truncation_and_bad_ids(self):
        for room, definitions in [(bytes([1])*47,bytes(16)), (bytes(48),bytes(16)), (bytes([2])*48,bytes(16)), (bytes([1])*48,bytes(15))]:
            with self.assertRaises(ValueError):
                expand_metatiles(room,definitions)
