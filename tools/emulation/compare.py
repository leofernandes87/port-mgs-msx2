"""Compare captured execution with extraction and publish explicit room snapshots."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT))
from tools.extractors.codecs import rgb_palette, png_indexed
from tools.extractors.extract import encode, publish
from tools.extractors.schema import validate_package, validate
from tools.rom import require_canonical_provenance


def screen_pixels(vram):
    if len(vram)!=65536:
        raise ValueError('Expected 64 KiB VRAM capture')
    return [pixel for byte in vram[:24576] for pixel in (byte>>4,byte&15)]


def atlas_tile(vram,tile):
    if len(vram)!=65536 or not 0<=tile<256:
        raise ValueError('Invalid VRAM/tile')
    start=0x8000+(tile//32)*1024+(tile%32)*4
    return [(vram[start+y*128+x//2]>>(4 if x%2==0 else 0))&15 for y in range(8) for x in range(8)]


def compose(tiles,atlas):
    if len(tiles)!=768 or len(atlas)!=256 or any(len(t)!=64 for t in atlas):
        raise ValueError('Invalid room/atlas dimensions')
    if any(type(t) is not int or not 0<=t<256 for t in tiles):
        raise ValueError('Invalid tile ID')
    return [atlas[tiles[y//8*32+x//8]][y%8*8+x%8] for y in range(192) for x in range(256)]


def door_record(door,persistent_state):
    """AddDoorsData's 16-byte RAM record; sums wrap exactly as Z80 ADD A."""
    g=door['region_profile_raw'];y=door['draw_y'];x=door['draw_x']
    state=0 if door['render_type_id']==6 else persistent_state
    return [door['door_id'],state,door['open_logic_raw'],door['render_type_id'],0,y,x,
            (y+g[0])&255,g[1],(x+g[2])&255,g[3],(y+g[4])&255,g[5],
            (x+g[6])&255,g[7],door['destination_room_id']]


def classify_atlas_inheritance(prior_vram,settled_vram,loaded_tile_ids):
    if len(prior_vram)!=65536 or len(settled_vram)!=65536:
        raise ValueError('Expected 64 KiB VRAM captures')
    overwritten=[];inherited=[];zeroed=[]
    for tile_id in range(256):
        t_prior=atlas_tile(prior_vram,tile_id)
        t_settled=atlas_tile(settled_vram,tile_id)
        if t_prior!=t_settled:
            overwritten.append(tile_id)
        elif all(p==0 for p in t_settled):
            zeroed.append(tile_id)
        else:
            inherited.append(tile_id)
    return {'overwritten_tile_ids':overwritten,'inherited_tile_ids':inherited,'zeroed_tile_ids':zeroed,
            'overwritten_count':len(overwritten),'inherited_count':len(inherited),'zeroed_count':len(zeroed),
            'loaded_subset_of_overwritten_or_common':all(t in overwritten or t in inherited for t in loaded_tile_ids)}


