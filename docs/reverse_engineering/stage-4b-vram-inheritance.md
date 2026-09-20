# Etapa 4B — Ampliação da evidência em execução: Início de Jogo, Tileset 3 e Herança de VRAM

Data: 2026-09-20.
Continuidade direta da Etapa 4 e atendimento aos critérios das seções 13 e 14 de `docs/HANDOFF.md`.
Escopo delimitado: captura e comparação da inicialização de jogo (sala 121, tileset 0) e de um tileset adicional além de 0 e 4 (sala 240, elevador, tileset 3), registrando o estado anterior de VRAM (`prior-vram.bin`) e o estado posterior estabilizado (`settled-vram.bin`) para comprovar o mecanismo de herança de atlas versus limpeza inicial.

## 1. Ambiente, ROM e Âncoras de Instrução

- **Ambiente**: macOS 15.7.7 x86_64, openMSX 21.0, máquina `C-BIOS_MSX2_JP`, Python 3.9.6, Godot 4.7.2.
- **ROM Principal**: SHA-256 `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf`. Inalterada antes e após a execução (`input_unchanged: true`).
- **Âncoras de instrução verificadas no executável (ROM offset / CPU address)**:
  - `RenderRoom`: ROM `0x0CF0`, CPU `0x4CF0`, banco 0 (`matches == [0xcf0]`).
  - `WaitVdpCmd`: ROM `0x0ED2`, CPU `0x4ED2`, RET `0x4EDB`, banco 0 (`waits == [0xed2]`).
  - `LoadRoomTiles`: ROM `0x0935`, CPU `0x4935`, banco 0 (`load_tiles == [0x935]`, assinatura única `\xcd\xc4\x42\xcd\x6a\x42\x21\x00\x60\xcd\xd1\x42\x21\x57\xc1`).

## 2. Metodologia de Captura e Sequência Reproduzível

- **Pontos de Instrumentação (somente leitura)**:
  1. `LoadRoomTiles` (`0x4935`): captura `prior-vram.bin` (64 KiB) imediatamente antes de qualquer descompactação ou alteração do atlas pela sala que está sendo carregada.
  2. `RenderRoom` retorno (`0x4cf0` stack return): captura `vram.bin` (64 KiB), `ram.bin` (16 KiB em `0xC000..0xFFFF`), `palette.bin` (32 bytes) e `state.txt`.
  3. `WaitVdpCmd` RET (`0x4EDB`): captura `settled-vram.bin` (64 KiB) após a estabilização completa do processador de vídeo (VDP Command Executing = 0).
- **Sequência de Entrada 100% Limpa**:
  Nenhuma escrita em memória (RAM/VRAM), nenhuma alteração de contador de programa (PC) e nenhum comando de "teleporte". Toda a navegação foi feita simulando a matriz física do teclado MSX (`SNSMAT` via `keymatrixdown` / `keymatrixup`):
  - Skip de logo: Espaço aos 2.0s emulados.
  - New Game: Espaço no menu inicial (`GameStatus == 1`).
  - Skip de diálogo do rádio na sala 121: Tecla RETURN (`keymatrixdown 7 128`) a cada pausa de texto (`TextWindowStatus == 3`).
  - Navegação física autônoma de Snake:
    - Sala 121 (praia, início de jogo): caminhada ao norte (UP) para a Sala 0.
    - Sala 0 (portão externo): contorno do obstáculo pela coluna 24 (px=192..200), subida e contorno à esquerda até a saída norte para a Sala 1.
    - Sala 1 (fachada do Prédio 1): contorno de cerca pela coluna 25 (px=200) e subida contínua ao norte para a Sala 2.
    - Sala 2 (corredor térreo): travessia pela passagem desimpedida da coluna 9.5 (px=76), contorno no topo e subida norte para a Sala 3.
    - Sala 3 (hall dos elevadores): subida até linha 17 (py=140), travessia oeste até coluna 3 (px=24), subida até linha 5 (py=40), deslocamento leste até px=108 e entrada direta na porta do elevador (Porta 2, `render_type 5`, que não exige cartão conforme `ChkNoCardDoorUp` em `opendoor.asm:68`).
    - Sala 240 (Elevador do Prédio 1, **Tileset 3**): transição completada com sucesso aos ~72s de tempo emulado (~4s de tempo real).

## 3. Resultados e Análise de Herança de VRAM

Foram capturadas e validadas 6 salas consecutivas nesta trajetória:

