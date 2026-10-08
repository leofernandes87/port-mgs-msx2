"""Radio dialogue tables and English radio texts from the canonical ROM.

Run: python3 -m tools.extractors.extract_radio_dialogue
Output (private, ignored): data/extracted/en-eu-rc750/radio/radio_dialogue.json

Evidence:
  UpdateRadio and RadioFreqs (Banks0123.asm:2379-2461): idxRoomRadio entries, person ID -> frequency,
  flags (byte >> 2) & 3 with bit 0 = wait call (RADIO_WAITCALL 4) and bit 1 = auto tune (RADIO_AUTOREPLY 8);
  data/radiocalls.asm (English, BanksDEF.asm:24); constants/Enums.asm:15-36;
  RoomsMusic bit 3 = incoming call and idxMapZones nibbles (data/musicradioconfig.asm, BanksABC.asm:22;
  ChkRadioCalls Banks0123.asm:1688-1745, SetRadioArea 1060-1068, GetNibbleRoom 847-874);
  idxTexts[TextId - 1] (Banks0123.asm:5280-5283) decoded like DecodeText (5305-5391).
The ROM is opened read-only; every source segment is compared byte for byte.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from tools.extractors.extract_grey_fox_dialogue import decode_pages, locate_texts_segment
from tools.extractors.reference import load_reference
from tools.reverse_engineering.analyze import data_segment, hits, number
from tools.rom import canonical_data_dir, resolve_canonical_rom

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = canonical_data_dir() / 'radio'
GROUP_DEF = 0x1A000                  # BanksDEF.asm (UpdateRadio calls SetBanks_D_E_F)
GROUP_ABC = 0x14000                  # BanksABC.asm (SetRadioArea/SetAreaMusic call SetBanks_A_B_C)
TEXT_SEND = 0x0A                     # SetRadioSend (Banks0123.asm:10759-10771)
TEXT_BUG_WARNING = 50                # ChkReplyBigBoss4 (Banks0123.asm:11088-11106)
TEXT_SWITCH_OFF = 136                # ChkReplyBigBoss2 (Banks0123.asm:11071-11081)
PERSON_COUNT = 7                     # RadioFreqs (Banks0123.asm:2455-2461)

# Raw DrawChar code -> ASCII cell of the existing msx_font atlas
# (extract_transceiver_sprites.generate_msx_font: tile = code - 30h).
CHAR_MAP = {0x00: ' ', 0x3A: '@', 0x3B: '*', 0x3C: '>', 0x3D: '!', 0x3E: '"', 0x40: '-',
            0x5B: '?', 0x5C: '.', 0x5F: ',', 0x97: "'"}
CHAR_MAP.update({c: chr(c) for c in range(0x30, 0x3A)})
CHAR_MAP.update({c: chr(c) for c in range(0x41, 0x5B)})

# Reviewed Z80 signatures (RAM addresses from Variables.asm) for the timings ported to Godot.
CODE_SIGNATURES = {
    # ChkIncomingCall: delay countdown, 58h call duration, flag 1 -> 2 (logic/incomingcall.asm:10-36)
    'ChkIncomingCall': '2160C1 7E A7 C8 3A5FC1 FE02 C8 3D 2809 35 C0 3658 3E01 325FC1 35 C0 3E02 325FC1 C9',
    # ChkRadioCalls4: (RoomsMusic & 8) * 4 = 32 ticks of delay (Banks0123.asm:1734-1741)
    'ChkRadioCalls4': '7E E608 0E02 2807 87 87 3260C1 0E00',
    # RadioSignalUp: one more led every 2 ticks (Banks0123.asm:10780-10790)
    'RadioSignalUp': '2102C8 35 C0 3602 2101C8 34',
    # RadioAutoReply2 tail: status 2 and 10h ticks before the first led (Banks0123.asm:11034-11039)
    'RadioAutoReplyLeds': '3602 3E10 3202C8 C9',
    # ChgRadioFreq2: clear AutoReplyDone/ReplyRequested, 8 ticks before repeat (Banks0123.asm:10921-10927)
    'ChgRadioFreqPress': '2105C8 3600 23 3600 215CC1 3608',
    # ChgRadioFreq hold repeat every 2 ticks (Banks0123.asm:10912-10917)
    'ChgRadioFreqHold': '215CC1 35 C0 3602',
}


def english_source(constants: dict):
    """Keep the ELSE branch of IF (JAPANESE) (JAPANESE equ 0) and fold A | B constant expressions."""
    def resolve(token: str) -> str:
        parts = [p.strip() for p in token.split('|')]
        value = 0
        for part in parts:
            value |= constants[part] if part in constants else number(part)
        return str(value)

    def transform(_file: str, text: str) -> str:
        out, state = [], None
        for line in text.splitlines():
            code = line.split(';', 1)[0].strip().upper()
            if code in ('IF (JAPANESE)', 'IF JAPANESE'):
                state = 'jp'
                out.append('')
                continue
            if state and code == 'ELSE':
                state = 'en'
                out.append('')
                continue
            if state and code == 'ENDIF':
                state = None
                out.append('')
                continue
            if state == 'jp':
                out.append('')
                continue
            match = re.match(r'^(\s*(?:\w+:)?\s*(?:db|dw)\s+)([^;]*)(;.*)?$', line, re.I)
            if match and '|' in match[2]:
                tokens = [resolve(t) if '|' in t else t.strip() for t in match[2].split(',')]
                line = match[1] + ', '.join(tokens)
            out.append(line)
        return '\n'.join(out)
    return transform


def parse_room(rom: bytes, offset: int, freqs: list[int]) -> list[dict]:
    """UpdateRadio: 0 = nobody; else 2-byte records until bit 0 of byte 0 is set."""
    persons = []
    if rom[offset] == 0:
        return persons
    while True:
        flags_byte, text_id = rom[offset], rom[offset + 1]
        person = flags_byte >> 4
        if not 1 <= person <= PERSON_COUNT:
            raise ValueError(f'Invalid radio person {person} at {offset:#x}')
        flags = (flags_byte >> 2) & 3
        persons.append({'person': person, 'freq': freqs[person - 1], 'wait_call': bool(flags & 1),
                        'auto_tune': bool(flags & 2), 'text_id': text_id})
        if flags_byte & 1:
            return persons
        offset += 2


def map_zone(table: bytes, room: int) -> int:
    """GetNibbleHL_A2: even rooms use the high nibble, odd rooms the low nibble."""
    value = table[room >> 1]
    return value & 0x0F if room & 1 else value >> 4


def text_lines(pages: list[list[int]]) -> list[list[str]]:
    result = []
    for page in pages:
        lines, current = [], []
        for code in page:
            if code == 0xFE:
                lines.append(''.join(current))
                current = []
                continue
            if code not in CHAR_MAP:
                raise ValueError(f'Unsupported character code {code:#x}')
            current.append(CHAR_MAP[code])
        lines.append(''.join(current))
        result.append(lines)
    return result


def _labels(source: str, symbol: str) -> list[str]:
    lines = source.splitlines()
    start = next(i for i, line in enumerate(lines) if line.startswith(symbol + ':'))
    labels = []
    for index, line in enumerate(lines[start:]):
        code = (line.split(':', 1)[1] if index == 0 else line).split(';', 1)[0].strip()
        match = re.fullmatch(r'(?i)dw\s+(.+)', code)
        if not match:
            if labels:
                break
            continue
        labels.extend(t.strip() for t in match[1].split(','))
    return labels


def extract(rom: bytes, reference: Path) -> dict:
    ref = load_reference(reference, rom)
    transform = english_source(ref.constants)
    ref.add(['data/radiocalls.asm'], GROUP_DEF, transform=transform)
    ref.add(['data/musicradioconfig.asm'], GROUP_ABC, transform=transform)

    numeric = re.sub(r'"([^"\n]*)"', lambda m: ','.join(str(ord(c)) for c in m[1]), ref.read('data/texts.asm'))
    segment, text_symbols, _ = data_segment([('data/texts.asm', numeric)], 0)
    texts_start, _, _ = locate_texts_segment(rom, numeric, text_symbols, segment, text_symbols['txtGrayFox'])
    ref.add(['data/texts.asm'], GROUP_ABC, texts_start, transform=lambda _f, _t: numeric)
    sym = ref.symbols

    freqs = [ref.constants[name] for name in ('FREQ_BIGBOSS', 'FREQ_SCHNEIDER', 'FREQ_DIANE',
             'FREQ_SCHNEIDER_BUILDING2', 'FREQ_DIANE_BUILDING2', 'FREQ_JENIFFER', 'FREQ_BIGBOSS_BUILDING2')]
    freq_hits = hits(rom, bytes(freqs))
    if len(freq_hits) != 1:
        raise ValueError(f'RadioFreqs must occur exactly once; found {len(freq_hits)}')

    signatures = {}
    for name, text in CODE_SIGNATURES.items():
        found = hits(rom, bytes.fromhex(text.replace(' ', '')))
        if len(found) != 1:
            raise ValueError(f'Code signature {name} must occur exactly once; found {len(found)}')
        signatures[name] = {'rom_offset': found[0], 'status': 'binary_verified'}

    room_labels = _labels(ref.read('data/radiocalls.asm'), 'idxRoomRadio')
    rooms = []
    for room in range(len(room_labels)):
        pointer = int.from_bytes(rom[sym['idxRoomRadio'] + room * 2:sym['idxRoomRadio'] + room * 2 + 2], 'little')
        if pointer != ref.locations[room_labels[room]]['cpu_address']:
            raise ValueError(f'idxRoomRadio[{room}] does not point to {room_labels[room]}')
        rooms.append(parse_room(rom, GROUP_DEF + pointer - 0x6000, freqs))

    music = rom[sym['RoomsMusic']:sym['RoomsMusic'] + 256]
    zones_length = len(_zone_bytes(ref.read('data/musicradioconfig.asm')))
    zones = rom[sym['idxMapZones']:sym['idxMapZones'] + zones_length]

    text_ids = sorted({p['text_id'] for persons in rooms for p in persons} |
                      {TEXT_SEND, TEXT_BUG_WARNING, TEXT_SWITCH_OFF})
    texts = {}
    for text_id in text_ids:
        pointer = int.from_bytes(rom[sym['idxTexts'] + (text_id - 1) * 2:sym['idxTexts'] + text_id * 2], 'little')
        offset = texts_start + pointer - (0x6000 + texts_start - GROUP_ABC)
        end = rom.index(0xFF, offset)
        dictionary = {}
        for code in set(rom[offset + 1:end + 1]) - {0xFD, 0xFE, 0xFF}:
            if code >= 0xA1:
                entry = int.from_bytes(rom[sym['idxDictionary'] + (code - 0xA1) * 2:
                                           sym['idxDictionary'] + (code - 0xA1) * 2 + 2], 'little')
                start = texts_start + entry - (0x6000 + texts_start - GROUP_ABC)
                dictionary[code] = rom[start:rom.index(0xFF, start) + 1]
        pages = decode_pages(rom[offset + 1:end + 1], dictionary)
        texts[str(text_id)] = {'box_type': rom[offset], 'pages': text_lines(pages)}

    return {
        'format_version': '1.0.0',
        'room_count': len(rooms),
        'rooms': rooms,
        'incoming_call_rooms': [r for r in range(256) if music[r] & 0x08],
        'map_zones': [map_zone(zones, r) for r in range(2 * len(zones))],
        'radio_freqs': freqs,
        'texts': texts,
        'special_text_ids': {'send': TEXT_SEND, 'bug_warning': TEXT_BUG_WARNING, 'switch_off_msx': TEXT_SWITCH_OFF},
        'code_signatures': signatures,
        'evidence': [ref.evidence(s, n) for s, n in [
            ('idxRoomRadio', 2 * len(rooms)), ('RoomsMusic', 256), ('idxMapZones', len(zones)),
            ('idxTexts', 2 * max(text_ids)), ('idxDictionary', 2)]] +
            [{'symbol': 'RadioFreqs', 'file': 'Banks0123.asm', 'line': 2455, 'rom_offset': freq_hits[0],
              'length': len(freqs), 'status': 'binary_verified'}],
    }


def _zone_bytes(source: str) -> list[str]:
    lines = source.splitlines()
    start = next(i for i, line in enumerate(lines) if line.startswith('idxMapZones:'))
    values = []
    for index, line in enumerate(lines[start:]):
        code = (line.split(':', 1)[1] if index == 0 else line).split(';', 1)[0].strip()
        match = re.fullmatch(r'(?i)db\s+(.+)', code)
        if not match:
            break
        values.extend(match[1].split(','))
    return values


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--rom', type=Path, help='Explicit ROM; validated against the canonical hash')
    parser.add_argument('--reference', type=Path, default=ROOT / 'external/MetalGear')
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    if (ROOT / 'data/extracted').resolve() not in args.output.resolve().parents:
        raise ValueError('Output must be under private data/extracted')
    canonical = resolve_canonical_rom(args.rom)
    data = extract(canonical.data, args.reference)
    data.update(canonical.provenance())
    canonical.assert_unchanged()
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / 'radio_dialogue.json').write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n',
                                                     encoding='utf-8')
    with_calls = sum(1 for persons in data['rooms'] if persons)
    print(f'RADIO_DIALOGUE_EXTRACT_OK: {with_calls} salas com rádio, {len(data["texts"])} textos em {args.output}')


if __name__ == '__main__':
    main()
