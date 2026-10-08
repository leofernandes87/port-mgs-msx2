"""Coverage views and classification checks. mechanics.json is the only catalog."""
from collections import Counter

STATUSES = ('IMPLEMENTED', 'PARTIAL', 'PROVISIONAL', 'NOT_STARTED', 'DEFERRED',
            'UNMAPPED', 'INVESTIGATING')
ID_FIELDS = {'actor_ids': (65, 'ator'), 'weapon_ids': (7, 'arma'),
             'pickup_ids': (35, 'pickup'), 'equipment_ids': (25, 'equipamento')}


def actor_ids(value):
    """Keep malformed entries reportable instead of crashing the coverage check."""
    return {n for n in value if type(n) is int} if isinstance(value, list) else set()


def check_classifications(catalog):
    problems = []
    items = catalog.get('mechanics', [])
    ids = {item.get('id') for item in items}
    audits = catalog.get('audits', {})
    if audits and set(catalog.get('status_definitions', {})) != set(STATUSES):
        problems.append('catálogo: status_definitions deve definir exatamente os sete statuses')
    for item in items:
        mid = item.get('id', '?')
        if 'status' in item and item['status'] not in STATUSES:
            problems.append(f'{mid}: status inválido {item["status"]}')
        if not item.get('domain'):
            if 'status' in item:
                problems.append(f'{mid}: status sem domínio auditado')
            continue  # Legacy chains outside the current audit are not classified.
        if item['domain'] not in audits:
            problems.append(f'{mid}: domínio desconhecido {item["domain"]}')
        for field in ('status', 'original_scope', 'implemented_scope', 'missing_scope',
                      'rationale', 'history', 'evidence_notes'):
            if field not in item:
                problems.append(f'{mid}: campo de cobertura {field} ausente')
        if not item.get('asm') or not item.get('rationale'):
            problems.append(f'{mid}: cobertura sem evidência/justificativa')
        if item.get('status') == 'IMPLEMENTED' and (item.get('missing_scope') or not item.get('tests') or not item.get('godot')):
            problems.append(f'{mid}: IMPLEMENTED exige Godot/testes e escopo sem pendência')
        if item.get('status') in ('NOT_STARTED', 'DEFERRED', 'UNMAPPED', 'PROVISIONAL') and not item.get('evidence_notes'):
            problems.append(f'{mid}: classificação exige nota de evidência/limitação')
        for related in item.get('related_features', []):
            if related not in ids or related == mid:
                problems.append(f'{mid}: feature relacionada inexistente/inválida {related}')
        audit = audits.get(item['domain'], {})
        for field, (limit, _) in ID_FIELDS.items():
            if field in audit and field not in item:
                problems.append(f'{mid}: campo de cobertura {field} ausente')
            values = item.get(field, [])
            if not isinstance(values, list) or any(type(n) is not int or not 1 <= n <= limit for n in values):
                problems.append(f'{mid}: {field} inválidos')
    for domain, audit in audits.items():
        for field in ID_FIELDS:
            if field not in audit:
                continue
            expected = actor_ids(audit[field])
            covered = {n for item in items if item.get('domain') == domain for n in actor_ids(item.get(field, []))}
            excluded = {item[field[:-1]] for item in audit.get('exclusions', []) if field[:-1] in item}
            if expected - covered - excluded:
                problems.append(f'{domain}: {field}: IDs sem entrada/exclusão: {sorted(expected - covered - excluded)}')
            if covered & excluded or (covered | excluded) - expected:
                problems.append(f'{domain}: {field}: IDs conflitantes com o recorte auditado')
    return problems


def describe_ids(item):
    return '; '.join(f'{label}: ' + ', '.join(map(str, item[field]))
                     for field, (_, label) in ID_FIELDS.items() if item.get(field)) or 'transversal'


def render(catalog):
    out = ['# Cobertura progressiva por domínio', '',
           'Gerado por `python3 -m tools.context.build_index` a partir de '
           '[mechanics.json](mechanics.json). Não editar esta visualização.', '',
           '**Relatório para leitura humana; não é contexto padrão de agentes.** '
           'Agentes não devem ler este arquivo integralmente: use '
           '`python3 -m tools.context.lookup domain DOMÍNIO`, `lookup status STATUS` '
           'ou `lookup unmapped`; detalhes somente com `lookup mech ID`.', '',
           'Contagem por feature/família declarada, não por rotina ou percentual do jogo. '
           'Cadeias sem `domain` estão fora da auditoria e não entram nos totais. '
           'IDs podem reaparecer em comportamentos transversais; não somar IDs como features.', '']
    for domain, audit in catalog.get('audits', {}).items():
        items = [i for i in catalog['mechanics'] if i.get('domain') == domain]
        out += [f'## {audit["title"]}', '', f'Auditoria: {audit["date"]}; HEAD de partida: `{audit["project_revision"]}`; '
                f'referência inglesa: `{audit["reference_revision"]}`.', '', audit['scope'], '', audit['method'], '']
        for note in audit.get('notes', []):
            out += ['- ' + note]
        out += ['', '| Status | Features |', '| --- | ---: |']
        counts = Counter(i['status'] for i in items)
        out += [f'| `{status}` | {counts[status]} |' for status in STATUSES]
        out += [f'| Total | {len(items)} |', '', '### Entradas', '',
                '| Feature | IDs | Status |', '| --- | --- | --- |']
        out += [f'| [{i["id"]}](#{i["id"]}) — {i["title"]} | '
                f'{describe_ids(i)} | `{i["status"]}` |' for i in items]
        out += ['', '### UNMAPPED', '']
        unmapped = [i for i in items if i['status'] == 'UNMAPPED']
        out += [f'- **{i["id"]}**: {i["rationale"]}' for i in unmapped] or ['Nenhuma entrada.']
        for item in items:
            out += ['', f'<a id="{item["id"]}"></a>', f'### {item["title"]}', '',
                    f'`{item["id"]}` · **{item["status"]}**', '',
                    '**Original:** ' + item['original_scope'], '', '**Classificação:** ' + item['rationale'], '']
            for key, title in [('asm', 'Assembly'), ('extractor', 'Extractors'), ('data', 'Dados canônicos locais'),
                               ('godot', 'Godot relacionado'), ('integration', 'Integração inspecionada'),
                               ('tests', 'Testes existentes'), ('docs', 'Documentação'),
                               ('history', 'Histórico consultado'), ('implemented_scope', 'Implementado'),
                               ('missing_scope', 'Faltante / não comprovado'), ('evidence_notes', 'Notas de evidência')]:
                values = item.get(key, [])
                out += [f'**{title}:** ' + ('; '.join(values) if values else 'Nenhum localizado neste recorte.'), '']
    return '\n'.join(out).rstrip() + '\n'
