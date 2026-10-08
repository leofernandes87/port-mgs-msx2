# Grey Fox: janela inglesa e paginação

Entrega de 2026-10-03. Referência: `external/MetalGear/`, revisão
`30d1b940bede10fdabbaf9767ad4f0ad8dd33291`, fontes assembly sem alterações.

## Variante e evidência

O usuário escolheu explicitamente **o inglês original da desmontagem**.
`data/texts.asm:64,290–302` contém o texto 59, cabeçalho `0x11`, dez páginas.
Não é o resumo anteriormente escrito em `Prisoner.PRISONER_TEXTS`.
Grafia, pontuação e quebras são preservadas, inclusive os erros da edição inglesa.
O texto protegido completo permanece somente no JSON local ignorado.

A ROM principal de 128 KiB contém os 240 bytes de `data/textsjp.asm:349–363`
em ocorrência única no offset físico `0x18DB8`: cabeçalho japonês `0x12`, outra
mensagem/paginação e janela de cinco linhas. O bloco inglês de 193 bytes não foi
encontrado nas duas ROMs locais. Isso não identifica integralmente suas revisões.
A extração inglesa é **validada contra a fonte fixada**, não contra a ROM local,
nem contra a tradução Nekura_Hoka. Nenhum endereço de texto inglês na ROM foi inferido.

| Regra | Evidência primária |
| --- | --- |
| Resgate chama SetText antes de verificar promoção; sala original 164 → texto 59 | `logic/actors/prisoner.asm:244–256,277` |
| Dicionário não recursivo; `FD` página, `FE` linha, `FF` fim | `Banks0123.asm:5305–5391` |
| Modal salva/restaura modo do jogo | `Banks0123.asm:7824–7828,8301–8303` |
| Teclas por transição: M/N ou Return | `Banks0123.asm:7952–7968,8150–8156` |
| Um caractere por máscara `TickCounter & 3 == 0` | `Banks0123.asm:7987–7997` |
| Glifos 8×8; avanço 4 para `97`; demais 8; linha +12 | `Banks0123.asm:8010–8033,8113–8124` |
| Pular durante impressão descarta o restante da página | `Banks0123.asm:8130–8136,8192–8198` |
| Página final espera confirmação; prompt apenas se houver próxima | `Banks0123.asm:8179–8185,8207–8218` |
| Geometria e parâmetros de abertura | `Banks0123.asm:8365–8387`; `logic/textboxappear.asm:10–62` |
| Fonte em índice de cor 14; regiões condicionais | `logic/loadfont.asm:10–18`; `gfx/font.asm:29–35,63–67` |

Janela tipo 1: `(48,8)`, tamanho `160×41`; texto em `(52,12)`, largura 152,
três linhas em Y=12/24/36; prompt em `(196,36)`. Abertura tem 18 passos de
crescimento, após pré-decrementar contador inicial 19. A camada da janela conserva
o fundo do mundo sem modificá-lo e desaparece ao terminar.

## Implementação

- `tools/extractors/extract_grey_fox_dialogue.py`: verifica revisão/limpeza da
  referência, resolve tabela inglesa/dicionário, exporta páginas e proveniência.
  Ponteiros montados são offsets internos do segmento de dados, não endereços ROM.
- `tools/extractors/extract_transceiver_sprites.py`: corrigida seleção exclusiva
  do ramo inglês da fonte. Antes concatenava ambos os ramos, deslocando pontuação
  e tiles seguintes. Apóstrofo usa tile 103 (`97`); vírgula, tile 47 (`5F`).
  O atlas compartilhado já utilizado pelo jogo é regenerado, sem fonte substituta.
- `PrisonerDialog`: máquina Init/Appear/Decode/Print/Wait/End; páginas privadas,
  fonte bitmap com nearest, largura estreita correta, sem timeout. Valida tipo,
  glifos, espaço disponível e hash do atlas. Falha explícita se extração faltar.
- `SandboxGameplay`: resgate de Grey Fox abre a janela inclusive ao subir de
  patente; suspende processamento dos nós do mundo e lógica de gameplay, consome
  entradas e restaura processamento ao fechar/resetar. O restante dos prisioneiros
  mantém o fluxo anterior. O alias local 212 corresponde à sala original 164.
- Removido o resumo inventado de Grey Fox no código versionado. Resgate permanece
  persistente na reentrada, sem repetir a mensagem nem incrementar duas vezes.

## Reprodução e verificações

Na raiz, com a referência privada fixada já disponível:

```sh
python3 -m tools.extractors.extract_grey_fox_dialogue
python3 tools/validate.py
/Applications/Godot.app/Contents/MacOS/Godot --path godot --script res://tests/prisoner_dialog_test.gd -- --render
```

