"""Canonical ROM resolution by content hash; names and directory order are irrelevant.

Usage:
  python3 -m tools.rom --check [--rom PATH]
  SJASM=/path/to/sjasm python3 -m tools.rom --verify-build

Only the profile marked canonical in data/rom-profiles.json is accepted. Other
known dumps are reported by name and rejected. Inputs are read, never written.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from typing import NamedTuple, Optional
import zlib

ROOT = Path(__file__).resolve().parents[1]
PROFILES_PATH = ROOT / 'data/rom-profiles.json'
ROMS_DIR = ROOT / 'roms'
REFERENCE = ROOT / 'external/MetalGear'
ENV_VAR = 'MG_ROM'


class RomError(ValueError):
    pass


class CanonicalRom(NamedTuple):
    path: Path
    data: bytes
    profile_id: str
    profile: dict
    sha256: str

    def assert_unchanged(self) -> None:
        if hashlib.sha256(self.path.read_bytes()).hexdigest() != self.sha256:
            raise RomError(f'ROM changed while in use: {self.path}')

    def provenance(self) -> dict:
        return {'rom_profile': self.profile_id, 'input_sha256': self.sha256}


def load_profiles(path: Path = PROFILES_PATH) -> dict:
    profiles = json.loads(path.read_text(encoding='utf-8'))
    canonical = profiles['canonical']
    entry = profiles['profiles'][canonical]
    if entry.get('role') != 'canonical':
        raise RomError('Canonical profile is not marked canonical')
    if [k for k, v in profiles['profiles'].items() if v.get('role') == 'canonical'] != [canonical]:
        raise RomError('Exactly one canonical ROM profile is allowed')
    return profiles


def identify(data: bytes, profiles: dict) -> Optional[str]:
    digest = hashlib.sha256(data).hexdigest()
    return next((k for k, v in profiles['profiles'].items() if v['sha256'] == digest), None)


def _accept(path: Path, profiles: dict) -> CanonicalRom:
    data = path.read_bytes()
    canonical = profiles['canonical']
    entry = profiles['profiles'][canonical]
    found = identify(data, profiles)
    if found != canonical:
        label = f'known profile "{found}" ({profiles["profiles"][found]["role"]})' if found else 'unknown content'
        raise RomError(f'{path.name}: {label}; only "{canonical}" (SHA-256 {entry["sha256"]}) is accepted')
    if len(data) != entry['size'] or f'{zlib.crc32(data) & 0xffffffff:08X}' != entry['crc32']:
        raise RomError(f'{path.name}: size/CRC32 disagree with the canonical profile')
    return CanonicalRom(path, data, canonical, entry, entry['sha256'])


def resolve_canonical_rom(path: Optional[Path] = None, *, roms_dir: Path = ROMS_DIR,
                          profiles: Optional[dict] = None, env: Optional[dict] = None) -> CanonicalRom:
    """Explicit path > $MG_ROM > content discovery in roms/. All paths must match the canonical hash."""
    profiles = profiles or load_profiles()
    env = os.environ if env is None else env
    explicit = path or (Path(env[ENV_VAR]) if env.get(ENV_VAR) else None)
    if explicit is not None:
        if not explicit.is_file():
            raise RomError(f'ROM not found: {explicit}')
        return _accept(explicit, profiles)
    if not roms_dir.is_dir():
        raise RomError(f'ROM directory not found: {roms_dir}')
    canonical_sha = profiles['profiles'][profiles['canonical']]['sha256']
    matches, seen = [], []
    for candidate in roms_dir.iterdir():
        if not candidate.is_file() or candidate.name.startswith('.') or candidate.name == 'README.md':
            continue
        digest = hashlib.sha256(candidate.read_bytes()).hexdigest()
        if digest == canonical_sha:
            matches.append(candidate)
        else:
            seen.append(identify(candidate.read_bytes(), profiles) or f'unknown:{candidate.name}')
    if not matches:
        raise RomError(f'No canonical ROM in {roms_dir} (found: {sorted(seen) or "nothing"}); '
                       f'expected SHA-256 {canonical_sha}')
    # Every match has identical bytes, so the choice cannot change any output.
    return _accept(min(matches), profiles)


def canonical_data_dir(profiles: Optional[dict] = None) -> Path:
    """Every artifact consumed downstream lives under data/extracted/<canonical profile id>/."""
    return ROOT / 'data/extracted' / (profiles or load_profiles())['canonical']


def require_canonical_provenance(record: dict, profiles: Optional[dict] = None) -> None:
    """Derived data is usable only when it names both the canonical profile and its hash."""
    profiles = profiles or load_profiles()
    canonical = profiles['canonical']
    expected_sha = profiles['profiles'][canonical]['sha256']
    profile, digest = record.get('rom_profile'), record.get('input_sha256')
    if (profile, digest) != (canonical, expected_sha):
        known = next((k for k, v in profiles['profiles'].items() if v['sha256'] == digest), None)
        raise RomError(f'Derived data is not from "{canonical}" (rom_profile={profile!r}, '
                       f'input_sha256 matches {known or "no known profile"}); re-extract it')


def verify_build(rom: CanonicalRom, sjasm: Path, reference: Path = REFERENCE) -> None:
    """Assemble a private copy of the reference with its default JAPANESE equ 0 and compare all bytes."""
    with tempfile.TemporaryDirectory(prefix='mg-build-') as tmp:
        source = Path(tmp) / 'src'
        shutil.copytree(reference, source, ignore=shutil.ignore_patterns('.git'))
        if 'JAPANESE\tequ\t0' not in (source / 'MetalGear.asm').read_text(encoding='latin-1'):
            raise RomError('Reference no longer defaults to JAPANESE equ 0')
        output = Path(tmp) / 'built.rom'
        result = subprocess.run([str(sjasm), 'MetalGear.asm', str(output)], cwd=source,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120)
        if result.returncode or 'Errors: 0' not in result.stdout or not output.is_file():
            raise RomError('Assembly failed:\n' + result.stdout[-2000:])
        if output.read_bytes() != rom.data:
            raise RomError('Assembled English reference differs from the canonical ROM')


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--rom', type=Path, help=f'Explicit ROM path (else ${ENV_VAR}, else hash discovery in roms/)')
    parser.add_argument('--check', action='store_true', help='Resolve and print the canonical ROM identity')
    parser.add_argument('--verify-build', action='store_true', help='Reassemble the reference with $SJASM and compare')
    args = parser.parse_args(argv)
    try:
        rom = resolve_canonical_rom(args.rom)
        if args.verify_build:
            sjasm = os.environ.get('SJASM')
            if not sjasm or not Path(sjasm).is_file():
                raise RomError('Set SJASM to a Sjasm 0.39 executable')
            verify_build(rom, Path(sjasm))
        rom.assert_unchanged()
    except (RomError, OSError, subprocess.SubprocessError) as error:
        print('ROM_CHECK_FAILED: ' + str(error), file=sys.stderr)
        return 1
    print(f'ROM_CHECK_OK: {rom.profile_id} sha256={rom.sha256} file="{rom.path.name}"'
          + (' build=identical' if args.verify_build else ''))
    return 0


if __name__ == '__main__':
    sys.exit(main())
