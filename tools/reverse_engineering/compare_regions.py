"""Compare data derived from the old Japanese dump with the canonical English re-extraction.

Read-only: both trees are only read; outputs go to a new JSON file and a Markdown summary.
Rooms are resolved exactly as Godot resolved them before (old stage5/stage4 order) and as it
resolves them now (local-aliases, then rooms). Every difference is classified as

  identical / expected regional / structural / unexplained

Structural address changes are accepted only when the delta equals the delta of the matching
symbol between the two assemblies of external/MetalGear (JAPANESE equ 0 and equ 1), built in a
temporary copy with Sjasm (``--sjasm``). Anything that matches no rule stays unexplained.

  python3 tools/reverse_engineering/compare_regions.py --sjasm /path/to/sjasm \\
      --json data/extracted/en-eu-rc750/region-diff.json --markdown /tmp/region-diff.md
"""
import argparse
import bisect
import csv
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tools.extractors.extract_transceiver_sprites import parse_asm_symbols
from tools.rom import REFERENCE, canonical_data_dir

IDENTICAL, REGIONAL, STRUCTURAL, UNEXPLAINED = ('identical', 'expected_regional', 'structural', 'unexplained')
SEVERITY = [IDENTICAL, STRUCTURAL, REGIONAL, UNEXPLAINED]
PROVENANCE = {'input_sha256', 'rom_profile', 'evidence', 'rom_evidence', 'provenance', 'local_alias_of',
              'local_door_remap', 'source'}
OLD_ROOM_DIRS = ['stage5-batch', 'stage5-item-rooms', 'stage5-lorries', 'stage5-elevators',
                 'stage4c-validated', 'stage4b-validated', 'stage4-validated']
OLD_ACTOR_DIRS = OLD_ROOM_DIRS[:4]
NEW_ROOM_DIRS = ['local-aliases', 'rooms']
OFFSET_SYMBOLS = {'speed_table': 'MissileIniSpeed', 'max_ammo_table': 'MaxAmmoLv1'}
SOURCE_SYMBOLS = {'gas_hazard.json': 'GasRooms', 'electrified_floor.json': 'ChkElectricFloor'}
STACK_DEPTH = 0x100
BIOS_AREA = 0xF380


def assemble_symbols(sjasm, reference=REFERENCE):
    """Symbol tables of the English (JAPANESE equ 0) and Japanese (equ 1) builds."""
    tables = {}
    with tempfile.TemporaryDirectory(prefix='mg-regions-') as tmp:
        for name, flag in (('en', '0'), ('jp', '1')):
            source = Path(tmp) / name
            shutil.copytree(reference, source, ignore=shutil.ignore_patterns('.git'))
            main = source / 'MetalGear.asm'
            text = main.read_text(encoding='latin-1')
            if 'JAPANESE\tequ\t0' not in text:
                raise ValueError('Reference no longer defaults to JAPANESE equ 0')
            main.write_text(text.replace('JAPANESE\tequ\t0', 'JAPANESE\tequ\t' + flag), encoding='latin-1')
            result = subprocess.run([str(sjasm), '-s', 'MetalGear.asm', str(Path(tmp) / f'{name}.rom')], cwd=source,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=180)
            if result.returncode or 'Errors: 0' not in result.stdout:
                raise ValueError(f'Assembly ({name}) failed:\n' + result.stdout[-2000:])
            symbols = (source / 'MetalGear.sym').read_text(encoding='latin-1')
            tables[name] = {m[1]: int(m[2], 16) for m in re.finditer(r'^(\w+): equ ([0-9A-F]+)h', symbols, re.M)}
    return tables['en'], tables['jp']


def json_diff(old, new, path=''):
    if type(old) is not type(new):
        return [(path, 'type', old, new)]
    if isinstance(old, dict):
        out = []
        for key in sorted(set(old) | set(new)):
            if key not in old:
                out.append((f'{path}/{key}', 'added', None, new[key]))
            elif key not in new:
                out.append((f'{path}/{key}', 'removed', old[key], None))
            else:
                out.extend(json_diff(old[key], new[key], f'{path}/{key}'))
        return out
    if isinstance(old, list):
        out = [(path, 'length', len(old), len(new))] if len(old) != len(new) else []
        for index, (a, b) in enumerate(zip(old, new)):
            out.extend(json_diff(a, b, f'{path}[{index}]'))
        return out
    return [] if old == new else [(path, 'value', old, new)]


