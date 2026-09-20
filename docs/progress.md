# Progresso

## 2026-09-19 — Etapa 1 concluída

Diretório inicial vazio, sem Git, AGENTS.md prévio, projeto ou ROM. Criada estrutura documentada no README, projeto Godot com cena original e GDScript tipado, testes Python e Godot, comando único de validação, política Git, regras permanentes e plano da Etapa 2. Nenhuma engenharia reversa completa, extração, montagem ou implementação de mecânicas foi iniciada.

### Ambiente real

- macOS 15.7.7, build 24G720; uname -m: x86_64.
- sysctl: Macmini8,1, Intel Core i5-8500B CPU @ 3.00GHz. Consulta hw.optional.arm64 indisponível nesse Mac; não foi usada para inferir arquitetura.
- Git 2.50.1 (Apple Git-155), /usr/bin/git; repositório inicializado em main, identidade já existente preservada, nenhum remoto de publicação.
- Python 3.9.6, /usr/bin/python3; somente biblioteca padrão.
- Godot 4.7.2.stable.official.ed1daf0bf, /Applications/Godot.app/Contents/MacOS/Godot, universal x86_64/arm64, fora do PATH.
- Renderização gráfica: OpenGL 4.1 INTEL-23.7.4, Compatibility, Intel UHD Graphics 630.
- Homebrew 5.0.11 encontrado; curl e make disponíveis; sjasm e openmsx não encontrados no PATH. Nenhum componente instalado.

### Verificações reais

| Verificação | Resultado |
| --- | --- |
| unittest discover | 2 testes, 16 casos de caminhos, OK |
| Editor Godot headless --editor --quit | código 0, sem ERROR |
| Godot smoke_test.gd | código 0; SMOKE_OK; carregamento, _ready e Label conferidos |
| Projeto headless --quit-after 5 | código 0; BOOT_OK |
| Editor gráfico --editor --quit-after 120 | código 0, renderizador OpenGL inicializado |
| Cena gráfica --quit-after 120 | código 0, renderizador inicializado, BOOT_OK |
| Inventário Git | somente fontes próprias e documentação candidatas; referência e caches ignorados |

Logs locais em reports/python-tests.log, godot-import.log, godot-smoke.log, godot-main.log, godot-gui-editor.log e godot-gui-main.log. Inicialização gráfica foi verificada por execução e logs; não houve inspeção visual por screenshot. Nenhum teste de mecânicas é alegado.

### Problemas encontrados e resolvidos

Clone inicialmente bloqueado por DNS do sandbox; repetido com autorização. Criação de .git bloqueada pelo sandbox; inicialização autorizada resolveu. A primeira rodada Python falhou porque Git ainda não havia sido inicializado; depois passou. Primeira importação Godot reportou falhas de acesso a Library/caches/configurações e certificados no sandbox; rodada autorizada passou sem erros. Não foram redirecionadas pastas de sistema nem instaladas dependências.

### Referência e limites

Referência fixada em 30d1b940bede10fdabbaf9767ad4f0ad8dd33291, isolada em external/MetalGear e ignorada. Inspeção registrada em reference.md, sem copiar código ou assets para a implementação. Não foi encontrado arquivo LICENSE/COPYING; não se presumiu permissão de redistribuição. ROM do usuário ausente: compatibilidade ainda não verificável. Nenhum dado protegido foi extraído. Sjasm/emulador não são necessários à Etapa 1; eventual instalação futura exige autorização.

### Próximo marco

Apresentar esta entrega. Etapa 2 ainda não iniciada: seguir stage-2-plan.md para identificação somente leitura, inventário rastreável, mapeamento comprovado e uma prova limitada de extração, condicionada à disponibilidade da ROM e evidências suficientes.


### Entrada observada ao final da preparação

Após a inspeção inicial apareceram na raiz `Metal Gear (1987)(Konami).dsk` e o ZIP correspondente. Foram apenas lidos para inventário, sem modificação ou extração. Ambos são ignorados pelo Git. DSK: 737280 bytes, CRC32 B4F2C508, SHA-256 2627e6cfd9849d756d0295c0486f147f3c7ea7a8fac3ebdbe376c5c7ef5a1ee3. ZIP: 94965 bytes; seu diretório lista um DSK de mesmo nome/tamanho/CRC. Inventário local completo: reports/input-inventory.json.

