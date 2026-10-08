---
name: implement-faithful-mechanic
description: >-
  Cadeia completa para implementar ou corrigir uma mecânica fiel ao Metal Gear MSX2 no Godot:
  asm → dados extraídos → sistema Godot → integração no sandbox → teste → documentação. Use ao
  criar ou alterar sistemas em godot/scripts/, ao integrar algo em sandbox_gameplay.gd ou ao
  corrigir divergência de comportamento.
---

# Implementar mecânica fiel

## 1. Situar antes de abrir arquivos grandes

1. `python3 -m tools.context.lookup domain DOMÍNIO`, `lookup status STATUS` e `lookup unmapped`
   retornam só ID, título e status. `lookup mech ID` dá os detalhes de uma feature: asm,
   extrator, dados, sistema, integração, testes, docs e cobertura. Mecânica nova: siga as vizinhas.

2. Passo zero: skill `inspect-msx-disassembly` para localizar rotina, confirmar ramo inglês e
   registrar citação com linhas.

3. Código Godot grande só por faixa: `docs/index/godot-outline.md` fornece `início-fim` de cada
   função de `sandbox_gameplay.gd`, `enemy.gd`, `player.gd` etc.
   `python3 -m tools.context.lookup gd ARQUIVO FUNÇÃO` imprime somente a função necessária.

4. Antes de mudar uma rotina já portada:
   `lookup cites arquivo.asm:linha` mostra quem depende dela.

É proibido ler integralmente arquivos grandes quando houver lookup apropriado, especialmente
`mechanics.json`, `coverage.md`, `Banks0123.asm`, `sandbox_gameplay.gd`, `enemy.gd` e histórico
de progresso (`lookup progress "título"`).

`coverage.md` é relatório para leitura humana e nunca contexto padrão de agentes.
Para consultar ou editar uma feature do catálogo, localize-a pelo ID sem despejar
`mechanics.json` inteiro no contexto.

## 2. Implementar

- Dados de tabela vêm da ROM canônica por extrator, usando a skill `rom-extraction`, e não devem
  ser digitados manualmente no `.gd`, salvo constantes pequenas diretamente justificadas por
  citação do assembly.

- Texto protegido do jogo não deve ser colocado em arquivos versionados.

- Prefira sistema pequeno e independente em `godot/scripts/systems/`, GDScript tipado e
  `class_name`.

- Ausência de feature não é bug. Não implemente conteúdo vizinho apenas porque apareceu no asm.

- Preserve o menor escopo possível: implemente somente a feature solicitada e suas dependências
  estritamente necessárias.

## 3. Checklist de integração no sandbox

- **Ordem de tick:** atores → `CommonLogic` dentro de `PlayModeLogic`
  (`Banks0123.asm:12151`); no Godot, respeitar a ordem equivalente em `_physics_process`.

- **Temporização:** contadores derivados do original permanecem em ticks. Não converter
  comportamento de frame/tick para temporização livre em segundos sem evidência.

- **Congelamento:** diálogos, rádio e menus suspendem o mundo
  (ver `_world_process_before_dialog`).

- **Camadas z:** sprites de HUD/janelas ficam acima do mundo; confira `z_index` vizinhos antes
  de criar novos elementos.

- **Reset e persistência:** estado novo deve ser coerente com `reset_game_state`,
  `change_to_room` e demais pontos de reset/persistência. Determine explicitamente o que
  persiste entre salas e o que reinicia.

- **Salas:** conferir aliases 211/212 e faixas de numeração em `docs/index/rooms.md` antes de
  introduzir lógica dependente de room ID.

## 4. Fechar

- Criar ou ampliar teste headless pertinente usando a skill `godot-testing`.

- Criar ou atualizar teste Python quando houver extrator ou transformação de dados.

- Para toda feature já presente em `docs/index/mechanics.json`, atualizar sua entrada após
  implementação ou correção. Revisar, conforme aplicável:
  - `status`
  - `implemented_scope`
  - `missing_scope`
  - `rationale`
  - `godot`
  - `integration`
  - `extractor`
  - `data`
  - `tests`
  - `docs`
  - `evidence_notes`
  - `related_features`

- Nunca promover uma feature para `IMPLEMENTED` apenas porque o teste passa. O escopo original
  declarado deve estar coberto e não pode haver lacuna conhecida dentro daquele recorte.

- Nunca editar `coverage.md` manualmente.

- Rodar:
  `python3 -m tools.context.build_index`

- Depois rodar:
  `python3 tools/validate.py`

- Se a validação falhar, corrigir antes de considerar a entrega concluída.

- Finalizar usando a skill `delivery`.

- Não fazer commit sem autorização explícita.