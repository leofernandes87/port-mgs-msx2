"""Synthetic-fixture tests for tools/extractors/extract_rolling_barrel.py (no game bytes)."""
import struct
import unittest
import zlib

from tools.extractors.codecs import png_indexed
from tools.extractors.extract_rolling_barrel import (
    _dw_labels, area, compose_frame, decode_patterns, parse_frame, side_by_side, sprite_palette)


def solid(row_byte):
    return bytes([row_byte] * 32)


class RollingBarrelExtractorTests(unittest.TestCase):
    def test_decode_patterns_fill_and_literal(self):
        stream = bytes([0x20, 0xAA, 0x82, 1, 2, 0x1E, 0x55, 0])
        patterns = decode_patterns(stream, 2)
        self.assertEqual(patterns[0], bytes([0xAA] * 32))
        self.assertEqual(patterns[1][:2], bytes([1, 2]))
        self.assertEqual(patterns[1][2:], bytes([0x55] * 30))

    def test_decode_patterns_rejects_wrong_size(self):
        with self.assertRaises(ValueError):
            decode_patterns(bytes([0x10, 0, 0]), 1)

    def test_parse_frame_unwraps_column_offsets(self):
        offsets = [bytes([0, 0xF8, 0, 0xF8, 0x40, 0xF8, 0x40, 0xF8, 0x80, 0xF8, 0x80, 0xF8])]
        patterns, offs = parse_frame(bytes([0x91, 0xD0, 0xD4, 0xD8, 0xDC, 0xE0, 0xE4]), offsets, 6)
        self.assertEqual(patterns, [0xD0, 0xD4, 0xD8, 0xDC, 0xE0, 0xE4])
        self.assertEqual(offs[-1], (128, -8))
        self.assertEqual(offs[2], (64, -8))

    def test_parse_frame_rejects_explicit_offsets(self):
        with self.assertRaises(ValueError):
            parse_frame(bytes([0x10, 0xD0]), [bytes(2)], 1)

    def test_compose_frame_color_compare(self):
        left = bytes([0b11000000] + [0] * 31)
        right = bytes([0b10100000] + [0] * 31)
        frame = compose_frame([left, right], 0xD0, [0xD0, 0xD4], [(0, -8), (0, -8)], [2, 0x4D])
        self.assertEqual((frame['width'], frame['height'], frame['origin']), (16, 16, [8, 0]))
        self.assertEqual(frame['pixels'][:4], [15, 2, 13, 0])

    def test_compose_frame_lower_plane_wins_without_cc(self):
        frame = compose_frame([solid(0xFF), solid(0xFF)], 0xD0, [0xD0, 0xD4], [(0, 0), (0, 0)], [2, 9])
        self.assertTrue(all(p == 2 for p in frame['pixels']))

    def test_compose_frame_stacks_rows(self):
        frame = compose_frame([solid(0xFF), solid(0x00)], 0xD0, [0xD0, 0xD4, 0xD0, 0xD4],
                              [(0, -8), (0, -8), (16, -8), (16, -8)], [2, 0x4D, 2, 0x4D])
        self.assertEqual((frame['width'], frame['height']), (16, 32))
        self.assertEqual(frame['pixels'][16 * 16], 2)

    def test_compose_frame_rejects_unloaded_pattern(self):
        with self.assertRaises(ValueError):
            compose_frame([solid(0)], 0xD0, [0xE0], [(0, 0)], [2])

    def test_sprite_palette_overrides_room_colours(self):
        room = [[i, i, i] for i in range(18)]
        palette = sprite_palette(room, bytes([2, 0x70, 0, 13, 0x07, 7, 0xFF]))
        self.assertEqual(len(palette), 16)
        self.assertEqual(palette[2], [255, 0, 0])
        self.assertEqual(palette[13], [0, 255, 255])
        self.assertEqual(palette[15], [15, 15, 15])

    def test_side_by_side_layout(self):
        a = {'width': 2, 'height': 1, 'origin': [0, 0], 'pixels': [1, 2]}
        b = {'width': 2, 'height': 1, 'origin': [0, 0], 'pixels': [3, 4]}
        self.assertEqual(side_by_side([a, b]), (4, 1, [1, 2, 3, 4]))

    def test_area_signed_offsets(self):
        self.assertEqual(area(bytes([0xF0, 0x10, 0, 8])),
                         {'offset_y': -16, 'radius_y': 16, 'offset_x': 0, 'radius_x': 8})

    def test_dw_labels(self):
        source = 'idxX:\tdw A\n\t\tdw B\n\n; end\nOther: dw C\n'
        self.assertEqual(_dw_labels(source, 'idxX'), ['A', 'B'])

    def test_png_transparent_index(self):
        png = png_indexed(2, 1, [0, 1], [[0, 0, 0], [9, 9, 9]], transparent=0)
        self.assertIn(b'tRNS', png)
        pos = png.index(b'tRNS')
        length = struct.unpack('>I', png[pos - 4:pos])[0]
        self.assertEqual(png[pos + 4:pos + 4 + length], b'\x00')
        idat = png.index(b'IDAT')
        size = struct.unpack('>I', png[idat - 4:idat])[0]
        self.assertEqual(zlib.decompress(png[idat + 4:idat + 4 + size]), b'\x00\x00\x01')


if __name__ == '__main__':
    unittest.main()
