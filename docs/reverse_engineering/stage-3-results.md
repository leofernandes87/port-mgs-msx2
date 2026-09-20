# Etapa 3 — Extração automatizada

Concluída em 2026-09-19 no escopo dos componentes comprovados. A autorização foi recebida após a entrega da Etapa 2. Não foi iniciado importador Godot, gameplay ou Etapa 4. A referência continua fixada em `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`.

## Entrega e cobertura

Ferramentas próprias em `tools/extractors/`, contrato `data/schemas/extraction.schema.json` versão 0.1.0 e fixture própria em `data/fixtures/synthetic-layout.json`. Nenhuma dependência Python adicional. Dados reais privados em `data/extracted/rc750-verified/`; repetição em `data/extracted/rc750-repeat/`. `rc750-v1/` é a primeira inspeção intermediária, anterior à ampliação dos hashes de fontes; use o pacote verified para a entrega.

| Estrutura | Resultado |
|---|---:|
| Índice de salas | 251 entradas: 235 decodificadas, 16 indefinidas |
| Layouts distintos referenciados | 172, com aliases preservados |
| Conjuntos de metatiles | 6: 216, 123, 106, 18, 96 e 21 definições |
| Tilesets | 8, slots não carregados explicitamente nulos |
| Perfis de colisão estática | 7 × 256 indicadores |
| Patches de paleta de sala | 16, mais base e patch de menu |
| Portas | 304 ocorrências, 154 IDs distintos |
| Atores | 396 ocorrências, mantendo ordem de cada lista |
| Caminhos | 114: 104 de pontos Y/X e 10 de direções cruas |
| Associações de caminhos | 179 entradas de sala |
| Itens | 60 ocorrências nas salas elegíveis |
| Saídas | 33 arquivos: pacote, checksums, 30 PNGs e legenda |

Contagens de portas/atores/itens representam ocorrências nas listas de salas, não objetos únicos existentes simultaneamente nem confirmação de alcance em gameplay.

## Entradas e comparação binária

Principal: ROM de 131072 bytes, CRC32 **BE84C94F**, SHA-1 `7d685547c2a4b92fa62e00854e4a9689d495f93d`, SHA-256 `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf`.

A tradução de 163840 bytes, CRC32 **87EC113E**, SHA-256 `89cfeee7d990a6bed050dcffa12ddff179e1632f13450247ee8860587adec6f4`, passou pela mesma extração em memória/dry-run. Recebe `region_verified_candidate`, não identidade com a ROM de referência. Ambas mantiveram seus hashes. CRC divergente não impediu o trabalho; versão regional/revisão integral continua não identificada.

O localizador recompõe somente declarações de dados DB/DW, constantes e referências a labels. Não monta instruções Z80. Cada segmento inteiro é comparado byte a byte antes da extração; uma assinatura inicial serve apenas para localização, nunca como prova suficiente. Fonte modificada ou revisão diferente é rejeitada. Os nove segmentos totalizam **45.982 bytes** sem sobreposição:

| Fonte relativa à referência | Offset físico | Bytes |
|---|---:|---:|
| data/rooms.asm + metatiles.asm + doors.asm + gfx/powerswitch.asm | 0x1A000 | 21279 |
| Includes de dados/gráficos de Banks789.asm anteriores a logic/elevatorroom.asm | 0x0E000 | 19817 |
| data/palettes.asm | 0x0AB0B | 669 |
| data/roomsconnections.asm | 0x0AE0E | 624 |
| data/actorsinrooms.asm | 0x0B07E | 1694 |
| data/paths.asm | 0x0BEA1 | 1444 |
| data/itemsinrooms.asm | 0x0D9FC | 415 |
| Banks0123.asm, ColorsTileset | 0x00B13 | 8 |
| Banks0123.asm, DefaultPalette | 0x00EA4 | 32 |

Manifesto inclui hashes de entrada, revisão, hashes das fontes lidas e de cada segmento. `Evidence` registra fonte, linha da declaração, símbolo, offset físico, endereço CPU do grupo, banco físico, extensão e `binary_verified`. A linha aponta à declaração de referência, não necessariamente ao DB exato de um registro interior; o offset delimita a leitura. Validação binária de dados **não** prova equivalência das instruções executáveis do usuário.

## Descobertas que alteram ou refinam a Etapa 2

