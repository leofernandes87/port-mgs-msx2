"""Extract the Rolling Barrel actor (ID_ROLLING_BARREL = 0Fh) from the canonical ROM.

Every table is located as a binary-verified source segment (never by fixed offset):
- sprites: SprSetRolBarrel/SprRollingBarrel (data/spritesets.asm:183-185, gfx/sprites.asm:837),
  RollBarrels1/2 (data/actorspriteattr.asm:361-372), SprOffsets7 (data/actorspriteattr.asm:593-610),
  ActorSprColors3 (data/actorspriteattr.asm:87), SprsetPal19 (data/palettes.asm:284-286);
- actor tables indexed by ID-1: NumSprEnemies, idxActorLife (data/actorspriteattr.asm:6,127),
  ActorShapeProject/ActorShapeExpl/ActorsShapeTouch/ActorTouchDamage/ImpactAreasInfo
  (data/shapes.asm), weapon damage (data/weapondamage.asm:4-62);
- behaviour constants: reviewed Z80 signatures of logic/actors/rollingbarrels.asm, each unique.

Outputs (private, under data/extracted/<canonical>/rolling-barrel/): rolling_barrel.json and one
indexed PNG per room (two 16x144 frames side by side). Inputs are opened read-only.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tools.extractors.batch_snapshots import build_palette
from tools.extractors.codecs import png_indexed, rgb_palette, unpack_gfx
from tools.extractors.extract import build
from tools.extractors.reference import load_reference
from tools.reverse_engineering.analyze import data_segment, hits, literal_block
from tools.rom import canonical_data_dir, resolve_canonical_rom

ACTOR_ID = 0x0F
# data/actorsinrooms.asm:860-866; idxActorsRooms reuses ActorsRoom141 for rooms 153 and 191
# (actorsinrooms.asm:1167, 1179, 1217, 1231; indexed by Room in Banks0123.asm:6141-6147).
ROOMS = (141, 153, 191, 205)
SPRITESET_ID = 19                   # SpritesetRooms[room] for every room above
SPRITE_IDS = (0x36, 0x37)           # InitRollingBarrel + Anim2FramesActor (xor 1)
FRAME_SYMBOLS = ('RollBarrels1', 'RollBarrels2')
COMMON_OFFSETS_FIRST = 0x91         # UpdateActorSprDat: 91h..A5h select idxSprOffsets
WEAPONS = ('HAND_GUN', 'SMG', 'GRENADE_LAUNCHER', 'ROCKET_LAUNCHER', 'PLASTIC_BOMB', 'LAND_MINE', 'MISSILE')
WEAPON_TABLES = ('BulletDamage', 'BulletDamage', 'GrenadeDamage', 'RocketDamage',
                 'PlasBombDamage', 'MineDamage', 'MissileDamage')

# Hand-assembled from logic/actors/rollingbarrels.asm and required to occur exactly once.
CODE_SIGNATURES = {
    # 14-16: ld a,(ix+Status); dec a; jr nz,RB_IncrementSpeed; 20-21: ld a,(ix+START_X); cp 80h
    'RollingBarrelLogic': bytes.fromhex('DD7E01 3D 2035 DD7E13 FE80'.replace(' ', '')),
    # 64-73: Direction>>1 carry selects -8 / +8
    'RB_IncrementSpeed': bytes.fromhex('DD7E11 1F 11F8FF 3003 110800 C3'.replace(' ', '')),
    # 82-104: X>=200 -> X=199, DIR_DOWN, -80h; X<56 -> X=57, DIR_LEFT, +80h
    'ChkBarrelBounce': bytes.fromhex('DD7E05 26C8 4C 25 B9 1180FF 0602 300B 2638 4C 24 B9 D0 0603 118000 '
                                     'DD7405 DD7011 CD'.replace(' ', '')),
    # 106: SFX 1Dh
    'ChkBarrelBounceSfx': bytes.fromhex('3E1D C3'.replace(' ', '')),
    # 121-125: PlayerX < 80h keeps +80h, else -80h
    'InitRollingBarrelSpeed': bytes.fromhex('FE80 3803 1180FF CD'.replace(' ', '')),
    # 130-132: inc (ix+MOVING); ld (ix+SpriteId),36h; ret
    'InitRollingBarrelEnd': bytes.fromhex('DD3406 DD360B36 C9'.replace(' ', '')),
}
BEHAVIOUR = {
    'right_limit_x': 200, 'right_reset_x': 199, 'left_limit_x': 56, 'left_reset_x': 57,
    'bounce_speed_x': 0x80, 'initial_speed_x': 0x80, 'player_x_split': 0x80,
    'acceleration_x': 8, 'anim_mask': 3, 'bounce_sfx': 0x1D,
    'dir_after_right_bounce': 2, 'dir_after_left_bounce': 3,
}

DEFAULT_OUTPUT = canonical_data_dir() / 'rolling-barrel'


def decode_patterns(stream: bytes, pattern_count: int) -> list[bytes]:
    """UnpackGfx2 stream without address prefix (LoadRoomSpr3 sets the VRAM address)."""
    chunks, _ = unpack_gfx(bytes(2) + bytes(stream), 0)
    if len(chunks) != 1 or len(chunks[0][1]) != pattern_count * 32:
        raise ValueError('Sprite stream does not decode to one contiguous pattern block')
    data = chunks[0][1]
    return [data[i * 32:(i + 1) * 32] for i in range(pattern_count)]


def parse_frame(frame: bytes, offsets_index: list[bytes], sprite_count: int) -> tuple[list[int], list[tuple[int, int]]]:
    """Frame = first byte 91h..A5h (shared offsets) followed by pattern numbers (UpdateActorSprDat)."""
    selector = frame[0] - COMMON_OFFSETS_FIRST
    if not 0 <= selector < len(offsets_index):
        raise ValueError('Frame does not use shared sprite offsets')
    patterns = list(frame[1:1 + sprite_count])
    raw = offsets_index[selector]
    if len(patterns) != sprite_count or len(raw) < sprite_count * 2:
        raise ValueError('Frame/offset table shorter than NumSprEnemies')
    signed = lambda b: b - 256 if b > 127 else b
    # UpdateActorSpr6 adds offsets with 8-bit wrap; Y is unwrapped relative to the first sprite so a
    # column such as SprOffsets7 (00h..80h) stays contiguous instead of folding 80h to -128.
    y0 = signed(raw[0])
    return patterns, [(y0 + ((raw[i * 2] - raw[0]) & 0xFF), signed(raw[i * 2 + 1])) for i in range(sprite_count)]


def compose_frame(patterns: list[bytes], pattern_base: int, frame_patterns: list[int],
                  offsets: list[tuple[int, int]], colors: list[int]) -> dict:
    """Sprite mode 2 composition: lower plane wins; CC (bit 6) ORs into the pixel below it."""
    min_x = min(dx for _, dx in offsets)
    min_y = min(dy for dy, _ in offsets)
    width = max(dx for _, dx in offsets) + 16 - min_x
    height = max(dy for dy, _ in offsets) + 16 - min_y
    pixels = [0] * (width * height)
    for number, (dy, dx), attr in zip(frame_patterns, offsets, colors):
        index, rest = divmod(number - pattern_base, 4)
        if rest or not 0 <= index < len(patterns):
            raise ValueError(f'Pattern {number:#x} outside loaded spriteset')
        pattern, color, cc = patterns[index], attr & 0x0F, bool(attr & 0x40)
        for y in range(16):
            for x in range(16):
                byte = pattern[y + (16 if x >= 8 else 0)]
                if not (byte >> (7 - (x & 7))) & 1:
                    continue
                at = (dy - min_y + y) * width + (dx - min_x + x)
                if cc:
                    pixels[at] = pixels[at] | color
                elif pixels[at] == 0:
                    pixels[at] = color
    return {'width': width, 'height': height, 'origin': [-min_x, -min_y], 'pixels': pixels}


def sprite_palette(room_palette: list[list[int]], sprset: bytes) -> list[list[int]]:
    """SetSprPal runs after SetRoomPal (Banks0123.asm:12553-12554): SprsetPal entries overwrite colours."""
    palette = [list(c) for c in room_palette[:16]]
    i = 0
    while sprset[i] != 0xFF:
        palette[sprset[i]] = rgb_palette([[sprset[i + 1], sprset[i + 2]]])[0]
        i += 3
    return palette


def side_by_side(frames: list[dict]) -> tuple[int, int, list[int]]:
    w, h = frames[0]['width'], frames[0]['height']
    if any((f['width'], f['height'], f['origin']) != (w, h, frames[0]['origin']) for f in frames):
        raise ValueError('Frames must share size and origin')
    pixels = [0] * (w * len(frames) * h)
    for n, frame in enumerate(frames):
        for y in range(h):
            pixels[y * w * len(frames) + n * w:y * w * len(frames) + (n + 1) * w] = frame['pixels'][y * w:(y + 1) * w]
    return w * len(frames), h, pixels


def area(raw: bytes) -> dict:
    s = [b - 256 if b > 127 else b for b in raw]
    return {'offset_y': s[0], 'radius_y': raw[1], 'offset_x': s[2], 'radius_x': raw[3]}


def _dw_labels(source: str, symbol: str) -> list[str]:
    lines = source.splitlines()
    start = next(i for i, line in enumerate(lines) if line.startswith(symbol + ':'))
    labels = []
    for index, line in enumerate(lines[start:]):
        code = (line.split(':', 1)[1] if index == 0 else line).split(';', 1)[0].strip()
        if not code:
            if labels:
                break
            continue
        match = re.fullmatch(r'(?i)dw\s+(\w+)', code)
        if not match:
            break
        labels.append(match[1])
    return labels


def _add_anchored(ref, rom: bytes, files: list[str], group: int, anchor_file: str, anchor: str) -> None:
    """Segments starting with DW pointers are anchored on one unique literal block inside them."""
    payload, _ = literal_block(ref.read(anchor_file), anchor)
    found = hits(rom, payload)
    if len(found) != 1:
        raise ValueError(f'Anchor {anchor} must occur exactly once; found {len(found)}')
    _, symbols, _ = data_segment([(f, ref.read(f)) for f in files], 0x6000, ref.constants)
    ref.add(files, group, found[0] - (symbols[anchor] - 0x6000))


def extract(rom: bytes, reference: Path, package: dict) -> tuple[dict, dict]:
    ref = load_reference(reference, rom)
    _add_anchored(ref, rom, ['data/weapondamage.asm', 'data/shapes.asm'], 0x8000,
                  'data/weapondamage.asm', 'BulletDamage')
    _add_anchored(ref, rom, ['data/actorspriteattr.asm'], 0x8000, 'data/actorspriteattr.asm', 'NumSprEnemies')
    _add_anchored(ref, rom, ['data/spritesets.asm', 'data/weaponspratt.asm', 'gfx/sprites.asm'], 0x14000,
                  'gfx/sprites.asm', 'SprRollingBarrel')
    sym = ref.symbols
    at = lambda name, index=0: rom[sym[name] + index]
    idx = ACTOR_ID - 1

    rooms_set = [at('SpritesetRooms', r) for r in ROOMS]
    if rooms_set != [SPRITESET_ID] * len(ROOMS):
        raise ValueError(f'Unexpected spritesets for rooms {ROOMS}: {rooms_set}')
    spriteset = rom[sym['SprSetRolBarrel']:sym['SprSetRolBarrel'] + 4]
    sprite_cpu = ref.locations['SprRollingBarrel']['cpu_address']
    if spriteset != bytes([spriteset[0], sprite_cpu & 0xFF, sprite_cpu >> 8, 0xFF]):
        raise ValueError('SprSetRolBarrel does not load SprRollingBarrel alone')
    pattern_base = spriteset[0]

    sprite_count = at('NumSprEnemies', idx)
    colors_ptr = int.from_bytes(rom[sym['idxActorSprCols'] + idx * 2:sym['idxActorSprCols'] + idx * 2 + 2], 'little')
    if colors_ptr != ref.locations['ActorSprColors3']['cpu_address']:
        raise ValueError('idxActorSprCols[ID-1] is not ActorSprColors3')
    colors = list(rom[sym['ActorSprColors3']:sym['ActorSprColors3'] + sprite_count])
    offset_labels = _dw_labels(ref.read('Banks0123.asm'), 'idxSprOffsets')
    table = b''.join(ref.locations[label]['cpu_address'].to_bytes(2, 'little') for label in offset_labels)
    if len(hits(rom, table)) != 1:
        raise ValueError('idxSprOffsets (Banks0123.asm:5961) must occur exactly once')
    offsets_index = [rom[sym[label]:sym[label] + 2 * sprite_count] for label in offset_labels]
    frames_meta, frame_patterns = [], []
    for sprite_id, name in zip(SPRITE_IDS, FRAME_SYMBOLS):
        cpu = int.from_bytes(rom[sym['idxSprites'] + sprite_id * 2:sym['idxSprites'] + sprite_id * 2 + 2], 'little')
        if cpu != ref.locations[name]['cpu_address']:
            raise ValueError(f'idxSprites[{sprite_id:#x}] is not {name}')
        pats, offs = parse_frame(rom[sym[name]:sym[name] + 1 + sprite_count], offsets_index, sprite_count)
        frame_patterns.append((pats, offs))
        frames_meta.append({'sprite_id': sprite_id, 'symbol': name, 'patterns': pats,
                            'offsets_yx': [list(o) for o in offs]})
    used = max(p for pats, _ in frame_patterns for p in pats)
    patterns = decode_patterns(rom[sym['SprRollingBarrel']:], (used - pattern_base) // 4 + 1)
    frames = [compose_frame(patterns, pattern_base, pats, offs, colors) for pats, offs in frame_patterns]

    signatures = {}
    for name, payload in CODE_SIGNATURES.items():
        found = hits(rom, payload)
        if len(found) != 1:
            raise ValueError(f'Code signature {name} must occur exactly once; found {len(found)}')
        signatures[name] = {'rom_offset': found[0], 'length': len(payload), 'status': 'binary_verified'}
    logic = signatures['RollingBarrelLogic']['rom_offset']
    if rom[logic - 8:logic - 6] != b'\x06\x03' or rom[logic - 6] != 0xCD or rom[logic - 3] != 0xCD:
        raise ValueError('RollingBarrelLogic does not start with ld b,3 / call / call')

    sprset_pal = rom[sym['SprsetPal19']:sym['SprsetPal19'] + 16]
    sprset_pal = sprset_pal[:sprset_pal.index(0xFF) + 1]
    width, height, sheet = side_by_side(frames)
    rooms, files = [], {}
    for room_id in ROOMS:
        room = next(r for r in package['rooms'] if r['id'] == room_id)
        palette = sprite_palette(build_palette(package, room['palette_ref']), sprset_pal)
        name = f'room-{room_id:03d}.png'
        files[name] = png_indexed(width, height, sheet, palette, transparent=0)
        rooms.append({'room_id': room_id, 'palette_ref': room['palette_ref'], 'spriteset': SPRITESET_ID,
                      'png': name, 'palette_rgb': palette})

    stream_length = unpack_gfx(bytes(2) + rom[sym['SprRollingBarrel']:], 0)[1] - 2
    shape_ids = {table: at(table, idx) for table in ('ActorsShapeTouch', 'ActorShapeProject', 'ActorShapeExpl')}
    # Both callers do `inc a` (FFh test) before GetShapeInfo's DEC_A_HL_4xA
    # (touchenemy.asm:87-93, damagetoenemy.asm:98-102), so the row is the shape value itself.
    impact = lambda table: area(rom[sym['ImpactAreasInfo'] + shape_ids[table] * 4:
                                    sym['ImpactAreasInfo'] + (shape_ids[table] + 1) * 4])
    damages = {}
    for weapon, table in zip(WEAPONS, WEAPON_TABLES):
        value = at(table, idx)
        damages[weapon] = None if value == 0xFF else value
    data = {
        'format_version': '1.0.0',
        'actor_id': ACTOR_ID,
        'rooms': rooms,
        'sprite': {'pattern_base': pattern_base, 'sprite_count': sprite_count, 'colors': colors,
                   'frame_width': frames[0]['width'], 'frame_height': height, 'origin': frames[0]['origin'],
                   'sheet_width': width, 'frames': frames_meta},
        'life': at('idxActorLife', idx),
        'touch_damage': at('ActorTouchDamage', idx),
        'touch_area': impact('ActorsShapeTouch'),
        'shot_area': impact('ActorShapeProject'),
        'explosive_area': impact('ActorShapeExpl'),
        'weapon_damage': damages,
        'behaviour': BEHAVIOUR,
        'code_signatures': signatures,
        'evidence': [ref.evidence(s, n) for s, n in [
            ('SprRollingBarrel', stream_length), ('SprSetRolBarrel', 4), ('RollBarrels1', 1 + sprite_count),
            ('RollBarrels2', 1 + sprite_count), ('SprOffsets7', 2 * sprite_count),
            ('ActorSprColors3', sprite_count), ('SprsetPal19', len(sprset_pal)), ('SpritesetRooms', 256),
            ('idxActorLife', 64), ('ActorTouchDamage', 65), ('ActorsShapeTouch', 65),
            ('ActorShapeProject', 65), ('ActorShapeExpl', 65),
            ('ImpactAreasInfo', 4 * (max(shape_ids.values()) + 1))]],
    }
    return data, files


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--rom', type=Path, help='Explicit ROM; validated against the canonical hash')
    parser.add_argument('--reference', type=Path, default=ROOT / 'external/MetalGear')
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    if (ROOT / 'data/extracted').resolve() not in args.output.resolve().parents:
        raise ValueError('Output must be under private data/extracted')
    canonical = resolve_canonical_rom(args.rom)
    package = build(canonical.data, args.reference)
    data, files = extract(canonical.data, args.reference, package)
    data.update(canonical.provenance())
    canonical.assert_unchanged()
    args.output.mkdir(parents=True, exist_ok=True)
    for name, payload in files.items():
        (args.output / name).write_bytes(payload)
    (args.output / 'rolling_barrel.json').write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n',
                                                     encoding='utf-8')
    print(f'ROLLING_BARREL_EXTRACT_OK: {len(files)} PNGs + rolling_barrel.json em {args.output}')


if __name__ == '__main__':
    main()
