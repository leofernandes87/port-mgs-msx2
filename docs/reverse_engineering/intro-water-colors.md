# Cores do mergulho na abertura — 2026-10-01

Escopo: `DEEP_WATER`, quadros SprWaterShadow e SprWaterShadow2. Referência inspecionada antes da alteração: `external/MetalGear`, revisão `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`.

## Evidência primária

| Fonte | Evidência |
| --- | --- |
| `logic/introscene.asm:51–58,82–89,139–146` | Alternância entre animações água (2) e submerso (4). |
| `Banks0123.asm:9827–9843` | Seleção dos IDs 37/38 para mergulho. |
| `data/playersprite.asm:44–45,66–85,112–116` | Ambos usam WaterShadowAttr: dois sprites visíveis na mesma posição, padrões 0/4, cores 0x0E/0x0F; bit CC desligado em ambos. |
| `Banks0123.asm:5405–5457,5499–5520` | Atributos mantêm ordem dos sprites; byte de cor é repetido nas 16 linhas de cada sprite. |
| `Banks0123.asm:11914–11916,2873–2877` | Inicialização da sala aplica PalMenuWeapon e depois patches de sala/sprites. |
| `data/palettes.asm:4–10` | PalMenuWeapon define índice 14 = RGB3 (7,7,7), branco; 15 = (0,0,0), preto. |
| `data/palettes.asm:70–168,214–313` | Patches normais de sala/sprites não substituem os índices 14/15. |
| `gfx/sprites.asm:365–372` | Dois padrões comprimidos; cada um expande para 64 bytes (dois sprites 16×16). |

Os números 14/15 são índices programáveis, não cores RGB fixas. Usar a paleta padrão do hardware para interpretar a cena de jogo era incorreto. A entrada anterior de progress.md que chamava `0x0F` de branco nesta cena fica explicitamente corrigida por esta análise.

O [manual primário Yamaha V9938](https://map.grauw.nl/resources/video/yamaha_v9938.pdf), seção de sprites e prioridade (2.7), descreve a prioridade por número e sua alteração pelo bit CC. Com CC=0, o primeiro sprite prevalece na sobreposição; não se cria uma terceira cor nem se aplica OR. Os pixels ativos são opacos.

## Conferência binária local

ROM principal SHA-256 `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf`. Busca exata dos blocos de dados, uma ocorrência por bloco:

| Bloco | Offset ROM | Banco físico de 8 KiB | Tamanho |
| --- | --- | --- | --- |
| SprWaterShadow | 0x154DD | 0x0A | 40 bytes comprimidos |
| SprWaterShadow2 | 0x15505 | 0x0A | 41 bytes comprimidos |
| WaterShadowAttr | 0x140E6 | 0x0A | 17 bytes |

Essas comparações validam os blocos citados, não todo o executável. Ambas as ROMs conservaram os hashes já documentados.

## Causa e correção

O extrator usava tons azuis com alpha parcial e um índice 16 inventado para sobreposição. O carregador Godot ainda convertia todos os pixels visíveis em branco, preservando o alpha incorreto. Assim, detalhes pretos desapareciam e a cor do fundo contaminava a figura.

`extract_snake_sprites.py` agora compõe branco/preto opacos, com prioridade do primeiro sprite; `player.gd` desenha as cores extraídas sem recolorir. Atualizado teste sintético para checar RGBA explícito, sobreposição, ambas as metades horizontais e área transparente. Nenhum byte do jogo foi incorporado aos testes.

Asset local regenerado: `godot/assets/protected/sprites/snake_msx.png`, ignorado. Backup anterior e versão nova em `data/extracted/intro-water-colors-20261001/`, ignorados. Comparação RGBA: 206 pixels alterados, todos nas células de mergulho (x=16–47, y=320–335); todos os demais pixels permaneceram iguais.

## Validação e limites

- Seis testes do extrator passaram; suíte completa: 90 testes Python, importação Godot e todas as etapas Godot do validador passaram (código 0).
- Integração gráfica real em Godot 4.7.2/OpenGL Compatibility/Intel UHD 630: renderizados ambos os quadros por PlayerController e comparados 512 pixels com o PNG extraído, sem diferenças. Quadro 0: 108 brancos/3 pretos; quadro 1: 92 brancos/3 pretos; demais pixels transparentes.
- Script diagnóstico local: `reports/check-water-render.gd`; log `reports/intro-water-render.log`; imagens `reports/water-render-0.png` e `water-render-1.png`. Comando: `/Applications/Godot.app/Contents/MacOS/Godot --path godot --script ../reports/check-water-render.gd`. Exige renderizador gráfico e o asset privado. A primeira imagem foi também inspecionada visualmente.
- Log integrado: `reports/intro-water-colors-validation.log`. Primeira tentativa no sandbox falhou por gravação de editor_settings em Library; execução gráfica no sandbox encerrou com 134 sem diagnóstico. Repetições autorizadas passaram.

Não foi capturado um novo frame da abertura no openMSX; esta validação combina dados binários/assembly, regras documentadas do VDP e renderização Godot. Não representa certificação de toda a cutscene. Paleta aproximada dos sprites de superfície/andar, fallback procedural sem assets e temporização da intro permanecem fora desta correção. Próximo passo se necessário: comparação sincronizada da cena completa no emulador, incluindo nado na superfície.
