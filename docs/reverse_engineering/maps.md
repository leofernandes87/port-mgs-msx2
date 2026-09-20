# Salas, tiles e colisões

## Localização e representação

**B:** rooms.asm + metatiles.asm, compilados apenas como declarações DB/DW, geram 18.176 bytes idênticos nas duas ROMs, intervalo físico `[0x1A000, 0x1E700)`. Não foi montado código Z80. Os includes de BanksDEF.asm:11 e :13 são consecutivos após ORG 0x6000.

| Estrutura | Arquivo / linha | CPU com D/E/F | Offset físico | Confirmação |
| --- | --- | --- | --- | --- |
| idxRooms | data/rooms.asm:7 | 0x6000 | 0x1A000 | B |
| MetaTileSetIDs | data/rooms.asm:268 | 0x61F6 | 0x1A1F6 | B |
| idxMetatileSet | data/rooms.asm:282 | 0x6274 | 0x1A274 | B |
| Room000 | data/rooms.asm:295 | 0x6280 | 0x1A280 | B |
| Metatiles1 | data/metatiles.asm:6 | 0x82C0 | 0x1C2C0 | B |
| Metatiles2 | data/metatiles.asm:229 | 0x9040 | 0x1D040 | B |
| Metatiles3 | data/metatiles.asm:359 | 0x97F0 | 0x1D7F0 | B |
| Metatiles4 | data/metatiles.asm:472 | 0x9E90 | 0x1DE90 | B |
| Metatiles5 | data/metatiles.asm:498 | 0x9FB0 | 0x1DFB0 | B |
| Metatiles6 | data/metatiles.asm:602 | 0xA5B0 | 0x1E5B0 | B |
| RoomGfxSetIds | data/roomtileset.asm:10 | 0x6000, grupo 7/8/9 | 0x0E000 | B, 126 bytes |
| RoomConnections | data/roomsconnections.asm:7 | 0x8E0E, grupo 4/5/6 | 0x0AE0E | B, 624 bytes |

idxRooms tem 251 palavras little-endian, IDs 0–250; há 165 labels RoomNNN. **Não são 251 layouts únicos ou necessariamente utilizáveis.** Há aliases, RoomUndefined, áreas não utilizadas e conteúdo adicional entre labels. O consumidor lê 48 bytes pelo ponteiro; o extrator futuro deve seguir a tabela, não dividir cegamente o arquivo em registros. Há intervalos maiores que 48 após Room110, Room166, Room203 e Room137, que exigem classificação antes de exportar todas as salas. IDs sem definição válida não devem virar mapas inventados.

**E:** `RenderRoom` (Banks0123.asm:3390) escolhe o ponteiro, expande seis linhas com oito IDs cada e desenha 0x300 tiles. `UnpackMetatiles` (:3322) usa `(id−1)*16` e copia quatro linhas de quatro bytes. Resultado: 8×6 metatiles, cada um de 4×4 tiles; 32×24 tiles de 8×8 pixels, isto é, plano lógico de 256×192. IDs de metatile são base 1. MetaTileSetIDs contém dois seletores por byte; GetNibbleHL_A2 (:859) usa nibble alto para sala par e baixo para ímpar. A tabela idxMetatileSet contém seis ponteiros; seletores 0 ou 7 observados em regiões especiais não devem ser tratados automaticamente como metatiles válidos. Seu fluxo especial permanece P.

**Correção de comentário:** o texto anterior a RenderRoom diz metatile de 8×8 tiles; isso contradiz os contadores 4×4 da rotina e as definições. A implementação futura deve seguir o código.

## Compressão e gráficos

O mapa é uma substituição por dicionário de metatiles, sem RLE no caminho RenderRoom inspecionado. **E:** não confundir essa representação com `UnpackGfx` (:3684), que lê endereço VRAM de 16 bits e tokens: 0 termina; 0x80 muda endereço; 1–127 repetem o próximo byte; 0x81–0xFF copiam os próximos (token & 127) bytes. Essa rotina é usada por recursos específicos, não por todo mapa.