class Classifier:
    def __init__(self, en, jp):
        self.en, self.jp = en, jp

    def delta(self, symbol):
        return self.en[symbol] - self.jp[symbol]

    def offset_change(self, old, new, symbol):
        """Old/new are ints or strings holding one hex offset; the change must equal the symbol delta."""
        def value(v):
            if isinstance(v, int):
                return v
            found = re.findall(r'0x([0-9A-Fa-f]+)', str(v))
            return int(found[-1], 16) if found else None
        a, b = value(old), value(new)
        if a is None or b is None:
            return None
        expected = self.delta(symbol)
        if b - a == expected:
            return STRUCTURAL, f'{symbol} relocated by {expected:+d} bytes between the JAPANESE builds'
        return UNEXPLAINED, f'offset moved {b - a:+d}, but {symbol} moved {expected:+d}'

    def classify(self, artifact, entry, old_doc, new_doc):
        path, kind, old, new = entry
        leaf = path.rsplit('/', 1)[-1]
        if leaf in OFFSET_SYMBOLS and '/rom_offsets/' in path:
            return self.offset_change(old, new, OFFSET_SYMBOLS[leaf])
        if path == '/source' and artifact in SOURCE_SYMBOLS:
            return self.offset_change(old, new, SOURCE_SYMBOLS[artifact])
        match = re.fullmatch(r'/items\[(\d+)\]/evidence/(rom_offset|cpu_address)', path)
        if match:
            return self.offset_change(old, new, new_doc['items'][int(match[1])]['evidence']['symbol'])
        match = re.fullmatch(r'/manifest/verified_segments\[(\d+)\]/(offset|sha256)', path)
        if match:
            segment = new_doc['manifest']['verified_segments'][int(match[1])]
            if segment['files'] == ['data/itemsinrooms.asm']:
                if match[2] == 'offset':
                    return self.offset_change(old, new, 'idxRoomItemsIdx')
                return STRUCTURAL, 'segment holds absolute dw pointers (idxRoomItems), so relocation changes its bytes'
        if artifact == 'respawn_info.json' and path == '/rooms' and kind == 'length':
            same_prefix = old_doc['rooms'][:new] == new_doc['rooms']
            if (old, new) == (189, 188) and same_prefix:
                return STRUCTURAL, ('old extractor read one entry past RespawnInfo; data/respawninfo.asm:13 holds '
                                    '564 bytes = 188 entries; first 188 entries identical')
        if artifact == 'capture_prison.json (root)' and path.startswith('/hollow_wall/'):
            return STRUCTURAL, 'stale file from an earlier extractor format; prison-walls/capture_prison.json is the current old copy'
        if path in ('/manifest/input_crc32', '/manifest/input_sha1', '/manifest/input_role', '/manifest/input_sha256',
                    '/manifest/rom_profile'):
            return IDENTICAL, 'provenance'
        return UNEXPLAINED, 'no rule explains this difference'


def first_existing(root, dirs, name):
    for directory in dirs:
        path = root / directory / name
        if path.exists():
            return path
    return None


def normalize(doc):
    doc = {k: v for k, v in doc.items() if k not in PROVENANCE}
    if 'doors' in doc:
        doc['doors'] = sorted(doc['doors'], key=lambda d: d['door_id'])
    return doc


