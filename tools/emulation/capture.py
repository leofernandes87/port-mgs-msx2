"""Read-only openMSX capture for the explicitly verified primary ROM."""
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
from tools.extractors.extract import PRIMARY_SHA256, encode


def run(rom_path,output,emulator,mode='demo'):
    rom=rom_path.read_bytes()
    digest=hashlib.sha256(rom).hexdigest()
    if digest!=PRIMARY_SHA256:
        raise ValueError('Debugger addresses reviewed only for the primary SHA-256')
    # Match the instruction structure independently before enabling a breakpoint.
    matches=[m.start() for m in re.finditer(rb'\xcd..\xcd..\x21\x00\xe0\x22..\x11\x00\x60\xcd..\xeb\x06\x06',rom[:0x8000],re.S)]
    if matches!=[0xcf0]:
        raise ValueError('RenderRoom instruction anchor differs')
    waits=[m.start() for m in re.finditer(rb'\x3e\x02\xcd..\x1f\xda\xd2\x4e\xc9',rom[:0x8000],re.S)]
    if waits!=[0xed2]:
        raise ValueError('WaitVdpCmd instruction anchor differs')
    load_tiles=[m.start() for m in re.finditer(rb'\xcd\xc4\x42\xcd\x6a\x42\x21\x00\x60\xcd\xd1\x42\x21\x57\xc1',rom[:0x8000],re.S)]
    if load_tiles!=[0x935]:
        raise ValueError('LoadRoomTiles instruction anchor differs')
    private=(ROOT/'data/extracted').resolve()
    if private not in output.resolve().parents or output.exists() or output.is_symlink():
        raise ValueError('Choose a new output directory under data/extracted')
    version=subprocess.check_output([str(emulator),'--version'],text=True).strip()
    if not version.startswith('openMSX 21.0'):
        raise ValueError('Capture commands reviewed for openMSX 21.0')
    output.mkdir(parents=True)
    script=output/'capture.tcl'
    shutil.copyfile(Path(__file__).with_suffix('.tcl'),script)
    (output/'config.tcl').write_text(f'set capture_mode "{mode}"\n')
    command=[str(emulator),'-machine','C-BIOS_MSX2_JP','-cart',str(rom_path.resolve()),'-script',str(script.resolve())]
    result=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=90)
    (output/'emulator.log').write_bytes(result.stdout)
    if result.returncode or not (output/'finished.txt').exists() or not list(output.glob('*-ram.bin')):
        raise ValueError('Capture did not finish with any room; inspect private emulator.log')
    if rom_path.read_bytes()!=rom:
        raise ValueError('Input changed during capture')
    files={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(output.iterdir()) if p.is_file()}
    actions='keyboard matrix input only (SNSMAT); no RAM/VRAM/ROM writes' if mode=='gameplay' else 'none; natural title/demo sequence; no RAM/VRAM/ROM writes'
    manifest={'format_version':'1.0.0','emulator':version,'machine':'C-BIOS_MSX2_JP',
              'input_sha256':digest,'capture_point':'RenderRoom return before DrawDoors and LoadRoomTiles entry',
              'breakpoint_cpu':0x4cf0,'breakpoint_load_tiles_cpu':0x4935,'capture_mode':mode,'input_unchanged':True,'files':files,
              'input_actions':actions}
    (output/'manifest.json').write_bytes(encode(manifest))
    print(json.dumps({'rooms':len(list(output.glob('*-ram.bin'))),'input_unchanged':True}))


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rom',required=True,type=Path)
    parser.add_argument('--output',required=True,type=Path)
    parser.add_argument('--emulator',type=Path,default=Path('/Applications/openMSX.app/Contents/MacOS/openmsx'))
    parser.add_argument('--mode',choices=['demo','gameplay'],default='demo',
                        help='Capture mode: "demo" (natural sequence) or "gameplay" (new game into elevator room 240)')
    args=parser.parse_args()
    try:run(args.rom,args.output,args.emulator,mode=args.mode)
    except (ValueError,OSError,subprocess.SubprocessError) as error:
        print('Capture failed: '+str(error),file=sys.stderr);sys.exit(1)