- **B:** os 165 labels numéricos RoomNNN não eram todos os layouts. Os intervalos maiores incluem sete layouts nomeados (`RoomLorry`, `RoomCell`, `RoomCell2`, `RoomCellW`, `RoomCellS`, `RoomTableE`, `RoomTableS`). O extrator segue `idxRooms` e conserva compartilhamento por offset, sem interpretar o intervalo inteiro como uma sala.
- **B/E:** apenas os IDs 0–250 são consultados. Nibble baixo final de `MetaTileSetIDs` corresponderia ao ID 251, fora desse índice; não cria uma nova sala. Salas indefinidas: 155, 222, 223, 227–239. Uma sala decodificada não é automaticamente alcançável.
- **B/E:** listas de portas compartilham finais e terminador entre labels em `data/doors.asm`. Um label intermediário não é obrigatoriamente fim de lista; leitura respeita registros de cinco bytes, FF na fronteira, segmento verificado e limite de oito portas.
- **B/E:** `data/paths.asm`, `Path_039_01` e os nove blocos seguintes armazenam direções, não pares Y/X. `Banks0123.asm:7188`, `GetSentinelLookDirs`, usa contador e bytes de direção, selecionando caminho por contagem de atores do mesmo tipo. Mantidos valores crus 0–3; não convertidos à convenção de movimento 1–4.
- **B/P:** `Path_031_02` (`data/paths.asm:235`) declara dois pontos e deixa três bytes antes do label seguinte. Somente os dois pontos declarados são consumidos; três bytes restantes aparecem como diagnóstico, sem interpretação de conteúdo não utilizado.
- **E:** `SetupEnemyRoom` (`Banks0123.asm:6145`) usa contador AND 0Fh e triplas ID,Y,X. `GetPathPoints:6924` e `GetSentinelLookDirs` usam índices específicos da inicialização, não o ordinal global indiscriminadamente. O pacote mantém candidatos ordenados e declara a associação por ator pendente.
- **E:** `logic/addroomitems.asm:15–20` exclui salas fora de 122–217, mesmo que a tabela tenha um byte adicional. Disponibilidade ainda depende de flags de coleta e progressão.

B = comparação binária; E = inspeção estática; P = pendente. Ver legenda completa no README desta pasta.

## Gráficos e formatos

A saída principal usa 3 bpp: 24 bytes por tile 8×8, três planos intercalados por linha, primeiro plano de peso 1; bit 7 é o pixel à esquerda. `Banks0123.asm:5204`, `Decode3bpp`, confirma a leitura E/D/C e composição. `ColorsTileset:2998` fornece o mapeamento para índices SCREEN 5; índices não são RGB.

`LoadRoomTiles:2540` e `LoadTileset:2642` processam no máximo três descritores. Normal: flags, quantidade, destino, ponteiro LE; bit 7 encerra a carga gráfica. `LoadTilesFlip:2663` reutiliza fonte/quantidade anteriores e lê destino no byte seguinte. Nos descritores desta revisão, flip está no último bloco; não se generaliza isso para ROMs arbitrárias. Flip inverte pixels em cada linha do tile, mantendo a ordem dos tiles (`Load3bppTileFlip`). Cargas comuns de caixas, suas cópias invertidas e painel/interruptor são aplicadas na ordem da rotina; o conjunto 6 pula caixas. A evidência de cada carga fica em `tilesets[].loads`.

Há primitivas próprias testadas para 1/2 bpp e `UnpackGfx`, mas não uma exportação completa dessas famílias. `Decode1bppTile:4602` usa cor 0 ou cor fornecida; `Decode2bppRow:5076` usa dois planos por linha e tabela de quatro cores; `UnpackGfx:3684` usa endereço LE inicial, 00 fim, 80 novo endereço, tokens 01–7F de repetição e 81–FF de literais. Limites são explícitos; não se aplica esse stream aos tiles planares. Portas em bitmap SCREEN 5, sprites, retratos, texto e áudio ainda não têm exportação completa.

A paleta nominal aplica DefaultPalette, PalMenuWeapon e patch da sala. Conversão RGB3→RGB8 linear, sem calibração analógica. Não simula escuridão, óculos ou trocas dinâmicas. Cargas não reconstruídas são `null`, nunca completadas com arte inventada. Magenta nas prévias é diagnóstico de slot ausente, não cor do jogo.

## Colisões, portas e eventos ainda necessários

`LoadColliTiles:2590` expande 32 bytes MSB-first; a grade derivada contém 768 indicadores de bloqueio estático. Overlay vermelho mostra esses indicadores. Não inclui portas abertas/fechadas, obstáculos móveis, alterações por evento ou todas as consultas do protagonista.