| Sala | Tileset | Bytes RAM | Tiles Carregados | Pixels Fundo Coincidentes | Registros Portas | Slots Sobrescritos | Slots Herdados | Slots Zerados |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 121 | 0 | 768/768 | 235/235 | 49152/49152 | 0 | 219 | 16 | 21 |
| 0 | 0 | 768/768 | 235/235 | 49152/49152 | 0 | 0 | 235 | 21 |
| 1 | 0 | 768/768 | 235/235 | 49152/49152 | 0 | 0 | 235 | 21 |
| 2 | 0 | 768/768 | 235/235 | 49152/49152 | 0 | 0 | 235 | 21 |
| 3 | 0 | 768/768 | 235/235 | 49152/49152 | 1/1 | 0 | 235 | 21 |
| 240 | 3 | 768/768 | 41/41 | 49152/49152 | 2/2 | 21 | 214 | 21 |

### Descobertas Críticas sobre a VRAM e os Tilesets

1. **Herança do Atlas de Tiles (Página 1, `0x8000..0xFFFF`)**:
   - `LoadRoomTiles` **não limpa** o atlas da página 1 ao trocar de tileset.
   - Na transição da Sala 3 (Tileset 0) para a Sala 240 (Tileset 3):
     - `TileSetElevator` descompacta exatamente **21 tiles** (slots 3 a 23, `0x15` tiles apontados por `GfxElevators`).
     - Apenas esses 21 slots foram sobrescritos no atlas (`overwritten_tile_ids: [3..23]`).
     - Todos os outros **214 slots não-nulos** do atlas permaneceram **rigorosamente idênticos** aos tiles do Prédio 1 (Tileset 0) que estavam carregados na Sala 3!
     - Os 21 slots restantes (slots 0..2, 138..145, 150..159) permaneceram com bytes zero porque nunca foram populados nem pelo Tileset 0 nem pelo Tileset 3.
2. **Reuso de Tileset entre Salas Consecutivas**:
   - Nas transições 121 → 0 → 1 → 2 → 3 (todas com `CurrentTileSet == 0`):
     - `LoadRoomTiles` detecta `CurrentTileSet == a` e desvia imediatamente para `SetBanks1_2_3` (`Banks0123.asm:2549`).
     - Não há nenhuma reescrita no atlas de VRAM (`overwritten_count: 0`, `inherited_count: 235`).
3. **Limpeza da Página 0 (Display)**:
   - Ao contrário da página 1, a página 0 (`0x0000..0x7FFF`) é explicitamente limpa antes da renderização pelo VDP (`ClearPage0` em `Banks0123.asm:3394`). Na entrada da Sala 121, a página 0 inicial continha 100% de bytes zero.
4. **Verificação dos Pixels do Fundo**:
   - Para todas as 6 salas, os 49.152 pixels do fundo sintetizados pelo decodificador Python a partir dos metatiles/tiles coincidiram em **100%** com os pixels lidos da VRAM estabilizada do openMSX (`settled-vram.bin`).
   - Diferença inicial de 42 pixels decorrente de comando VDP pendente (`CE=1`) na primeira amostragem foi confirmada e eliminada pela sincronização no RET de `WaitVdpCmd` (`0x4EDB`).

## 4. Integração no Godot 4

- Snapshots gerados para a Sala 240 (`room-240.json`) e Sala 121 (`room-121.json`) foram testados em modo headless com `tests/room_snapshot_integration.gd`:
  - `ROOM_LOADED: 240` → `ROOM_INTEGRATION_OK: 49152 pixels matched Python; room 240`.
  - `ROOM_LOADED: 121` → `ROOM_INTEGRATION_OK: 49152 pixels matched Python; room 121`.
- Suíte `tools/validate.py` executada com código 0: **37 testes Python OK**, importação do editor, smoke test, snapshot test e main scene aprovados.

## 5. Fronteira de Fidelidade e Próximos Passos

- O comportamento de herança de VRAM está agora formalmente comprovado entre Tileset 0 e Tileset 3 em execução real no hardware emulado.
- O capturador e o comparador agora suportam tanto a sequência clássica da demo quanto a sequência determinística de início de jogo e navegação real via teclado.
- Pendências preservadas: deltas pós-DrawDoors/itens, paletas dinâmicas em jogo contínuo, tilesets 1, 2, 5, 6 e 7.
- Não avançar para a Etapa 5 (movimento/física) antes de deltas e medições de colisão.