Trata-se de imagem de disco, não de uma ROM de cartucho identificada. Comparar o CRC do disco aos CRCs de cartucho do README não estabelece compatibilidade. A Etapa 2 deve primeiro identificar o conteúdo e a variante em leitura, ou usar uma ROM de cartucho correspondente quando disponível. Não foi validada equivalência ao RC750 nem executado o disco.


## 2026-09-19 — Conferência da nova ROM

Arquivo encontrado em roms/ (não rons/): `Metal Gear - Konami (1987) [English Version - Nekura_Hoka v.1.995c] [RC-750] [Translated] [7660].rom`. Leitura apenas, sem alteração. Tamanho: 163840 bytes (160 KiB); CRC32: `87EC113E`; SHA-256: `89cfeee7d990a6bed050dcffa12ddff179e1632f13450247ee8860587adec6f4`. Cabeçalho inicia com 41 42, coerente com a declaração inicial de Banks0123.asm, mas isso não comprova equivalência.

CRC32 não corresponde aos valores do README da referência: inglês E85C5731 e japonês FAFE1303. O nome indica tradução Nekura_Hoka v.1.995c; a autoria/versão não foi confirmada pelo conteúdo. Tratar como variante não correspondente aos checksums de referência, sem presumir compatibilidade dos bancos, ponteiros ou textos. Pode servir à análise específica dessa variante; para correspondência direta ao disassembly, preferir entrada com checksum documentado. Não foi executada em emulador nem validada integralmente. Git check-ignore confirmou proteção. Relatório local: reports/rom-check.json. Nenhuma extração iniciada.


## 2026-09-19 — Conferência da entrada indicada como japonesa

Arquivo: `roms/Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom`. Tamanho: 131072 bytes (128 KiB). CRC32 calculado: BE84C94F; SHA-256: 254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf. Não corresponde ao CRC32 japonês FAFE1303 declarado no README da referência (nem ao inglês E85C5731). Nome do arquivo não confirma região ou revisão. Divergência não demonstra corrupção: variante/revisão ainda não identificada. Não foi realizada comparação byte a byte nem execução em emulador. Entrada lida sem alteração; git check-ignore confirmou que está ignorada. Relatório atualizado em reports/rom-check.json.

## 2026-09-19 — Etapa 2 concluída no escopo de análise inicial

Solicitação atual ampliou o plano histórico da Etapa 1 para cobrir arquitetura e principais sistemas. Foram lidos integralmente AGENTS.md, README e este progresso; arquitetura e isolamento de entradas preservados. Nenhum bloqueio da Etapa 1 impediu a investigação. Mantida a revisão externa `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`, sem alterações rastreadas. Não foi iniciada a Etapa 3.

### Resultado principal: a ROM serve como candidata de trabalho

A entrada de 128 KiB (CRC32 BE84C94F) tem compatibilidade parcial comprovada com a referência: 18.176 bytes consecutivos de salas/metatiles são idênticos em 0x1A000; conexões, seleção de tileset, formas de colisão e sete máscaras de colisão também coincidem. A tradução de 160 KiB (CRC32 87EC113E) preserva os mesmos dados. Isso substitui a incerteza inicial sobre utilidade dessas ROMs, mas não identifica a região/revisão exata nem comprova equivalência integral de código. SHA-1/SHA-256 completos em reverse_engineering/rom-compatibility.md e reports/reverse-engineering.json.

Nenhuma evidência de cabeçalho externo prefixado: AB em zero, tamanhos alinhados em 8 KiB, dados coincidentes nos offsets esperados; sondagens 16/512 sem AB. Conclusão limitada, sem normalizar/remover nada. Original de 128 KiB conserva SHA-256 254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf; de 160 KiB conserva 89cfeee7d990a6bed050dcffa12ddff179e1632f13450247ee8860587adec6f4.

### Descobertas documentadas