Saídas privadas: `data/extracted/dialogues/grey-fox-en.json` e
`godot/assets/protected/sprites/transceiver/msx_font.png`.
JSON SHA-256: `1793a266d92f488223480019d8c9eb1d362f53f6d0c44d55fc22d131090dcb46`.
Atlas SHA-256: `f32ec09bf9fc0458c326dbb1bbad19f9e63bb524a3473f2c37f1b903440ddb15`.
Reextração repetida: JSON e atlas idênticos byte a byte.
Comprimentos das páginas decodificadas (incluindo FE): 13/34/49/34/13/17/30/23/45/52.

Validação completa: 98 testes Python, importação, todas as suítes Godot e boot
passaram. Novo teste Godot: 75 verificações, sem falhas; modo gráfico: 86, sem
falhas. Verificados todos os pixels dos glifos necessários contra as linhas da
fonte inglesa, incluindo vírgula/apóstrofo; dez páginas renderizadas pelo OpenGL
coincidiram em 49.152 pixels cada com composição independente desses dados.
Inclui testes sintéticos sem ROM, promoção simultânea, bloqueio de ações,
persistência, fechamento e reset. Integração privada é explicitamente pulada
quando não há extração disponível.

Logs: `reports/grey-fox-validation.log`, `reports/grey-fox-render.log`.
PNGs: `reports/grey-fox-room.png`, `reports/grey-fox-page-{01,03,10}.png`.
Sala real e página 3 inspecionadas visualmente; texto legível, sem cortes.

## Correções de fidelidade (revisão contra o assembly)

| Correção | Evidência primária |
| --- | --- |
| Estados do ator: amarrado → espera → resgatado → inativo | `logic/actors/prisoner.asm:63–67` |
| Toque só arma o bit 7 de `TOUCH_INFO`; ator lê no tick seguinte e espera `TIMER=2` | `prisoner.asm:90–95,199–203`; `ChkTouchEnemies` após `EnemiesLogic` em `Banks0123.asm:12072–12087` |
| Resgate (SetText, IncRescued) em T+4 após o toque em T | `prisoner.asm:244–256` |
| SetText só troca GameMode; o restante do tick continua (tiros, colisões) | `Banks0123.asm:7824–7829,12072–12087` |
| Promoção redesenha classe e vida no mesmo tick | `Banks0123.asm:9656,9675–9677` |
| Prompt só a partir do 1.º tick de TW_Wait, só se houver próxima página | `Banks0123.asm:8102–8107,8179–8185,8207–8218` |
| Fase apagada do prompt copia célula vazia sobre `(196,36)` | `Banks0123.asm:4726–4744,8210–8211` |
| Janela desenhada no bitmap da página 0; sprites de hardware ficam acima | `logic/textboxappear.asm:51–62`; `Banks0123.asm:4741–4744`; `logic/hudspritemask.asm:37–41`; `logic/nextroom.asm:90` |

Implementação: `Prisoner.actor_tick()` + `check_touch()` (sem resgate imediato),
laço de prisioneiros do sandbox sem `return` ao abrir o diálogo, `hud.update_hud_state()`
na promoção, `PrisonerDialog.prompt_active()/prompt_visible()` e `z_index = 7`
(acima de sala/itens/portas, abaixo de inimigos, Snake e tiros).

Sonda openMSX 21.0 (C-BIOS MSX2 JP, ROM principal somente leitura, saídas ignoradas
em `data/extracted/textbox-probe-20261004/`): abertura do texto 2 registrou 33 passos
de comandos VDP gravando no bitmap, coerente com a rotina. Não exercitou Grey Fox.

## Limites

Não houve nova captura de Grey Fox no openMSX. A comparação de pixels foi contra
a composição da fonte/páginas da desmontagem, não contra frame do emulador.
Cadência usa o relógio de 60 Hz existente no projeto e as máscaras de tick do
assembly; não estabelece sincronismo temporal integral com CPU/VDP. SFX de
digitação `0x23` (`Banks0123.asm:8035–8043`) e SFX de promoção não integrados.
Pendências sem prova segura (não implementadas): pixels da última linha interna da
moldura (VRAM da sonda já preta antes da caixa; alinhamento por byte do HMMV pode
deixar coluna x=206 no tipo 1); botão B do joystick (`controls.asm:53–57,65`, sem
mapeamento de gamepad no projeto); fase do TickCounter semeada por
`Engine.get_physics_frames()`; prisioneiro (z=3) abaixo das portas e ausência de
DismissActor0 de resgatados na reentrada (preexistentes). Tarefa separada:
`RESCUED_PER_RANK = 4` versus `cp 5` em IncRescued (`Banks0123.asm:9593,9634–9641`).
Assets privados continuam necessários
à execução local; não foi preparado pacote exportado nem incluído conteúdo
protegido no Git. Próxima melhoria, se solicitada: SFX e comparação dinâmica com
uma edição inglesa correspondente, sem tratar a ROM japonesa como essa edição.
