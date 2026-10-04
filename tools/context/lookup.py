"""Consulta os índices e imprime só a faixa relevante (uma chamada em vez de buscar e depois ler).

  python3 -m tools.context.lookup asm ChkRadioCalls [-n 40] [--jp]  # definição + N linhas do asm
  python3 -m tools.context.lookup ram TextId                         # endereço/tamanho (aceita trecho)
  python3 -m tools.context.lookup cites logic/items.asm[:399]        # quem cita o trecho
  python3 -m tools.context.lookup gd godot/scripts/systems/enemy.gd _physics_process
  python3 -m tools.context.lookup mech [radio]                       # cadeia completa da mecânica
  python3 -m tools.context.lookup progress ["Fase 4"]                # última entrada ou por título
"""
import argparse
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.context import build_index, progress_archive  # noqa: E402


def local_index(name):
    path = build_index.LOCAL_INDEX / name
    if build_index.REFERENCE.is_dir():
        build_index.refresh_local_indexes(build_index.asm_sources())
    if not path.exists():
        raise SystemExit('external/MetalGear ausente: índice asm indisponível')
    return [line.split('\t') for line in path.read_text().splitlines() if not line.startswith('#')]


def cmd_asm(args):
    rows = [r for r in local_index('asm-symbols.tsv') if r[0] == args.symbol and (args.jp or r[4] != 'jp')]
    if not rows:
        close = sorted({r[0] for r in local_index('asm-symbols.tsv') if args.symbol.lower() in r[0].lower()})
        print('não encontrado; parecidos: ' + ', '.join(close[:30]))
        return 1
    for symbol, kind, where, group, branch, value in rows:
        file, line = where.rsplit(':', 1)
        print(f'== external/MetalGear/{where} ({kind}{", grupo " + group if group else ""}'
              f'{", ramo " + branch if branch else ""}){" = " + value if value else ""}')
        if kind == 'label':
            lines = (build_index.REFERENCE / file).read_text(encoding='latin-1').splitlines()
            start = int(line)
            for number in range(start, min(len(lines), start + args.n - 1) + 1):
                print(f'{number:6}|{lines[number - 1]}')
    return 0


def cmd_ram(args):
    rows = local_index('ram-map.tsv')
    exact = [r for r in rows if r[0] == args.name]
    for r in exact or [r for r in rows if args.name.lower() in r[0].lower()]:
        print('\t'.join(r))
    return 0 if rows else 1


def cmd_cites(args):
    path, _, line = args.target.partition(':')
    text = (build_index.DOCS_INDEX / 'asm-citations.md').read_text()
    section = re.search(r'^## (\S*' + re.escape(path) + r')\n(.*?)(?=^## |\Z)', text, re.M | re.S)
    if not section:
        print('nenhuma citação para ' + path)
        return 1
    print('## ' + section.group(1))
    for entry in section.group(2).strip().splitlines():
        span = entry[2:].split(':', 1)[0]
        if line and span != 'arquivo':
            first, _, last = span.partition('-')
            if not int(first) <= int(line) <= int(last or first):
                continue
        print(entry)
    return 0


def cmd_gd(args):
    lines = (ROOT / args.file).read_text().splitlines()
    pattern = re.compile(r'^\s*(?:static\s+)?func\s+' + re.escape(args.function) + r'\s*\(')
    starts = [i for i, l in enumerate(lines) if pattern.match(l)]
    if not starts:
        print('função não encontrada')
        return 1
    start = starts[0]
    indent = len(lines[start]) - len(lines[start].lstrip())
    end = start + 1
    while end < len(lines):
        current = lines[end]
        if current.strip() and len(current) - len(current.lstrip()) <= indent and not current.lstrip().startswith('#'):
            break
        end += 1
    for number in range(start, end):
        print(f'{number + 1:6}|{lines[number]}')
    return 0


def cmd_mech(args):
    data = json.loads((build_index.DOCS_INDEX / 'mechanics.json').read_text())
    if not args.id:
        for item in data['mechanics']:
            print(f'{item["id"]:20} {item["title"]}')
        return 0
    for item in data['mechanics']:
        if item['id'] == args.id:
            for key in ('title', 'asm', 'extractor', 'data', 'godot', 'integration', 'tests', 'docs'):
                if key in item:
                    value = item[key]
                    print(f'{key:12} ' + (value if isinstance(value, str) else '\n             '.join(value) or '—'))
            return 0
    print('mecânica desconhecida')
    return 1


def cmd_progress(args):
    sources = [p for p in progress_archive.archive_files(ROOT / 'docs/progress')] + [ROOT / 'docs/progress.md']
    entries = []
    for path in sources:
        entries += progress_archive.split_entries(path.read_text())[1]
    chosen = [e for e in entries if args.text.lower() in progress_archive.entry_title(e).lower()] if args.text else entries[-1:]
    for entry in chosen:
        print(entry.rstrip() + '\n')
    return 0 if chosen else 1


def main(argv=None):
    parser = argparse.ArgumentParser(description='Consulta índices de contexto')
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('asm'); p.add_argument('symbol'); p.add_argument('-n', type=int, default=30)
    p.add_argument('--jp', action='store_true', help='inclui o ramo japonês (ignorado por padrão)')
    p.set_defaults(func=cmd_asm)
    p = sub.add_parser('ram'); p.add_argument('name'); p.set_defaults(func=cmd_ram)
    p = sub.add_parser('cites'); p.add_argument('target'); p.set_defaults(func=cmd_cites)
    p = sub.add_parser('gd'); p.add_argument('file'); p.add_argument('function'); p.set_defaults(func=cmd_gd)
    p = sub.add_parser('mech'); p.add_argument('id', nargs='?'); p.set_defaults(func=cmd_mech)
    p = sub.add_parser('progress'); p.add_argument('text', nargs='?'); p.set_defaults(func=cmd_progress)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == '__main__':
    sys.exit(main())
