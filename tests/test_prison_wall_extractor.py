import unittest
from tools.extractors.extract_prison_wall import compose_wall


class PrisonWallExtractorTests(unittest.TestCase):
    def test_row_major_pixels_and_collision(self):
        atlas = [[i] * 64 for i in range(4)]
        result = compose_wall([2, 2, 0, 1, 2, 3], atlas, [0, 1, 1, 0])
        self.assertEqual((result['width'], result['height']), (16, 16))
        self.assertEqual(result['pixels'][:16], [0] * 8 + [1] * 8)
        self.assertEqual(result['pixels'][128:144], [2] * 8 + [3] * 8)
        self.assertEqual(result['collision'], [0, 1, 1, 0])

    def test_rejects_invalid_dimensions_and_missing_tiles(self):
        for block in [[], [0, 1], [1, 2, 0]]:
            with self.assertRaises(ValueError):
                compose_wall(block, [[0] * 64], [0])
        with self.assertRaises(ValueError):
            compose_wall([1, 1, 0], [None], [0])