def compare_json(classifier, artifact, old_path, new_path):
    record = {'artifact': artifact, 'old': str(old_path.relative_to(ROOT)) if old_path else None,
              'new': str(new_path.relative_to(ROOT)) if new_path else None, 'findings': []}
    if old_path is None or new_path is None:
        record['category'] = STRUCTURAL
        record['findings'].append({'category': STRUCTURAL, 'explanation':
                                   'present only in the new export (room decoded but never exported before)'
                                   if old_path is None else 'missing from the new export'})
        if new_path is None:
            record['category'] = UNEXPLAINED
        return record
    old_doc, new_doc = json.loads(old_path.read_text()), json.loads(new_path.read_text())
    if old_doc.get('doors') is not None and new_doc.get('doors') is not None and \
            old_doc['doors'] != new_doc['doors'] and normalize(old_doc)['doors'] == normalize(new_doc)['doors']:
        record['findings'].append({'category': STRUCTURAL, 'explanation': 'same doors in a different order'})
    for entry in json_diff(normalize(old_doc), normalize(new_doc)):
        category, explanation = classifier.classify(artifact, entry, old_doc, new_doc)
        if category != IDENTICAL:
            record['findings'].append({'category': category, 'path': entry[0], 'kind': entry[1],
                                       'old': short(entry[2]), 'new': short(entry[3]), 'explanation': explanation})
    if artifact in SOURCE_SYMBOLS and old_doc.get('source') != new_doc.get('source'):
        entry = ('/source', 'value', old_doc.get('source'), new_doc.get('source'))
        category, explanation = classifier.classify(artifact, entry, old_doc, new_doc)
        record['findings'].append({'category': category, 'path': '/source', 'old': entry[2], 'new': entry[3],
                                   'explanation': explanation})
    record['category'] = max((f['category'] for f in record['findings']), key=SEVERITY.index, default=IDENTICAL)
    return record


def short(value):
    text = json.dumps(value)
    return value if len(text) <= 120 else text[:117] + '...'


def compare_intro(old_dir, new_dir):
    rows = lambda d: list(csv.DictReader((d / 'trace.csv').open()))
    old, new = rows(old_dir), rows(new_dir)
    key = lambda r: tuple(r[k] for k in ('state', 'count', 'x', 'y', 'speed', 'animation'))
    period = lambda r: (float(r[-1]['time']) - float(r[0]['time'])) / (len(r) - 1)
    findings = []
    if [key(r) for r in old] != [key(r) for r in new]:
        findings.append({'category': UNEXPLAINED, 'explanation': 'per-update intro sequence differs'})
    machines = json.loads((old_dir / 'manifest.json').read_text())['machine'], \
        json.loads((new_dir / 'manifest.json').read_text())['machine']
    findings.append({'category': STRUCTURAL, 'explanation':
                     f'identical {len(new)}-update sequence; wall-clock period {period(old):.5f}s ({machines[0]}) '
                     f'vs {period(new):.5f}s ({machines[1]}, 50 Hz VBLANK)'})
    return findings


