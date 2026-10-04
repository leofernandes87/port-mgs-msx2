"""Canonical ROM policy: synthetic bytes only, never game data."""
import hashlib
import json
from pathlib import Path
import re
import tempfile
import unittest
import zlib

from tools.rom import RomError, identify, load_profiles, resolve_canonical_rom

ROOT = Path(__file__).resolve().parents[1]


def profile(data, role):
    return {'role': role, 'size': len(data), 'crc32': f'{zlib.crc32(data) & 0xffffffff:08X}',
            'sha256': hashlib.sha256(data).hexdigest()}


class SyntheticProfiles(unittest.TestCase):
    canonical = b'canonical-synthetic-rom' * 7
    forbidden = b'forbidden-synthetic-rom' * 7

    def profiles(self):
        return {'canonical': 'synthetic-en', 'profiles': {
            'synthetic-en': profile(self.canonical, 'canonical'),
            'synthetic-jp': profile(self.forbidden, 'forbidden')}}

    def make_dir(self, files):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        for name, data in files.items():
            (root / name).write_bytes(data)
        return root

    def test_discovery_ignores_names_and_order(self):
        layouts = [
            {'aaa-official.rom': self.forbidden, 'zzz.bin': self.canonical},
            {'zzz-official.rom': self.forbidden, 'aaa.bin': self.canonical, 'notes.txt': b'x'},
            {'Metal Gear (Europe).rom': self.forbidden, 'random-name': self.canonical},
        ]
        for files in layouts:
            rom = resolve_canonical_rom(roms_dir=self.make_dir(files), profiles=self.profiles(), env={})
            self.assertEqual(rom.data, self.canonical)
            self.assertEqual(rom.profile_id, 'synthetic-en')

    def test_duplicate_canonical_copies_are_equivalent(self):
        rom = resolve_canonical_rom(roms_dir=self.make_dir({'b.rom': self.canonical, 'a.rom': self.canonical}),
                                    profiles=self.profiles(), env={})
        self.assertEqual(rom.sha256, hashlib.sha256(self.canonical).hexdigest())

    def test_explicit_and_env_paths_are_hash_checked(self):
        root = self.make_dir({'good.rom': self.canonical, 'bad.rom': self.forbidden, 'odd.rom': b'unknown'})
        self.assertEqual(resolve_canonical_rom(root / 'good.rom', profiles=self.profiles(), env={}).data,
                         self.canonical)
        self.assertEqual(resolve_canonical_rom(profiles=self.profiles(), roms_dir=root / 'missing',
                                               env={'MG_ROM': str(root / 'good.rom')}).data, self.canonical)
        with self.assertRaisesRegex(RomError, 'synthetic-jp'):
            resolve_canonical_rom(root / 'bad.rom', profiles=self.profiles(), env={})
        with self.assertRaisesRegex(RomError, 'unknown content'):
            resolve_canonical_rom(profiles=self.profiles(), env={'MG_ROM': str(root / 'odd.rom')})

    def test_no_canonical_rom_is_an_error_without_fallback(self):
        root = self.make_dir({'only-forbidden.rom': self.forbidden})
        with self.assertRaisesRegex(RomError, 'No canonical ROM'):
            resolve_canonical_rom(roms_dir=root, profiles=self.profiles(), env={})

    def test_unchanged_guard(self):
        root = self.make_dir({'good.rom': self.canonical})
        rom = resolve_canonical_rom(root / 'good.rom', profiles=self.profiles(), env={})
        rom.assert_unchanged()
        (root / 'good.rom').write_bytes(self.forbidden)
        with self.assertRaises(RomError):
            rom.assert_unchanged()

    def test_profiles_require_exactly_one_canonical(self):
        broken = self.profiles()
        broken['profiles']['synthetic-jp']['role'] = 'canonical'
        with tempfile.NamedTemporaryFile('w', suffix='.json', delete=False) as handle:
            json.dump(broken, handle)
        self.addCleanup(Path(handle.name).unlink)
        with self.assertRaises(RomError):
            load_profiles(Path(handle.name))
        self.assertEqual(identify(self.forbidden, self.profiles()), 'synthetic-jp')


class RealProfileFile(unittest.TestCase):
    def test_canonical_profile_is_the_official_english_rom(self):
        profiles = load_profiles()
        canonical = profiles['profiles'][profiles['canonical']]
        self.assertEqual(profiles['canonical'], 'en-eu-rc750')
        self.assertEqual(canonical['crc32'], 'E85C5731')
        self.assertEqual(canonical['openmsx_machine'], 'C-BIOS_MSX2_EU')
        hashes = [p['sha256'] for p in profiles['profiles'].values()]
        self.assertEqual(len(hashes), len(set(hashes)))
        self.assertTrue(all(re.fullmatch(r'[0-9a-f]{64}', h) for h in hashes))

    def test_capture_anchor_set_matches_profile(self):
        from tools.emulation.capture import ANCHORS, breakpoints
        profiles = load_profiles()
        canonical = profiles['profiles'][profiles['canonical']]
        self.assertEqual(set(canonical['debugger_cpu']), set(ANCHORS))
        with self.assertRaises(ValueError):
            breakpoints(bytes(0x8000), canonical)

    def test_godot_mirror_matches_profile(self):
        profiles = load_profiles()
        source = (ROOT / 'godot/scripts/systems/rom_provenance.gd').read_text(encoding='utf-8')
        mirror = dict(re.findall(r'const (\w+): String = "([^"]*)"', source))
        self.assertEqual(mirror['CANONICAL_PROFILE'], profiles['canonical'])
        self.assertEqual(mirror['CANONICAL_SHA256'], profiles['profiles'][profiles['canonical']]['sha256'])
        self.assertEqual(mirror['LEGACY_PENDING_REEXTRACTION_SHA256'],
                         profiles['profiles']['jp-rc750-local']['sha256'])


class RomPolicyLint(unittest.TestCase):
    """Fails if a tool reintroduces name-, order- or offset-based ROM selection."""
    FORBIDDEN = [
        (r'roms/Metal Gear|\[RC-750\]|Does not work on Non Japanese', 'ROM file name'),
        (r'\bDEFAULT_ROM\b|\bPRIMARY_SHA256\b', 'name/hash constant outside the profile'),
        (r'C-BIOS_MSX2_JP', 'Japanese capture machine'),
        (r'_ROM_OFFSET\s*=\s*0x', 'fixed physical ROM offset'),
        (r'0x(4C79|4C0D|48DE|51D6|DB0D|375F|775F)\b', 'offset of the Japanese dump'),
    ]
    ROMS_DIR_ALLOWED = {'tools/rom.py', 'tools/reverse_engineering/analyze.py', 'tools/validate.py'}

    def files(self):
        for pattern in ('tools/**/*.py', 'tools/**/*.tcl', 'tools/**/*.md', 'godot/scripts/**/*.gd'):
            yield from ROOT.glob(pattern)

    def test_no_name_order_or_offset_selection(self):
        problems = []
        for path in self.files():
            relative = path.relative_to(ROOT).as_posix()
            text = path.read_text(encoding='utf-8', errors='replace')
            for pattern, reason in self.FORBIDDEN:
                for match in re.finditer(pattern, text, re.I):
                    problems.append(f'{relative}: {reason}: {match.group(0)}')
            if relative not in self.ROMS_DIR_ALLOWED and re.search(r"""['"]roms['"]""", text):
                problems.append(f'{relative}: direct access to roms/; use tools.rom.resolve_canonical_rom')
        self.assertEqual(problems, [])


if __name__ == '__main__':
    unittest.main()
