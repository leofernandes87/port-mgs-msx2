# Atores, inimigos e IA

Escopo: **E**, identificação de módulos e relações; não especificação exaustiva de cada inimigo nem validação em execução.

## Estruturas e ciclo

`constants/structures.asm`, STRUCT ACTOR, contém campos ID, Status, Ydec/Y, Xdec/X, Moving, velocidades, sprite, vida, colisão, direção, caminho e campos específicos. Offsets iniciais: ID +0, Status +1, Ydec/Y +2/+3, Xdec/X +4/+5, Moving +6, velocidade Y +7/+8, X +9/+A, SpriteId +B, ANIM_CNT +C, LIFE +D, COLLISION_CFG +E, Direction +11, TOUCH_INFO +1E, StunnedCnt +1F. Fields posteriores são reutilizados por tipo; não exportá-los com um significado universal.

`Banks0123.asm:12612 EnemiesLogic` percorre 16 slots, passo 0x80, em EnemyList (0xD000). ID 0 é vazio. Ator atordoado segue caminho especial; demais executam RunEnemyLogic, MoveActor e ChkActorExitRoom. RunEnemyLogic (:12657) testa LIFE=0, bit 7 do ID e contato de soco antes do despacho por ID−1. MoveActor (:12875) soma velocidades fracionárias às posições. KillActor (:13192), DismissActor (:12927) e rotinas específicas tratam remoção, morte, sprites, itens e chefes.

Fonte ROM dos atores é compacta: `data/actorsinrooms.asm` contém listas de contagem e triplas `[ID, Y, X]`. `SetupEnemyRoom` (:6088) zera 0x800 bytes, seleciona idxActorsRooms e usa contagem & 0x0F. Salas >=222 são excluídas nesse caminho. AddEnemy inicializa campos e despacha lógica específica. A representação em RAM não é o mesmo formato da lista na ROM.

## Patrulha e percepção

| Módulo / símbolo | Responsabilidade e evidência |
| --- | --- |
| logic/actors/guard.asm:29 GuardLogic | Testa remoção, sono, percepção e alerta. Despacha GuardPatrolLogic, GuardPatrolTurn, GuardPatrolWait, GuardSleeping, GuardWakeUp por GuardStatus. |
| Banks0123.asm:6852 InitGuardPath, :6924 GetPathPoints, :6956 GetPathPoint | Escolhe caminho por sala e ordinal de guardas/câmeras; lê número de pontos e pares Y/X. Também aplica exceções de entrada para evitar contato imediato com guardas. |
| data/paths.asm, idxRoomPaths | Dois níveis de ponteiros: sala → caminhos → contagem e pontos. Não é navegação por malha ou busca A*. |
| Banks0123.asm, SetDirToPoint e WalkSpeeds | Deriva destino/direção e escolhe velocidades por categoria. Direção de patrulha neste caminho é construída como 0–3; alguns comentários ACTOR.Direction dizem 1–4. Não normalizar sem considerar consumidor e transformação de estado. |
| logic/actors/chkdiscover.asm:7 ChkActSeePlayer | Usa posição, direção, alerta, sprites de água profunda e caixa parada; contato pode disparar alarme. |
| ChkLookUp/Down/Left/Right; :212 ChkViewObstacles | Testa faixa alinhada à direção e caminha em tiles até o jogador, consultando CollisionTiles; há exceções para grades/corrimãos no tileset Building. |
| :447 ChkViewVertical / :472 ChkViewHorizontal | Constantes de largura 16 na vertical; horizontal usa 8 para câmera e 12 para outros. Limites exatos usam aritmética de byte e flags, não foram simulados em todo domínio. |
| logic/actors/guardalert.asm | Comportamento de guarda em alerta; separado da patrulha e dos tipos especiais. |
| logic/actors/guardshot.asm, shottoplayer.asm, bullethv.asm | Disparo e trajetórias/projéteis; não assumir que todo ataque é a mesma rotina. |

O termo “campo de visão” não implica cone geométrico: as rotinas inspecionadas usam faixas direcionais e obstrução por tiles. **P:** auditar todas as convenções de direção entre patrulha, câmera e alerta antes de implementar percepção.

## Alerta e persistência

`logic/setalert.asm:12 SetAlertModeRespawn` e `SetAlertMode` guardam estado global, sala de disparo e quantidade de reforços. O código percorre cartões de 8 para 1 e usa maior índice encontrado +3, com exceção para sala 216; câmeras/lasers selecionam música diferente. `ChkAlarmEnd`, `ChkRespawnEnemy` e `logic/checkweaponalert.asm` relacionam alerta à mudança de sala, tiro e reforços.

`logic/actors.asm` agrega tipos como guardas, câmeras, cães, projéteis, prisioneiros, buracos, interruptores e chefes. A lista EnemyList é de atores de gameplay, não apenas inimigos hostis. Estados de chefes e resgatados são persistidos em flags globais e afetam montagem da sala.

P: todas as condições de encerramento de alerta, probabilidades de espera/sono, sequências de chefes, trajetórias completas, limites de sprites, semântica integral de COLLISION_CFG/TOUCH_INFO por tipo. As rotinas foram localizadas, sem prometer IA completa.

## Atualização da Etapa 3

A Etapa 3 distinguiu 104 caminhos de pontos e 10 listas de direções. Nem todo Path_ representa pares Y/X. Associação por ator depende dos contadores usados pela inicialização; foi preservada sem normalização arbitrária. Veja [resultados](stage-3-results.md).
