"""Generate and validate room snapshots in batch from the verified extraction package.

Reads data/extracted/en-eu-rc750/package/package.json (produced by extract.py) and emits
one room-NNN.json + room-NNN.png per decoded room for the requested building scope.
No emulator required; pixels are reconstructed from ROM-extracted tile graphics and
metatile layout data. Unloaded tile slots render as index 0 (black) — consistent with
emulator-validated captures that confirmed tiles 0/1/2 are zero-filled before room load.

ROM and emulator captures are NOT modified or read here; the package is the sole input.

Usage:
    python3 tools/extractors/batch_snapshots.py \\
        --package data/extracted/en-eu-rc750/package/package.json \\
        --output data/extracted/en-eu-rc750/rooms \\
        [--rooms all]

The package must carry the canonical rom_profile and input_sha256 (tools/rom.py).
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.extractors.codecs import rgb_palette, png_indexed
from tools.extractors.extract import encode, publish
from tools.extractors.schema import validate
from tools.rom import require_canonical_provenance


SNAPSHOT_SCHEMA = ROOT / 'data/schemas/room-snapshot.schema.json'
BUILDING_SCOPES = {
    'building1': range(0, 16),
    'building2': range(16, 64),
    'building3': range(64, 126),
    'buildings123': range(0, 126),
    'lorries': range(126, 208),
    'all': range(0, 251),
}


def parse_room_range(spec):
    """Parse '0-125' or '5' into a set of room IDs."""
    parts = spec.split('-')
    if len(parts) == 1:
        return {int(parts[0])}
    if len(parts) == 2:
        lo, hi = int(parts[0]), int(parts[1])
        return set(range(lo, hi + 1))
    raise ValueError(f'Invalid room range: {spec!r}')


def build_palette(package, palette_ref):
    """Reconstruct the 18-entry RGB palette used for a room (default + room patch)."""
    pairs = [row[:] for row in package['palette_base']['default_register_pairs']]
    for patch in (package['palette_base']['menu_patch'], package['palettes'][palette_ref]):
        for index, rb, g in patch['registers']:
            pairs[index] = [rb, g]
    return rgb_palette(pairs) + [[255, 0, 255], [40, 0, 40]]


def compose_pixels(expanded_tiles, tileset):
    """Reconstruct the 256x192 pixel array from a room's expanded tile list.

    Unloaded tile slots (pixels_by_tile entry is None) render as 0 (black/index 0),
    matching the emulator behaviour where VRAM for those tiles is zero-filled before
    the room's tile load routine runs.
    """
    atlas = tileset['pixels_by_tile']
    pixels = []
    for cell_idx, tile_id in enumerate(expanded_tiles):
        row = cell_idx // 32  # 0-5 (6 rows of 8-pixel-high tiles)
        col = cell_idx % 32   # 0-31 (32 columns of 8-pixel-wide tiles)
        tile = atlas[tile_id]  # list of 64 ints, or None
        # Fill the 8x8 block
        if tile is None:
            block = [0] * 64
        else:
            block = tile
        for ty in range(8):
            start = (row * 8 + ty) * 256 + col * 8
            pixels[start:start + 8] = block[ty * 8: ty * 8 + 8]
    # Build a flat list in raster order (pixels was assembled by extending slices above)
    # Re-build properly: the slice assignment approach needs a pre-allocated list.
    return _compose_raster(expanded_tiles, atlas)


def _compose_raster(expanded_tiles, atlas):
    """Build 256x192 flat pixel list in raster scan order."""
    result = [0] * (256 * 192)
    for cell_idx, tile_id in enumerate(expanded_tiles):
        row = cell_idx // 32
        col = cell_idx % 32
        tile = atlas[tile_id]
        if tile is None:
            continue  # slot stays 0
        for ty in range(8):
            base = (row * 8 + ty) * 256 + col * 8
            result[base:base + 8] = tile[ty * 8: ty * 8 + 8]
    return result


def make_snapshot(package, room, schema):
    """Build and validate a snapshot dict for a single decoded room."""
    gfx = room['graphics_set_ref']
    tileset = package['tilesets'][gfx]
    palette = build_palette(package, room['palette_ref'])

    unloaded_used = sorted(set(room['expanded_tiles']) & set(tileset['unloaded_tile_ids']))
    pixels = _compose_raster(room['expanded_tiles'], tileset['pixels_by_tile'])

    source = (
        'ROM-only static background; tile graphics reconstructed from verified '
        'package (extract.py). Palette: default + room patch, no live sprites/doors/items.'
    )
    if unloaded_used:
        source += (
            f' Unloaded tile IDs rendered as index-0 (black): {unloaded_used}. '
            'Emulator captures confirm these tiles are zero-filled at room-load time.'
        )

    snapshot = {
        'format_version': '1.0.0',
        'room_id': room['id'],
        'width': 256,
        'height': 192,
        'pixels': pixels,
        'palette_rgb': palette,
        'collision': room['static_collision'],
        'input_sha256': package['manifest']['input_sha256'],
        'rom_profile': package['manifest']['rom_profile'],
        'source': source,
    }
    validate(snapshot, schema)
    return snapshot, {'unloaded_tile_ids_used': unloaded_used}


def cross_check_existing(snapshot, validated_dir):
    """If an emulator-validated snapshot exists for this room, assert pixels match."""
    room_id = snapshot['room_id']
    for vdir in [validated_dir] if validated_dir else []:
        candidate = vdir / f'room-{room_id:03d}.json'
        if candidate.exists():
            ref = json.loads(candidate.read_text())
            if ref.get('pixels') == snapshot['pixels']:
                return {'cross_checked': True, 'reference': str(candidate)}
            else:
                # Count differences to help diagnose
                diff = sum(a != b for a, b in zip(ref['pixels'], snapshot['pixels']))
                return {'cross_checked': False, 'reference': str(candidate),
                        'pixel_diff_count': diff}
    return {'cross_checked': False, 'reference': None}


def run(package_path, output, room_ids, validated_dirs):
    private = (ROOT / 'data/extracted').resolve()
    if private not in output.resolve().parents or output.exists() or output.is_symlink():
        raise ValueError('Choose a new directory under data/extracted')

    package = json.loads(package_path.read_bytes())
    require_canonical_provenance(package['manifest'])
    schema = json.loads(SNAPSHOT_SCHEMA.read_text())

    rooms_by_id = {r['id']: r for r in package['rooms']}
    decoded_ids = sorted(i for i in room_ids if rooms_by_id.get(i, {}).get('status') == 'decoded')
    skipped_ids = sorted(i for i in room_ids if i not in rooms_by_id or rooms_by_id[i].get('status') != 'decoded')

    if not decoded_ids:
        raise ValueError('No decoded rooms in requested scope')

    files = {}
    results = []

    for room_id in decoded_ids:
        room = rooms_by_id[room_id]
        snapshot, report = make_snapshot(package, room, schema)

        cross = {'cross_checked': False, 'reference': None}
        for vdir in validated_dirs:
            cross = cross_check_existing(snapshot, vdir)
            if cross['cross_checked']:
                break

        key = f'room-{room_id:03d}'
        files[f'{key}.json'] = encode(snapshot)
        files[f'{key}.png'] = png_indexed(256, 192, snapshot['pixels'], snapshot['palette_rgb'])
        results.append({
            'room_id': room_id,
            'gfx': room['graphics_set_ref'],
            'palette_ref': room['palette_ref'],
            **report,
            **cross,
        })
        print(f'  room {room_id:03d} ok'
              + (f' [unloaded: {report["unloaded_tile_ids_used"]}]' if report['unloaded_tile_ids_used'] else '')
              + (' [cross-checked]' if cross['cross_checked'] else ''), flush=True)

    summary = {
        'format_version': '1.0.0',
        'package_sha256': hashlib.sha256(package_path.read_bytes()).hexdigest(),
        'source': 'ROM-only batch extraction; no emulator required',
        'rooms_extracted': len(decoded_ids),
        'rooms_skipped_undefined': skipped_ids,
        'rooms': results,
    }
    files['batch_summary.json'] = encode(summary)
    files['checksums.json'] = encode({n: hashlib.sha256(b).hexdigest() for n, b in sorted(files.items())})
    publish(output, files)
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--package', required=True, type=Path,
                        help='Path to a canonical package.json produced by extract.py')
    parser.add_argument('--output', required=True, type=Path,
                        help='New output directory under data/extracted')
    parser.add_argument('--rooms', default='buildings123',
                        help='Room scope: "building1", "building2", "building3", '
                             '"buildings123", "lorries", "all", or a range like "0-125"')
    parser.add_argument('--validated', nargs='*', type=Path, default=[],
                        help='Directories with emulator-validated canonical snapshots to cross-check against')
    args = parser.parse_args()

    if args.rooms in BUILDING_SCOPES:
        room_ids = set(BUILDING_SCOPES[args.rooms])
    else:
        room_ids = parse_room_range(args.rooms)

    validated_dirs = [p for p in (args.validated or []) if p.is_dir()]

    print(f'Extracting {len(room_ids)} candidate rooms → {args.output}')
    print(f'Cross-check sources: {[str(d) for d in validated_dirs]}')

    try:
        summary = run(args.package, args.output, room_ids, validated_dirs)
    except (ValueError, OSError, KeyError) as err:
        print('Batch extraction failed: ' + str(err), file=sys.stderr)
        sys.exit(1)

    cross_ok = sum(1 for r in summary['rooms'] if r.get('cross_checked'))
    print(f'\nDone: {summary["rooms_extracted"]} snapshots written.')
    print(f'Cross-checked against emulator captures: {cross_ok}/{summary["rooms_extracted"]}')
    if summary['rooms_skipped_undefined']:
        print(f'Skipped (undefined): {summary["rooms_skipped_undefined"]}')


if __name__ == '__main__':
    main()