- Inicialização Z80/slots/RAM, bancos de 8 KiB e fluxo por HTIMI/InterruptTick com proteção de reentrância. SCREEN 5, operações VDP, controles e driver PSG localizados.
- idxRooms: 251 ponteiros, não 251 layouts únicos jogáveis. Encontrados 165 labels RoomNNN. Salas normais: 8×6 metatiles de 4×4 tiles, resultando em 32×24 tiles. Comentário de 8×8 metatiles contradiz a cópia executada pelo código.
- Apenas Room000 expandida em memória, sem gerar mapa/imagem. Saída 768 bytes e SHA-256 baa2b8e3f3e3a5815e2b10946f9de9ff743a8f076bc0b1c1c0a06d5c5b753b3d em ambas as entradas.
- Jogador usa posições 8.8, estados de controle/animação separados, movimento por eixo e duas amostras de colisão por direção. Bordas, portas e ambiente possuem caminhos específicos.
- Lista de 16 atores de 128 bytes, despacho por ID, patrulha por pontos, percepção direcional com obstáculos e alerta global. Convenções de direção precisam ser tratadas por consumidor.
- Inventário/quantidades BCD, armas/tiros/dano, itens, portas/cartões, eventos, rádio/textos e checkpoints localizados. Strides RAM não devem ser deduzidos apenas dos STRUCTs parciais.
- Modelo intermediário conceitual em JSON e imagens futuras, independente de Godot/SNES. Campos propostos explicitamente separados do formato original.

### Arquivos criados/modificados

Criados 11 documentos em docs/reverse_engineering/: README.md, architecture.md, memory-and-banks.md, maps.md, movement-and-collision.md, enemies.md, inventory-and-events.md, rom-compatibility.md, intermediate-data-model.md, validation.md e stage-3-plan.md. Criados tools/reverse_engineering/analyze.py e tests/test_reverse_engineering.py. Atualizados README.md, docs/README.md, data/schemas/README.md, tools/reverse_engineering/README.md e este progresso. Relatórios gerados apenas em reports/, ignorado.

Nenhum código Godot, ROM, código/asset de terceiros ou dependência do sistema foi alterado/instalado. Git da Etapa 1 continua com seu índice prévio; não foi criado commit nem publicado conteúdo nesta etapa.

### Testes e resultados reais

- `python3 -m unittest discover -s tests -v`: 12 testes OK (10 novos + 2 existentes); inclui dados sintéticos, limites, endianness, parser estrito, ambiguidades, RAM e posicionamento de metatiles.
- `python3 tools/reverse_engineering/analyze.py`: código 0. 225 fontes assembly, 224 includes resolvidos, 8657 declarações lexicais de símbolos; 11 probes por ROM, todas com ocorrência única.
- Repetição da análise produziu relatório idêntico: SHA-256 fa7803d4906deb599cf22db11b74de03caccbfa2b851094a1f098962dc473e91. Verificado segmento esperado sem diferenças, 22 probes únicas e hashes das duas entradas preservados; reports/analysis-verification.log.
- `python3 tools/validate.py` autorizado fora do sandbox para caches Godot: Python OK, editor headless código 0 sem ERROR, smoke SMOKE_OK e execução BOOT_OK. Nenhuma mecânica nova foi implementada ou alegada como testada.
- `git diff --check`: passou. Referência externa permanece limpa e ROMs ignoradas.
- Falhas intermediárias: parser rejeitou declaração RAM sem dois-pontos; suporte explícito adicionado e testado. Inventário encontrou texto assembly não UTF-8; leitura lexical Latin-1 resolveu sem modificar fonte.

### Pendências e fronteira da conclusão

Não foram montadas as ROMs de referência nem executado o jogo em emulador. Sjasm/openMSX não encontrados nas verificações disponíveis; nada instalado. Versão exata e motivo do CRC divergente permanecem pendentes. Não há licença explícita de redistribuição presumida. Ficam pendentes gráficos/flip completos, aliases/IDs especiais de salas, convenções de direção, IA integral, temporização real, todos os eventos e comparação integral do executável. Toda conclusão está classificada como estática, binária, hipótese ou pendente nos documentos.

A conclusão é da análise inicial solicitada, não de engenharia reversa total nem de fidelidade dinâmica. A Etapa 3 está detalhada em reverse_engineering/stage-3-plan.md: contratos → salas/metatiles → gráficos/paletas → colisões/conexões/portas → entidades/itens → validação e entrega, sem gameplay completo. Aguardar autorização antes de iniciá-la.

## 2026-09-19 — Etapa 3 autorizada e entregue

Executada após “autorizado”, seguindo reverse_engineering/stage-3-plan.md. Entrega restrita aos componentes comprovados; relatório em [reverse_engineering/stage-3-results.md](reverse_engineering/stage-3-results.md). Arquitetura preservada, sem importação Godot ou avanço para Etapa 4.

### Resultado

