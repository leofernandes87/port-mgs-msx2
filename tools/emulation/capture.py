"""Read-only openMSX capture for the canonical ROM (resolved by hash)."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT))
from tools.extractors.extract import encode
from tools.rom import resolve_canonical_rom

# Banks 0-3 occupy CPU 4000h-BFFFh, so physical offset = CPU - 4000h for these routines.
ANCHORS={
    'RenderRoom':rb'\xcd..\xcd..\x21\x00\xe0\x22..\x11\x00\x60\xcd..\xeb\x06\x06',
    'WaitVdpCmd':rb'\x3e\x02\xcd..\x1f\xda\xd2\x4e\xc9',
    'LoadRoomTiles':rb'\xcd\xc4\x42\xcd\x6a\x42\x21\x00\x60\xcd\xd1\x42\x21\x57\xc1',
    'DrawDoors':rb'\x3a\xff\xc4\xa7\xc8\x47\x21\xd0\xc3',
}
WAIT_VDP_CMD_LENGTH=9


def breakpoints(rom,profile):
    """Every reviewed CPU address must match its instruction anchor exactly once."""
    expected={name:int(value,16) for name,value in profile['debugger_cpu'].items()}
    if set(expected)!=set(ANCHORS):
        raise ValueError('Profile debugger addresses differ from the reviewed anchor set')
    for name,pattern in ANCHORS.items():
        found=[m.start() for m in re.finditer(pattern,rom[:0x8000],re.S)]
        if found!=[expected[name]-0x4000]:
            raise ValueError(f'{name} instruction anchor differs')
    return {'load_tiles':expected['LoadRoomTiles'],'room':expected['RenderRoom'],
            'doors':expected['DrawDoors'],'vdp_settled':expected['WaitVdpCmd']+WAIT_VDP_CMD_LENGTH}


def run(rom_path,output,emulator,mode='demo',machine=None):
    canonical=resolve_canonical_rom(rom_path)
    rom_path,rom,digest=canonical.path,canonical.data,canonical.sha256
    machine=machine or canonical.profile['openmsx_machine']
    cpu=breakpoints(rom,canonical.profile)
    private=(ROOT/'data/extracted').resolve()
    if private not in output.resolve().parents or output.exists() or output.is_symlink():
        raise ValueError('Choose a new output directory under data/extracted')
    version=subprocess.check_output([str(emulator),'--version'],text=True).strip()
    if not version.startswith('openMSX 21.0'):
        raise ValueError('Capture commands reviewed for openMSX 21.0')
    output.mkdir(parents=True)
    script=output/'capture.tcl'
    shutil.copyfile(Path(__file__).with_suffix('.tcl'),script)
    (output/'config.tcl').write_text(f'set capture_mode "{mode}"\n'+''.join(
        f'set bp_{name} 0x{address:04x}\n' for name,address in cpu.items()))
    command=[str(emulator),'-machine',machine,'-cart',str(rom_path.resolve()),'-script',str(script.resolve())]
    result=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=90)
    (output/'emulator.log').write_bytes(result.stdout)
    if result.returncode or not (output/'finished.txt').exists() or not list(output.glob('*-ram.bin')):
        raise ValueError('Capture did not finish with any room; inspect private emulator.log')
    canonical.assert_unchanged()
    files={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(output.iterdir()) if p.is_file()}
    actions='keyboard matrix input only (SNSMAT); no RAM/VRAM/ROM writes' if mode=='gameplay' else 'none; natural title/demo sequence; no RAM/VRAM/ROM writes'
    manifest={'format_version':'1.0.0','emulator':version,'machine':machine,
              'input_sha256':digest,'rom_profile':canonical.profile_id,
              'capture_point':'LoadRoomTiles entry, RenderRoom return, and DrawDoors return',
              'breakpoint_cpu':cpu['room'],'breakpoint_load_tiles_cpu':cpu['load_tiles'],
              'breakpoint_draw_doors_cpu':cpu['doors'],'breakpoint_vdp_settled_cpu':cpu['vdp_settled'],
              'capture_mode':mode,'input_unchanged':True,'files':files,
              'input_actions':actions}
    (output/'manifest.json').write_bytes(encode(manifest))
    print(json.dumps({'rooms':len(list(output.glob('*-ram.bin'))),'input_unchanged':True}))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rom',type=Path,help='Explicit ROM; validated against the canonical hash')
    parser.add_argument('--output',required=True,type=Path)
    parser.add_argument('--emulator',type=Path,default=Path('/Applications/openMSX.app/Contents/MacOS/openmsx'))
    parser.add_argument('--machine',help='openMSX machine (default: the canonical profile, C-BIOS_MSX2_EU)')
    parser.add_argument('--mode',choices=['demo','gameplay'],default='demo',
                        help='Capture mode: "demo" (natural sequence) or "gameplay" (new game into elevator room 240)')
    args=parser.parse_args()
    try:run(args.rom,args.output,args.emulator,mode=args.mode,machine=args.machine)
    except (ValueError,OSError,subprocess.SubprocessError) as error:
        print('Capture failed: '+str(error),file=sys.stderr);sys.exit(1)