`LoadRoomTiles` (:2540) seleciona RoomGfxSetIds, carrega blocos gráficos via idxTileSets e decodifica propriedades de colisão. `LoadTileset` (:2642) usa registro normal de cinco bytes: configuração, quantidade, tile inicial, ponteiro LE. O comentário em data/roomtileset.asm desloca campos de destino/ponteiro; prevalecem os acessos IX+2 e IX+3/+4. O caminho de flip reaproveita dados e tem semântica própria; especificação completa dos gráficos fica P para Etapa 3. Não importar PNGs de room_images como mapas reconstruídos.

## Colisão e alterações dinâmicas

**B:** sete blocos de 32 bytes coincidem nas duas ROMs: CollTilesBuilding 0x0E0E9, Basem 0x0E109, Roof 0x0E129, Elevator 0x0E149, Lorry 0x0E169, HindD 0x0E189 e MetalGear 0x0E1A9. `LoadColliTiles` (:2590) expande MSB primeiro para 256 bytes em CollisionTiles (0xC700), bit 0 indica bloqueio. A propriedade depende do tileset; o mesmo ID não é universalmente sólido.

**E:** CoordToBuffTile (:7570) relaciona coordenadas a RoomTileBuffer. Portas fechadas escrevem tiles de colisão no buffer (`logic/doors/drawdoors.asm:92 PutDoorCollTiles`); a abertura/remoção restaura conteúdo. Água, eletricidade, gás, buracos, tiros e visão têm regras adicionais. Uma única grade booleana estática não representa toda a jogabilidade.

## Carregamento, portas e associações

**E:** `InitRoom` (:11861) prepara portas e entrada; InitRoom2 aplica checkpoints/eventos e limpa temporários; carrega tiles, sprites e mapa; desenha portas e itens, ajusta paletas/HUD e configura inimigos. Save/load tem caminho de restauração separado.

Conexões têm quatro bytes (norte, sul, oeste, leste), 0xFF representa indefinido. `GetNextRoomNum` (:889) usa índice sala para 0–125; sala−82 para 208–227; sala−95 para 241–250. 126–207 e 228–240 não usam essa conexão normal. Elevadores e portas têm tratamento específico. `logic/nextroom.asm:13 SetNextRoom` considera porta, paraquedas e a bússola no deserto; não assumir grade espacial regular entre IDs.

Portas: data/doors.asm contém idxDoors e listas de registros de cinco bytes `[id, render_type, draw_y, draw_x, destination]`, terminadas por 0xFF. AddDoorsData (:1270) pula IDs 225–239, expande registros para 16 bytes em RAM, associa IdDoorsLogic, estado persistente DoorOpenArray e caixas de abertura/entrada. A lista de atores usa idxActorsRooms, contagem no nibble baixo e triplas ID/Y/X (SetupEnemyRoom :6088). Itens usam idxRoomItemsIdx e listas ID/Y/X com terminador FF (logic/addroomitems.asm:8). Eventos não residem numa tabela universal de sala: vários são condições em código.

## Prova exploratória limitada

Apenas Room000 foi expandida em memória pela ferramenta própria, sem gerar imagem ou arquivo de mapa. Foram obtidos 768 bytes; SHA-256 `baa2b8e3f3e3a5815e2b10946f9de9ff743a8f076bc0b1c1c0a06d5c5b753b3d`, igual nas duas ROMs. Confirma execução do algoritmo exploratório e dados válidos para essa amostra; não é validação visual nem execução do renderizador Z80. Um extrator automático é viável para os formatos delimitados, condicionado à validação de aliases, IDs especiais, gráficos e sobreposições dinâmicas.

## Atualização da Etapa 3

A Etapa 3 resolveu os intervalos entre labels: 172 layouts distintos (165 labels numéricos e sete nomeados), 235 entradas decodificadas e 16 indefinidas. Listas de portas podem compartilhar finais. Veja [resultados e evidências](stage-3-results.md).

## Validação em execução — Etapa 4

Salas 1, 5, 31 e 127 tiveram RoomTileBuffer e fundo completo comparados com openMSX 21.0/C-BIOS_MSX2_JP. Captura ocorre antes da composição de portas/entidades, esperando o comando VDP pendente. Sete registros de DoorsList também coincidiram. Isso não valida toda a colisão ou todas as transições. Ver [Etapa 4](stage-4-results.md).
