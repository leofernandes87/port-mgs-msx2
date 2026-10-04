"""Read-only, bounded static probes. No Z80 assembler or full asset extractor.

Run from any directory: python3 tools/reverse_engineering/analyze.py
Only metadata/hashes are saved, never ROM bytes or source data tables.
"""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import zlib

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
REFERENCE = ROOT / 'external/MetalGear'
PINNED_REVISION = '30d1b940bede10fdabbaf9767ad4f0ad8dd33291'
EXPECTED = {'FAFE1303': 'Japanese (reference README)', 'E85C5731': 'English (reference README)'}


def number(token):
    token = token.strip()
    if re.fullmatch(r'-?\d+', token):
        return int(token)
    if re.fullmatch(r'#[0-9a-fA-F]+', token):
        return int(token[1:], 16)
    if re.fullmatch(r'[0-9][0-9a-fA-F]*[hH]', token):
        return int(token[:-1], 16)
    if re.fullmatch(r'[01]+[bB]', token):
        return int(token[:-1], 2)
    raise ValueError('Unsupported literal: ' + token)


def data_segment(sources, base, constants=None):
    """Strict two-pass DB/DW+labels only. Reject all unknown syntax/expressions."""
    constants = constants or {}
    labels, locations, rows = {}, {}, []
    cursor = base
    for name, content in sources:
        for line_no, line in enumerate(content.splitlines(), 1):
            code = line.split(';', 1)[0].strip()
            if not code:
                continue
            match = re.match(r'^(\w+):\s*(.*)$', code)
            if match:
                label, code = match.groups()
                if label in labels:
                    raise ValueError('Duplicate label: ' + label)
                labels[label] = cursor
                locations[label] = {'file': name, 'line': line_no}
            if not code:
                continue
            match = re.fullmatch(r'(?i)(db|dw)\s+(.+)', code)
            if not match:
                raise ValueError(f'{name}:{line_no}: unsupported data syntax {code}')
            directive, values = match.groups()
            width = 1 if directive.lower() == 'db' else 2
            tokens = [v.strip() for v in values.split(',')]
            rows.append((width, tokens))
            cursor += width * len(tokens)
    result = bytearray()
    for width, tokens in rows:
        for token in tokens:
            value = labels[token] if token in labels else constants[token] if token in constants else number(token)
            if not -(1 << (width * 8 - 1)) <= value < (1 << (width * 8)):
                raise ValueError('Value out of range: ' + token)
            result.extend((value % (1 << (width * 8))).to_bytes(width, 'little'))
    return bytes(result), labels, locations


def literal_block(content, symbol):
    """Only consecutive DB literals after one label. Never skip unknown lines."""
    lines = content.splitlines()
    for start, line in enumerate(lines):
        match = re.match(r'^' + re.escape(symbol) + r':\s*(.*)', line)
        if match:
            selected = []
            for index in range(start, len(lines)):
                code = (match.group(1) if index == start else lines[index]).split(';', 1)[0].strip()
                if not code:
                    continue
                db = re.fullmatch(r'(?i)db\s+(.+)', code)
                if not db:
                    break
                selected.append(code)
            if not selected:
                raise ValueError('No literal DB block for ' + symbol)
            data, _, _ = data_segment([(symbol, '\n'.join(selected))], 0)
            return data, start + 1
    raise ValueError('Missing symbol ' + symbol)


def hits(data, needle):
    if not needle:
        raise ValueError('Empty signature')
    positions, start = [], 0
    while True:
        pos = data.find(needle, start)
        if pos < 0:
            return positions
        positions.append(pos)
        start = pos + 1


def bank_offset(bank, address, window, size):
    if window not in (0x4000, 0x6000, 0x8000, 0xA000) or bank < 0:
        raise ValueError('Invalid bank/window')
    if not window <= address < window + 0x2000:
        raise ValueError('CPU address outside window')
    offset = bank * 0x2000 + address - window
    if offset >= size:
        raise ValueError('Offset outside input')
    return offset


