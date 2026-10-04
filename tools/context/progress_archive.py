"""Rotação do histórico de docs/progress.md, sem editar nenhuma entrada.

docs/progress.md guarda só as KEEP entradas mais recentes. As anteriores são anexadas, byte a
byte, a docs/progress/AAAA-MM.md (mês da primeira data AAAA-MM do título; sem data, herda o da
entrada anterior). docs/progress/INDEX.md lista todas as entradas com arquivo e linha.

  python3 -m tools.context.progress_archive          # rotaciona e regenera o índice
  python3 -m tools.context.progress_archive --check  # falha se for preciso rotacionar
"""
import argparse
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
KEEP = 5
CURRENT_HEADER = ("# Progresso\n\n"
                  "Somente as entradas mais recentes. Histórico completo, sem edição, em `docs/progress/`;\n"
                  "índice com arquivo e linha em `docs/progress/INDEX.md`. Rotação: "
                  "`python3 -m tools.context.build_index`.\n\n")
ARCHIVE_HEADER = "# Progresso — arquivo {month}\n\nEntradas movidas de `docs/progress.md` sem edição.\n\n"
MONTH = re.compile(r'(\d{4})-(\d{2})')


def split_entries(text):
    """Returns (header, [entry_text]); each entry starts with '## ' and keeps its exact bytes."""
    starts = [m.start() for m in re.finditer(r'^## ', text, re.M)]
    if not starts:
        return text, []
    bounds = starts + [len(text)]
    return text[:starts[0]], [text[a:b] for a, b in zip(bounds, bounds[1:])]


def entry_title(entry):
    return entry.split('\n', 1)[0][3:].strip()


def assign_months(entries, previous=None):
    months = []
    for entry in entries:
        match = MONTH.search(entry_title(entry))
        previous = f'{match.group(1)}-{match.group(2)}' if match else previous
        if previous is None:
            raise ValueError('Primeira entrada sem data AAAA-MM no título: ' + entry_title(entry))
        months.append(previous)
    return months


def archive_files(directory):
    return sorted(p for p in directory.glob('[0-9][0-9][0-9][0-9]-[0-9][0-9].md'))


def last_archived_month(directory):
    files = archive_files(directory)
    return files[-1].stem if files else None


def rotate(progress, directory, keep=KEEP):
    """Moves all but the last `keep` entries to monthly archives. Returns moved count."""
    _, entries = split_entries(progress.read_text())
    if len(entries) <= keep:
        return 0
    old, recent = entries[:-keep], entries[-keep:]
    months = assign_months(old, last_archived_month(directory))
    if months != sorted(months) or (last_archived_month(directory) or months[0]) > months[0]:
        raise ValueError('Entradas fora de ordem cronológica; o arquivo mensal perderia a sequência')
    directory.mkdir(parents=True, exist_ok=True)
    for month in sorted(set(months)):
        target = directory / f'{month}.md'
        chunk = ''.join(e for e, m in zip(old, months) if m == month)
        existing = target.read_text() if target.exists() else ARCHIVE_HEADER.format(month=month)
        if not existing.endswith('\n\n') and existing.endswith('\n'):
            existing += '\n'
        target.write_text(existing + chunk)
    progress.write_text(CURRENT_HEADER + ''.join(recent))
    return len(old)


def build_index(progress, directory, root=ROOT):
    rows = []
    sources = [(p, p.read_text()) for p in archive_files(directory)]
    sources.append((progress, progress.read_text()))
    for path, text in sources:
        for match in re.finditer(r'^## (.*)$', text, re.M):
            line = text.count('\n', 0, match.start()) + 1
            title = match.group(1).strip().replace('|', '\\|')
            rows.append(f'| {path.relative_to(root).as_posix()}:{line} | {title} |')
    return ('# Índice do progresso\n\nGerado por `tools/context/progress_archive.py`; não editar. '
            'Leia uma entrada: `python3 -m tools.context.lookup progress "trecho do título"`.\n\n'
            '| Arquivo:linha | Entrada |\n|---|---|\n' + '\n'.join(rows) + '\n')


def check(progress, directory, keep=KEEP, root=ROOT):
    problems = []
    _, entries = split_entries(progress.read_text())
    if len(entries) > keep:
        problems.append(f'docs/progress.md tem {len(entries)} entradas (máximo {keep}); rotacione')
    index = directory / 'INDEX.md'
    if not index.exists() or index.read_text() != build_index(progress, directory, root):
        problems.append('docs/progress/INDEX.md desatualizado')
    return problems


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.split('\n', 1)[0])
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args(argv)
    progress, directory = ROOT / 'docs/progress.md', ROOT / 'docs/progress'
    if args.check:
        problems = check(progress, directory)
        for problem in problems:
            print('PROGRESS_STALE: ' + problem)
        return 1 if problems else 0
    moved = rotate(progress, directory)
    (directory / 'INDEX.md').write_text(build_index(progress, directory))
    print(f'progress: {moved} entradas arquivadas')
    return 0


if __name__ == '__main__':
    sys.exit(main())
