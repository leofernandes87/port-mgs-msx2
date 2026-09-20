"""Restricted, verified source-data locator. Does not assemble Z80 instructions."""
from pathlib import Path
import hashlib
import re
import subprocess
from tools.reverse_engineering.analyze import data_segment, hits, number, literal_block, PINNED_REVISION


class Reference:
    def __init__(self, path: Path, rom: bytes):
        self.path, self.rom = path, rom
        revision = subprocess.check_output(['git', '-C', str(path), 'rev-parse', 'HEAD'], text=True).strip()
        if revision != PINNED_REVISION:
            raise ValueError('Reference revision differs from reviewed commit')
        if subprocess.check_output(['git', '-C', str(path), 'diff', 'HEAD', '--', '*.asm'], text=True):
            raise ValueError('Reference assembly modified')
        self.symbols, self.locations, self.segments = {}, {}, []
        self.constants = {}
        for line in self.read('constants/Enums.asm').splitlines():
            code = line.split(';')[0].strip()
            if not code:
                continue
            m = re.fullmatch(r'(\w+):?\s+equ\s+(\S+)', code, re.I)
            if not m:
                raise ValueError('Unsupported enum: ' + code)
            self.constants[m[1]] = number(m[2])

    def read(self, file):
        return (self.path / file).read_text(encoding='latin-1')

    def add(self, files, group, offset=None):
        """group physical base maps CPU 6000..BFFF. Verify entire segment."""
        sources = [(f, self.read(f)) for f in files]
        if offset is None:
            prototype, _, _ = data_segment(sources, 0, self.constants)
            # Call sites use data-only leading blocks. Full reassembly below
            # confirms all pointers; this signature alone is never enough.
            found = hits(self.rom, prototype[:32])
            if len(found) != 1:
                raise ValueError(f'Nonunique source anchor {files}: {found}')
            offset = found[0]
        base = 0x6000 + offset - group
        payload, symbols, locations = data_segment(sources, base, self.constants)
        if not group <= offset or offset + len(payload) > group + 0x6000:
            raise ValueError('Source segment crosses its bank group')
        if self.rom[offset:offset+len(payload)] != payload:
            raise ValueError(f'Binary mismatch: {files} at {offset:#x}')
        for key, cpu in symbols.items():
            if key in self.symbols:
                raise ValueError('Duplicate imported symbol ' + key)
            self.symbols[key] = offset + cpu - base
            self.locations[key] = {**locations[key], 'cpu_address': cpu,
                                   'rom_offset': offset + cpu - base,
                                   'bank': (offset + cpu - base) // 8192}
        self.segments.append({'files': files, 'offset': offset, 'length': len(payload),
                              'sha256': hashlib.sha256(payload).hexdigest()})
        return offset + len(payload)

    def literal(self, file, symbol):
        payload, line = literal_block(self.read(file), symbol)
        found = hits(self.rom, payload)
        if len(found) != 1:
            raise ValueError('Ambiguous literal block: ' + symbol)
        offset = found[0]
        self.symbols[symbol] = offset
        self.locations[symbol] = {'file': file, 'line': line,
            'rom_offset': offset, 'cpu_address': offset + 0x4000,
            'bank': offset // 8192}
        self.segments.append({'files': [file], 'offset': offset, 'length': len(payload),
            'sha256': hashlib.sha256(payload).hexdigest()})
        return payload

    def evidence(self, symbol, length):
        return {**self.locations[symbol], 'symbol': symbol, 'length': length,
                'status': 'binary_verified'}

    def source_hashes(self):
        files = {'constants/Enums.asm', 'Banks0123.asm', 'Banks789.asm', 'BanksDEF.asm', 'logic/addroomitems.asm'}
        files.update(f for segment in self.segments for f in segment['files'])
        return {f: hashlib.sha256((self.path / f).read_bytes()).hexdigest() for f in sorted(files)}


def load_reference(path, rom):
    ref = Reference(path, rom)
    end = ref.add(['data/rooms.asm', 'data/metatiles.asm', 'data/doors.asm', 'gfx/powerswitch.asm'], 0x1A000, 0x1A000)
    graphics = re.findall(r'include\s+"([^"]+)"', ref.read('Banks789.asm').split('include\t"logic/elevatorroom.asm"')[0], re.I)
    if not graphics or any(f.startswith('logic/') for f in graphics):
        raise ValueError('Graphics include boundary changed')
    ref.add(graphics, 0xE000, 0xE000)
    for file in ['data/palettes.asm', 'data/roomsconnections.asm', 'data/actorsinrooms.asm', 'data/paths.asm', 'data/itemsinrooms.asm']:
        ref.add([file], 0x8000)
    return ref
