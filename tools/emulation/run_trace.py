"""Run a read-only openMSX Tcl trace against the canonical ROM.

The script is copied into a new directory under data/extracted/ and executed there with
the canonical profile's machine. Address substitutions (``--map OLD=NEW``) are explicit,
each one checked against an expected opcode byte in the canonical ROM (``--expect CPU=BYTE``),
and all of them are recorded in manifest.json next to the outputs.

  python3 tools/emulation/run_trace.py --script old/trace.tcl --output data/extracted/<new> \\
      --map 0x828f=0x8240 --expect 0x8240=0x21
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tools.rom import resolve_canonical_rom

FIXED_BANKS_CPU = range(0x4000, 0xC000)


def parse_pairs(values):
    pairs = {}
    for value in values or []:
        old, new = (int(part, 16) for part in value.split('='))
        pairs[old] = new
    return pairs


def rewrite(script, mapping):
    """Replace whole hexadecimal literals only; unknown addresses stay untouched."""
    def substitute(match):
        value = int(match.group(0), 16)
        return f'0x{mapping[value]:04x}' if value in mapping else match.group(0)
    return re.sub(r'0x[0-9a-fA-F]{4}\b', substitute, script)


def check_expectations(rom, expectations):
    for cpu, byte in expectations.items():
        if cpu not in FIXED_BANKS_CPU:
            raise ValueError(f'Expectation 0x{cpu:04X} is outside the fixed banks 0-3')
        if rom.data[cpu - 0x4000] != byte:
            raise ValueError(f'Canonical ROM has 0x{rom.data[cpu - 0x4000]:02X} at 0x{cpu:04X}, expected 0x{byte:02X}')


def run(script_path, output, emulator, mapping, expectations, timeout):
    private = (ROOT / 'data/extracted').resolve()
    if private not in output.resolve().parents or output.exists():
        raise ValueError('Choose a new directory under data/extracted')
    rom = resolve_canonical_rom()
    check_expectations(rom, expectations)
    script = rewrite(script_path.read_text(encoding='utf-8'), mapping)
    output.mkdir(parents=True)
    target = output / script_path.name
    target.write_text(script, encoding='utf-8')
    machine = rom.profile['openmsx_machine']
    result = subprocess.run([str(emulator), '-machine', machine, '-cart', str(rom.path), '-script', str(target)],
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=timeout)
    (output / 'emulator.log').write_text(result.stdout)
    rom.assert_unchanged()
    files = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
             for p in sorted(output.iterdir()) if p.is_file() and p.name != 'manifest.json'}
    manifest = {
        'format_version': '1.0.0', **rom.provenance(), 'machine': machine,
        'source_script': str(script_path), 'source_script_sha256': hashlib.sha256(script_path.read_bytes()).hexdigest(),
        'address_map': {f'0x{k:04X}': f'0x{v:04X}' for k, v in sorted(mapping.items())},
        'opcode_checks': {f'0x{k:04X}': f'0x{v:02X}' for k, v in sorted(expectations.items())},
        'emulator_exit_code': result.returncode, 'input_unchanged': True, 'files': files,
    }
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--script', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--emulator', type=Path, default=Path('/Applications/openMSX.app/Contents/MacOS/openmsx'))
    parser.add_argument('--map', action='append', help='OLD=NEW CPU address substitution (hex)')
    parser.add_argument('--expect', action='append', help='CPU=BYTE opcode check in the canonical ROM (hex)')
    parser.add_argument('--timeout', type=int, default=180)
    args = parser.parse_args()
    try:
        manifest = run(args.script, args.output, args.emulator, parse_pairs(args.map), parse_pairs(args.expect),
                       args.timeout)
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        print('TRACE_FAILED: ' + str(error), file=sys.stderr)
        sys.exit(1)
    print(json.dumps({k: manifest[k] for k in ('rom_profile', 'machine', 'address_map', 'emulator_exit_code')}))


if __name__ == '__main__':
    main()
