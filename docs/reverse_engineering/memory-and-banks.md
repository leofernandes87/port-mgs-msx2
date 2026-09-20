# Memória e bancos

## Janelas de ROM (E)

`Banks0123.asm:621 SetBanks1_2_3`, :654 `SetBanks`, :683 `SetBanks_7_8_9`, `SetBanks_A_B_C` e `SetBanks_D_E_F` escrevem números consecutivos nos registradores mapeados em 0x6000, 0x8000 e 0xA000. Cada janela abrange 0x2000 bytes. A janela 0x4000–0x5FFF contém os wrappers, início e interrupção; não é alterada por SetBanks. O padrão é compatível com mapper Konami sem SCC (**H quanto à identificação formal do mapper físico**); os endereços efetivamente escritos são comprovados pelo código.

| Grupo de fonte | Bancos | Endereço CPU declarado | Offset físico candidato / confirmado nas amostras |
| --- | --- | --- | --- |
| Banks0123.asm | 0–3 | 0x4000–0xBFFF | 0x00000–0x07FFF |
| Banks456.asm | 4–6 | 0x6000–0xBFFF | 0x08000–0x0DFFF |
| Banks789.asm | 7–9 | 0x6000–0xBFFF | 0x0E000–0x13FFF |
| BanksABC.asm | A–C | 0x6000–0xBFFF | 0x14000–0x19FFF |
| BanksDEF.asm | D–F | 0x6000–0xBFFF | 0x1A000–0x1FFFF |

Evidência E: cada grupo termina com preenchimento até 0xC000; Banks0123 inicia em 0x4000 e os outros em 0x6000. A ordem de inclusão está em MetalGear.asm:59. Evidência B: o segmento rooms+metatiles coincide em 0x1A000 e RoomGfxSetIds em 0x0E000 nas duas ROMs. Isso confirma essas posições sem pressupor que todo código dos cinco grupos seja idêntico.

Para uma janela selecionada: `offset = banco * 8192 + (endereço_CPU - início_da_janela)`. Exigir 0 ≤ deslocamento < 8192, banco presente no arquivo e contexto correto. Exemplo: Metatiles1 em CPU 0x82C0, banco E em janela 0x8000 → offset 0x1C2C0. `tools/reverse_engineering/analyze.py:bank_offset` implementa limites e testes de ida/volta. Para percorrer um grupo contíguo D/E/F, a passagem de 0x7FFF para 0x8000 muda de D para E; não manter banco D ao cruzar a janela.

A ROM de 128 KiB contém 16 blocos completos de 8 KiB. A de 160 KiB contém 20, mas **P:** semântica dos quatro blocos adicionais e alterações no mapper da tradução. Não aplicar os bancos extras à versão de 128 KiB nem assumir que são cabeçalho.

## RAM (E, calculada por declarações)

`Variables.asm:8` inicia MAP 0xC000. O parser estrito soma cada reserva, inclusive declarações sem dois-pontos. Não são endereços extraídos de execução do jogo.

| Símbolo | Endereço | Uso / tamanho reservado |
| --- | --- | --- |
| GameStatus | 0xC000 | estado superior, 1 byte |
| Room / Life | 0xC130 / 0xC131 | sala e vida |
| PlayerMovSpeed | 0xC143 | 2 bytes |
| GameMode | 0xC151 | modo de gameplay |
| PlayerYdec / PlayerY | 0xC181 / 0xC182 | fração / inteiro Y |
| PlayerXdec / PlayerX | 0xC183 / 0xC184 | fração / inteiro X |
| PlayerSpeedY / PlayerSpeedX | 0xC186 / 0xC188 | 2 bytes cada |
| PlayerAnimation | 0xC18B | seletor de animação |
| DoorsList | 0xC3D0 | 0x80 bytes; registros de 0x10 |
| Weapons | 0xC500 | 0x1C bytes, mais InvSupressor a seguir |
| Equipment | 0xC530 | primeiro byte; reserva seguinte completa área de 0x70 |
| ItemsInTheRoom | 0xC5D0 | 0x30 bytes, três slots com passo 0x10 |
| AlertMode | 0xC602 | declaração reserva 2 bytes; nem todo acesso é word |
| CollisionTiles | 0xC700 | 256 propriedades de tile |
| EnemyList | 0xD000 | conjunto de reservas totaliza 0x800, 16×0x80 |
| EnemyListCopy | 0xD800 | 0x800, cópia para binóculos |
| RoomTileBuffer | 0xE000 | reserva 0x500; RenderRoom usa inicialmente 0x300 |
| Stack | 0xF0F0 | SP inicial, pilha cresce para baixo |
| BankIn60 / BankIn80 / BankInA0 | 0xF0F1–0xF0F3 | cópias dos bancos selecionados |

Outras áreas: tiros, portas abertas, inventário coletado, eventos, dados de checkpoint, texto, atributos e cores de sprites. O relatório local contém endereço, tamanho e linha de todas as declarações. BIOS e variáveis do sistema têm equates próprios em constants/bios.asm e constants/SystemVariables.asm. **P:** mapa completo dos slots de RAM em execução e todos os efeitos de save/load.
