"""Re-extraction tools: synthetic documents and symbols only, never game data."""
import unittest

from tools.emulation.run_trace import check_expectations, parse_pairs, rewrite
from tools.extractors.export_local_aliases import build_aliases
from tools.reverse_engineering.compare_regions import (IDENTICAL, STRUCTURAL, UNEXPLAINED, Classifier, json_diff,
                                                       normalize)
from tools.rom import RomError, load_profiles


def canonical():
    profiles = load_profiles()
    return {'rom_profile': profiles['canonical'],
            'input_sha256': profiles['profiles'][profiles['canonical']]['sha256']}


def door(door_id, destination):
    return {'door_id': door_id, 'destination_room_id': destination}


class LocalAliases(unittest.TestCase):
    def rooms(self, provenance):
        return {
            164: ({'room_id': 164, 'pixels': [1], **provenance},
                  {'room_id': 164, 'doors': [door(1, 165)], **provenance}),
            165: ({'room_id': 165, 'pixels': [2], **provenance},
                  {'room_id': 165, 'doors': [door(2, 164), door(3, 7)], **provenance}),
            54: ({'room_id': 54, 'pixels': [3], **provenance},
                 {'room_id': 54, 'doors': [door(4, 164)], **provenance}),
            7: ({'room_id': 7, 'pixels': [4], **provenance},
                {'room_id': 7, 'doors': [door(5, 8)], **provenance}),
        }

    def test_aliases_copy_originals_and_remap_doors(self):
        files = build_aliases(self.rooms(canonical()))
        self.assertEqual(sorted(files), ['room-054-actors.json', 'room-211-actors.json', 'room-211.json',
                                         'room-212-actors.json', 'room-212.json'])
        self.assertEqual((files['room-211.json']['room_id'], files['room-211.json']['local_alias_of'],
                          files['room-211.json']['pixels']), (211, 165, [2]))
        self.assertEqual([d['destination_room_id'] for d in files['room-211-actors.json']['doors']], [212, 7])
        self.assertEqual([d['destination_room_id'] for d in files['room-212-actors.json']['doors']], [211])
        self.assertEqual([d['destination_room_id'] for d in files['room-054-actors.json']['doors']], [212])
        self.assertEqual(files['room-054-actors.json']['room_id'], 54)

    def test_non_canonical_inputs_are_refused(self):
        with self.assertRaises(RomError):
            build_aliases(self.rooms({'rom_profile': 'synthetic', 'input_sha256': '0' * 64}))


class TraceRelocation(unittest.TestCase):
    def test_rewrite_replaces_whole_literals_only(self):
        mapping = parse_pairs(['828f=8240', '0x82DF=0x8290'])
        script = 'bp 0x828f; peek 0x828f0; read 0x82df 0x1234'
        self.assertEqual(rewrite(script, mapping), 'bp 0x8240; peek 0x828f0; read 0x8290 0x1234')

    def test_expectations_only_in_fixed_banks(self):
        class Rom:
            data = bytes([0xC9]) + bytes(0x7FFF)
        check_expectations(Rom, {0x4000: 0xC9})
        with self.assertRaisesRegex(ValueError, 'expected 0x00'):
            check_expectations(Rom, {0x4000: 0x00})
        with self.assertRaisesRegex(ValueError, 'outside the fixed banks'):
            check_expectations(Rom, {0xC000: 0x00})


class RegionClassifier(unittest.TestCase):
    classifier = Classifier(en={'MissileIniSpeed': 0x4800, 'GasRooms': 0x4C00},
                            jp={'MissileIniSpeed': 0x4810, 'GasRooms': 0x4C40})

    def test_json_diff_and_normalize(self):
        old = {'a': 1, 'b': [1, 2], 'input_sha256': 'x', 'doors': [door(2, 0), door(1, 0)]}
        new = {'a': 2, 'b': [1], 'rom_profile': 'y', 'doors': [door(1, 0), door(2, 0)]}
        self.assertEqual(json_diff(normalize(old), normalize(new)),
                         [('/a', 'value', 1, 2), ('/b', 'length', 2, 1)])

    def test_offset_change_must_match_symbol_delta(self):
        entry = ('/rom_offsets/speed_table', 'value', '0x0810', '0x0800')
        self.assertEqual(self.classifier.classify('missile_weapon.json', entry, {}, {})[0], STRUCTURAL)
        entry = ('/rom_offsets/speed_table', 'value', '0x0810', '0x0801')
        self.assertEqual(self.classifier.classify('missile_weapon.json', entry, {}, {})[0], UNEXPLAINED)
        entry = ('/source', 'value', 'GasRooms @ 0x0C40', 'GasRooms @ 0x0C00')
        self.assertEqual(self.classifier.classify('gas_hazard.json', entry, {}, {})[0], STRUCTURAL)

    def test_unknown_differences_stay_unexplained(self):
        self.assertEqual(self.classifier.classify('x.json', ('/damage', 'value', 1, 2), {}, {})[0], UNEXPLAINED)
        self.assertEqual(self.classifier.classify('package.json', ('/manifest/rom_profile', 'value', 'a', 'b'),
                                                  {}, {})[0], IDENTICAL)


if __name__ == '__main__':
    unittest.main()
