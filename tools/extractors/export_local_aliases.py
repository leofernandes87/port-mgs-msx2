"""Derive the laboratory's local prison room aliases from canonical room exports.

The Godot project addresses the capture cell (original room 165, logic/capturescene.asm:87-118)
as 211 and the adjacent bag room (original 164, data/doors.asm:724-728) as 212; see
docs/reverse_engineering/prison-wall.md. These IDs are a local convention, not ROM data,
so they are produced here from canonical files instead of being edited by hand:

- room-211/212 snapshots and actors are copies of 165/164 with ``local_alias_of`` set;
- every door whose destination is an aliased original is redirected to the alias, and each
  rewritten actors file records ``local_door_remap``.

Provenance (rom_profile, input_sha256) is copied unchanged and must be canonical.

  python3 tools/extractors/export_local_aliases.py
"""
import argparse
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tools.extractors.extract import encode
from tools.rom import canonical_data_dir, require_canonical_provenance

ALIASES = {211: 165, 212: 164}


def remap_doors(actors, remap):
    doors = [dict(door, destination_room_id=remap.get(door['destination_room_id'], door['destination_room_id']))
             for door in actors['doors']]
    return dict(actors, doors=doors)


def build_aliases(rooms, aliases=ALIASES):
    """rooms: {room_id: (snapshot, actors)} from canonical exports -> {file name: document}."""
    remap = {original: alias for alias, original in aliases.items()}
    used = {f'{k}': v for k, v in sorted(remap.items())}
    files = {}
    for alias, original in sorted(aliases.items()):
        snapshot, actors = rooms[original]
        files[f'room-{alias:03d}.json'] = dict(snapshot, room_id=alias, local_alias_of=original)
        files[f'room-{alias:03d}-actors.json'] = dict(remap_doors(actors, remap), room_id=alias,
                                                      local_alias_of=original, local_door_remap=used)
    for room_id, (_, actors) in sorted(rooms.items()):
        if room_id in remap or room_id in aliases:
            continue
        if any(door['destination_room_id'] in remap for door in actors['doors']):
            files[f'room-{room_id:03d}-actors.json'] = dict(remap_doors(actors, remap), local_door_remap=used)
    for document in files.values():
        require_canonical_provenance(document)
    return files


def load_rooms(rooms_dir):
    rooms = {}
    for snapshot_path in sorted(rooms_dir.glob('room-[0-9][0-9][0-9].json')):
        actors_path = snapshot_path.with_name(snapshot_path.stem + '-actors.json')
        rooms[int(snapshot_path.stem[5:])] = (json.loads(snapshot_path.read_text()), json.loads(actors_path.read_text()))
    return rooms


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--rooms', type=Path, default=canonical_data_dir() / 'rooms')
    parser.add_argument('--output', type=Path, default=canonical_data_dir() / 'local-aliases')
    args = parser.parse_args()
    if args.output.exists():
        print('Alias export failed: output already exists; choose a new directory', file=sys.stderr)
        sys.exit(1)
    files = build_aliases(load_rooms(args.rooms))
    args.output.mkdir(parents=True)
    for name, document in files.items():
        (args.output / name).write_bytes(encode(document))
    print(json.dumps({'written': sorted(files)}))


if __name__ == '__main__':
    main()
