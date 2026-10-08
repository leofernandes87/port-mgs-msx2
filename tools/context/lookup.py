"""Consulta os índices e imprime só a faixa relevante (uma chamada em vez de buscar e depois ler).

  python3 -m tools.context.lookup asm ChkRadioCalls [-n 40] [--jp]  # definição + N linhas do asm
  python3 -m tools.context.lookup ram TextId                         # endereço/tamanho (aceita trecho)
  python3 -m tools.context.lookup cites logic/items.asm[:399]        # quem cita o trecho
  python3 -m tools.context.lookup gd godot/scripts/systems/enemy.gd _physics_process
  python3 -m tools.context.lookup mech [radio]                       # resumo; com ID, detalhes da feature
  python3 -m tools.context.lookup domain actors-bosses                # ID, título e status por domínio
  python3 -m tools.context.lookup status PARTIAL                      # ID, título e status por classificação
  python3 -m tools.context.lookup unmapped                            # atalho para status UNMAPPED
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
from tools.context.coverage import STATUSES  # noqa: E402


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


def mechanics_catalog():
    # The tool reads the canonical catalog; agents receive only the requested selection.
    return json.loads((build_index.DOCS_INDEX / 'mechanics.json').read_text())


def print_mechanics_summary(items):
    """One TSV row per feature, no evidence, history or full audit payload."""
    for item in items:
        print('\t'.join((item['id'], item['title'], item.get('status', '—'))))
    return 0  # A valid filter with no matches is a successful, empty query.


def cmd_domain(args):
    data = mechanics_catalog()
    if args.domain not in data.get('audits', {}):
        print('domínio desconhecido; disponíveis: ' + ', '.join(data.get('audits', {})), file=sys.stderr)
        return 1
    return print_mechanics_summary(i for i in data['mechanics'] if i.get('domain') == args.domain)


def cmd_status(args):
    data = mechanics_catalog()
    return print_mechanics_summary(i for i in data['mechanics'] if i.get('status') == args.status)


def cmd_mech(args):
    data = mechanics_catalog()
    if not args.id:
        return print_mechanics_summary(data['mechanics'])
    for item in data['mechanics']:
        if item['id'] == args.id:
            for key in ('id', 'title', 'domain', 'status', 'original_scope', 'rationale', 'actor_ids',
                        'weapon_ids', 'pickup_ids', 'equipment_ids',
                        'asm', 'extractor', 'data', 'godot', 'integration', 'tests', 'docs', 'history',
                        'implemented_scope', 'missing_scope', 'evidence_notes', 'related_features'):
                if key in item:
                    value = item[key]
                    print(f'{key:12} ' + (value if isinstance(value, str) else '\n             '.join(map(str, value)) or '—'))
            return 0
    print('mecânica desconhecida: ' + args.id, file=sys.stderr)
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


def cmd_room(args):
    if args.id is None:
        print('Faixas de salas da ROM (idxRooms: 251 entradas, IDs 0-250):')
        print('  Salas 0–125   : Conexões de borda 1:1 na tabela RoomConnections')
        print('  Salas 126–207 : Salas isoladas, caminhões e interiores; trânsito apenas por portas')
        print('  Salas 208–227 : Deserto (208-210), canal (211-212), caminhões (213-219), escuras (220-221), escadas (224-227)')
        print('  Salas 228–239 : Indefinidas na ROM')
        print('  Sala 240      : Elevador 1 (Prédio 1)')
        print('  Salas 241–250 : Elevadores 2–11 (Prédio 1, 2 e 3)')
        print('Use: python3 -m tools.context.lookup room <ID> para detalhes de uma sala.')
        return 0

    room_id = args.id
    if room_id < 0 or room_id > 250:
        print(f'Room ID inválido: {room_id}. O intervalo canônico é 0–250.', file=sys.stderr)
        return 1

    conns_asm = ROOT / 'external/MetalGear/data/roomsconnections.asm'
    conns = []
    if conns_asm.exists():
        for l in conns_asm.read_text().splitlines():
            if 'db' in l:
                idx = l.find('db')
                parts = [p.strip() for p in l[idx + 2:].split(';')[0].split(',') if p.strip()]
                if len(parts) == 4:
                    conns.append([int(p) for p in parts])

    idx = -1
    if room_id < 126:
        idx = room_id
    elif room_id < 208:
        idx = -1
    elif room_id < 228:
        idx = room_id - 82
    elif room_id < 241:
        idx = -1
    elif room_id <= 250:
        idx = room_id - 95

    conn_str = 'Nenhuma (sala isolada / sem saída de borda)'
    if 0 <= idx < len(conns):
        c = conns[idx]
        conn_str = f'UP: {c[0]}, DOWN: {c[1]}, LEFT: {c[2]}, RIGHT: {c[3]}'

    zone_names = {
        0: 'Pátios externos / Fachada / Praia (Edifício 1)',
        1: 'Edifício 1 — 1º Andar (Térreo)',
        2: 'Edifício 1 — 2º Andar',
        3: 'Edifício 1 — 3º Andar',
        4: 'Edifício 1 — Telhado e Masmorra / Subsolo',
        5: 'Deserto e Pátios Externos Intermediários',
        6: 'Edifício 2 — 1º Andar (Térreo)',
        7: 'Edifício 2 — 2º Andar',
        8: 'Edifício 2 — Telhado e Subsolo',
        9: 'Canal Subterrâneo de Água e Acessos ao Edifício 3',
        10: 'Edifício 3 — Área Final e Fuga',
    }
    zones_asm = ROOT / 'external/MetalGear/data/musicradioconfig.asm'
    zone_val = None
    if zones_asm.exists():
        txt = zones_asm.read_text()
        bytes_list = []
        for l in txt.split('idxMapZones:')[1].split(';')[0].splitlines():
            l = l.strip()
            if not l.startswith('db'):
                continue
            for p in l[2:].split(','):
                p = p.strip()
                bytes_list.append(int(p[:-1], 16) if p.endswith('h') else int(p))
        if room_id // 2 < len(bytes_list):
            b = bytes_list[room_id // 2]
            zone_val = (b >> 4) if (room_id % 2 == 0) else (b & 0xF)

    zone_desc = f'Zone {zone_val} ({zone_names.get(zone_val, "Desconhecida")})' if zone_val is not None else 'Desconhecida'

    doors_asm = ROOT / 'external/MetalGear/data/doors.asm'
    doors = []
    if doors_asm.exists():
        txt = doors_asm.read_text()
        patterns = [f'DoorsRoom{room_id:03d}:', f'DoorsRoom{room_id}:', f'DoorsRoom_{room_id}:', f'Door_{room_id}:', f'DoorsRoom_{room_id:03d}:']
        start = -1
        for p in patterns:
            start = txt.find(p)
            if start != -1:
                break
        if start != -1:
            first = True
            for line in txt[start:].splitlines():
                line = line.strip()
                if first:
                    first = False
                    if ':' in line:
                        line = line.split(':', 1)[1].strip()
                if not line.startswith('db'):
                    if line and not line.startswith(';'):
                        break
                    continue
                parts = [x.strip() for x in line[2:].split(';')[0].split(',') if x.strip()]
                if not parts or parts[0] in ('0FFh', '255'):
                    break
                def parse_n(s): return int(s[:-1], 16) if s.endswith('h') else int(s)
                i = 0
                while i + 4 < len(parts):
                    d_id = parse_n(parts[i])
                    r_type = parse_n(parts[i+1])
                    dy = parse_n(parts[i+2])
                    dx = parse_n(parts[i+3])
                    dest = parse_n(parts[i+4])
                    doors.append({'id': d_id, 'render_type': r_type, 'y': dy, 'x': dx, 'dest': dest})
                    i += 5
                    if i < len(parts) and parts[i] in ('0FFh', '255'):
                        break

    props = []
    water_rooms = [70, 73, 74, 77, 78, 107, 105, 106, 211, 212]
    gas_rooms = [29, 94, 96, 97, 98, 100, 101, 112, 114]
    elec_rooms = [16, 37, 40, 110, 116]
    dark_rooms = [123, 124, 125, 220, 221]
    lorry_moving = [199, 217, 219, 213, 215, 173]
    if room_id in water_rooms:
        props.append('Água profunda / asfixia (RoomsWater, Banks0123.asm:9267)')
    if room_id in gas_rooms:
        props.append('Gás tóxico ambiental (GasRooms, logic/damagegas.asm:53)')
    if room_id in elec_rooms:
        props.append('Piso eletrificado (logic/damageelectric.asm:8-63)')
    if room_id in dark_rooms:
        props.append('Sala escura / paleta 0Bh sem Lanterna (Banks0123.asm:2946)')
    if room_id in lorry_moving:
        props.append('Caminhão em movimento / teletransporte geográfico (logic/lorry.asm:23)')
    if 240 <= room_id <= 250:
        props.append('Eixo de elevador (data/elevatorrooms.asm)')
    if room_id == 204:
        props.append('Descida vertical em paraquedas (Big bricks wall, logic/nextroom.asm:209)')
    if room_id == 103:
        props.append('Deserto com loop infinito sem Compass (logic/nextroom.asm:46)')
    if room_id == 53:
        props.append('Corrente de ar / vento no telhado (AirFlowLogic, Banks0123.asm:9284)')
    if room_id in (45, 46):
        props.append('Ponte móvel com queda para andar inferior 58/59 (logic/bridge.asm)')
    if room_id == 165:
        props.append('Cela de prisão original (PutInPrison, logic/capturescene.asm:102)')
    if room_id == 164:
        props.append('Sala original da bolsa de equipamentos (DoorsRoom_164, data/doors.asm:724)')

    prop_str = '; '.join(props) if props else 'Normal'

    godot_status = 'Mapeada normalmente'
    snap_canon = ROOT / f'data/extracted/en-eu-rc750/rooms/room-{room_id:03d}.json'
    if room_id in (211, 212):
        orig = 165 if room_id == 211 else 164
        godot_status = f'CONFLITO CRÍTICO — Mascarada por local-aliases/room-{room_id:03d}.json (alias da sala {orig}); get_next_room retorna NO_ROOM'
    elif room_id == 204:
        godot_status = "DIVERGÊNCIA — Tratada como 'o limbo' em sandbox_gameplay.gd:1393 e bloqueada"
    elif not snap_canon.exists():
        godot_status = 'NÃO DECODIFICADA — Sem snapshot extraído em data/extracted/en-eu-rc750/rooms/'

    print(f'== Sala {room_id} (0x{room_id:02X}) ==')
    print(f'  MapZone            : {zone_desc}')
    print(f'  Conexões cardinais : {conn_str}')
    print(f'  Propriedades ROM   : {prop_str}')
    print(f'  Status no Godot    : {godot_status}')
    if doors:
        print('  Portas             :')
        for d in doors:
            print(f'    - Porta {d["id"]} (tipo {d["render_type"]}) em ({d["x"]}, {d["y"]}) -> Destino: Sala {d["dest"]}')
    else:
        print('  Portas             : Nenhuma')
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description='Consulta índices de contexto')
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('asm'); p.add_argument('symbol'); p.add_argument('-n', type=int, default=30)
    p.add_argument('--jp', action='store_true', help='inclui o ramo japonês (ignorado por padrão)')
    p.set_defaults(func=cmd_asm)
    p = sub.add_parser('ram'); p.add_argument('name'); p.set_defaults(func=cmd_ram)
    p = sub.add_parser('cites'); p.add_argument('target'); p.set_defaults(func=cmd_cites)
    p = sub.add_parser('gd'); p.add_argument('file'); p.add_argument('function'); p.set_defaults(func=cmd_gd)
    p = sub.add_parser('mech', help='lista resumida; detalhes somente com ID')
    p.add_argument('id', nargs='?'); p.set_defaults(func=cmd_mech)
    p = sub.add_parser('domain', help='features do domínio: ID, título e status')
    p.add_argument('domain'); p.set_defaults(func=cmd_domain)
    p = sub.add_parser('status', help='features por status: ID, título e status')
    p.add_argument('status', type=str.upper, choices=STATUSES); p.set_defaults(func=cmd_status)
    p = sub.add_parser('unmapped', help='atalho para status UNMAPPED, somente resumo')
    p.set_defaults(func=cmd_status, status='UNMAPPED')
    p = sub.add_parser('progress'); p.add_argument('text', nargs='?'); p.set_defaults(func=cmd_progress)
    p = sub.add_parser('room', help='identidade, conexões e status da sala por ID')
    p.add_argument('id', type=int, nargs='?', help='Room ID canônico (0-250)')
    p.set_defaults(func=cmd_room)
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == '__main__':
    sys.exit(main())
