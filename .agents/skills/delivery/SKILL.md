---
name: delivery
description: >-
  Fechar uma entrega neste projeto: validação, entrada curta no progresso, STATUS, índices,
  revisão de conteúdo protegido e, só com autorização, commit/tag. Use ao terminar qualquer tarefa
  que alterou arquivos, ou quando o usuário pedir commit, tag ou atualização de documentação.
---

# Entrega

## Contexto antes da entrega

Não leia integralmente arquivos grandes quando houver lookup apropriado. Consulte a entrega
anterior por `python3 -m tools.context.lookup progress "título"`; para cobertura, use
`lookup domain DOMÍNIO`, `lookup status STATUS`, `lookup unmapped` e depois `lookup mech ID`.
`mechanics.json` continua sendo o catálogo; `coverage.md` é relatório para leitura humana,
não contexto padrão de agentes. Para `Banks0123.asm`, `sandbox_gameplay.gd` e `enemy.gd`,
use `lookup asm`/`lookup gd` e as faixas dos índices, conforme `AGENTS.md`.

## 1. Verificar

1. `python3 -m tools.context.build_index` (rotaciona o progresso; regenera esboço, citações e testes).
2. `python3 tools/validate.py` fora do sandbox. Relate o resultado real (etapas PASS, número de
   testes Python, falhas). Não declare pronto sem isso.

## 2. Documentar

- `docs/progress.md`: acrescente **uma** entrada ao fim, até ~15 linhas:

  ```markdown
  ## AAAA-MM-DD — Título curto

  **Feito:** o que mudou e por quê, com a evidência asm principal.
  **Testes:** suítes novas/ampliadas; `validate.py`: exit, etapas, testes Python.
  **Pendências:** o que ficou de fora. **Git:** sem commit | commit `abc1234`.
  ```

  Não repita hash da ROM, ambiente ou regras. Rode `build_index` de novo: só as 5 entradas mais
  recentes ficam; as antigas vão intactas para `docs/progress/AAAA-MM.md`.
- `docs/STATUS.md`: atualize HEAD, trabalho em andamento, próximas tarefas e decisões pendentes.
  Máximo ~60 linhas; nada de histórico (isso é o progresso).
- Descobertas detalhadas: documento da mecânica em `docs/reverse_engineering/`.

## 3. Commit (só quando o usuário pedir)

- Preserve alterações alheias à tarefa: `godot/project.godot` local fica fora dos commits.
- Adicione arquivos explicitamente; nunca `git add -A` às cegas nem `git add -f`.
- Revise `git diff --cached`: sem ROM, bytes do jogo, textos protegidos ou dados de `data/extracted/`.
- Mensagem em português no estilo do histórico: `tipo(escopo): resumo` (ex.:
  `fix(radio): alinha chamadas de rádio portadas à edição inglesa`), corpo curto com o porquê.
- Tag/push só se pedido. Depois do commit, atualize o `**Git:**` da entrada e o HEAD no STATUS.
