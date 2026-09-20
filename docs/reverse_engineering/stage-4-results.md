# Etapa 4 — Verificação em execução e visualizador de salas

Autorizada em 2026-09-20. Base: commit fe4c755 e entrega da Etapa 3. Marco implementado: observar a execução de salas, comparar dados/fundo e carregar snapshots explícitos no Godot. A composição dinâmica completa e o movimento fiel permanecem pendentes; não são apresentados como concluídos.

## Ambiente e método

Arquitetura x86_64, Python 3.9.6, Git 2.50.1, Godot 4.7.2 reconferidos. Encontrado **openMSX 21.0** em /Applications/openMSX.app, embora fora do PATH. Usada máquina C-BIOS_MSX2_JP fornecida pelo aplicativo, sem instalar componentes ou obter BIOS de terceiros. Configuração save_settings_on_exit=false; renderização desativada na captura automatizada. ROM principal preservada com SHA-256 `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf`.

`tools/emulation/capture.py`/`capture.tcl` verificam SHA e âncoras de instrução únicas, acompanham a sequência natural de demo e leem RAM/VRAM. Sem escrever na memória do MSX ou mudar o contador de programa. Captura inicial na volta de RenderRoom; segunda captura, quando necessária, no primeiro retorno de WaitVdpCmd.

| Evidência | Fonte / endereço | Grau |
|---|---|---|
| Limpeza de VRAM páginas 0 e 1 | logic/inithardware.asm:27–31, ClearPage; Banks0123.asm:3776 | Estático |
| RenderRoom | Banks0123.asm:3391; ROM offset 0x0CF0, CPU 0x4CF0, banco 0 | Âncora única + breakpoint atingido |
| Última cópia VDP ainda pode estar pendente ao retornar | WaitVdpCmd em Banks0123.asm:3982; início CPU 0x4ED2, RET 0x4EDB | Execução: CE=1 em três capturas |
| RoomTileBuffer | Variables.asm:402, CPU/RAM 0xE000, primeiros 768 bytes | Comparação em execução nas quatro salas |
| Tileset e coordenadas VRAM | Banks0123.asm:4885 GetTileXY; página 1, tiles em grade de 32 colunas | Comparação dos pixels carregados |
| Composição de registros de portas | Banks0123.asm:1270 AddDoorsData; Variables.asm:202/205, RAM 0xC3D0/0xC450 | Sete registros comparados em execução |
| Ordem de composição | Banks0123.asm:11908 em diante: fundo → portas → itens → paletas/HUD → atores | Estático; capturas limitadas ao fundo |

Fontes relativas à referência externa no commit `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`. Nenhum trecho de código externo incorporado ao Godot. Os decoders/comparadores são próprios.

## Resultados medidos

| Sala | Tileset | Bytes do mapa | Tiles carregados coincidentes | Pixels do fundo coincidentes | Registros de portas |
|---:|---:|---:|---:|---:|---:|
| 1 | 0 | 768/768 | 235/235 | 49152/49152 | 0 |
| 5 | 0 | 768/768 | 235/235 | 49152/49152 | 5 |
| 31 | 0 | 768/768 | 235/235 | 49152/49152 | 1 |
| 127 | 4 | 768/768 | 158/158 | 49152/49152 | 1 |

A primeira captura de cada sala 1/5/31 diferia em 42 pixels porque o VDP ainda copiava o último tile. Esperar o retorno de WaitVdpCmd resolveu as três diferenças. Sala 127 já estava com CE=0. O comparador exige igualdade completa da imagem estabilizada; não mascara diferenças nem tolera pixels divergentes.

Slots referenciados antes nulos: tile 1 nas salas 5/31 e tile 2 na sala 127 continham somente índice de cor 0. Isso é coerente com a limpeza inicial, mas **não** prova que todo slot não carregado seja sempre zero. Mudanças de conjunto podem herdar gráficos anteriores. O extrator 0.1.0 e os pacotes da Etapa 3 foram preservados; snapshots novos preenchem esses pixels exclusivamente com a observação específica da captura.

