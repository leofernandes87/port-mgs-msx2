"""Synthetic framebuffer/capture tests; no game bytes required."""
import copy
import json
import unittest
from pathlib import Path
from tools.emulation.compare import atlas_tile,screen_pixels,compose,compare_room,door_record,classify_atlas_inheritance,reconstruct_doors_overlay
from tools.extractors.schema import validate


class CaptureComparisonTests(unittest.TestCase):
    def test_atlas_boundary_addresses_and_nibbles(self):
        for tile in (0,31,32,255):
            v=bytearray(65536)
            address=0x8000+(tile//32)*1024+(tile%32)*4
            v[address]=0xab;v[address+7*128+3]=0xcd
            pixels=atlas_tile(v,tile)
            self.assertEqual(pixels[:2],[10,11]);self.assertEqual(pixels[-2:],[12,13])
            self.assertEqual(sum(pixels),46)
        with self.assertRaises(ValueError):atlas_tile(bytes(65535),0)

    def test_compose_grid_and_orientation(self):
        atlas=[[i%16]*64 for i in range(256)]
        tiles=[i%256 for i in range(768)]
        pixels=compose(tiles,atlas)
        self.assertEqual(pixels[8],1)
        self.assertEqual(pixels[255],15)
        self.assertEqual(pixels[8*256+8],1)
        with self.assertRaises(ValueError):compose([256]*768,atlas)

    def fixture(self):
        room={'status':'decoded','graphics_set_ref':0,'palette_ref':0,'expanded_tiles':[0]*768,'static_collision':[0]*768}
        p={'doors':[],'rooms':[room],'tilesets':[{'pixels_by_tile':[[0]*64]+[None]*255,'unloaded_tile_ids':list(range(1,256))}],
           'palette_base':{'default_register_pairs':[[0,0]]*16,'menu_patch':{'registers':[]}},
           'palettes':[{'registers':[]}],'manifest':{'input_sha256':'0'*64,'rom_profile':'synthetic'}}
        return p,bytearray(16384),bytearray(65536)

    def test_matching_snapshot_and_contract(self):
        p,ram,v=self.fixture();snapshot,report=compare_room(p,ram,v,v)
        schema=json.loads(Path('data/schemas/room-snapshot.schema.json').read_text())
        validate(snapshot,schema)
        self.assertEqual(report['background_pixels_matched'],49152)
        self.assertEqual(report['ram_bytes_matched'],768)
        broken=copy.deepcopy(snapshot);broken['pixels'][0]=18
        with self.assertRaises(ValueError):validate(broken,schema)

    def test_pending_vdp_does_not_false_fail_but_settled_must_match(self):
        p,ram,v=self.fixture();pending=v[:];pending[24575]=0x01
        _,report=compare_room(p,ram,pending,v)
        self.assertEqual(report['initial_pending_pixels'],1)
        with self.assertRaises(ValueError):compare_room(p,ram,v,pending)

    def test_corrupt_ram_and_loaded_tile_are_rejected(self):
        p,ram,v=self.fixture();ram[0x2000]=1
        with self.assertRaises(ValueError):compare_room(p,ram,v,v)
        ram[0x2000]=0;v[0x8000]=0x10
        with self.assertRaises(ValueError):compare_room(p,ram,v,v)
        with self.assertRaises(ValueError):screen_pixels(bytes(1))

    def test_door_region_wrap_and_dummy_open_state(self):
        door={'door_id':1,'render_type_id':1,'open_logic_raw':65,'draw_y':250,'draw_x':6,
              'region_profile_raw':[10,8,246,16,0,24,0,32],'destination_room_id':2}
        result=door_record(door,1)
        self.assertEqual(result[7:11],[4,8,252,16])
        self.assertEqual(result[1],1)
        door['render_type_id']=6
        self.assertEqual(door_record(door,1)[1],0)

    def test_atlas_inheritance_classification(self):
        prior=bytearray(65536);settled=bytearray(65536)
        addr1=0x8000+4;prior[addr1]=0x11;settled[addr1]=0x22
        addr2=0x8000+8;prior[addr2]=0x33;settled[addr2]=0x33
        res=classify_atlas_inheritance(prior,settled,[1])
        self.assertEqual(res['overwritten_tile_ids'],[1])
        self.assertEqual(res['inherited_tile_ids'],[2])
        self.assertEqual(res['zeroed_count'],254)
        self.assertTrue(res['loaded_subset_of_overwritten_or_common'])
        with self.assertRaises(ValueError):classify_atlas_inheritance(bytes(10),settled,[])

    def test_compare_room_with_prior_vram(self):
        p,ram,v=self.fixture();prior=bytearray(65536);prior[0x8000]=0x10
        snapshot,report=compare_room(p,ram,v,v,prior_vram=prior)
        self.assertIn('atlas_inheritance',report)
        self.assertIn(0,report['atlas_inheritance']['overwritten_tile_ids'])

    def test_reconstruct_doors_overlay(self):
        base=[0]*49152;door={'door_id':1,'render_type_id':5,'draw_x':100,'draw_y':0}
        vram=bytearray(65536);ram=bytearray(16384)
        vram[0x8000+192*128+196//2]=0xf0
        ram[0x450]=1
        pixels,closed=reconstruct_doors_overlay(base,[door],vram,ram)
        self.assertEqual(closed,1)
        self.assertEqual(pixels[0*256+100],15)
        ram[0x450]=0
        pixels_open,closed_open=reconstruct_doors_overlay(base,[door],vram,ram)
        self.assertEqual(closed_open,0)
        self.assertEqual(pixels_open,base)

    def test_compare_room_with_doors_vram(self):
        p,ram,v=self.fixture()
        door={'door_id':1,'room_id':0,'ordinal':0,'render_type_id':5,'draw_x':100,'draw_y':0,
              'open_logic_raw':65,'region_profile_raw':[0]*8,'destination_room_id':2}
        p['doors']=[door];ram[0x450]=1
        ram[0x3d0:0x3e0]=door_record(door,1)
        v[0x8000+192*128+196//2]=0xf0
        expected_doors,_=reconstruct_doors_overlay([0]*49152,[door],v,ram)
        doors_v=bytearray(65536)
        for y in range(192):
            for x in range(0,256,2):
                p1=expected_doors[y*256+x];p2=expected_doors[y*256+x+1]
                doors_v[y*128+x//2]=(p1<<4)|p2
        snapshot,report=compare_room(p,ram,v,v,doors_vram=doors_v)
        self.assertIn('doors_delta',report)
        self.assertEqual(report['doors_delta']['closed_doors_count'],1)
        self.assertEqual(report['doors_delta']['modified_pixels_count'],1)
        bad_doors=bytearray(doors_v);bad_doors[0]=0x99
        with self.assertRaises(ValueError):compare_room(p,ram,v,v,doors_vram=bad_doors)
