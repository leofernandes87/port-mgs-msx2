# Movimentação e colisões do protagonista

Todas as conclusões comportamentais são **E (estáticas no disassembly)**; o bloco BoxColliderDat de 48 bytes também é **B**, encontrado em 0x0431A nas duas ROMs. Não foi validada a execução do jogador localmente.

| Responsabilidade | Fonte e símbolo | Evidência / conclusão |
| --- | --- | --- |
| Inicialização | Banks0123.asm:8397 InitPlayerVars | Vida e máximo 0x18, classe 0, direção para baixo, velocidade inicial 0x0200; modo de introdução usa 0x0100, X=0xC000 e Y=0xB800 em coordenadas fracionárias. |
| Coordenadas | Variables.asm:144; Banks0123.asm:9549 MovePlayerX e :9566 MovePlayerY | Byte baixo fracionário, alto inteiro; posição de 16 bits recebe adição da velocidade de 16 bits. Representação 8.8, com velocidades negativas em complemento de dois. |
| Input | logic/controls.asm:8, :23 StoreControls e :46 ReadControls | Held contém estado atual; trigger = (novo XOR antigo) AND novo. Bits 0–3 direções, 4 disparo/Space, 5 segundo botão/M ou N. Teclado e joystick são combinados. |
| Direção | Banks0123.asm, GetPlayerDir e IdsDirection (:8767) | Direção nova tem precedência; mantém máscara da última e anterior. Direções do jogador: 1 cima, 2 baixo, 3 esquerda, 4 direita (Enums.asm:63). Não tratar entrada diagonal como vetor normalizado. |
| Velocidade | ChkControlPlayer, ControlPlayer2 e PlayerMovUp (:8890) | Normalmente apenas um eixo recebe PlayerMovSpeed, outro zero; cima/esquerda negam sinal. Parada zera velocidade. Fluxo de ar modifica o caminho. |
| Próxima posição | Banks0123.asm:8972 ChkPlayerColl | Soma posição+velocidade provisoriamente, testa colisão com shape 0 e direção. Em colisão chama ResetPlayerSpd. Sala 78 testa adicionalmente shape 2. |
| Geometria | logic/collisions.asm:15 ChkTileCollision_ e :77 BoxColliderDat | Duas amostras na borda por direção; índice shape*16+(direção−1)*4. Busca tile em RoomTileBuffer e propriedade em CollisionTiles. |
| Integração / saída | Banks0123.asm:9418 ChkExitRoom | Move X, testa X<12 ou X>=244; depois move Y, testa Y<16 ou Y>=186. ExitRoom marca modo/direção; não equivale a colisão contínua com retângulos. |
| Animação | Banks0123.asm:9687 AnimatePlayer e SetSprWalk | Seletor separado do controle. Contador muda frame a cada 6 iterações; ciclo de caminhada retorna de 3 para 1; parado usa frame 0. Sprite depende de direção e arma. |

## Forma de colisão do jogador

Para shape 0, pares relativos `(dy, dx)` inspecionados: cima (−5,−6)/(−5,5); baixo (4,−6)/(4,5); esquerda (−4,−8)/(3,−8); direita (−4,7)/(3,7). São pontos testados na próxima posição inteira, não o tamanho visual inteiro do sprite. A prova binária confirma a tabela, não a semântica de todo o fluxo.

`CoordToBuffTile` (Banks0123.asm:7570) manipula bits das coordenadas para localizar a célula de 8 pixels na grade de largura 32. A Etapa 3 deve testar limites e overflow de coordenadas com fidelidade ao Z80; a fórmula geométrica em valores normais é `base + (y//8)*32 + x//8`.

## Estados separados

PlayerControlMod tem nove entradas em PlayerControlLogic (:8447): normal, soco, elevador, morto, paraquedas, fluxo de ar, andar na escada, subir escada e introdução. PlayerAnimation tem oito em AnimatePlayer: normal, soco, água, paraquedas, água profunda, escada, morto e caixa. GameMode controla contexto global, como menus e transições. Não colapsar os três em um enum único do remake.

NormalCtrl encadeia direção → água → vento → soco → velocidade → colisão → animação → saída. `chkPunch` usa trigger do segundo botão, rejeita água/caixa, configura contador 8 e modo de soco. Colisão do soco possui offset próprio. Água depende de salas e IDs de tiles, não só da máscara sólida. Elevadores e escadas têm limites e controles próprios.

## Direção e combinações de teclas (CORE-002)

**E:** `StoreControls` (logic/controls.asm:23-30) grava `ControlsHold` e `ControlsTrigger` =
bits recém-pressionados, uma vez por iteração em qualquer GameMode. `GetPlayerDir`
(Banks0123.asm:8702-8759) resolve `PlayerDirectionNew` assim:

1. Há direção nova no trigger: `DirectionMaskOld` ← `DirectionMask`; `DirectionMask` ← a primeira
   nova na ordem fixa cima, baixo, esquerda, direita.
2. Sem trigger, se o hold ainda contém `DirectionMask`: índice = hold inteiro. Com duas ou mais
   direções mantidas, `IdsDirection` dá 0 e a direção atual é conservada.
3. Senão, se o hold contém `DirectionMaskOld`: volta à antiga, que vira `DirectionMask`, e zera
   `DirectionMaskOld`.
4. Senão: índice = hold inteiro, sem atualizar máscaras.

`ChkControlPlayer` (8825-8848) move enquanto qualquer direção estiver mantida (mesmo com
`PlayerDirectionNew` = 0) e zera as duas velocidades na hora quando nenhuma está (`SetStopPlayer`).
`DisableControls` (logic/nextroom.asm:380-384) zera as máscaras ao entrar/sair de elevador,
paraquedas e escadas; a entrada normal por porta (`SetPlayerInDoor2`) não as zera.
`PlayerMovSpeed` só é gravado com 200h (8415-8416, 9400-9401) e 100h (intro, 8435-8436; escada,
9360): nenhum ramo de água altera esse valor.

**Port:** `PlayerControls` (`godot/scripts/systems/player_controls.gd`) porta StoreControls,
GetPlayerDir e DisableControls; `PlayerController.step_control` aplica ChkControlPlayer e soma a
velocidade em 8.8 inteiro por tick (`MovePlayerX/Y`), sem `delta`. Míssil e elevador ainda leem o
hold em cascata vertical-primeiro.

## Pendências

`NormalCtrl` (8468-8470) ignora os controles quando `PlayerShotsList` = 7: é o ID do primeiro tiro
(constants/structures.asm:3661-3662) e 7 = `MISSILE` (constants/Enums.asm:10), ou seja, míssil
teleguiado ativo; o sandbox já transfere a direção ao míssil.

P: overflow de 16 bits nas bordas (o port não faz wrap), chamadas de `DisableControls` em elevador/paraquedas/escada,
velocidade 100h em água de superfície no port sem evidência no asm (feature de água), temporização
real de animação, equivalência binária de cada rotina nas ROMs.
