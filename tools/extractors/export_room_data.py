"""Export per-room actor/item/door data from the verified extraction package.

Reads rc750-verified/package.json and emits one lightweight room-NNN-actors.json
per decoded room under the stage5-batch directory (alongside existing snapshots).
No ROM, emulator, or network access required.

Output schema per file:
  {
    "format_version": "1.0.0",
    "room_id": int,
    "actors": [{"actor_type_id": int, "y": int, "x": int,
                "patrol_path": [[y, x], ...]}, ...],
    "items":  [{"item_type_id": int, "y": int, "x": int}, ...],
    "doors":  [{"door_id": int, "render_type_id": int, "draw_y": int,
                "draw_x": int, "destination_room_id": int,
                "open_rule_id": int, "open_logic_raw": int}, ...]
  }

Actor ordering matches the ROM's actor-slot initialisation order.
Patrol paths are ordered candidate lists; runtime binding by slot index.
Unresolved actor-path bindings remain raw ordered data (see package docs).
"""
import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.extractors.extract import encode


def export_room_data(package: dict, room_ids: set) -> dict:
    """Return a dict of {room_id: room_data_dict} for all requested rooms."""
    rooms_by_id = {r['id']: r for r in package['rooms']}
    entities_by_room: dict = {}
    for e in package['entities']:
        entities_by_room.setdefault(e['room_id'], []).append(e)
    items_by_room: dict = {}
    for i in package['items']:
        items_by_room.setdefault(i['room_id'], []).append(i)
    doors_by_room: dict = {}
    for d in package['doors']:
        doors_by_room.setdefault(d['room_id'], []).append(d)

    # Build path lookup: room_id -> ordered list of path values lists
    room_paths_by_id = {p['room_id']: p['ordered_path_refs'] for p in package['room_paths']}
    path_by_ref = {p['id']: p for p in package['paths']}

    result = {}
    for room_id in sorted(room_ids):
        room = rooms_by_id.get(room_id)
        if room is None or room['status'] != 'decoded':
            continue

        # Actors: merge patrol paths by position (ordered_path_refs[i] → actor[i])
        raw_actors = sorted(entities_by_room.get(room_id, []), key=lambda e: e['ordinal'])
        path_refs = room_paths_by_id.get(room_id, [])
        actors = []
        for i, e in enumerate(raw_actors):
            patrol = []
            if i < len(path_refs):
                path_obj = path_by_ref.get(path_refs[i])
                if path_obj and path_obj['kind'] == 'points_yx':
                    patrol = path_obj['values']  # list of [y, x]
            actors.append({
                'actor_type_id': e['actor_type_id'],
                'y': e['y'],
                'x': e['x'],
                'patrol_path': patrol,
            })

        # Items: only y, x, type — availability rules are runtime/progression
        items = [
            {'item_type_id': i['item_type_id'], 'y': i['y'], 'x': i['x']}
            for i in sorted(items_by_room.get(room_id, []), key=lambda i: i['ordinal'])
        ]

        # Doors: geometry and rule; lorry doors (render_type_id >= 6) included
        doors = [
            {
                'door_id': d['door_id'],
                'render_type_id': d['render_type_id'],
                'draw_y': d['draw_y'],
                'draw_x': d['draw_x'],
                'destination_room_id': d['destination_room_id'],
                'open_rule_id': d['open_rule_id'],
                'open_logic_raw': d['open_logic_raw'],
            }
            for d in sorted(doors_by_room.get(room_id, []), key=lambda d: d['ordinal'])
        ]

        result[room_id] = {
            'format_version': '1.0.0',
            'room_id': room_id,
            'actors': actors,
            'items': items,
            'doors': doors,
        }
    return result


def run(package_path: Path, output_dir: Path, room_ids: set) -> dict:
    private = (ROOT / 'data/extracted').resolve()
    if private not in output_dir.resolve().parents and output_dir.resolve() != private:
        raise ValueError('Output must be under data/extracted')
    if not output_dir.is_dir():
        raise ValueError('Output directory must already exist (alongside snapshots)')

    package = json.loads(package_path.read_bytes())
    room_data = export_room_data(package, room_ids)

    written = []
    skipped = []
    for room_id, data in room_data.items():
        out_file = output_dir / f'room-{room_id:03d}-actors.json'
        if out_file.exists():
            skipped.append(room_id)
            continue
        out_file.write_bytes(encode(data))
        written.append(room_id)

    summary = {
        'package_sha256': hashlib.sha256(package_path.read_bytes()).hexdigest(),
        'rooms_written': len(written),
        'rooms_skipped_existing': skipped,
        'rooms_skipped_undefined': sorted(room_ids - set(room_data.keys())),
    }
    return summary


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--package', required=True, type=Path,
                        help='Path to rc750-verified/package.json')
    parser.add_argument('--output', required=True, type=Path,
                        help='Existing directory to write room-NNN-actors.json files into')
    parser.add_argument('--rooms', default='0-125',
                        help='Room range, e.g. "0-125" or "5"')
    args = parser.parse_args()

    parts = args.rooms.split('-')
    if len(parts) == 1:
        room_ids = {int(parts[0])}
    elif len(parts) == 2:
        room_ids = set(range(int(parts[0]), int(parts[1]) + 1))
    else:
        print(f'Invalid room range: {args.rooms}', file=sys.stderr)
        sys.exit(1)

    try:
        summary = run(args.package, args.output, room_ids)
    except (ValueError, OSError, KeyError) as err:
        print('Export failed: ' + str(err), file=sys.stderr)
        sys.exit(1)

    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
