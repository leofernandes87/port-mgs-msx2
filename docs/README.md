# Documentação e mapa do repositório

Comece por `docs/STATUS.md`. Regras em `AGENTS.md`; procedimentos em `.agents/skills/`.

## Documentos

- `STATUS.md`: estado atual, trabalho em andamento, próximas tarefas e decisões pendentes.
- `progress.md`: as 5 entregas mais recentes. `progress/AAAA-MM.md`: histórico completo, sem
  edição; `progress/INDEX.md`: todas as entradas com arquivo e linha.
- `index/`: índices de contexto (ver `index/README.md`).
  Agentes usam `python3 -m tools.context.lookup` para domínio/status/feature, código e histórico;
  leitura integral de arquivos grandes com lookup apropriado é proibida por `AGENTS.md`.
  `index/coverage.md` é relatório para leitura humana, não contexto padrão de agentes.
- `reverse_engineering/`: evidências por mecânica e relatórios; `README.md` dali é o índice temático
  das etapas 2–4. Auditoria regional e reextração: `en-eu-reextraction.md`.
- `history/`: documentos substituídos, preservados sem edição (ex.: handoff até 2026-10-04).
- `reference.md`, `stage-2-plan.md`, `GUIA_PROGRAMACAO.md`: material histórico da Etapa 1.

## Repositório

- `tools/`: `rom.py` (ROM canônica por hash), `validate.py` (validação única),
  `context/` (índices e consulta), `extractors/` (extração reproduzível, sem modificar entradas),
  `reverse_engineering/` (inventário e comparação regional), `emulation/` (openMSX somente leitura).
- `data/`: `rom-profiles.json`, `schemas/` (contratos neutros), `fixtures/` (dados sintéticos
  próprios); `extracted/` é local e ignorado (dados da ROM e índices derivados de terceiros).
- `godot/`: projeto independente; `scenes/`, `scripts/systems/`, `scripts/scenes/`, `tests/`.
- `tests/`: testes Python (`unittest`) com fixtures sintéticas.
- Privados e ignorados: `roms/`, `external/` (desmontagem de referência), `assets/protected/`,
  `reports/` (logs do validate).

Fluxo: ROM somente leitura → ferramentas Python → dados intermediários validados em
`data/extracted/en-eu-rc750/` → carregamento com proveniência conferida no Godot.

## Ambiente verificado (2026-09)

| Item | Valor |
|---|---|
| macOS | 15.7.7, x86_64 (Intel i5-8500B) |
| Python | `/usr/bin/python3`, só biblioteca padrão |
| Godot | 4.7.2, `/Applications/Godot.app/Contents/MacOS/Godot` (ou `$GODOT_BIN`) |
| openMSX | 21.0, `/Applications/openMSX.app/Contents/MacOS/openmsx` |