def vram_pixel(vram,page,x,y):
    if not (0<=x<256 and 0<=y<256):return 0
    byte_idx=page*0x8000+y*128+(x//2)
    b=vram[byte_idx]
    return (b>>4) if (x%2==0) else (b&0x0F)


def reconstruct_doors_overlay(base_pixels,doors,vram,ram):
    pixels=list(base_pixels);closed_doors=0
    for door in doors:
        persistent_state=ram[0x450+door['door_id']-1]
        state=0 if door['render_type_id']==6 else persistent_state
        if state==0:continue
        closed_doors+=1
        rtype=door['render_type_id'];dx=door['draw_x'];dy=door['draw_y']
        if rtype==1:
            sx,sy,nx,ny=196,160,24,32
            for y in range(ny):
                for x in range(nx):
                    sp=vram_pixel(vram,1,sx+x,sy+y)
                    if sp!=0 and 0<=dx+x<256 and 0<=dy+y<192:
                        pixels[(dy+y)*256+(dx+x)]=sp
        elif rtype==2:
            sx,sy,nx,ny=224,192,32,8
            for y in range(ny):
                for x in range(nx):
                    sp=vram_pixel(vram,1,sx+x,sy+y)
                    if sp!=0 and 0<=dx+x<256 and 0<=dy+y<192:
                        pixels[(dy+y)*256+(dx+x)]=sp
        elif rtype==3:
            for col in range(8):
                cur_dy=dy+4*col;cur_dx=dx+col
                for row in range(32):
                    sp=vram_pixel(vram,1,224+col,160+row)
                    if sp!=0 and 0<=cur_dx<256 and 0<=cur_dy+row<192:
                        pixels[(cur_dy+row)*256+cur_dx]=sp
        elif rtype==4:
            for col in range(8):
                cur_dy=dy+28-4*col;cur_dx=dx+col
                for row in range(32):
                    sp=vram_pixel(vram,1,232+col,160+row)
                    if sp!=0 and 0<=cur_dx<256 and 0<=cur_dy+row<192:
                        pixels[(cur_dy+row)*256+cur_dx]=sp
        elif rtype==5:
            sx,sy,nx,ny=196,192,24,32
            for y in range(ny):
                for x in range(nx):
                    sp=vram_pixel(vram,1,sx+x,sy+y)
                    if sp!=0 and 0<=dx+x<256 and 0<=dy+y<192:
                        pixels[(dy+y)*256+(dx+x)]=sp
    return pixels,closed_doors


def compare_room(package,ram,initial_vram,settled_vram,prior_vram=None,doors_vram=None,doors_ram=None):
    if len(ram)!=16384:
        raise ValueError('Expected C000..FFFF memory capture')
    room_id=ram[0x130];gfx=ram[0x157]
    if room_id>=251 or gfx>=8:
        raise ValueError('Uninitialized room/tileset')
    room=package['rooms'][room_id]
    if room['status']!='decoded' or gfx!=room['graphics_set_ref']:
        raise ValueError('Room graphics state differs')
    if list(ram[0x2000:0x2300])!=room['expanded_tiles']:
        raise ValueError('RoomTileBuffer differs from extraction')
    atlas=[atlas_tile(initial_vram,i) for i in range(256)]
    ts=package['tilesets'][gfx]
    loaded=[i for i,t in enumerate(ts['pixels_by_tile']) if t is not None]
    if any(ts['pixels_by_tile'][i]!=atlas[i] for i in loaded):
        raise ValueError('Loaded graphics differ from extraction')
    expected=compose(room['expanded_tiles'],atlas)
    actual=screen_pixels(settled_vram)
    if expected!=actual:
        raise ValueError('Settled background differs from reconstructed tiles')
    doors=[d for d in package['doors'] if d['room_id']==room_id]
    for door in doors:
        expected_door=door_record(door,ram[0x450+door['door_id']-1])
        start=0x3d0+door['ordinal']*16
        if list(ram[start:start+16])!=expected_door:
            raise ValueError('DoorsList runtime record differs from extracted rule/geometry')
    pairs=[v[:] for v in package['palette_base']['default_register_pairs']]
    for patch in (package['palette_base']['menu_patch'],package['palettes'][room['palette_ref']]):
        for index,rb,g in patch['registers']:pairs[index]=[rb,g]
    palette=rgb_palette(pairs)+[[255,0,255],[40,0,40]]
    snapshot={'format_version':'1.0.0','room_id':room_id,'width':256,'height':192,
              'pixels':expected,'palette_rgb':palette,'collision':room['static_collision'],
              'input_sha256':package['manifest']['input_sha256'],'rom_profile':package['manifest']['rom_profile'],
              'source':'Emulator-matched background before doors/entities; nominal room palette'}
    missing=sorted(set(room['expanded_tiles'])&set(ts['unloaded_tile_ids']))
    report={'room_id':room_id,'graphics_set':gfx,'ram_bytes_matched':768,
            'door_records_matched':len(doors),'loaded_tiles_matched':len(loaded),'background_pixels_matched':len(actual),
            'initial_pending_pixels':sum(a!=b for a,b in zip(expected,screen_pixels(initial_vram))),
            'unloaded_referenced_tiles_observed':{str(i):sorted(set(atlas[i])) for i in missing}}
    if prior_vram is not None:
        report['atlas_inheritance']=classify_atlas_inheritance(prior_vram,settled_vram,loaded)
    if doors_vram is not None:
        expected_doors,closed_count=reconstruct_doors_overlay(expected,doors,settled_vram,ram)
        actual_doors=screen_pixels(doors_vram)
        if expected_doors!=actual_doors:
            raise ValueError('Settled doors VRAM differs from reconstructed door overlay')
        diff_count=sum(a!=b for a,b in zip(actual,actual_doors))
        report['doors_delta']={'closed_doors_count':closed_count,'modified_pixels_count':diff_count}
    return snapshot,report


def run(package_path,capture,output):
    private=(ROOT/'data/extracted').resolve()
    if private not in output.resolve().parents or output.exists() or output.is_symlink():
        raise ValueError('Choose a new directory under data/extracted')
    package_bytes=package_path.read_bytes();package=json.loads(package_bytes)
    validate_package(package)
    require_canonical_provenance(package['manifest'])
    manifest=json.loads((capture/'manifest.json').read_text())
    require_canonical_provenance(manifest)
    for name,digest in manifest['files'].items():
        if Path(name).name!=name or hashlib.sha256((capture/name).read_bytes()).hexdigest()!=digest:
            raise ValueError('Capture hash/path invalid: '+name)
    schema=json.loads((ROOT/'data/schemas/room-snapshot.schema.json').read_text())
    files={};results=[]
    for f in sorted(p for p in capture.glob('room-*-ram.bin') if not p.name.endswith('-doors-ram.bin')):
        prefix=f.name[:-8]
        prior_file=capture/(prefix+'-prior-vram.bin')
        prior_vram=prior_file.read_bytes() if prior_file.exists() else None
        doors_file=capture/(prefix+'-doors-vram.bin')
        doors_vram=doors_file.read_bytes() if doors_file.exists() else None
        doors_ram_file=capture/(prefix+'-doors-ram.bin')
        doors_ram=doors_ram_file.read_bytes() if doors_ram_file.exists() else None
        snapshot,report=compare_room(package,f.read_bytes(),(capture/(prefix+'-vram.bin')).read_bytes(),
                                     (capture/(prefix+'-settled-vram.bin')).read_bytes(),prior_vram=prior_vram,
                                     doors_vram=doors_vram,doors_ram=doors_ram)
        validate(snapshot,schema)
        files[prefix+'.json']=encode(snapshot)
        files[prefix+'.png']=png_indexed(256,192,snapshot['pixels'],snapshot['palette_rgb'])
        if doors_vram is not None:
            doors_pixels=screen_pixels(doors_vram)
            files[prefix+'-doors.png']=png_indexed(256,192,doors_pixels,snapshot['palette_rgb'])
        results.append(report)
    if not results:raise ValueError('No captured rooms')
    result={'format_version':'1.0.0','package_sha256':hashlib.sha256(package_bytes).hexdigest(),
            'capture_manifest_sha256':hashlib.sha256((capture/'manifest.json').read_bytes()).hexdigest(),
            'comparison':'indices only; nominal palette is not a live palette comparison','rooms':results}
    files['comparison.json']=encode(result)
    files['checksums.json']=encode({n:hashlib.sha256(b).hexdigest() for n,b in sorted(files.items())})
    publish(output,files)
    print(json.dumps(result,indent=2))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--package',required=True,type=Path)
    parser.add_argument('--capture',required=True,type=Path)
    parser.add_argument('--output',required=True,type=Path)
    args=parser.parse_args()
    try:run(args.package,args.capture,args.output)
    except (ValueError,OSError,KeyError) as error:
        print('Comparison failed: '+str(error),file=sys.stderr);sys.exit(1)
