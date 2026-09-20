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

## Pendências

P: frequência efetiva de atualização, relação com 50/60 Hz, todas as alterações de PlayerMovSpeed, overflow exato em bordas, comportamento de combinações simultâneas, temporização real de animação, equivalência binária de cada rotina nas ROMs. Não converter 0x0200 diretamente em uma constante por segundo antes de medir. Nenhum CharacterBody2D ou sistema de movimento foi implementado nesta etapa.
