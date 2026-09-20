"""Optional private integration: rebuild, audit hashes and reject changed source data."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0,str(ROOT))
from tools.extractors.extract import build, encode, previews
from tools.extractors.schema import validate_package


def verify(rom_path,reference,package_path,repeat=None):
    original=rom_path.read_bytes()
    package=build(original,reference)
    validate_package(package)
    expected={'package.json':encode(package),**previews(package)}
    checksums={name:hashlib.sha256(payload).hexdigest() for name,payload in sorted(expected.items())}
    expected['checksums.json']=encode(checksums)
    ignored_metadata=[]
    for destination in [package_path]+([repeat] if repeat else []):
        members=[p for p in destination.rglob('*') if p.is_file()]
        ignored_metadata.extend(str(p.relative_to(destination)) for p in members if p.name=='.DS_Store')
        found={str(p.relative_to(destination)) for p in members if p.name!='.DS_Store'}
        if found!=set(expected):
            raise ValueError('Package file inventory differs from reconstruction')
        for name,payload in expected.items():
            if (destination/name).read_bytes()!=payload:
                raise ValueError('Nonreproducible file: '+name)
    # Mutations stay in memory; never modify the ROM, even for negative checks.
    changed=bytearray(original)
    changed[package['manifest']['verified_segments'][0]['offset']]^=1
    for candidate in (bytes(changed),original[:8192]):
        try:
            build(candidate,reference)
        except ValueError:
            pass
        else:
            raise ValueError('Corrupt/truncated input was accepted')
    if original!=rom_path.read_bytes():
        raise ValueError('Original changed during verification')
    return {'files_identical':len(expected),'runs_compared':2 if repeat else 1,
            'package_sha256':checksums['package.json'],'input_sha256':hashlib.sha256(original).hexdigest(),
            'negative_inputs_rejected':2,'ignored_os_metadata':ignored_metadata,'schema_and_derived_data':'passed','input_unchanged':True}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rom',required=True,type=Path)
    parser.add_argument('--package',required=True,type=Path)
    parser.add_argument('--repeat-package',type=Path)
    parser.add_argument('--reference',type=Path,default=ROOT/'external/MetalGear')
    args=parser.parse_args()
    print(json.dumps(verify(args.rom,args.reference,args.package,args.repeat_package),indent=2))

if __name__=='__main__':
    try:main()
    except (OSError,ValueError) as error:
        print('Verification failed: '+str(error),file=sys.stderr)
        sys.exit(1)
