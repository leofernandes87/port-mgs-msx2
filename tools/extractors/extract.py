"""Verified RC750-region extraction. Real payloads stay local and ignored."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import zlib

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from tools.extractors.reference import load_reference
from tools.extractors.codecs import (read, word, pointer, nibble, collision_bits,
    planar, flip_x, terminated, rgb_palette, png_indexed, connection_index)
from tools.reverse_engineering.analyze import expand_metatiles, PINNED_REVISION

VERSION = '0.1.0'
PRIMARY_SHA256 = '254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf'


def encode(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2)+'\n').encode()


def build(rom, reference_path):
    ref = load_reference(reference_path, rom)
    color_map = list(ref.literal('Banks0123.asm', 'ColorsTileset'))
    default = ref.literal('Banks0123.asm', 'DefaultPalette')
    symbols = ref.symbols
    by_offset = {}
    for label, offset in symbols.items():
        by_offset.setdefault(offset, []).append(label)
    def evidence(offset, length):
        # Pick nearest preceding declaration in the same verified segment.
        containers = [s for s in ref.segments if s['offset'] <= offset and offset+length <= s['offset']+s['length']]
        if not containers:
            raise ValueError(f'Unverified source extent {offset:#x}+{length}')
        start = max(v for v in by_offset if containers[0]['offset'] <= v <= offset)
        label = by_offset[start][0]
        value = ref.evidence(label,length)
        value['rom_offset'] = offset
        value['cpu_address'] += offset-start
        value['bank'] = offset//8192
        return value
    def bounded_end(offset):
        limits = [v for v in by_offset if v > offset]
        limits += [s['offset']+s['length'] for s in ref.segments if s['offset'] <= offset < s['offset']+s['length']]
        return min(limits)
    def records(offset,width,limit):
        end_limit=min(s["offset"]+s["length"] for s in ref.segments if s["offset"] <= offset < s["offset"]+s["length"])
        rows,end=terminated(rom,offset,width,limit,end_limit)
        return rows,evidence(offset,end-offset)
    def palette_patch(offset):
        rows,ev=records(offset,3,16)
        if any(row[0]>15 or row[1]&0x88 or row[2]>7 for row in rows):
            raise ValueError('Invalid palette register')
        return {'registers':rows,'evidence':ev}

    package = {key:[] for key in ('rooms','layouts','metatile_sets','collision_profiles','tilesets',
              'palettes','doors','entities','paths','room_paths','items','connections','diagnostics')}
    metabytes = {}
    for set_id in range(1,7):
        start=symbols[f'Metatiles{set_id}']
        end=symbols[f'Metatiles{set_id+1}'] if set_id<6 else symbols['DoorClosedTiles']
        data=read(rom,start,end-start)
        if len(data)%16:
            raise ValueError('Metatile definitions not aligned')
        metabytes[set_id]=data
        package['metatile_sets'].append({'id':set_id,'tile_width':4,'tile_height':4,
            'definitions':[list(data[i:i+16]) for i in range(0,len(data),16)],'evidence':evidence(start,len(data))})
    for set_id in range(7):
        off=pointer(rom,symbols['IdxColisTiles']+2*set_id,0xE000)
        package['collision_profiles'].append({'id':set_id,'movement_blocked_by_tile':collision_bits(read(rom,off,32)),
            'scope':'static_movement_only','evidence':evidence(off,32)})
    for palette_id in range(16):
        off=pointer(rom,symbols['idxRoomPalettes']+2*palette_id,0x8000)
        package['palettes'].append({'id':palette_id,**palette_patch(off)})
    menu=palette_patch(symbols['PalMenuWeapon'])
    package['palette_base']={'default_register_pairs':[list(default[i:i+2]) for i in range(0,32,2)],
        'menu_patch':menu,'evidence':evidence(symbols['DefaultPalette'],32),
        'display_conversion':'linear RGB3 to RGB8; no analog calibration'}

    # Decode actual tilesets. IDs not loaded by these routines stay null.
    for set_id in range(8):
        tiles=[None]*256
        loads=[]
        def load_tiles(offset,count,dest,flip=False):
            raw=read(rom,offset,count*24)
            ev=evidence(offset,count*24)
            if dest+count>256:
                raise ValueError('Tile destination outside tileset')
            for i in range(count):
                tile=planar(raw[i*24:i*24+24],3,color_map)
                tiles[dest+i]=flip_x(tile) if flip else tile
            loads.append({'destination':dest,'count':count,'flip_x':flip,'evidence':ev})
        load_tiles(symbols['gfxPowSwitch'],4,146)
        if set_id!=6:
            load_tiles(symbols['GfxCrates'],8,160)
            load_tiles(symbols['GfxCrates'],8,208,True)
        cursor=pointer(rom,symbols['idxTileSets']+set_id*2,0xE000)
        descriptor_start=cursor
        previous=None
        for _ in range(3):
            config=read(rom,cursor,1)[0]
            if config&128:
                cursor+=1
                break
            if config&64:
                if previous is None:
                    raise ValueError('Flip without prior source')
                destination=read(rom,cursor+1,1)[0]
                load_tiles(previous[0],previous[1],destination,True)
                cursor+=2
                # In inspected descriptors flip is final block (B reaches 0).
            else:
                count,destination=read(rom,cursor+1,2)
                if not count:
                    raise ValueError('Zero count is not supported')
                source=pointer(rom,cursor+3,0xE000)
                load_tiles(source,count,destination)
                previous=(source,count)
                cursor+=5
        package['tilesets'].append({'id':set_id,'tile_pixel_width':8,'tile_pixel_height':8,
            'color_map':color_map,'pixels_by_tile':tiles,'loads':loads,
            'unloaded_tile_ids':[i for i,t in enumerate(tiles) if t is None],
            'evidence':evidence(descriptor_start,cursor-descriptor_start)})

    # All 251 index entries are represented, including explicitly undefined ones.
    layouts={}
    for room_id in range(251):
        index=symbols['idxRooms']+room_id*2
        off=pointer(rom,index,0x1A000)
        meta=nibble(rom,symbols['MetaTileSetIDs'],room_id)
        gfx=nibble(rom,symbols['RoomGfxSetIds'],room_id)
        pal=nibble(rom,symbols['IdsRoomPal'],room_id)
        room={'id':room_id,'layout_ref':None,'metatile_set_ref':meta,'graphics_set_ref':gfx,
              'palette_ref':pal,'status':'undefined','expanded_tiles':[], 'static_collision':[],
              'evidence':evidence(index,2)}
        if off!=symbols['RoomUndefined'] and meta in metabytes:
            layout_id=f'layout_{off:05x}'
            raw=read(rom,off,48)
            if not any(label.startswith('Room') for label in by_offset.get(off,[])):
                raise ValueError('Room pointer not at known layout boundary')
            expanded=expand_metatiles(raw,metabytes[meta])
            room.update(layout_ref=layout_id,status='decoded',expanded_tiles=list(expanded))
            if gfx<7:
                flags=package['collision_profiles'][gfx]['movement_blocked_by_tile']
                room['static_collision']=[flags[t] for t in expanded]
            layouts[layout_id]={'id':layout_id,'grid_width':8,'grid_height':6,'id_base':1,
                'metatile_ids':list(raw),'source_labels':by_offset[off],'evidence':evidence(off,48)}
        else:
            package['diagnostics'].append({'room_id':room_id,'kind':'undefined_layout',
                'detail':'RoomUndefined pointer or unsupported metatile selector; no fabricated map'})
        package['rooms'].append(room)
        ci=connection_index(room_id)
        values=list(read(rom,symbols['RoomConnections']+ci*4,4)) if ci is not None else []
        package['connections'].append({'room_id':room_id,'table_index':ci,
            'destinations':[None if v==255 else v for v in values],
            'evidence':evidence(symbols['RoomConnections']+ci*4,4) if ci is not None else None})
        # Door index omits rooms 225..239. Keep opening rules raw and separate.
        if room_id<225 or room_id>=240:
            di=room_id if room_id<225 else room_id-15
            off=pointer(rom,symbols['idxDoors']+di*2,0x1A000)
            rows,ev=records(off,5,8)
            for ordinal,(door_id,render,y,x,destination) in enumerate(rows):
                if not 1<=render<=20 or not 1<=door_id<=160:
                    raise ValueError('Door ID/type out of range')
                logic=read(rom,symbols['IdDoorsLogic']+door_id-1,1)[0]
                region=list(read(rom,symbols['DoorOpenEnterDat']+(render-1)*8,8))
                package['doors'].append({'room_id':room_id,'ordinal':ordinal,'door_id':door_id,
                    'render_type_id':render,'draw_y':y,'draw_x':x,'destination_room_id':destination,
                    'open_logic_raw':logic,'open_rule_id':logic&31,'region_profile_raw':region,
                    'evidence':ev,'rule_evidence':evidence(symbols['IdDoorsLogic']+door_id-1,1),
                    'region_evidence':evidence(symbols['DoorOpenEnterDat']+(render-1)*8,8)})
        if room_id<222:
            off=pointer(rom,symbols['idxActorsRooms']+room_id*2,0x8000)
            count=read(rom,off,1)[0]&15
            read(rom,off,1+count*3)
            if off+1+count*3>bounded_end(off):
                raise ValueError('Actor count exceeds source block')
            for ordinal in range(count):
                actor,y,x=read(rom,off+1+ordinal*3,3)
                package['entities'].append({'room_id':room_id,'ordinal':ordinal,'actor_type_id':actor,
                    'y':y,'x':x,'path_binding':'runtime_init_not_normalized',
                    'evidence':evidence(off+1+ordinal*3,3)})
        if 122<=room_id<218:
            si=read(rom,symbols['idxRoomItemsIdx']+room_id-122,1)[0]
            if si:
                off=pointer(rom,symbols['idxRoomItems']+(si-1)*2,0x8000)
                rows,ev=records(off,3,3)
                for ordinal,(item,y,x) in enumerate(rows):
                    package['items'].append({'room_id':room_id,'ordinal':ordinal,'item_type_id':item,
                        'y':y,'x':x,'availability_rule':'AddRoomItems: collected flags and progression gates',
                        'evidence':ev})
    package['layouts']=list(layouts.values())
    # Paths contain byte count + Y/X pairs; lists have no terminator: source boundaries bound them.
    path_ids={}
    for label,off in symbols.items():
        if label.startswith('Path_'):
            count=read(rom,off,1)[0]
            size=bounded_end(off)-off-1
            if off < symbols['Path_039_01'] and size >= count*2:
                kind='points_yx'
                if size > count*2:
                    package['diagnostics'].append({'room_id':None,'kind':'unconsumed_path_bytes',
                        'detail':label+': '+str(size-count*2)+' trailing bytes not interpreted'})
                size=count*2
                values=[list(read(rom,off+1+i*2,2)) for i in range(count)]
            elif size == count:
                kind='look_directions_raw'
                values=list(read(rom,off+1,count))
                if any(v>3 for v in values):
                    raise ValueError('Invalid look direction')
            else:
                raise ValueError('Unknown path record extent')
            path_id=f'path_{off:05x}'
            path_ids[off]=path_id
            package['paths'].append({'id':path_id,'source_label':label,'kind':kind,
                'values':values,'evidence':evidence(off,1+size)})
    path_segment=next(s for s in ref.segments if s['files']==['data/paths.asm'])
    count=(path_segment['offset']+path_segment['length']-symbols['idxRoomPaths'])//2
    for room_id in range(count):
        off=pointer(rom,symbols['idxRoomPaths']+room_id*2,0x8000)
        end=bounded_end(off)
        candidates=[]
        for pos in range(off,end,2):
            target=pointer(rom,pos,0x8000)
            if target not in path_ids:
                raise ValueError('Unknown patrol path pointer')
            candidates.append(path_ids[target])
        package['room_paths'].append({'room_id':room_id,'ordered_path_refs':candidates,
            'binding_status':'ordered_candidates; actor ordinal resolved by runtime initialization',
            'evidence':evidence(off,end-off)})
    # Report graph issues without pretending all edges must be reciprocal.
    valid={x['id'] for x in package['rooms'] if x['status']=='decoded'}
    for conn in package['connections']:
        for target in conn['destinations']:
            if target is not None and target not in valid:
                package['diagnostics'].append({'room_id':conn['room_id'],'kind':'connection_to_undefined',
                    'detail':str(target)})
    package['limitations']=[
        'Static room backgrounds only; no live door, actor, item or event composition.',
        'Undefined rooms are retained; no claim that every decoded room is reachable.',
        'Unloaded tiles remain null. Preview marks missing tiles; no invented graphics.',
        'Palette preview applies default + menu + nominal room patch, not live goggles/darkness/sprite palette state.',
        'Actor-path binding and progression scripts remain runtime-specific; raw ordered data retained.',
        'No emulator execution, audio extraction, text extraction or full ROM rebuild.']
    package['manifest']={'format_version':'0.1.0','tool_version':VERSION,'reference_commit':PINNED_REVISION,
        'input_size':len(rom),'input_crc32':f'{zlib.crc32(rom)&0xffffffff:08X}',
        'input_sha1':hashlib.sha1(rom).hexdigest(),'input_sha256':hashlib.sha256(rom).hexdigest(),
        'input_role':'primary' if hashlib.sha256(rom).hexdigest()==PRIMARY_SHA256 else 'region_verified_candidate',
        'verification_scope':'all exported source-data segments compared byte-for-byte; behavior statically inspected',
        'verified_segments':ref.segments,'source_hashes':ref.source_hashes()}
    return package


def previews(package):
    result={}
    # 8 tileset atlases: unloaded slots use diagnostic checkerboard.
    def palette_for(palette_id):
        pairs=[row[:] for row in package['palette_base']['default_register_pairs']]
        for patch in (package['palette_base']['menu_patch'],package['palettes'][palette_id]):
            for index,rb,g in patch['registers']:
                pairs[index]=[rb,g]
        return rgb_palette(pairs)+[[255,0,255],[40,0,40]]
    def missing():
        return [16+(x+y)%2 for y in range(8) for x in range(8)]
    for ts in package['tilesets']:
        pixels=[0]*(128*128)
        for i,tile in enumerate(ts['pixels_by_tile']):
            tile=missing() if tile is None else tile
            for y in range(8):
                dest=(i//16*8+y)*128+(i%16)*8
                pixels[dest:dest+8]=tile[y*8:y*8+8]
        result[f'previews/tileset-{ts["id"]}.png']=png_indexed(128,128,pixels,palette_for(0))
    # Nominal room samples, one per graphics set (except ending which has no room index).
    selected=[]
    contact=[0]*(1024*384)
    contact_palette=[]
    for gfx in range(7):
        room=next(x for x in package['rooms'] if x['status']=='decoded' and x['graphics_set_ref']==gfx)
        selected.append(room['id'])
        pixels=[0]*(256*192)
        ts=package['tilesets'][gfx]
        for i,tile_id in enumerate(room['expanded_tiles']):
            tile=ts['pixels_by_tile'][tile_id]
            tile=missing() if tile is None else tile
            for y in range(8):
                start=(i//32*8+y)*256+(i%32)*8
                pixels[start:start+8]=tile[y*8:y*8+8]
        result[f'previews/room-{room["id"]:03d}-static.png']=png_indexed(256,192,pixels,palette_for(room['palette_ref']))
        palette=palette_for(room['palette_ref'])
        contact_palette.extend(palette)
        for y in range(192):
            start=((gfx//4)*192+y)*1024+(gfx%4)*256
            contact[start:start+256]=[p+gfx*18 for p in pixels[y*256:(y+1)*256]]
        mask=[room['static_collision'][(y//8)*32+x//8] for y in range(192) for x in range(256)]
        result[f'previews/room-{room["id"]:03d}-collision.png']=png_indexed(256,192,mask,[[20,30,35],[230,80,50]])
        overlay=[p+18 if blocked else p for p,blocked in zip(pixels,mask)]
        overlay_palette=palette+[[min(255,(r+255)//2),g//2,b//2] for r,g,b in palette]
        result[f'previews/room-{room["id"]:03d}-overlay.png']=png_indexed(256,192,overlay,overlay_palette)
    result['previews/contact-sheet.png']=png_indexed(1024,384,contact,contact_palette)
    result['previews/README.txt']=('Static samples: '+str(selected)+'\nMagenta checkerboard = unloaded tile; no assets invented.\nPalettes are nominal; no live sprites/doors/items, darkness or goggles.\n').encode()
    return result


def publish(output, files):
    """Never overwrite anything, including symlinks/hardlinks or old packages."""
    if output.exists() or output.is_symlink():
        raise ValueError('Output already exists; choose a new directory')
    output.parent.mkdir(parents=True,exist_ok=True)
    staging=Path(tempfile.mkdtemp(prefix='.extract-',dir=output.parent))
    try:
        for name,payload in files.items():
            relative=Path(name)
            if relative.is_absolute() or '..' in relative.parts:
                raise ValueError('Unsafe output member path')
            target=staging/relative
            target.parent.mkdir(parents=True,exist_ok=True)
            with target.open('xb') as f:
                f.write(payload)
        # link/rename races are not expected in this local workflow, recheck before rename.
        if output.exists() or output.is_symlink():
            raise ValueError('Output appeared during extraction')
        staging.rename(output)
    except BaseException:
        shutil.rmtree(staging)
        raise


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rom',required=True,type=Path)
    parser.add_argument('--output',required=True,type=Path)
    parser.add_argument('--reference',type=Path,default=ROOT/'external/MetalGear')
    parser.add_argument('--dry-run',action='store_true')
    args=parser.parse_args()
    # Outputs must be under the explicitly ignored private data tree.
    private=(ROOT/'data/extracted').resolve()
    output=args.output.absolute()
    if private not in output.resolve().parents:
        raise ValueError('Output must be a new directory under data/extracted')
    if output.exists() or output.is_symlink():
        raise ValueError('Output exists; refusing overwrite')
    rom=args.rom.read_bytes()
    package=build(rom,args.reference)
    from tools.extractors.schema import validate_package
    validate_package(package)
    if args.rom.read_bytes()!=rom:
        raise ValueError('Input changed during extraction')
    counts={k:len(package[k]) for k in ('rooms','layouts','metatile_sets','tilesets','doors','entities','paths','items','diagnostics')}
    if not args.dry_run:
        files={'package.json':encode(package),**previews(package)}
        files['checksums.json']=encode({k:hashlib.sha256(v).hexdigest() for k,v in sorted(files.items())})
        publish(output,files)
    print(json.dumps({'dry_run':args.dry_run,'counts':counts,'input_unchanged':True,
                      'input_role':package['manifest']['input_role']},indent=2))

if __name__=='__main__':
    try:
        main()
    except (ValueError,OSError) as error:
        print('Extraction failed: '+str(error),file=sys.stderr)
        sys.exit(1)
