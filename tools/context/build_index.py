"""Gera e confere os índices determinísticos de contexto. Somente biblioteca padrão.

  python3 -m tools.context.build_index          # regenera tudo (inclui rotação do progresso)
  python3 -m tools.context.build_index --check  # falha se algo estiver desatualizado ou quebrado

Locais (derivados de código de terceiros, ignorados pelo Git; refeitos quando a fonte muda):
  data/extracted/index/asm-symbols.tsv   rótulos e equ → arquivo:linha, grupo de bancos, ramo regional
  data/extracted/index/ram-map.tsv       variáveis de Variables.asm → endereço, tamanho, linha
Versionados (só caminhos, nomes e números de linha do próprio projeto):
  docs/index/asm-citations.md   citações reversas arquivo.asm:linhas → quem cita
  docs/index/godot-outline.md   esboço dos .gd grandes com faixa de linhas por função
  docs/index/tests.md           etapa do validate → script → marcador → sistemas usados
  docs/index/coverage.md        visão de cobertura gerada do catálogo canônico
Curados e validados aqui:
  docs/index/mechanics.json     mecânica → asm → extrator/dados → Godot → integração → teste → docs
  docs/index/rooms.md           aliases locais de sala (conferidos com export_local_aliases.ALIASES)
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.context import progress_archive  # noqa: E402

REFERENCE = ROOT / 'external/MetalGear'
LOCAL_INDEX = ROOT / 'data/extracted/index'
DOCS_INDEX = ROOT / 'docs/index'
OUTLINE_MIN_LINES = 300
CITATION_EXCLUDE = ('docs/progress.md', 'docs/progress/', 'docs/history/', 'docs/index/asm-citations.md',
                    'docs/index/coverage.md', 'tools/context/', 'tests/test_context_index.py')
ENTRY_DOCS = ('AGENTS.md', 'GEMINI.md', 'docs/STATUS.md', 'docs/README.md', 'docs/index/README.md')
SKILLS_DIR = ROOT / '.agents/skills'
CITATION = re.compile(r'(?<![\w/.-])(?:external/MetalGear/)?((?:[A-Za-z0-9_-]+/)*[A-Za-z0-9_-]+\.asm)'
                      r'(?::(\d+)(?:\s*[-–]\s*(\d+))?)?')


# ---------------------------------------------------------------- assembly (índices A e B)

def asm_sources(reference=REFERENCE):
    return {p.relative_to(reference).as_posix(): p.read_text(encoding='latin-1')
            for p in sorted(reference.rglob('*.asm'))}


def include_groups(sources, root='MetalGear.asm'):
    """file → top-level file included by MetalGear.asm that (transitively) includes it."""
    edges = {}
    for name, text in sources.items():
        for line in text.splitlines():
            match = re.match(r'\s*include\s+"([^"]+)"', line.split(';', 1)[0], re.I)
            if match:
                target = match.group(1)
                folder = name.rsplit('/', 1)[0] + '/' if '/' in name else ''
                resolved = folder + target if folder + target in sources else target
                edges.setdefault(name, []).append(resolved)
    groups = {root: ''}
    for top in edges.get(root, []):
        stack = [top]
        while stack:
            current = stack.pop()
            if current in groups:
                continue
            groups[current] = top
            stack.extend(edges.get(current, []))
    return groups


def parse_asm_symbols(name, text):
    """Labels (`Name:`) and constants (`Name: equ v` / `Name equ v`) with JAPANESE branch tags."""
    rows, stack = [], []
    for line_no, line in enumerate(text.splitlines(), 1):
        code = line.split(';', 1)[0].strip()
        if not code:
            continue
        directive = code.split(None, 1)[0].upper()
        if directive == 'IF':
            condition = code[2:].replace(' ', '').replace('\t', '').upper()
            stack.append({'(JAPANESE)': 'jp', '(!JAPANESE)': 'en'}.get(condition, 'other'))
            continue
        if directive == 'ELSE' and stack:
            stack[-1] = {'jp': 'en', 'en': 'jp'}.get(stack[-1], 'other')
            continue
        if directive == 'ENDIF' and stack:
            stack.pop()
            continue
        branch = next((b for b in reversed(stack) if b in ('jp', 'en')), '')
        match = re.match(r'^(\w+)(:?)\s*(?:equ\s+(.+))?$', code, re.I) or re.match(r'^(\w+):', code)
        if not match:
            continue
        groups = match.groups() + (None,) * 3
        symbol, colon, value = groups[0], groups[1], groups[2]
        if value is not None:
            rows.append((symbol, 'equ', name, line_no, branch, value.strip()))
        elif colon or code.startswith(symbol + ':'):
            rows.append((symbol, 'label', name, line_no, branch, ''))
    return rows


def build_asm_symbols(sources):
    groups = include_groups(sources)
    rows = []
    for name, text in sources.items():
        rows.extend(parse_asm_symbols(name, text))
    rows.sort(key=lambda r: (r[0], r[2], r[3]))
    out = ['# symbol\tkind\tfile:line\tgroup\tbranch\tvalue',
           '# Consulta: rg "^Simbolo\\t" data/extracted/index/asm-symbols.tsv | ramo jp é ignorado']
    for symbol, kind, name, line, branch, value in rows:
        out.append(f'{symbol}\t{kind}\t{name}:{line}\t{groups.get(name, "")}\t{branch}\t{value}')
    return '\n'.join(out) + '\n'


def build_ram_map(variables_text):
    from tools.reverse_engineering.analyze import ram_map
    entries = sorted(ram_map(variables_text).items(), key=lambda item: (item[1]['address'], item[0]))
    out = ['# symbol\taddress\tsize\tsource', '# Consulta: rg "^Simbolo\\t" data/extracted/index/ram-map.tsv']
    for symbol, info in entries:
        out.append(f'{symbol}\t0x{info["address"]:04X}\t{info["size"]}\tVariables.asm:{info["line"]}')
    return '\n'.join(out) + '\n'


def source_digest(sources):
    digest = hashlib.sha256()
    for name, text in sources.items():
        digest.update(name.encode() + b'\0' + text.encode('latin-1') + b'\0')
    return digest.hexdigest()


def refresh_local_indexes(sources):
    """Ignored caches; rebuilt silently whenever the reference changes."""
    manifest_path = LOCAL_INDEX / 'manifest.json'
    digest = source_digest(sources)
    current = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    files = {'asm-symbols.tsv', 'ram-map.tsv'}
    if current.get('source_digest') == digest and all((LOCAL_INDEX / f).exists() for f in files):
        return False
    LOCAL_INDEX.mkdir(parents=True, exist_ok=True)
    (LOCAL_INDEX / 'asm-symbols.tsv').write_text(build_asm_symbols(sources))
    (LOCAL_INDEX / 'ram-map.tsv').write_text(build_ram_map(sources['Variables.asm']))
    manifest_path.write_text(json.dumps({'source_digest': digest, 'files': sorted(files)}, indent=2) + '\n')
    return True


def symbol_table(sources):
    table = {}
    for name, text in sources.items():
        for symbol, _, file, line, branch, _ in parse_asm_symbols(name, text):
            table.setdefault(symbol, []).append((file, line, branch))
    return table


# ---------------------------------------------------------------- arquivos do projeto

def project_files(suffixes):
    output = subprocess.check_output(['git', 'ls-files', '-co', '--exclude-standard'], cwd=ROOT, text=True)
    return sorted(p for p in output.splitlines() if p.endswith(suffixes) and (ROOT / p).is_file())


# ---------------------------------------------------------------- citações reversas (índice C)

def resolve_asm(path, sources):
    if path in sources:
        return path
    matches = [name for name in sources if name.rsplit('/', 1)[-1] == path.rsplit('/', 1)[-1]
               and name.endswith(path)]
    return matches[0] if len(matches) == 1 else None


def collect_citations(files, sources, root=ROOT):
    """Returns ({asm_file: {range: {citing files}}}, [broken reference strings])."""
    cites, broken = {}, []
    lengths = {name: text.count('\n') + 1 for name, text in sources.items()}
    for rel in files:
        if rel.startswith(CITATION_EXCLUDE):
            continue
        text = (root / rel).read_text(errors='replace')
        for line_no, line in enumerate(text.splitlines(), 1):
            for match in CITATION.finditer(line):
                path, start, end = match.groups()
                resolved = resolve_asm(path, sources)
                where = f'{rel}:{line_no}: {match.group(0)}'
                if resolved is None:
                    # Só citações com linha valem como evidência; nomes soltos podem ser variáveis ou globs.
                    if start:
                        broken.append(where + ' (arquivo inexistente ou ambíguo na referência)')
                    continue
                first = int(start) if start else 0
                last = int(end) if end else first
                if first and (last < first or last > lengths[resolved]):
                    broken.append(where + f' (linha além do fim: {lengths[resolved]})')
                    continue
                key = (first, last)
                cites.setdefault(resolved, {}).setdefault(key, set()).add(rel)
    return cites, broken


def render_citations(cites):
    out = ['# Citações reversas do assembly', '',
           'Gerado por `tools/context/build_index.py`; não editar. Para cada trecho de `external/MetalGear/`',
           'citado como `arquivo.asm:linhas`, os arquivos do projeto que o citam (histórico de progresso',
           'excluído). Antes de mudar uma rotina, veja quem depende dela: `rg -n "^## logic/items.asm" -A20`.', '']
    for name in sorted(cites):
        out.append(f'## {name}')
        for (first, last), citing in sorted(cites[name].items()):
            where = 'arquivo' if not first else (str(first) if first == last else f'{first}-{last}')
            out.append(f'- {where}: ' + ', '.join(sorted(citing)))
        out.append('')
    return '\n'.join(out)


# ---------------------------------------------------------------- esboço Godot (índice E)

GD_DECL = re.compile(r'^(?:static\s+)?func\s+(\w+)\s*\((.*)|^class\s+(\w+)|^(signal|const|enum|var|@export\S*\s+var|@onready\s+var)\s+(\w+)')


def outline_gd(rel, text):
    lines = text.splitlines()
    head, funcs, consts, signals, vars_ = [], [], [], [], []
    starts = []
    for index, line in enumerate(lines, 1):
        stripped = line.strip()
        if line.startswith(('class_name ', 'extends ')):
            head.append(stripped)
        match = GD_DECL.match(line)
        if not match:
            inner = re.match(r'^\t(?:static\s+)?func\s+(\w+)\s*\(', line)
            if inner:
                starts.append((index, '  ' + stripped))
            continue
        if match.group(1):
            starts.append((index, stripped))
        elif match.group(3):
            starts.append((index, stripped))
        else:
            kind, name = match.group(4), match.group(5)
            bucket = {'signal': signals, 'const': consts, 'enum': consts}.get(kind, vars_)
            bucket.append(f'{name}@{index}')
    for position, (start, signature) in enumerate(starts):
        end = (starts[position + 1][0] - 1) if position + 1 < len(starts) else len(lines)
        while end > start and not lines[end - 1].strip():
            end -= 1
        signature = signature.rstrip(':')
        if len(signature) > 110:
            signature = signature[:107] + '...'
        funcs.append(f'- {start}-{end} {signature}')
    out = [f'## {rel} ({len(lines)} linhas)', ' · '.join(head) or '(sem class_name/extends)']
    if signals:
        out.append('signals: ' + ', '.join(signals))
    if consts:
        out.append('const/enum: ' + ', '.join(consts))
    if vars_:
        out.append('var: ' + ', '.join(vars_))
    return '\n'.join(out + funcs) + '\n'


def render_outline(files):
    sections = []
    for rel in files:
        text = (ROOT / rel).read_text()
        if rel.endswith('.gd') and text.count('\n') + 1 >= OUTLINE_MIN_LINES:
            sections.append(outline_gd(rel, text))
    return ('# Esboço dos scripts Godot grandes\n\n'
            f'Gerado por `tools/context/build_index.py` para .gd com {OUTLINE_MIN_LINES}+ linhas; não editar.\n'
            'Leia por faixa (`Read offset/limit` ou `python3 -m tools.context.lookup gd ARQUIVO FUNC`),\n'
            'nunca o arquivo inteiro. Formato: `- início-fim assinatura`; `nome@linha` em sinais/constantes.\n\n'
            + '\n'.join(sections))


# ---------------------------------------------------------------- testes (índice F)

def class_names(files):
    names = {}
    for rel in files:
        if rel.endswith('.gd') and rel.startswith('godot/scripts/'):
            match = re.search(r'^class_name\s+(\w+)', (ROOT / rel).read_text(), re.M)
            if match:
                names[match.group(1)] = rel
    return names


def render_tests(files):
    from tools.validate import GODOT_TESTS
    names = class_names(files)
    out = ['# Índice de testes', '',
           'Gerado por `tools/context/build_index.py` a partir de `tools/validate.py`; não editar.',
           'Rodar uma suíte: `$GODOT --headless --path godot --script res://tests/ARQUIVO`; passa só se o',
           'marcador aparecer e não houver `ERROR:`. Suíte nova: acrescentar a `GODOT_TESTS` e regenerar.', '',
           '## Godot (ordem do validate)', '']
    for stage, script, marker, _ in GODOT_TESTS:
        rel = f'godot/tests/{script}'
        text = (ROOT / rel).read_text() if (ROOT / rel).exists() else ''
        used = set(re.findall(r'res://((?:scripts|scenes)/[\w/]+\.(?:gd|tscn))', text))
        used |= {names[n][len('godot/'):] for n in names if re.search(r'\b' + n + r'\b', text)}
        out.append(f'- `{stage}` · `{script}` · `{marker}` · ' + (', '.join(sorted(used)) or '—'))
    out += ['', '## Python (`python3 -m unittest discover -s tests`)', '']
    for rel in files:
        if rel.startswith('tests/test_') and rel.endswith('.py'):
            text = (ROOT / rel).read_text()
            classes = re.findall(r'^class\s+(\w+)\(', text, re.M)
            modules = sorted(set(re.findall(r'^(?:from|import)\s+(tools(?:\.\w+)+)', text, re.M)))
            out.append(f'- `{rel}` · ' + ', '.join(classes) + ' · ' + (', '.join(modules) or '—'))
    return '\n'.join(out) + '\n'


# ---------------------------------------------------------------- mecânicas (índice D) e salas (G)

ASM_REF = re.compile(r'^((?:[\w-]+/)*[\w-]+\.asm)(?::(\d+)(?:-(\d+))?)?(?:\s+(\w+))?$')


def check_mechanics(sources, path=None, root=ROOT):
    from tools.context.coverage import check_classifications
    data = json.loads((path or DOCS_INDEX / 'mechanics.json').read_text())
    problems = check_classifications(data)
    from tools.validate import GODOT_TESTS
    stages = {stage for stage, *_ in GODOT_TESTS} | {'python-tests', 'godot-main'}
    table = symbol_table(sources) if sources else {}
    seen = set()
    entries = data['mechanics'] + [
        {'id': 'audit-' + domain, 'title': audit['title'], 'asm': audit.get('asm', []),
         'godot': [], 'tests': [], 'docs': []}
        for domain, audit in data.get('audits', {}).items()]
    for item in entries:
        mid = item.get('id', '?')
        if mid in seen:
            problems.append(f'{mid}: id duplicado')
        seen.add(mid)
        for field in ('id', 'title', 'asm', 'godot', 'tests', 'docs'):
            if field not in item:
                problems.append(f'{mid}: campo {field} ausente')
        for rel in item.get('extractor', []) + item.get('godot', []) + item.get('docs', []):
            if not (root / rel).is_file():
                problems.append(f'{mid}: caminho inexistente {rel}')
        for test in item.get('tests', []):
            if test not in stages and not (root / test).is_file():
                problems.append(f'{mid}: teste desconhecido {test}')
        for ref in item.get('integration', []):
            file, _, func = ref.partition('::')
            text = (root / file).read_text() if (root / file).is_file() else ''
            if not re.search(r'^(?:static\s+)?func\s+' + re.escape(func) + r'\s*\(', text, re.M):
                problems.append(f'{mid}: integração inexistente {ref}')
        for ref in item.get('history', []):
            file, separator, heading = ref.partition('::')
            text = (root / file).read_text() if (root / file).is_file() else ''
            if not separator or not heading or ('## ' + heading) not in text.splitlines():
                problems.append(f'{mid}: histórico inexistente {ref}')
        private = root / 'data/extracted/en-eu-rc750'
        for rel in item.get('data', []):
            target = private / rel
            if private.resolve() not in target.resolve().parents:
                problems.append(f'{mid}: dado fora do diretório canônico {rel}')
            elif private.is_dir() and not target.exists():
                problems.append(f'{mid}: dado extraído inexistente {rel}')
        for ref in item.get('asm', []):
            match = ASM_REF.fullmatch(ref)
            if not match:
                problems.append(f'{mid}: referência asm inválida {ref}')
                continue
            if not sources:
                continue  # Syntax checked; resolving needs the local third-party checkout.
            resolved = resolve_asm(match.group(1), sources) if match else None
            if not resolved:
                problems.append(f'{mid}: referência asm inválida {ref}')
                continue
            first = int(match.group(2) or 0)
            last = int(match.group(3) or first)
            length = sources[resolved].count('\n') + 1
            if match.group(2) and (first < 1 or last < first):
                problems.append(f'{mid}: faixa asm inválida {ref}')
            if first and last > length:
                problems.append(f'{mid}: {ref} além do fim ({length})')
            symbol = match.group(4)
            if symbol:
                places = [(f, line) for f, line, branch in table.get(symbol, []) if f == resolved and branch != 'jp']
                if not places:
                    problems.append(f'{mid}: símbolo {symbol} não está em {resolved}')
                elif first and not any(first <= line <= last for _, line in places):
                    problems.append(f'{mid}: símbolo {symbol} fora de {ref} (linha {places[0][1]})')
    return problems


def check_rooms():
    from tools.extractors.export_local_aliases import ALIASES
    text = (DOCS_INDEX / 'rooms.md').read_text()
    block = text.split('<!-- aliases -->', 2)
    rows = dict((int(a), int(b)) for a, b in re.findall(r'^\|\s*(\d+)\s*\|\s*(\d+)\s*\|', block[1], re.M)) \
        if len(block) == 3 else {}
    return [] if rows == ALIASES else [f'docs/index/rooms.md: aliases {rows} != export_local_aliases.ALIASES {ALIASES}']


PLACEHOLDER = re.compile(r'AAAA|NNN|ARQUIVO|FUNÇÃO|[<>*{}$]|\.\.\.|…')


def doc_path_problems(rel, text, root=ROOT, known_names=frozenset()):
    """Backticked paths in entry docs and skills must exist. Bare names (`enemy.gd`, `rooms/`) only
    need to exist somewhere in the project; placeholders and private directories are skipped."""
    problems = []
    data_dir = root / 'data/extracted/en-eu-rc750'
    for token in re.findall(r'`([^`\s]+)`', text):
        token = token.split('::', 1)[0].split(':', 1)[0].rstrip('.,;')
        if PLACEHOLDER.search(token) or token.startswith(('res://', 'user://', 'http', '-', '.')):
            continue
        if not (re.fullmatch(r'[\w./-]+', token) and ('/' in token or
                re.search(r'\.(md|py|gd|json|tcl|tscn)$', token))):
            continue
        if token.startswith(('external/', 'roms/', 'data/extracted/', 'reports/')) or token.endswith('.asm'):
            continue
        bare = token.rstrip('/')
        if '/' not in bare:
            if bare in known_names or (data_dir / bare).exists() or not data_dir.exists():
                continue
        else:
            bases = [root, root / Path(rel).parent, root / 'docs', root / 'godot', root / 'tools',
                     root / 'data', data_dir]
            if any((base / token).exists() for base in bases) or not data_dir.exists():
                continue
        problems.append(f'{rel}: caminho inexistente `{token}`')
    return problems


def project_names(files):
    names = set()
    for rel in files:
        names.update(Path(rel).parts)
    return frozenset(names)


def check_entry_docs(root=ROOT, skills_dir=None, known_names=None):
    skills_dir = skills_dir or root / '.agents/skills'
    if known_names is None:
        known_names = project_names(project_files(('',)))
    problems = []
    skills = sorted(p.name for p in skills_dir.iterdir() if (p / 'SKILL.md').exists())
    docs = [rel for rel in ENTRY_DOCS if (root / rel).exists()]
    docs += [str((skills_dir / s / 'SKILL.md').relative_to(root)) for s in skills]
    for rel in docs:
        problems += doc_path_problems(rel, (root / rel).read_text(), root, known_names)
    for skill in skills:
        head = (skills_dir / skill / 'SKILL.md').read_text().split('---', 2)
        if len(head) < 3 or not re.search(r'^name:\s*' + re.escape(skill) + r'\s*$', head[1], re.M) \
                or 'description:' not in head[1]:
            problems.append(f'skill {skill}: frontmatter sem name igual à pasta ou sem description')
    agents = (root / 'AGENTS.md').read_text() if (root / 'AGENTS.md').exists() else ''
    listed = agents.split('Skills', 1)[-1] if 'Skills' in agents else ''
    missing = [s for s in skills if f'`{s}`' not in listed]
    if missing:
        problems.append('AGENTS.md não lista as skills: ' + ', '.join(missing))
    return problems


# ---------------------------------------------------------------- orquestração

def generated(files, sources):
    from tools.context.coverage import render
    outputs = {'godot-outline.md': render_outline(files), 'tests.md': render_tests(files)}
    outputs['coverage.md'] = render(json.loads((DOCS_INDEX / 'mechanics.json').read_text()))
    broken = []
    if sources:
        # Cite the curated catalog, never last run's generated coverage view.
        cites, broken = collect_citations(files + ['docs/index/mechanics.json'], sources)
        outputs['asm-citations.md'] = render_citations(cites)
    return outputs, broken


def main(argv=None):
    parser = argparse.ArgumentParser(description='Índices determinísticos de contexto')
    parser.add_argument('--check', action='store_true', help='não escreve índices versionados; falha se desatualizados')
    args = parser.parse_args(argv)
    sources = asm_sources() if REFERENCE.is_dir() else {}
    if sources:
        rebuilt = refresh_local_indexes(sources)
        print('asm-symbols/ram-map: ' + ('regenerados' if rebuilt else 'atualizados'))
    else:
        print('asm-symbols/ram-map/asm-citations: SKIP (external/MetalGear ausente)')
    files = project_files(('.gd', '.py', '.md'))
    if not args.check:
        progress_archive.main([])
    problems = check_mechanics(sources)
    if problems:
        for problem in problems:
            print('CONTEXT_INDEX_PROBLEM: ' + problem)
        return 1  # Do not render incomplete/invalid coverage entries.
    outputs, broken = generated(files, sources)
    problems = [f'referência asm quebrada: {b}' for b in broken]
    for name, content in outputs.items():
        target = DOCS_INDEX / name
        if args.check:
            if not target.exists() or target.read_text() != content:
                problems.append(f'docs/index/{name} desatualizado')
        else:
            DOCS_INDEX.mkdir(parents=True, exist_ok=True)
            target.write_text(content)
    problems += check_rooms()
    problems += check_entry_docs()
    progress_dir = ROOT / 'docs/progress'
    problems += progress_archive.check(ROOT / 'docs/progress.md', progress_dir)
    for problem in problems:
        print('CONTEXT_INDEX_PROBLEM: ' + problem)
    if problems:
        print('Corrija as referências ou rode: python3 -m tools.context.build_index')
        return 1
    print(f'CONTEXT_INDEX_OK: {len(outputs)} índices versionados, mecânicas e salas conferidos')
    return 0


if __name__ == '__main__':
    sys.exit(main())