Conexões mantêm ordem original da tabela, FF→null e índices por três faixas. Há dois diagnósticos de destino indefinido: sala 226→227 e 227→228; nenhuma reciprocidade foi fabricada.

`AddDoorsData` em `Banks0123.asm:1283` liga lista, `IdDoorsLogic` e `DoorOpenEnterDat`. Mantidos byte bruto da regra, regra baixa AND 1Fh e oito bytes de geometria, sem converter offsets crus em retângulos definitivos. Estado persistente está em DoorOpenArray; byte de regra não é estado atual. `SetDefaultDoorLock:1005` deriva estado inicial dos bits superiores, e render type 6 força abertura na inicialização. Nenhum desses estados é simulado pelo pacote.

Amostras rastreáveis no JSON: sala 3, porta 2, tipo 5, regra 1/elevador; sala 111, porta 95, regra 9/cartão 8; sala 58, porta 140, regra 16/parede do subsolo. Registros respectivos em `DoorsRoom003`, `DoorsRoom111`, `DoorsRoom058`; tabela de regras comentada em `data/doors.asm:887–902` e despacho no código. São regras identificadas, não gameplay implementado.

Catálogo pendente: aplicação de estados persistentes às portas; patches de paredes destruídas; flags de itens e JeniRocketF; seleção exata de caminho por tipo/contador; spawns/despawns e eventos; inicialização e herança de VRAM nos slots não carregados; paletas dinâmicas. O formato guarda referências/valores sem inventar estados normalizados.

## Validação real

- 29 testes unittest sem ROM ou referência: limites de leitura/ponteiro, todas as posições de bits de colisão, planos e orientação de pixels, flip, paleta, CRC/decompressão de PNG, metatiles, FF dentro de registro, truncamento, streams, schema e referências derivadas, publicação sem sobrescrita e aliases por symlink/hardlink.
- Dois runs independentes geraram **33 arquivos idênticos**, incluindo imagens. Metadados `.DS_Store` posteriores do Finder são listados separadamente e não integram os 33 arquivos gerados. SHA-256 de `package.json`: `438c3c25cc8aee6e70828594e27959a7a784135291befeac1cca42d41d31d738`.
- `verify.py` recompôs o pacote, validou contrato e dados derivados, conferiu todos os arquivos e rejeitou uma alteração e uma truncagem feitas somente em memória. Entradas preservadas.
- Dry-run da tradução passou e não criou `data/extracted/translation-probe/`.
- Inspeção visual da folha de contato (salas 0, 54, 40, 204, 122, 50, 118), atlas 0 e overlay 0. Comparação visual com os PNGs externos MGEAR1_0000/0054/0040/0204: organização e padrões reconhecíveis correspondem, com diferenças de escala, conversão de cor e slots marcados. Não foi alegada comparação pixel a pixel nem fidelidade de um frame completo.
- Comandos reproduzíveis no [guia do extrator](../../tools/extractors/README.md). Resultado integrado de Python/Godot e revisão Git registrados em [progress.md](../progress.md).

Falhas intermediárias corrigidas: limite por label rejeitava listas de portas compartilhadas; caminhos de direções eram inicialmente tratados como pares; Path_031_02 revelou bytes excedentes; erro de parênteses na geração inicial do schema corrigido antes da publicação. Asserções e limites permanecem estritos nos componentes compreendidos.

Não houve execução em emulador, montagem integral da ROM, instalação de componentes ou autorização presumida de redistribuição. A prova cobre formatos estáticos e regiões binárias, não a lógica dinâmica.

## Próximo escopo proposto, ainda não iniciado

1. Priorizar inicialização/herança de tiles ausentes e composição dinâmica de portas/parede; ampliar fontes verificadas e testes antes de fechar a imagem de uma sala.
2. Preparar comparação em emulador, se disponível/autorizado: captura após RenderRoom de RAM e VRAM, paleta e estado das portas; comparar com o pacote por sala e entrada conhecida.
3. Só então propor importador explícito no Godot, consumindo JSON validado e conteúdo privado separado. Primeiro uma sala estática e sobreposição diagnóstica, sem IA/combate.
4. Especificar coordenadas, colisão por pontos e transições do protagonista com estados capturados antes de implementar movimento fiel.

Apresentar esses critérios antes de uma nova etapa principal. A Etapa 4 depende de nova autorização.
