# Arquitetura geral

Escopo e graus E/B/H/P: [índice](README.md). Todos os comportamentos nesta página são **E**, salvo ressalva explícita.

## Fluxo principal

```mermaid
flowchart TD
    A[Header AB / Start] --> B[Slots, pilha, RAM, bancos e RegionLock]
    B --> C[InitHardware: PSG e SCREEN 5]
    C --> D[Instala InterruptTick em HTIMI]
    D --> E[DummyLoop aguarda interrupções]
    E --> F[InterruptTick atualiza áudio]
    F --> G{TickInProgress?}
    G -->|sim| E
    G -->|não| H[GameStatusLogic]
    H --> I[GameLogic / GameModeLogic]
    I --> J[Controles, jogador, tiros, atores, lógica comum e sprites]
    J --> E
```

| Descoberta | Fonte / símbolo | Evidência |
| --- | --- | --- |
| Programa Z80, endereços de 16 bits e acesso ao BIOS MSX | Banks0123.asm:552 `Start`; constants/bios.asm | DI/EI, IX/IY, LDIR, EXX, IN/OUT e chamadas ENASLT/RSLREG/CHGMOD. Não há emulação de CPU no Godot. |
| Entrada de cartucho | Banks0123.asm:8; `Start` | ORG 0x4000, assinatura AB, palavra de entrada. Nas duas ROMs, palavra de entrada aponta para 0x41F3 (B apenas para o header). |
| RAM e slots | Banks0123.asm:552 `Start` | SP recebe Stack; descobre slot e habilita cartucho em 0x8000–0xBFFF; zera 0xC000–0xF0EF; configura bancos e chama RegionLock. |
| Loop orientado por interrupção | Banks0123.asm:440 `InterruptTick`, :607 `DummyLoop` | Start grava JP no hook HTIMI, definido como 0xFD9F em constants/SystemVariables.asm:16; laço externo apenas salta para si. |
| Áudio precede lógica | Banks0123.asm:440 | Seleciona bancos 4/5, chama UpdateSound e restaura bancos antes de testar TickInProgress. EI permite novas interrupções; flag evita reentrância da lógica, não impede atualização de som. |
| Estados superiores | Banks0123.asm:10058 `GameStatusLogic` | TickCounter incrementado; JumpIndex despacha nove estados: logo, espera/menu, demo, início, criação do jogo, gameplay, game-over, pausa/save/load e final. |
| Submodos de gameplay | Banks0123.asm:12015 `GameLogic`, `GameModeLogic` | Atualiza apresentação conforme modo, lê controles, despacha Playing/NextRoom/menus/rádio/caminhão/elevador/porta/binóculos/morte/texto/captura/evento. |
| Ordem da simulação | Banks0123.asm:12151 `PlayModeLogic`; logic/common.asm:8 `CommonLogic` | Alerta, temporizadores e chamada recebida; jogador; disparo; tiros; inimigos; colisões de combate, ambiente, portas e itens; veneno e atualização de sprites. Alguns estados pulam passos. |

A ordem importa para fidelidade: o fluxo não é simplesmente “mover todos e depois desenhar”. A lógica pode mudar modo durante a iteração. O remake deverá modelar passos discretos antes de interpolar apresentação. **P:** duração real do tick por variante/região, eventuais frames perdidos, ordem exata de todos os submodos. Não se converte ainda velocidade para pixels/segundo.

## Hardware gráfico e áudio

`logic/inithardware.asm:14 InitHardware` chama CHGMOD com 5 (SCREEN 5), inicializa PSG, limpa páginas de VRAM e grava registradores VDP. `InitVdpDat` configura sprites e tabelas, com comentários de atributos 0xF600 e padrões 0xF800. `Banks0123.asm` contém operações VDP_Copy_Dot, DrawTile, transferências RAM/VRAM e buffers; `logic/updatesprites.asm` trata atualização e alternância/embaralhamento de sprites. Fontes de portas usam cópias retangulares na VRAM, não um TileMap de hardware que deva ser reproduzido literalmente no Godot.

Tiles lógicos de 8×8 são desenhados como bitmap. `UnpackGfx` (Banks0123.asm:3684) decodifica blocos literais/repetidos para VRAM; Load1bppTiles/Load2bppTiles/Load3bppTiles têm rotas próprias. Não supor um único formato de compressão para todos os recursos.

`sound/sound.asm` inclui bgmdriver.asm, instruments.asm, setsound.asm e sounddata.asm. `sound/bgmdriver.asm:12 UpdateSound` processa quatro áreas de trabalho de 0x20 bytes (três musicais e uma de SFX); Variables.asm:32 em diante declara essas áreas. O driver atualiza PSG, envelope, volume, instrumentos e transições musicais. **P:** especificação completa dos comandos musicais, correspondência sonora e exportação de áudio.

`logic/controls.asm:8 UpdateControls` combina teclado e joystick via SNSMAT/WRTPSG/RDPSG, mantém held/trigger. Ver [movimentação](movement-and-collision.md). Não atribuímos desempenho de hardware ou áudio equivalentes a uma inspeção estática.