Extrator Python próprio, contrato JSON Schema 0.1.0, fixture sintética, prévias privadas e verificador de reprodução. Pacote principal `data/extracted/rc750-verified/`; segundo run `data/extracted/rc750-repeat/`; primeira inspeção intermediária `rc750-v1/` preservada. Todos ignorados. Publicação exige destino novo, confirma entrada inalterada, recusa saída fora da árvore privada ou sobrescrita. Nenhum componente instalado, ROM modificada, fonte protegida copiada para implementação, commit ou publicação realizados.

251 entradas: 235 salas decodificadas, 16 indefinidas; 172 layouts distintos; seis conjuntos de metatiles; oito tilesets parcialmente carregados; sete perfis de colisão; 16 patches de paleta; 304 ocorrências de portas; 396 atores; 114 caminhos; 60 ocorrências de itens. Os limites por label foram refinados para listas compartilhadas; caminhos de direções foram separados dos caminhos Y/X; três bytes excedentes em Path_031_02 permanecem sem interpretação.

Comparação integral de nove segmentos de dados, totalizando 45.982 bytes, em ambas as ROMs. Principal BE84C94F/128 KiB; tradução 87EC113E/160 KiB passou em dry-run sem criar destino. SHA-256 preservados: principal `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf`; tradução `89cfeee7d990a6bed050dcffa12ddff179e1632f13450247ee8860587adec6f4`. Isso amplia a compatibilidade comprovada, sem resolver a identidade integral/revisão regional.

### Verificações reais

- `python3 -m unittest discover -s tests -v`: **29 testes OK**, 17 novos de extração e 12 anteriores; sem ROM e sem referência externa.
- `python3 tools/validate.py`: **PASS** em Python, importação headless Godot, smoke `SMOKE_OK` e projeto `BOOT_OK`, código 0. Godot 4.7.2; caches autorizados; nenhum gameplay novo alegado.
- `extract.py` executado em dois destinos novos: **33 arquivos gerados idênticos**, inclusive 30 PNGs. `verify.py --package data/extracted/rc750-verified --repeat-package data/extracted/rc750-repeat` recompôs conteúdo, validou schema/derivados e rejeitou alteração/truncagem em cópias somente em memória.
- SHA-256 package.json: `438c3c25cc8aee6e70828594e27959a7a784135291befeac1cca42d41d31d738`. Relatório reproduzível em `reports/extraction-verification.json`.
- Folha de contato de sete salas, atlas com flip e overlay inspecionados. Conferência visual com quatro PNGs da referência, sem declarar equivalência pixel a pixel. Magenta representa tiles não reconstruídos, não conteúdo original.
- `git check-ignore`: 70 arquivos privados conferidos (dois pacotes, metadados Finder e duas ROMs); nenhum conteúdo protegido encontrado no índice. `git diff --check`: sem erro. Referência sem alterações rastreadas; há `.DS_Store` não rastreado, preservado.
- Falhas intermediárias reais: listas compartilhadas rejeitadas por limite por label; caminhos com semânticas diferentes; bytes excedentes em caminho; erro de sintaxe na primeira geração do schema. Corrigidos/registrados antes da entrega. Verificação final também encontrou `.DS_Store` criado pelo Finder: verificador passou a ignorar exclusivamente esse metadado e listar a exclusão no relatório, mantendo verificação de todos os 33 arquivos gerados. Não apagou arquivos do usuário.

### Arquivos e limites

Criados `tools/extractors/{codecs,extract,schema,verify}.py`, contrato `data/schemas/extraction.schema.json`, fixture `data/fixtures/synthetic-layout.json`, `tests/test_extractors.py` e `docs/reverse_engineering/stage-3-results.md`. Aproveitado/refinado `tools/extractors/reference.py` já presente; usado o parser de análise com suporte a constantes. Atualizados READMEs, plano da Etapa 3 e adendos de mapas/inimigos/compatibilidade. Nenhum arquivo Godot alterado; índice preexistente do Git preservado.

Permanecem pendentes: inicialização/herança dos tiles ausentes, composição dinâmica e paletas especiais, associação precisa de caminhos por ator, disponibilidade de itens/eventos, sprites/texto/áudio completos e comparação em execução. Sjasm/openMSX não instalados; sem montagem integral ou emulação. Conteúdo protegido continua privado, sem licença de redistribuição presumida.

Etapa 3 concluída como extração dos componentes comprovados, com limitações explícitas; não como reconstrução de um frame completo ou do jogo. Próximo escopo proposto no relatório: fechar cargas/composição → comparar RAM/VRAM em execução → propor importador de uma sala → especificar movimento/colisão. **Etapa 4 não iniciada; aguardar nova autorização.**
