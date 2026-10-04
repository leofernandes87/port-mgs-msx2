"""Índices de contexto: parsing, detecção de referências quebradas e rotação sem perda (fixtures sintéticas)."""
import json
from pathlib import Path
import tempfile
import unittest

from tools.context import build_index, coverage, progress_archive

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


def coverage_fixture():
    """Invented actor and source references, with no game data."""
    return {
        'status_definitions': dict.fromkeys(coverage.STATUSES, 'Definition'),
        'audits': {'actors-bosses': {
            'title': 'Fixture', 'date': '2026-01-01', 'project_revision': 'synthetic',
            'reference_revision': 'synthetic', 'scope': 'Scope', 'method': 'Method',
            'actor_ids': [1, 2], 'exclusions': [{'actor_id': 2, 'reason': 'Unused'}],
            'asm': ['logic/a.asm:1 Start'],
        }},
        'mechanics': [{
            'id': 'sample', 'title': 'Sample', 'domain': 'actors-bosses', 'actor_ids': [1],
            'status': 'PARTIAL', 'original_scope': 'Original scope', 'rationale': 'Evidence',
            'implemented_scope': ['Some behavior'], 'missing_scope': ['Remaining behavior'],
            'evidence_notes': ['Inspected dispatcher'], 'related_features': [],
            'asm': ['logic/a.asm:1 Start'], 'godot': ['godot/sample.gd'],
            'extractor': ['tools/sample.py'], 'data': ['actors.json'],
            'tests': ['tests/test_sample.py'], 'docs': ['docs/sample.md'],
            'integration': ['godot/sample.gd::step'], 'history': ['docs/sample.md::Delivery'],
        }],
    }


