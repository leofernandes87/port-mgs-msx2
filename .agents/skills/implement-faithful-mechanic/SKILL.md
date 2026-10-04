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

1. `python3 -m tools.context.lookup mech` lista as mecânicas; `lookup mech ID` dá asm, extrator,
   dados, sistema, função de integração, testes e docs. Mecânica nova: siga as vizinhas.
2. Passo zero: skill `inspect-msx-disassembly` (rotina, ramo inglês, citação com linhas).
3. Código Godot grande só por faixa: `docs/index/godot-outline.md` dá `início-fim` de cada função
   de `sandbox_gameplay.gd` (3 mil linhas), `enemy.gd`, `player.gd` etc.;
   `python3 -m tools.context.lookup gd ARQUIVO FUNÇÃO` imprime só a função.
4. Antes de mudar uma rotina já portada: `lookup cites arquivo.asm:linha` mostra quem depende dela.

## 2. Implementar

- Dados de tabela vêm da ROM canônica por extrator (skill `rom-extraction`), não digitados no
  `.gd`, salvo constantes pequenas citadas. Texto protegido do jogo não vai para arquivos versionados.
- Sistema pequeno e independente em `godot/scripts/systems/`, GDScript tipado, `class_name`.
- Ausência de feature não é bug: não implemente conteúdo vizinho só porque apareceu no asm.

## 3. Checklist de integração no sandbox

- **Ordem de tick:** atores → `CommonLogic` dentro de `PlayModeLogic` (`Banks0123.asm:12151`);
  no Godot, `_physics_process` do sandbox. Contadores em ticks de 60 Hz, não em segundos livres.
- **Congelamento:** diálogos, rádio e menus suspendem o mundo (ver `_world_process_before_dialog`).
- **Camadas z:** sprites de HUD/janelas acima do mundo; confira `z_index` vizinhos antes de criar.
- **Reset e persistência:** estado novo precisa ser limpo em `reset_game_state` e coerente com
  `change_to_room` (o que persiste entre salas, o que reinicia).
- **Salas:** aliases 211/212 e faixas de numeração em `docs/index/rooms.md`.

## 4. Fechar

- Teste headless novo ou ampliado: skill `godot-testing`. Teste Python para extrator.
- Atualize `docs/index/mechanics.json` se a cadeia mudou e rode
  `python3 -m tools.context.build_index` (esboço, citações e índice de testes).
- Entrega: skill `delivery`.
