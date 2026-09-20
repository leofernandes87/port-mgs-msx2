"""Original synthetic data only; these tests do not require the reference or ROM."""
import copy
import json
import os
from pathlib import Path
import struct
import tempfile
import unittest
import zlib
from tools.extractors.codecs import (read, word, pointer, nibble, collision_bits,
    planar, flip_x, terminated, unpack_gfx, rgb_palette, png_indexed, connection_index)
from tools.extractors.extract import encode, publish
from tools.extractors.schema import validate, validate_relations, SCHEMA
from tools.extractors.batch_snapshots import _compose_raster, build_palette, parse_room_range, BUILDING_SCOPES
from tools.reverse_engineering.analyze import data_segment


class CodecTests(unittest.TestCase):
    def test_pointer_across_group_banks(self):
        for cpu in (0x6000,0x7fff,0x8000,0x9fff,0xa000,0xbfff):
            data=cpu.to_bytes(2,'little')+bytes(0x7ffe)
            self.assertEqual(pointer(data,0,0x2000),0x2000+cpu-0x6000)
        for data in (b'\x00',b'\xff\x5f',b'\x00\xc0',b'\x01\x60'):
            with self.assertRaises(ValueError):
                pointer(data,0,0x2000)
        self.assertEqual(word(b'\x12\x34',0),0x3412)

    def test_bounded_read_and_nibbles(self):
        self.assertEqual([nibble(b'\xab\xcd',0,i) for i in range(4)],[10,11,12,13])
        for offset,size in [(-1,1),(0,-1),(1,2)]:
            with self.assertRaises(ValueError):read(b'ab',offset,size+1 if offset==1 else size)

    def test_collision_every_bit(self):
        for i in range(256):
            data=bytearray(32);data[i//8]=1<<(7-i%8)
            bits=collision_bits(data)
            self.assertEqual([j for j,v in enumerate(bits) if v],[i])
        with self.assertRaises(ValueError):collision_bits(bytes(31))

    def test_planar_planes_and_orientation(self):
        for bpp in (1,2,3):
            for plane in range(bpp):
                raw=bytearray(bpp*8);raw[3*bpp+plane]=0x81
                pixels=planar(raw,bpp,list(range(1<<bpp)))
                self.assertEqual(pixels[24:32],[1<<plane,0,0,0,0,0,0,1<<plane])
                self.assertEqual(sum(pixels),2*(1<<plane))
        raw=bytes([0x55,0x33,0x0f])*8
        self.assertEqual(planar(raw,3,list(range(8)))[:8],list(range(8)))
        self.assertEqual(planar(bytes([0x80])*8,1,[0,13])[:8],[13,0,0,0,0,0,0,0])

    def test_planar_rejects_truncation(self):
        for raw,bpp,palette in [(bytes(23),3,list(range(8))),(bytes(24),4,list(range(8))),(bytes(24),3,[0])]:
            with self.assertRaises(ValueError):planar(raw,bpp,palette)

    def test_flip_each_row_not_tile_order(self):
        pixels=list(range(64));result=flip_x(pixels)
        self.assertEqual(result[:8],list(range(7,-1,-1)))
        self.assertEqual(result[8:16],list(range(15,7,-1)))
        self.assertEqual(flip_x(result),pixels)

    def test_record_terminator_only_on_boundary(self):
        self.assertEqual(terminated(bytes([1,255,2,255]),0,3,3),([[1,255,2]],4))
        self.assertEqual(terminated(b'\xff',0,3,3),([],1))
        for data,limit,end in [(bytes([1,2,3]),3,None),(bytes([1,2,3,255]),0,None),(bytes([1,2,3,255]),3,3)]:
            with self.assertRaises(ValueError):terminated(data,0,3,limit,end)

    def test_unpack_runs_literals_and_address_change(self):
        raw=bytes([0x20,0,3,7,0x82,8,9,0x80,0x40,0,1,6,0])
        self.assertEqual(unpack_gfx(raw),([(32,bytes([7,7,7,8,9])),(64,b'\x06')],len(raw)))
        for data in (b'\x00',b'\x00\x00\x03',b'\x00\x00\x82\x01',b'\x00\x00\x80',b'\xff\xff\x02\x01\x00'):
            with self.assertRaises(ValueError):unpack_gfx(data)
        with self.assertRaises(ValueError):unpack_gfx(raw,max_output=2)

    def test_connection_boundaries(self):
        expected={0:0,125:125,126:None,207:None,208:126,227:145,228:None,240:None,241:146,250:155,251:None}
        for room,index in expected.items():self.assertEqual(connection_index(room),index)

    def test_palette_and_png_roundtrip(self):
        self.assertEqual(rgb_palette([[0x70,7],[0x07,0]]),[[255,255,0],[0,0,255]])
        raw=png_indexed(2,2,[0,1,1,0],[[0,0,0],[255,0,0]])
        self.assertEqual(raw[:8],b'\x89PNG\r\n\x1a\n')
        pos=8;compressed=b''
        while pos<len(raw):
            size=struct.unpack('>I',raw[pos:pos+4])[0]
            kind=raw[pos+4:pos+8];payload=raw[pos+8:pos+8+size]
            self.assertEqual(struct.unpack('>I',raw[pos+8+size:pos+12+size])[0],zlib.crc32(kind+payload)&0xffffffff)
            if kind==b'IDAT':compressed+=payload
            pos+=12+size
        self.assertEqual(zlib.decompress(compressed),bytes([0,0,1,0,1,0]))
        with self.assertRaises(ValueError):png_indexed(1,1,[2],[[0,0,0]])

    def test_constants_are_resolved_without_eval(self):
        data,_,_=data_segment([('fixture','Here: db TEST\n dw Here')],0x6000,{'TEST':42})
        self.assertEqual(data,bytes([42,0,0x60]))


class ContractAndSafetyTests(unittest.TestCase):
    def test_layout_contract_and_invalid_ids(self):
        schema=json.loads(SCHEMA.read_text())
        fixture=json.loads((SCHEMA.parents[1]/'fixtures/synthetic-layout.json').read_text())
        validate(fixture,schema['$defs']['Layout'],schema)
        for field,value in [('grid_width',9),('metatile_ids',[0]*48),('metatile_ids',[1]*47),('id_base',True)]:
            invalid={**fixture,field:value}
            with self.assertRaises(ValueError):validate(invalid,schema['$defs']['Layout'],schema)
        with self.assertRaises(ValueError):validate({**fixture,'mystery':1},schema['$defs']['Layout'],schema)

    def test_schema_rejects_bool_as_int_and_unknown_features(self):
        for schema in ({'type':'integer'},{'enum':[0,1]},{'const':1},{'unknown':1},{'$ref':'https://example.test/schema'}):
            with self.assertRaises(ValueError):validate(True,schema)

    def test_deterministic_json(self):
        self.assertEqual(encode({'b':1,'a':2}),encode({'a':2,'b':1}))

    def test_publication_refuses_existing_symlinks_and_hardlinks(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);original=root/'input';original.write_bytes(b'own synthetic input')
            out=root/'new';publish(out,{'dir/result.txt':b'own result'})
            self.assertEqual((out/'dir/result.txt').read_bytes(),b'own result')
            linked=root/'link';linked.symlink_to(original)
            broken=root/'broken';broken.symlink_to(root/'absent')
            hard=root/'hard';os.link(original,hard)
            for destination in (out,original,linked,broken,hard):
                with self.assertRaises(ValueError):publish(destination,{'x':b'bad'})
            self.assertEqual(original.read_bytes(),b'own synthetic input')

    def test_publication_rejects_path_escape_and_cleans_own_staging(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp)
            for name in ('../escape','/absolute'):
                with self.assertRaises(ValueError):publish(root/'new',{name:b'bad'})
            self.assertEqual(list(root.iterdir()),[])

    def test_cross_references_and_derived_values(self):
        p={'rooms':[{'id':i,'status':'undefined','layout_ref':None,'expanded_tiles':[],
                     'static_collision':[],'graphics_set_ref':0,'palette_ref':0} for i in range(251)],
           'layouts':[{'id':'own','metatile_ids':[1]*48}],
           'metatile_sets':[{'id':i,'definitions':[[0]*16]} for i in range(1,7)],
           'collision_profiles':[{'id':i,'movement_blocked_by_tile':[0]*256} for i in range(7)],
           'tilesets':[{'id':i,'pixels_by_tile':[None]*256,'unloaded_tile_ids':list(range(256))} for i in range(8)],
           'palettes':[{'id':i} for i in range(16)],'paths':[],'room_paths':[],'doors':[]}
        p['rooms'][0].update(status='decoded',layout_ref='own',metatile_set_ref=1,
                             expanded_tiles=[0]*768,static_collision=[0]*768)
        validate_relations(p)
        mutations=[lambda x:x['rooms'][0]['expanded_tiles'].__setitem__(0,1),
                   lambda x:x['rooms'][0]['static_collision'].__setitem__(0,1),
                   lambda x:x['rooms'][0].update(layout_ref='missing'),
                   lambda x:x['rooms'][0].update(metatile_set_ref=0),
                   lambda x:x['rooms'][1].update(layout_ref='own'),
                   lambda x:x['tilesets'][0]['unloaded_tile_ids'].pop(),
                   lambda x:x['room_paths'].append({'ordered_path_refs':['missing']})]
        for mutate in mutations:
            invalid=copy.deepcopy(p);mutate(invalid)
            with self.assertRaises(ValueError):validate_relations(invalid)


class BatchSnapshotTests(unittest.TestCase):
    """Synthetic tests for batch_snapshots.py using no real ROM or emulator output."""

    def _make_minimal_package(self):
        """Build a minimal package stub with 2 synthetic decoded rooms."""
        # 16 colours, each a flat [R,G,B]
        default_pairs = [[0, 0]] * 16
        palette_patch = {'registers': [[1, 0x70, 7]], 'evidence': {}}
        tile_all_zero = [0] * 64
        tile_all_one = [1] * 64
        pixels_by_tile = [None] * 256
        pixels_by_tile[3] = tile_all_zero
        pixels_by_tile[4] = tile_all_one
        tileset = {'id': 0, 'pixels_by_tile': pixels_by_tile, 'unloaded_tile_ids': [0, 1, 2]}
        room0 = {
            'id': 0, 'status': 'decoded', 'graphics_set_ref': 0, 'palette_ref': 0,
            'expanded_tiles': [3] * 768,  # all tile 3 (all-zero pixels)
            'static_collision': [0] * 768,
        }
        room1 = {
            'id': 1, 'status': 'decoded', 'graphics_set_ref': 0, 'palette_ref': 0,
            'expanded_tiles': [3] * 767 + [1],  # last cell uses unloaded tile 1
            'static_collision': [0] * 768,
        }
        package = {
            'tilesets': [tileset],
            'palettes': [{'id': 0, 'registers': [], 'evidence': {}}],
            'palette_base': {
                'default_register_pairs': default_pairs,
                'menu_patch': {'registers': []},
            },
            'manifest': {'input_sha256': 'a' * 64},
        }
        return package, [room0, room1]

    def test_compose_raster_dimensions(self):
        """_compose_raster always returns exactly 49152 ints."""
        tiles = [3] * 768
        atlas = [None] * 256
        atlas[3] = [5] * 64
        result = _compose_raster(tiles, atlas)
        self.assertEqual(len(result), 49152)
        self.assertTrue(all(p == 5 for p in result))

    def test_compose_raster_unloaded_renders_zero(self):
        """Unloaded tile slots (atlas[tid] is None) must render as pixel 0."""
        tiles = [0] * 768  # tile 0 is unloaded (None)
        atlas = [None] * 256
        result = _compose_raster(tiles, atlas)
        self.assertEqual(result, [0] * 49152)

    def test_compose_raster_tile_placement(self):
        """Each metatile cell is placed in the correct 8×8 pixel block."""
        atlas = [[0] * 64 for _ in range(256)]
        atlas[1] = [7] * 64  # distinct value
        # Put tile 1 at cell (row=0, col=1) and nowhere else
        tiles = [0] * 768
        tiles[1] = 1
        result = _compose_raster(tiles, atlas)
        # Pixels at (y=0..7, x=8..15) should be 7
        for y in range(8):
            for x in range(8):
                self.assertEqual(result[y * 256 + 8 + x], 7, f'cell y={y} x={x}')
        # All other pixels should be 0
        others = [result[y * 256 + x] for y in range(192) for x in range(256)
                  if not (0 <= y <= 7 and 8 <= x <= 15)]
        self.assertTrue(all(p == 0 for p in others))

    def test_build_palette_applies_patches(self):
        """build_palette returns an 18-entry list (16 room + 2 diagnostic colours)."""
        package, _ = self._make_minimal_package()
        palette = build_palette(package, 0)
        self.assertEqual(len(palette), 18)
        self.assertEqual(len(palette[0]), 3)
        # Last two entries are diagnostic colours from compare.py convention
        self.assertEqual(palette[16], [255, 0, 255])
        self.assertEqual(palette[17], [40, 0, 40])

    def test_parse_room_range_single_and_range(self):
        self.assertEqual(parse_room_range('5'), {5})
        self.assertEqual(parse_room_range('0-3'), {0, 1, 2, 3})
        with self.assertRaises(ValueError):
            parse_room_range('0-1-2')

    def test_building_scopes_cover_correct_ranges(self):
        self.assertEqual(set(BUILDING_SCOPES['building1']), set(range(0, 16)))
        self.assertEqual(set(BUILDING_SCOPES['building2']), set(range(16, 64)))
        self.assertEqual(set(BUILDING_SCOPES['building3']), set(range(64, 126)))
        b123 = set(BUILDING_SCOPES['buildings123'])
        self.assertEqual(b123, set(range(0, 126)))
        self.assertTrue(b123 == set(BUILDING_SCOPES['building1']) |
                        set(BUILDING_SCOPES['building2']) |
                        set(BUILDING_SCOPES['building3']))