class CoverageTests(unittest.TestCase):
    def equipment_catalog(self):
        catalog = coverage_fixture()
        audit = dict(catalog['audits']['actors-bosses'])
        audit.pop('actor_ids')
        audit.update(title='Equipment fixture', weapon_ids=[1], pickup_ids=[1, 2],
                     equipment_ids=[1], exclusions=[])
        catalog['audits']['weapons-items'] = audit
        item = dict(catalog['mechanics'][0])
        item.pop('actor_ids')
        item.update(id='equipment', domain='weapons-items', weapon_ids=[1],
                    pickup_ids=[1, 2], equipment_ids=[1])
        catalog['mechanics'].append(item)
        return catalog

    def test_independent_id_namespaces_and_multi_domain_report(self):
        catalog = self.equipment_catalog()
        self.assertEqual(coverage.check_classifications(catalog), [])
        rendered = coverage.render(catalog)
        self.assertIn('## Equipment fixture', rendered)
        self.assertIn('arma: 1; pickup: 1, 2; equipamento: 1', rendered)
        self.assertIn('ator: 1', rendered)

    def test_equipment_inventory_cannot_hide_missing_or_invalid_ids(self):
        for field, limit in [('weapon_ids', 7), ('pickup_ids', 35), ('equipment_ids', 25)]:
            for values, expected in [([], 'sem entrada/exclusão'), ([limit + 1], 'inválidos'),
                                     ([True], 'inválidos'), (None, 'inválidos')]:
                with self.subTest(field=field, values=values):
                    catalog = self.equipment_catalog()
                    catalog['mechanics'][1][field] = values
                    problems = coverage.check_classifications(catalog)
                    self.assertTrue(any(field in p and expected in p for p in problems), problems)
            catalog = self.equipment_catalog()
            del catalog['mechanics'][1][field]
            self.assertTrue(any(f'{field} ausente' in p for p in coverage.check_classifications(catalog)))

    def test_equipment_exclusion_does_not_cover_weapon_with_same_number(self):
        catalog = self.equipment_catalog()
        catalog['mechanics'][1].update(weapon_ids=[], equipment_ids=[])
        catalog['audits']['weapons-items']['exclusions'] = [{'equipment_id': 1, 'reason': 'Fixture'}]
        problems = coverage.check_classifications(catalog)
        self.assertEqual(len(problems), 1, problems)
        self.assertIn('weapon_ids: IDs sem entrada/exclusão', problems[0])

    def test_all_seven_statuses_are_accepted_and_legacy_is_not_classified(self):
        for status in coverage.STATUSES:
            with self.subTest(status=status):
                catalog = coverage_fixture()
                catalog['mechanics'][0].update(status=status, missing_scope=[])
                catalog['mechanics'].append({'id': 'legacy', 'title': 'Outside audit'})
                self.assertEqual(coverage.check_classifications(catalog), [])

    def test_invalid_status_missing_fields_and_unknown_domain(self):
        catalog = coverage_fixture()
        item = catalog['mechanics'][0]
        item['status'] = 'DONE'
        self.assertTrue(any('status inválido' in p for p in coverage.check_classifications(catalog)))
        del item['status']
        self.assertTrue(any('status ausente' in p for p in coverage.check_classifications(catalog)))
        item.update(status='PARTIAL', domain='unknown')
        self.assertTrue(any('domínio desconhecido' in p for p in coverage.check_classifications(catalog)))
        del item['domain']
        self.assertTrue(any('status sem domínio' in p for p in coverage.check_classifications(catalog)))

    def test_classification_requires_evidence_and_valid_relationships(self):
        catalog = coverage_fixture()
        item = catalog['mechanics'][0]
        item.update(status='IMPLEMENTED', related_features=['absent'])
        problems = coverage.check_classifications(catalog)
        self.assertTrue(any('IMPLEMENTED exige' in p for p in problems))
        self.assertTrue(any('relacionada inexistente' in p for p in problems))
        item.update(status='NOT_STARTED', evidence_notes=[])
        self.assertTrue(any('exige nota' in p for p in coverage.check_classifications(catalog)))
        del catalog['status_definitions']['UNMAPPED']
        self.assertTrue(any('status_definitions' in p for p in coverage.check_classifications(catalog)))

    def test_actor_inventory_holes_conflicts_and_malformed_ids(self):
        catalog = coverage_fixture()
        item = catalog['mechanics'][0]
        for ids, message in [([], 'sem entrada/exclusão'), ([1, 2], 'conflitantes'),
                             ([1, 66], 'inválidos'), (None, 'inválidos'), ([True], 'inválidos')]:
            with self.subTest(ids=ids):
                item['actor_ids'] = ids
                self.assertTrue(any(message in p for p in coverage.check_classifications(catalog)))

    def test_generated_counts_unmapped_and_legacy_exclusion(self):
        catalog = coverage_fixture()
        catalog['mechanics'][0]['status'] = 'UNMAPPED'
        catalog['mechanics'].append({'id': 'legacy', 'title': 'Outside audit'})
        rendered = coverage.render(catalog)
        self.assertIn('| `UNMAPPED` | 1 |', rendered)
        self.assertIn('| `NOT_STARTED` | 0 |', rendered)
        self.assertIn('| Total | 1 |', rendered)
        self.assertIn('### UNMAPPED\n\n- **sample**: Evidence', rendered)
        self.assertNotIn('Outside audit', rendered)
        self.assertIn('Relatório para leitura humana; não é contexto padrão de agentes.', rendered)
        self.assertIn('lookup unmapped', rendered)
        self.assertEqual(rendered, coverage.render(catalog))

    def test_reference_validation_covers_each_catalog_chain(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            files = {'godot/sample.gd': 'func step() -> void:\n\tpass\n',
                     'tools/sample.py': '', 'tests/test_sample.py': '',
                     'docs/sample.md': '# Notes\n\n## Delivery\n',
                     'data/extracted/en-eu-rc750/actors.json': '{}'}
            for name, text in files.items():
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(text)
            path = root / 'mechanics.json'

            def check(catalog, sources=None):
                path.write_text(json.dumps(catalog))
                return build_index.check_mechanics({'logic/a.asm': 'Start:\tret\n'}
                                                  if sources is None else sources, path, root)

            self.assertEqual(check(coverage_fixture()), [])
            cases = [('godot', 'godot/missing.gd', 'caminho inexistente'),
                     ('extractor', 'tools/missing.py', 'caminho inexistente'),
                     ('docs', 'docs/missing.md', 'caminho inexistente'),
                     ('tests', 'godot-nonexistent-stage', 'teste desconhecido'),
                     ('integration', 'godot/sample.gd::missing', 'integração inexistente'),
                     ('history', 'docs/sample.md::Missing', 'histórico inexistente'),
                     ('data', 'missing.json', 'dado extraído inexistente'),
                     ('data', '../outside.json', 'fora do diretório canônico'),
                     ('asm', 'logic/missing.asm:1', 'referência asm inválida'),
                     ('asm', 'logic/a.asm:2-1', 'faixa asm inválida'),
                     ('asm', 'logic/a.asm:0', 'faixa asm inválida')]
            for field, ref, expected in cases:
                with self.subTest(field=field, ref=ref):
                    catalog = coverage_fixture()
                    catalog['mechanics'][0][field] = [ref]
                    self.assertTrue(any(expected in p for p in check(catalog)))
            catalog = coverage_fixture()
            catalog['audits']['actors-bosses']['asm'] = ['missing.asm:1']
            self.assertTrue(any('audit-actors-bosses' in p for p in check(catalog)))
            catalog['mechanics'][0]['asm'] = ['invalid syntax']
            self.assertTrue(any('referência asm inválida' in p for p in check(catalog, {})))

    def test_private_data_absence_is_portable_but_cannot_escape_canonical_root(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = root / 'mechanics.json'
            catalog = {'mechanics': [{'id': 'legacy', 'title': 'Legacy', 'asm': [],
                       'godot': [], 'tests': [], 'docs': [], 'data': ['actors.json']}]}
            path.write_text(json.dumps(catalog))
            self.assertEqual(build_index.check_mechanics({}, path, root), [])
            catalog['mechanics'][0]['data'] = ['/tmp/escape.json']
            path.write_text(json.dumps(catalog))
            self.assertTrue(any('fora do diretório' in p for p in build_index.check_mechanics({}, path, root)))


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