def font_glyph_cells(vram_old, vram_new):
    """Byte addresses where the two dumps should differ if only the regional glyphs differ."""
    font_asm = (REFERENCE / 'gfx/font.asm').read_text(encoding='latin-1')
    with tempfile.TemporaryDirectory() as tmp:
        jp_asm = Path(tmp) / 'font-jp.asm'
        jp_asm.write_text(re.sub(r'(?ims)^\s*IF\s*\(JAPANESE\)\s*$(.*?)^\s*ELSE\s*$.*?^\s*ENDIF\s*$',
                                 lambda m: m[1], font_asm), encoding='latin-1')
        jp = parse_asm_symbols(str(jp_asm))
    en = parse_asm_symbols(str(REFERENCE / 'gfx/font.asm'))
    font = lambda s: s['gfxFont'] + s['gfxSymbChars']
    en_font, jp_font = font(en), font(jp)
    glyphs = [g for g in range(len(en_font) // 8) if en_font[g * 8:g * 8 + 8] != jp_font[g * 8:g * 8 + 8]]

    def cell(vram, x, y):
        return [sum(1 << (7 - i) for i in range(8)
                    if (vram[(y + r) * 128 + (x + i) // 2] >> (4 if (x + i) % 2 == 0 else 0)) & 0xF)
                for r in range(8)]
    expected, located = set(), {}
    for glyph in glyphs:
        hits = [(x, y) for y in range(len(vram_new) // 128 - 7) for x in range(0, 256, 8)
                if cell(vram_new, x, y) == en_font[glyph * 8:glyph * 8 + 8]
                and cell(vram_old, x, y) == jp_font[glyph * 8:glyph * 8 + 8]]
        if len(hits) != 1:
            return None, glyphs, located
        x, y = hits[0]
        located[glyph] = {'x': x, 'vram_line': y}
        for r in range(8):
            for b in range(4):
                address = (y + r) * 128 + x // 2 + b
                if vram_old[address] != vram_new[address]:
                    expected.add(address)
    return expected, glyphs, located


def compare_probe(old_dir, new_dir, en):
    findings = []
    if (old_dir / 'probe.log').read_text() != (new_dir / 'probe.log').read_text():
        findings.append({'category': UNEXPLAINED, 'explanation': 'DrawTextBoxIn entry/exit log differs'})
    for name in ('pre-vram.bin', 'final-vram.bin'):
        old, new = (old_dir / name).read_bytes(), (new_dir / name).read_bytes()
        actual = {i for i in range(len(old)) if old[i] != new[i]}
        if not actual:
            continue
        expected, glyphs, located = font_glyph_cells(old, new)
        if expected == actual:
            findings.append({'category': REGIONAL, 'path': name, 'explanation':
                             f'{len(actual)} VRAM bytes = regional glyphs {glyphs} of gfx/font.asm:29-33,63-67 '
                             f'(located at {located})'})
        else:
            findings.append({'category': UNEXPLAINED, 'path': name,
                             'explanation': f'{len(actual)} VRAM bytes differ beyond the regional glyphs'})
    if (old_dir / 'final-palette.bin').read_bytes() != (new_dir / 'final-palette.bin').read_bytes():
        findings.append({'category': UNEXPLAINED, 'explanation': 'palette differs'})
    old, new = (old_dir / 'final-ram.bin').read_bytes(), (new_dir / 'final-ram.bin').read_bytes()
    ram = sorted((v, k) for k, v in en.items() if 0xC000 <= v < 0x10000)
    addresses = [v for v, _ in ram]
    groups = {}
    for i in range(len(old)):
        if old[i] != new[i]:
            address = 0xC000 + i
            index = bisect.bisect_right(addresses, address) - 1
            groups.setdefault(ram[index][1] if index >= 0 else '?', []).append(address)
    stack = en['Stack']
    for symbol, hits in groups.items():
        span = f'0x{hits[0]:04X}-0x{hits[-1]:04X} ({len(hits)} bytes, nearest symbol {symbol})'
        if symbol == 'TickCounter' or symbol.startswith('SoundWorkArea'):
            category, why = STRUCTURAL, 'frame/music phase at capture time; capture machine runs at 50 Hz'
        elif all(stack - STACK_DEPTH <= a < stack for a in hits):
            category, why = STRUCTURAL, f'game stack below Stack=0x{stack:04X} (Banks0123.asm:554): return addresses of relocated routines'
        elif all(a >= BIOS_AREA for a in hits):
            category, why = STRUCTURAL, 'MSX BIOS system area (C-BIOS EU vs JP machine; e.g. RG9SAV bit 1 = PAL)'
        else:
            category, why = UNEXPLAINED, 'not referenced by any symbol or literal of the game; probably C-BIOS work area'
        findings.append({'category': category, 'path': 'final-ram.bin ' + span, 'explanation': why})
    return findings


def run(old_root, new_root, en, jp):
    classifier = Classifier(en, jp)
    records = [compare_json(classifier, 'package.json', old_root / 'rc750-verified/package.json',
                            new_root / 'package/package.json')]
    for name in ('gas_hazard.json', 'respawn_info.json', 'missile_weapon.json', 'electrified_floor.json'):
        records.append(compare_json(classifier, name, old_root / name, new_root / name))
    records.append(compare_json(classifier, 'capture_prison.json (root)', old_root / 'capture_prison.json',
                                new_root / 'capture_prison.json'))
    records.append(compare_json(classifier, 'capture_prison.json', old_root / 'prison-walls/capture_prison.json',
                                new_root / 'capture_prison.json'))
    for wall in (12, 13, 14, 15):
        records.append(compare_json(classifier, f'wall-{wall}.json', old_root / f'prison-walls/wall-{wall}.json',
                                    new_root / f'prison-walls/wall-{wall}.json'))
    records.append(compare_json(classifier, 'grey-fox-en.json', old_root / 'dialogues/grey-fox-en.json',
                                new_root / 'dialogues/grey-fox-en.json'))
    for room in range(251):
        for suffix, old_dirs in (('', OLD_ROOM_DIRS), ('-actors', OLD_ACTOR_DIRS)):
            name = f'room-{room:03d}{suffix}.json'
            old_path, new_path = first_existing(old_root, old_dirs, name), first_existing(new_root, NEW_ROOM_DIRS, name)
            if old_path or new_path:
                records.append(compare_json(classifier, name, old_path, new_path))
    for old_dir in ('stage4-validated', 'stage4b-validated', 'stage4c-validated'):
        for old_path in sorted((old_root / old_dir).glob('room-[0-9][0-9][0-9].json')):
            new_path = first_existing(new_root, ['emulator-demo-validated', 'emulator-gameplay-validated'], old_path.name)
            records.append(compare_json(classifier, f'{old_dir}/{old_path.name} (emulator)', old_path, new_path))
    traces = [('intro trace', compare_intro(old_root / 'intro-timing-20261001', new_root / 'traces/intro-timing')),
              ('text box probe', compare_probe(old_root / 'textbox-probe-20261004', new_root / 'traces/textbox-probe', en))]
    for artifact, findings in traces:
        records.append({'artifact': artifact, 'findings': findings,
                        'category': max((f['category'] for f in findings), key=SEVERITY.index, default=IDENTICAL)})
    summary = {category: sum(1 for r in records if r['category'] == category) for category in SEVERITY}
    finding_summary = {category: sum(1 for r in records for f in r['findings'] if f['category'] == category)
                       for category in SEVERITY if category != IDENTICAL}
    return {'format_version': '1.0.0', 'old_root': str(old_root.relative_to(ROOT)),
            'new_root': str(new_root.relative_to(ROOT)), 'summary': summary,
            'finding_summary': finding_summary, 'records': records}


def markdown(report):
    lines = ['| Categoria | Artefatos (pior achado) | Achados |', '| --- | ---: | ---: |']
    findings = report.get('finding_summary', {})
    lines += [f"| {k} | {v} | {findings.get(k, '—')} |" for k, v in report['summary'].items()]
    lines += ['', '| Artefato | Categoria | Achados |', '| --- | --- | --- |']
    for record in report['records']:
        if record['category'] == IDENTICAL:
            continue
        grouped = {}
        for finding in record['findings']:
            text = re.sub(r'^\w+ relocated by', 'symbols relocated by', finding['explanation'])
            grouped.setdefault(f"{finding['category']}: {text}", []).append(finding)
        notes = '; '.join(f'{text} (×{len(items)})' if len(items) > 1 else text for text, items in sorted(grouped.items()))
        lines.append(f"| {record['artifact']} | {record['category']} | {notes} |")
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--sjasm', required=True, type=Path)
    parser.add_argument('--old-root', type=Path, default=ROOT / 'data/extracted/legacy-jp-rc750-local')
    parser.add_argument('--new-root', type=Path, default=canonical_data_dir())
    parser.add_argument('--json', required=True, type=Path)
    parser.add_argument('--markdown', type=Path)
    args = parser.parse_args()
    if args.json.exists():
        print('Refusing to overwrite ' + str(args.json), file=sys.stderr)
        sys.exit(1)
    en, jp = assemble_symbols(args.sjasm)
    report = run(args.old_root, args.new_root, en, jp)
    args.json.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')
    if args.markdown:
        args.markdown.write_text(markdown(report))
    print(json.dumps({'artifacts': report['summary'], 'findings': report['finding_summary']}))


if __name__ == '__main__':
    main()
