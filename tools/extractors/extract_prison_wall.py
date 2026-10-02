"""Export private prison-wall tile blocks, verified against the read-only ROM.

Primary evidence: data/doors.asm:992-1031; drawdoors.asm:262-319;
Banks0123.asm:1480-1531,4789-4809. No graphic bytes are embedded here.
"""
import argparse
import hashlib
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tools.extractors.extract import build, encode, publish
from tools.extractors.reference import load_reference
from tools.extractors.batch_snapshots import build_palette
from tools.extractors.codecs import png_indexed


def compose_wall(block, atlas, flags):
    """Compose the row-major tile block used by DrawTileBlkTimp (synthetic-testable)."""
    if len(block) < 2:
        raise ValueError('Missing block dimensions')
    height, width = block[:2]
    if not 0 < width <= 32 or not 0 < height <= 24 or len(block) != 2 + width * height:
        raise ValueError('Invalid tile block size')
    pixels = [0] * (width * height * 64)
    collision = []
    for i, tile_id in enumerate(block[2:]):
        tile = atlas[tile_id]
        if tile is None or len(tile) != 64:
            raise ValueError('Wall references an unloaded tile')
        collision.append(flags[tile_id])
        for y in range(8):
            start = ((i // width * 8 + y) * width * 8) + (i % width * 8)
            pixels[start:start + 8] = tile[y * 8:y * 8 + 8]
    return dict(width=width * 8, height=height * 8, pixels=pixels, collision=collision)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rom', type=Path, required=True)
    parser.add_argument('--reference', type=Path, default=ROOT / 'external/MetalGear')
    parser.add_argument('--output', type=Path, default=ROOT / 'data/extracted/prison-walls')
    args = parser.parse_args()
    if (ROOT / 'data/extracted').resolve() not in args.output.resolve().parents:
        raise ValueError('Output must be under private data/extracted')
    rom = args.rom.read_bytes()
    package = build(rom, args.reference)
    ref = load_reference(args.reference, rom)
    files = {}
    for render_type, room_id, symbol in [(12, 54, 'TilesWallPrison2'), (13, 164, 'TilesWallPrison2'),
                                         (14, 165, 'TilesWallPrison1'), (15, 164, 'TilesWallPrison')]:
        room = next(r for r in package['rooms'] if r['id'] == room_id)
        start = ref.symbols[symbol]
        size = 2 + rom[start] * rom[start + 1]
        gfx = room['graphics_set_ref']
        data = compose_wall(rom[start:start + size], package['tilesets'][gfx]['pixels_by_tile'],
                            package['collision_profiles'][gfx]['movement_blocked_by_tile'])
        data.update(format_version='1.0.0', render_type=render_type,
                    palette_rgb=build_palette(package, room['palette_ref']),
                    input_sha256=hashlib.sha256(rom).hexdigest(), evidence=ref.evidence(symbol, size))
        files[f'wall-{render_type}.json'] = encode(data)
        files[f'wall-{render_type}.png'] = png_indexed(data['width'], data['height'], data['pixels'], data['palette_rgb'])
        print(symbol, ref.evidence(symbol, size))
    if args.rom.read_bytes() != rom:
        raise ValueError('Input changed during extraction')
    publish(args.output, files)
    print('PRISON_WALL_EXPORT_OK: ROM unchanged; output', args.output)


if __name__ == '__main__':
    main()
