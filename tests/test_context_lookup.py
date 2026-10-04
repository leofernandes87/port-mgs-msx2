"""CLI de contexto: seleção e limites de saída, com catálogo inteiramente sintético."""
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tools.context import lookup


class MechanicsLookupTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.directory = Path(temp.name)
        # No coverage.md or assembly checkout: queries must use only the catalog.
        self.catalog = {
            'audits': {'actors': {'notes': ['AUDIT_NOT_FOR_SUMMARIES']}, 'other': {}, 'empty': {}},
            'mechanics': [
                {'id': 'watcher', 'title': 'Vigia sintético', 'status': 'PARTIAL', 'domain': 'actors',
                 'original_scope': 'WATCHER_DETAILS', 'rationale': 'Evidence', 'actor_ids': [1],
                 'asm': ['SourceSymbol'], 'extractor': ['extract.py'], 'data': ['data.json'],
                 'godot': ['actor.gd'], 'integration': ['actor.gd::step'], 'tests': ['test_actor'],
                 'docs': ['actor.md'], 'history': ['notes.md::Entry'],
                 'implemented_scope': ['Some behavior'], 'missing_scope': ['More behavior'],
                 'evidence_notes': ['A limitation'], 'related_features': ['mystery']},
                {'id': 'mystery', 'title': 'Ator desconhecido', 'status': 'UNMAPPED',
                 'domain': 'actors', 'original_scope': 'MYSTERY_DETAILS'},
                {'id': 'other-mystery', 'title': 'Outra feature', 'status': 'UNMAPPED',
                 'domain': 'other', 'original_scope': 'OTHER_DETAILS'},
                {'id': 'legacy', 'title': 'Fora da auditoria', 'original_scope': 'LEGACY_DETAILS'},
            ],
        }
        self.write_catalog()
        patcher = patch.object(lookup.build_index, 'DOCS_INDEX', self.directory)
        patcher.start()
        self.addCleanup(patcher.stop)

    def write_catalog(self):
        (self.directory / 'mechanics.json').write_text(json.dumps(self.catalog))

    def run_lookup(self, *args):
        stdout, stderr = StringIO(), StringIO()
        with redirect_stdout(stdout), redirect_stderr(stderr):
            try:
                code = lookup.main(list(args))
            except SystemExit as exc:
                code = exc.code
        return code, stdout.getvalue(), stderr.getvalue()

    def test_domain_returns_only_three_columns_for_matching_features(self):
        self.assertEqual(self.run_lookup('domain', 'actors'),
                         (0, 'watcher\tVigia sintético\tPARTIAL\n'
                          'mystery\tAtor desconhecido\tUNMAPPED\n', ''))

    def test_status_selects_across_domains_and_excludes_unclassified_legacy(self):
        self.assertEqual(self.run_lookup('status', 'UNMAPPED'),
                         (0, 'mystery\tAtor desconhecido\tUNMAPPED\n'
                          'other-mystery\tOutra feature\tUNMAPPED\n', ''))
        self.assertEqual(self.run_lookup('status', 'PARTIAL'),
                         (0, 'watcher\tVigia sintético\tPARTIAL\n', ''))

    def test_unmapped_alias_and_lowercase_status_match_canonical_query(self):
        expected = self.run_lookup('status', 'UNMAPPED')
        self.assertEqual(self.run_lookup('unmapped'), expected)
        self.assertEqual(self.run_lookup('status', 'unmapped'), expected)

    def test_mech_without_id_remains_a_summary_with_unclassified_marker(self):
        self.assertEqual(self.run_lookup('mech'),
                         (0, 'watcher\tVigia sintético\tPARTIAL\n'
                          'mystery\tAtor desconhecido\tUNMAPPED\n'
                          'other-mystery\tOutra feature\tUNMAPPED\n'
                          'legacy\tFora da auditoria\t—\n', ''))

    def test_specific_mech_returns_all_its_fields_and_no_other_details(self):
        code, output, errors = self.run_lookup('mech', 'watcher')
        self.assertEqual((code, errors), (0, ''))
        fields = [line.split()[0] for line in output.splitlines()]
        self.assertEqual(set(fields), set(self.catalog['mechanics'][0]))
        self.assertIn('WATCHER_DETAILS', output)
        for unwanted in ('MYSTERY_DETAILS', 'OTHER_DETAILS', 'LEGACY_DETAILS', 'AUDIT_NOT_FOR_SUMMARIES'):
            self.assertNotIn(unwanted, output)

    def test_valid_empty_filters_succeed_without_payload(self):
        self.assertEqual(self.run_lookup('domain', 'empty'), (0, '', ''))
        self.assertEqual(self.run_lookup('status', 'DEFERRED'), (0, '', ''))
        self.catalog['mechanics'] = []
        self.write_catalog()
        self.assertEqual(self.run_lookup('unmapped'), (0, '', ''))

    def test_weapon_ids_are_detail_only_and_new_domain_keeps_summary_contract(self):
        self.catalog['audits']['weapons-items'] = {}
        self.catalog['mechanics'][0].update(domain='weapons-items', weapon_ids=[1],
                                             pickup_ids=[2], equipment_ids=[3])
        self.write_catalog()
        self.assertEqual(self.run_lookup('domain', 'weapons-items'),
                         (0, 'watcher\tVigia sintético\tPARTIAL\n', ''))
        code, output, errors = self.run_lookup('mech', 'watcher')
        self.assertEqual((code, errors), (0, ''))
        for field in ('weapon_ids', 'pickup_ids', 'equipment_ids'):
            self.assertIn(field, output)

    def test_unknown_domain_and_feature_fail_without_dumping_catalog(self):
        for command, error in [('domain', 'domínio desconhecido'), ('mech', 'mecânica desconhecida')]:
            with self.subTest(command=command):
                code, output, errors = self.run_lookup(command, 'absent')
                self.assertEqual((code, output), (1, ''))
                self.assertIn(error, errors)
                self.assertNotIn('DETAILS', errors)

    def test_invalid_status_and_summary_detail_flags_are_rejected(self):
        for args in [('status', 'DONE'), ('domain', 'actors', '--details'), ('unmapped', '--details')]:
            with self.subTest(args=args):
                code, output, errors = self.run_lookup(*args)
                self.assertEqual((code, output), (2, ''))
                self.assertIn('error:', errors)


if __name__ == '__main__':
    unittest.main()