As portas são verificadas como registros RAM: ID, estado de DoorOpenArray (ou aberto para tipo 6), regra, tipo, contador inicial, coordenadas, áreas de abertura/entrada e destino. Somatórios de offsets são módulo 256, inclusive bytes que representam deslocamentos negativos. Não significa que animações de abertura, cartão, colisão atual ou paredes destruídas tenham sido simuladas. SetDefaultDoorLock ainda possui a discrepância comentada de 160 iterações/156 dados, fora do escopo destes sete registros.

## Artefatos e visualizador

- `data/extracted/emulator-stage4-settled/`: capturas brutas privadas, estado do VDP, script, manifesto e hashes.
- `data/extracted/stage4-validated/`: quatro JSONs e quatro PNGs, comparison.json e checksums.json.
- `data/schemas/room-snapshot.schema.json`: contrato diagnóstico 1.0.0 independente de engine. Pixels indexados 256×192, 18 cores RGB nominais (16 + 2 diagnósticas), máscara estática 32×24, ID e procedência.
- `godot/scenes/room_inspector.tscn`: visualizador separado com abertura explícita de snapshot, escala inteira, filtro nearest e overlay de colisão.
- RoomSnapshot valida os campos consumidos, tamanho de arquivo, números inteiros, limites e hash; falha limpa o estado anterior. Não é substituto do validador completo JSON Schema em Python. RoomCanvas só desenha dados; não é colisão física do jogador.

Não há cópia automática de conteúdo privado para Godot, mudança na cena inicial, geração de recursos do jogo para versionamento ou implementação de movimento/IA/combate. O usuário pode executar a cena com F6 e escolher um JSON local. Procedimentos e comandos completos em [tools/emulation/README.md](../../tools/emulation/README.md).

## Testes e inspeção

Testes sintéticos novos cobrem endereços VRAM entre linhas/bancos de tiles, nibbles, orientação da imagem, erro por divergência de RAM/gráficos/fundo, VDP pendente, soma de geometria módulo 256 e porta tipo 6. O teste Godot cobre contrato, cores nos cantos, rejeição de frações/booleanos, limpeza após erro, criação do visualizador e toggle.

Integração real da sala 5: Image produzida pelo Godot coincide com os **49.152 pixels RGB** do PNG Python. Comparação de índices contra VRAM e comparação RGB nominal entre ferramentas são afirmações distintas. Paleta capturada é preservada, mas a prévia usa paleta nominal da extração, não a paleta dinâmica do frame. Screenshots reais com e sem overlay em reports/stage4-inspector-final-plain.png e reports/stage4-inspector-final-overlay.png, ignorados.

Falhas intermediárias: captura prematura antes da inicialização retornou tileset 255 e foi rejeitada; tentativa inicial de iniciar por teclado substituída pela sequência natural de demo; captura antes de o VDP terminar mostrou 42 diferenças, investigadas e resolvidas por sincronização. Teste inválido de JSON usava Array[int], que convertia 1.5 em 1 antes da validação; fixture passou a Array sem restrição, e os casos negativos foram efetivamente exercitados. Sobreposição chamada programaticamente foi sincronizada ao estado visual do botão.

## Fronteira do marco e próxima etapa

O fundo das quatro salas e sete registros de porta têm evidência em execução **no openMSX/C-BIOS e nesta ROM**. Não foram comprovados todos os tilesets, todas as salas, RGB final com paletas dinâmicas, frame completo, execução em MSX físico, temporização/IA ou identidade integral do executável.

Próximo marco proposto, dependente de autorização:

1. Ampliar capturas para início de jogo e outros tilesets; distinguir VRAM inicial de herança por transição.
2. Capturar depois de DrawDoors/itens e exportar deltas separados do fundo. Validar estados aberto/fechado, tipo 6 e uma parede destrutível antes de implementar composição.
3. Medir estado do jogador por tick com entradas determinísticas: coordenadas 8.8, velocidade, duas amostras de colisão, bordas e transições. O documento movement-and-collision.md segue sendo especificação estática para esses comportamentos; este marco não os validou.
4. Implementar um controlador mínimo em GDScript somente após essa comparação, usando os contratos neutros e mantendo mecânicas modernas separadas.

Etapa 5 não iniciada. Nenhum commit automático realizado nesta etapa.
