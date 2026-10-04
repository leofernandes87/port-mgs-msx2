"""Índices de contexto: parsing, detecção de referências quebradas e rotação sem perda (fixtures sintéticas)."""
import json
from pathlib import Path
import tempfile
import unittest

from tools.context import build_index, progress_archive

SYNTH_ASM = """
Start:\tld a, 1
CONST_A:\tequ 4
OTHER equ 10h
\tIF (JAPANESE)
JpOnly:\tnop
\tELSE
EnOnly:\tnop
\tENDIF
\tIF (!JAPANESE)
EnToo:\tnop
\tENDIF
\tret
"""


class AsmSymbolTests(unittest.TestCase):
    def test_labels_constants_and_regional_branches(self):
        rows = {r[0]: r for r in build_index.parse_asm_symbols('logic/x.asm', SYNTH_ASM)}
        self.assertEqual(rows['Start'][1:5], ('label', 'logic/x.asm', 2, ''))
        self.assertEqual(rows['CONST_A'][1], 'equ')
        self.assertEqual(rows['CONST_A'][5], '4')
        self.assertEqual(rows['OTHER'][5], '10h')
        self.assertEqual(rows['JpOnly'][4], 'jp')
        self.assertEqual(rows['EnOnly'][4], 'en')
        self.assertEqual(rows['EnToo'][4], 'en')
        self.assertNotIn('ret', rows)

    def test_include_groups_follow_transitive_includes(self):
        sources = {'Main.asm': 'include "BankA.asm"\n', 'BankA.asm': 'include "logic/y.asm"\n',
                   'logic/y.asm': 'Y:\tret\n', 'orphan.asm': ''}
        groups = build_index.include_groups(sources, root='Main.asm')
        self.assertEqual(groups['logic/y.asm'], 'BankA.asm')
        self.assertNotIn('orphan.asm', groups)


class CitationTests(unittest.TestCase):
    def test_resolution_ambiguity_and_out_of_range(self):
        sources = {'logic/a.asm': 'A:\n' * 10, 'logic/actors/cam.asm': 'C:\n' * 5, 'gfx/cam.asm': 'G:\n' * 5}
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'doc.md').write_text('ok `a.asm:2-3`, longe `logic/a.asm:40`, ambíguo `cam.asm:2`,\n'
                                         'qualificado `logic/actors/cam.asm:4`, solto `variavel.asm`\n')
            cites, broken = build_index.collect_citations(['doc.md'], sources, root)
        self.assertEqual(cites['logic/a.asm'][(2, 3)], {'doc.md'})
        self.assertIn((4, 4), cites['logic/actors/cam.asm'])
        self.assertEqual(len(broken), 2)
        self.assertTrue(any('além do fim' in b for b in broken))
        self.assertTrue(any('ambíguo' in b for b in broken))


class OutlineTests(unittest.TestCase):
    def test_function_ranges_and_declarations(self):
        text = ('class_name Foo\nextends Node\nsignal hit(n: int)\nconst MAX: int = 3\nvar hp: int = 1\n\n'
                'func a() -> void:\n\tpass\n\n\nfunc b(x: int) -> int:\n\treturn x\n')
        outline = build_index.outline_gd('godot/x.gd', text)
        self.assertIn('class_name Foo · extends Node', outline)
        self.assertIn('signals: hit@3', outline)
        self.assertIn('const/enum: MAX@4', outline)
        self.assertIn('- 7-8 func a() -> void', outline)
        self.assertIn('- 11-12 func b(x: int) -> int', outline)


class MechanicsTests(unittest.TestCase):
    def test_symbol_must_be_inside_cited_range(self):
        sources = {'logic/a.asm': 'X:\tnop\nY:\tnop\n' + '\tnop\n' * 8}
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'm.json'
            path.write_text(json.dumps({'mechanics': [{
                'id': 'm', 'title': 't', 'godot': [], 'tests': ['godot-main'], 'docs': [],
                'asm': ['logic/a.asm:1-1 X', 'logic/a.asm:3-4 Y', 'logic/a.asm Z', 'logic/a.asm:99']}]}))
            problems = build_index.check_mechanics(sources, path)
        self.assertEqual(len(problems), 3, problems)
        self.assertTrue(any('fora de' in p and 'Y' in p for p in problems))
        self.assertTrue(any('Z' in p for p in problems))
        self.assertTrue(any('além do fim' in p for p in problems))


class EntryDocTests(unittest.TestCase):
    def test_paths_and_skill_listing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'docs').mkdir()
            (root / 'data/extracted/en-eu-rc750').mkdir(parents=True)
            (root / 'docs/real.md').write_text('x')
            skill = root / '.agents/skills/alpha'
            skill.mkdir(parents=True)
            (skill / 'SKILL.md').write_text('---\nname: alpha\ndescription: d\n---\nveja `docs/real.md`\n')
            (root / 'AGENTS.md').write_text('`docs/real.md` `docs/sumiu.md` `AAAA-MM.md` `enemy.gd`\nSkills: nenhuma\n')
            problems = build_index.check_entry_docs(root, known_names=frozenset({'enemy.gd'}))
        self.assertIn('AGENTS.md: caminho inexistente `docs/sumiu.md`', problems)
        self.assertTrue(any('não lista as skills: alpha' in p for p in problems))
        self.assertEqual(len(problems), 2, problems)


class ProgressArchiveTests(unittest.TestCase):
    def test_rotation_is_lossless_and_index_is_checked(self):
        entries = [f'## 2026-0{m}-0{d} — Entrega {m}{d}\n\nCorpo {m}{d}\n\n' for m, d in
                   ((8, 1), (8, 2), (9, 1), (9, 2))]
        entries.append('## [v0.1.9] - Sem data\n\nHerdado\n\n')
        entries.append('## 2026-10-01 — Recente\n\nFim\n')
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            progress, directory = root / 'progress.md', root / 'progress'
            progress.write_text('# Progresso\n\n' + ''.join(entries))
            moved = progress_archive.rotate(progress, directory, keep=2)
            self.assertEqual(moved, 4)
            rebuilt = []
            for path in progress_archive.archive_files(directory) + [progress]:
                rebuilt += progress_archive.split_entries(path.read_text())[1]
            self.assertEqual(''.join(rebuilt), ''.join(entries))
            self.assertEqual([p.stem for p in progress_archive.archive_files(directory)], ['2026-08', '2026-09'])
            problems = progress_archive.check(progress, directory, keep=2, root=root)
            self.assertEqual(problems, ['docs/progress/INDEX.md desatualizado'])
            (directory / 'INDEX.md').write_text(progress_archive.build_index(progress, directory, root))
            self.assertEqual(progress_archive.check(progress, directory, keep=2, root=root), [])
            progress.write_text(progress.read_text() + '## 2026-10-02 — Nova\n')
            self.assertTrue(any('rotacione' in p for p in progress_archive.check(progress, directory, 2, root)))


if __name__ == '__main__':
    unittest.main()
