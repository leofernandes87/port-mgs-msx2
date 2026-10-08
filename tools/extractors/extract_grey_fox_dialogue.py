"""English text 59 from the pinned disassembly, verified byte for byte in the canonical ROM.

Run: python3 -m tools.extractors.extract_grey_fox_dialogue
The whole data/texts.asm segment (with its pointers relocated to the base found in the
ROM) and the English font must match the canonical ROM. Protected text/font output
stays local. The ROM is opened read-only.
Evidence: prisoner.asm:244-277; texts.asm:64,290-302;
Banks0123.asm:5305-5391 (dictionary and FD/FE/FF), 8024-8033 (widths).
"""
from pathlib import Path
import hashlib
import json
import re

from tools.extractors.reference import Reference
from tools.rom import canonical_data_dir, resolve_canonical_rom
from tools.extractors.extract_transceiver_sprites import parse_asm_symbols, generate_msx_font
from tools.reverse_engineering.analyze import data_segment, PINNED_REVISION

ROOT = Path(__file__).resolve().parents[2]


def decode_pages(encoded, dictionary):
    """Preserve explicit page/line breaks; dictionary entries are not recursive."""
    pages = [[]]
    for index, code in enumerate(encoded):
        if code == 0xFF:
            if index != len(encoded) - 1:
                raise ValueError('Bytes after end of message')
            return pages
        if code == 0xFD:
            pages.append([])
        elif code == 0xFE or code < 0xA1:
            pages[-1].append(code)
        else:
            if code not in dictionary:
                raise ValueError('Missing dictionary entry')
            entry = dictionary[code]
            if not entry or entry[-1] != 0xFF or 0xFF in entry[:-1]:
                raise ValueError('Invalid dictionary terminator')
            pages[-1].extend(entry[:-1])
    raise ValueError('Missing message terminator')


def locate_texts_segment(rom_data, numeric_source, symbols, segment, message_offset):
    """Find the ROM copy of texts.asm via text 59 and require every byte to match after relocation."""
    message = segment[message_offset:segment.index(0xFF, message_offset) + 1]
    hits = [i for i in range(len(rom_data)) if rom_data.startswith(message, i)]
    if len(hits) != 1:
        raise ValueError(f'Text 59 must occur exactly once in the ROM (found {len(hits)})')
    start = hits[0] - message_offset
    pointer = start + symbols['idxTexts'] + (59 - 1) * 2
    base = int.from_bytes(rom_data[pointer:pointer + 2], 'little') - message_offset
    relocated, _, _ = data_segment([('data/texts.asm', numeric_source)], base)
    if rom_data[start:start + len(relocated)] != relocated:
        raise ValueError('data/texts.asm differs from the canonical ROM')
    return start, base, len(relocated)


def glyph_cell(code):
    """Raw DrawChar code -> existing ASCII atlas cell, not a prose translation."""
    if 0x30 <= code <= 0x39 or 0x41 <= code <= 0x5A:
        return code
    return {0: 32, 0x3F: 35, 0x5C: 46, 0x5F: 44, 0x97: 96}[code]


def export():
    reference = ROOT / 'external/MetalGear'
    rom = resolve_canonical_rom()
    ref = Reference(reference, rom.data)  # Checks pinned revision and unmodified assembly.
    source = ref.read('data/texts.asm')
    numeric = re.sub(r'"([^"\n]*)"', lambda m: ','.join(str(ord(c)) for c in m[1]), source)
    segment, symbols, _ = data_segment([('data/texts.asm', numeric)], 0)
    # These are offsets in a source-data segment, never guessed CPU/ROM addresses.
    pointer = symbols['idxTexts'] + (59 - 1) * 2
    offset = int.from_bytes(segment[pointer:pointer + 2], 'little')
    if offset != symbols['txtGrayFox'] or segment[offset] != 0x11:
        raise ValueError('Reviewed English message changed')
    encoded = segment[offset + 1:segment.index(0xFF, offset) + 1]
    dictionary = {}
    for code in set(encoded) - {0xFD, 0xFE, 0xFF}:
        if code >= 0xA1:
            pointer = symbols['idxDictionary'] + (code - 0xA1) * 2
            start = int.from_bytes(segment[pointer:pointer + 2], 'little')
            dictionary[code] = segment[start:segment.index(0xFF, start) + 1]
    pages = decode_pages(encoded, dictionary)
    texts_start, texts_base, texts_length = locate_texts_segment(rom.data, numeric, symbols, segment, offset)
    font_symbols = parse_asm_symbols(str(reference / 'gfx/font.asm'))
    font = font_symbols['gfxFont'] + font_symbols['gfxSymbChars']
    if len(font) != 108 * 8:
        raise ValueError('Reviewed font size changed')
    font_hits = [i for i in range(len(rom.data)) if rom.data.startswith(bytes(font), i)]
    if len(font_hits) != 1:
        raise ValueError('English font must occur exactly once in the canonical ROM')
    glyphs = {}
    for code in set(sum(pages, [])) | {0x3F}:
        if code == 0xFE:
            continue
        cell = glyph_cell(code)  # Reject unsupported codes instead of substituting glyphs.
        glyphs[str(code)] = {'atlas_cell': cell, 'rows': [0] * 8 if code == 0 else font[(code - 0x30) * 8:(code - 0x30 + 1) * 8]}
    font_path = ROOT / 'godot/assets/protected/sprites/transceiver/msx_font.png'
    generate_msx_font(font_symbols, str(font_path))
    payload = {'schema': 'msx-english-dialogue-1', 'text_id': 59, 'box_type': 0x11,
               'provenance': 'pinned_disassembly_english_verified_in_canonical_rom',
               **rom.provenance(),
               'rom_evidence': {'texts_rom_offset': f'0x{texts_start:05X}', 'texts_cpu_base': f'0x{texts_base:04X}',
                                'texts_length': texts_length, 'font_rom_offset': f'0x{font_hits[0]:05X}'},
               'reference_commit': PINNED_REVISION,
               'source_sha256': hashlib.sha256((reference / 'data/texts.asm').read_bytes()).hexdigest(),
               'font_sha256': hashlib.sha256(font_path.read_bytes()).hexdigest(),
               'pages': pages, 'glyphs': glyphs}
    rom.assert_unchanged()
    output = canonical_data_dir() / 'dialogues/grey-fox-en.json'
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, indent=2) + '\n')
    print(f'{output.relative_to(ROOT)}: {len(pages)} pages; texts.asm and font identical in the canonical ROM')


if __name__ == '__main__':
    export()