def ram_map(content):
    result, cursor = {}, None
    for line_no, line in enumerate(content.splitlines(), 1):
        code = line.split(';', 1)[0].strip()
        if not code:
            continue
        match = re.fullmatch(r'map\s+(\S+)', code, re.I)
        if match:
            cursor = number(match.group(1))
            continue
        match = re.fullmatch(r'(\w+):?\s*#\s*(\S+)', code)
        if not match or cursor is None:
            raise ValueError(f'Unsupported RAM declaration at line {line_no}: {code}')
        symbol, count = match.groups()
        size = number(count)
        result[symbol] = {'address': cursor, 'size': size, 'line': line_no}
        cursor += size
    return result


def expand_metatiles(room, definitions):
    """Exploratory single-room probe: 8x6 indices, 4x4 tiles, IDs start at 1."""
    if len(room) != 48 or len(definitions) % 16:
        raise ValueError('Invalid room/metatile size')
    output = bytearray(32 * 24)
    for index, tile_id in enumerate(room):
        if not 1 <= tile_id <= len(definitions) // 16:
            raise ValueError('Invalid metatile ID')
        for row in range(4):
            source = (tile_id - 1) * 16 + row * 4
            dest = ((index // 8) * 4 + row) * 32 + (index % 8) * 4
            output[dest:dest + 4] = definitions[source:source + 4]
    return bytes(output)


def run(inventory_all=False):
    revision = subprocess.check_output(['git', '-C', str(REFERENCE), 'rev-parse', 'HEAD'], text=True).strip()
    if revision != PINNED_REVISION:
        raise ValueError('Reference revision changed; review the documented layout first')
    if subprocess.check_output(['git', '-C', str(REFERENCE), 'diff', 'HEAD', '--', '*.asm'], text=True):
        raise ValueError('Reference assembly has local modifications')
    source_files = ['data/rooms.asm', 'data/metatiles.asm']
    sources = [(name, (REFERENCE / name).read_text()) for name in source_files]
    segment, labels, locations = data_segment(sources, 0x6000)
    # BanksDEF starts with rooms.asm followed immediately by metatiles.asm.
    expected_offset = bank_offset(13, 0x6000, 0x6000, 0x20000)
    probes = [('data/roomtileset.asm', 'RoomGfxSetIds'),
              ('data/roomsconnections.asm', 'RoomConnections'),
              ('logic/collisions.asm', 'BoxColliderDat'),
              ('data/rooms.asm', 'Room000')]
    probes.extend(('data/roomtileset.asm', symbol) for symbol in (
        'CollTilesBuilding', 'CollTilesBasem', 'CollTilesRoof', 'CollTilesElevator',
        'CollTilesLorry', 'CollTilesHindD', 'CollTilesMetalGear'))
    report = {'reference_commit': revision, 'method': 'strict literal data comparison; no Z80 execution',
              'segment': {'files': source_files, 'bytes': len(segment), 'expected_offset': expected_offset,
                          'sha256': hashlib.sha256(segment).hexdigest()},
              'roms': [], 'ram_symbols': ram_map((REFERENCE / 'Variables.asm').read_text())}
    from tools.rom import identify, load_profiles, resolve_canonical_rom
    profiles = load_profiles()
    if inventory_all:
        # Comparative inventory only; non-canonical entries are labelled, never used as inputs.
        inputs = sorted(p for p in (ROOT / 'roms').iterdir() if p.is_file() and p.suffix.lower() == '.rom')
    else:
        inputs = [resolve_canonical_rom().path]
    for p in inputs:
        data = p.read_bytes()
        crc = f'{zlib.crc32(data) & 0xffffffff:08X}'
        sha = hashlib.sha256(data).hexdigest()
        profile_id = identify(data, profiles)
        entry = {'file': str(p.relative_to(ROOT)), 'rom_profile': profile_id,
                 'canonical': profile_id == profiles['canonical'], 'size': len(data), 'crc32': crc,
                 'sha1': hashlib.sha1(data).hexdigest(), 'sha256': sha,
                 'checksum_match': EXPECTED.get(crc),
                 'ab_header_offsets_tested': [n for n in (0, 16, 512) if data[n:n+2] == b'AB'],
                 'entrypoint_le': int.from_bytes(data[2:4], 'little'),
                 'bank_size_candidate': 8192, 'full_banks': len(data) // 8192, 'remainder': len(data) % 8192,
                 'segment_matches': hits(data, segment),
                 'segment_diff_bytes_at_expected_offset': sum(a != b for a,b in zip(segment, data[expected_offset:expected_offset+len(segment)])) + max(0, expected_offset+len(segment)-len(data)),
                 'probes': [], 'banks_sha256': [hashlib.sha256(data[i:i+8192]).hexdigest() for i in range(0,len(data),8192)]}
        for name, symbol in probes:
            block, line = literal_block((REFERENCE / name).read_text(), symbol)
            entry['probes'].append({'file': name, 'symbol': symbol, 'line': line,
                                    'length': len(block), 'matches': hits(data, block),
                                    'sha256': hashlib.sha256(block).hexdigest()})
        if expected_offset in entry['segment_matches']:
            # Validate one room only, not an extractor. Save hash, no tile payload.
            room_off = expected_offset + labels['Room000'] - 0x6000
            meta_off = expected_offset + labels['Metatiles1'] - 0x6000
            meta_size = labels['Metatiles2'] - labels['Metatiles1']
            room = data[room_off:room_off+48]
            expanded = expand_metatiles(room, data[meta_off:meta_off+meta_size])
            entry['room000_probe'] = {'room_offset': room_off, 'metatile_set_offset': meta_off,
                                      'output_size': len(expanded), 'output_sha256': hashlib.sha256(expanded).hexdigest()}
        entry['original_unchanged'] = hashlib.sha256(p.read_bytes()).hexdigest() == sha
        entry['git_ignored'] = subprocess.run(['git','check-ignore','-q',str(p)], cwd=ROOT).returncode == 0
        report['roms'].append(entry)
    report['segment_symbols'] = {key: {'cpu_address_group_DEF': value, 'physical_offset': expected_offset + value - 0x6000, **locations[key]}
                                 for key,value in labels.items() if key in ('idxRooms','MetaTileSetIDs','idxMetatileSet','Room000','Room001','Metatiles1','Metatiles2','Metatiles3','Metatiles4','Metatiles5','Metatiles6')}
    report['room_index_entries'] = (labels['MetaTileSetIDs'] - labels['idxRooms']) // 2
    report['room_definition_count'] = len([label for label in labels if re.fullmatch(r'Room\d+',label)])
    report['source_hashes'] = {str(p.relative_to(REFERENCE)): hashlib.sha256(p.read_bytes()).hexdigest()
                               for p in sorted(REFERENCE.rglob('*.asm'))}
    report['include_edges'] = []
    report['symbols'] = []
    for p in sorted(REFERENCE.rglob('*.asm')):
        for line_no, line in enumerate(p.read_text(encoding='latin-1').splitlines(), 1):
            code = line.split(';', 1)[0].strip()
            inc = re.match(r'include\s+"([^"]+)"', code, re.I)
            if inc:
                candidates = [p.parent / inc.group(1), REFERENCE / inc.group(1)]
                target = next((v for v in candidates if v.is_file()), None)
                report['include_edges'].append({'file': str(p.relative_to(REFERENCE)), 'line': line_no,
                    'target': str(target.relative_to(REFERENCE)) if target else None,
                    'note': 'lexical inventory; conditional branches not evaluated'})
            label = re.match(r'^(\w+):', code)
            if label:
                report['symbols'].append({'symbol': label.group(1), 'file': str(p.relative_to(REFERENCE)), 'line': line_no})
    report['source_file_count'] = len(report['source_hashes'])
    target = ROOT / 'reports/reverse-engineering.json'
    target.parent.mkdir(exist_ok=True)
    target.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k:v for k,v in report.items() if k not in ('ram_symbols','source_hashes','symbols','include_edges')}, indent=2))

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Lexical inventory and canonical ROM comparison; read-only.')
    parser.add_argument('--inventory-all', action='store_true',
                        help='Also inventory every .rom in roms/ (labelled by profile; not extraction inputs)')
    run(parser.parse_args().inventory_all)
