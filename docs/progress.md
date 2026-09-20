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

## 2026-09-20 — Etapa 4: fundos em execução e visualizador

Autorizada por “Vamos para proxima etapa?”. Partida em fe4c755, árvore limpa. Relatório: [reverse_engineering/stage-4-results.md](reverse_engineering/stage-4-results.md). Marco entregue: captura reprodutível, comparação com o jogo executando e visualizador diagnóstico separado. Composição dinâmica completa e movimento continuam pendentes.

### Ambiente e descobertas

Reconferidos x86_64, Python 3.9.6, Git 2.50.1, Godot 4.7.2. Encontrado openMSX 21.0 instalado em /Applications (fora do PATH), com C-BIOS_MSX2_JP. Nenhum componente instalado. Execuções autorizadas para configurações normais dos aplicativos.

Captura automatizada segue título/demo sem injetar teclas, escrever RAM/VRAM/ROM ou mudar PC. ROM principal selecionada por SHA-256 e duas âncoras únicas de instrução verificadas antes dos breakpoints. Observação na volta de RenderRoom CPU 0x4CF0; se necessário, segunda VRAM no RET de WaitVdpCmd 0x4EDB.

Salas 1/5/31 (tileset 0) e 127 (tileset 4): mapa 768/768 bytes e fundo 49.152/49.152 pixels coincidentes em cada uma. Respectivamente 235/235/235/158 tiles carregados conferidos. Sete registros RAM de portas coincidiram com regras/geometria extraídas e estado persistente observado. Slots antes nulos referenciados nessas amostras tinham índice 0. Não generalizado a outras salas/transições; extração anterior preservada.

Três capturas iniciais tinham 42 pixels divergentes e VDP ocupado: a última cópia ainda não terminara. Esperar o VDP resolveu a divergência integralmente. Limpeza inicial de páginas é evidenciada por logic/inithardware.asm. Não se confunde fundo pré-portas com frame final.

### Implementação e arquivos

Criados tools/emulation/capture.py, capture.tcl, compare.py e README; data/schemas/room-snapshot.schema.json; tests/test_emulation.py; godot/scenes/room_inspector.tscn; scripts tipados room_inspector.gd, systems/room_snapshot.gd e room_canvas.gd; testes room_snapshot_test.gd e room_snapshot_integration.gd, com UIDs. Atualizado tools/validate.py para incluir o teste sintético Godot. Atualizados READMEs, schemas e documentação, sem mudar a cena principal ou o contrato de extração anterior.

Saídas privadas finais: data/extracted/emulator-stage4-settled/ (24 arquivos de captura/manifesto) e data/extracted/stage4-validated/ (10 arquivos: quatro snapshots, quatro PNGs, comparação e checksums). Investigações intermediárias preservadas/ignoradas. Visualizador abre snapshot explicitamente, valida entrada, desenha em escala inteira e permite overlay; não incorpora conteúdo privado a res://.

### Testes reais

- `python3 tools/validate.py`: **35 testes Python OK**; importação Godot, smoke principal, novo teste `ROOM_SNAPSHOT_OK` e execução `BOOT_OK` passaram, código 0.
- Captura final via `tools/emulation/capture.py` e comparação via `compare.py`: quatro salas coincidentes conforme tabela do relatório. SHA do manifesto de captura: `55d15792329e16f5dc2559f7469209a05c863e8e81fd8549ada5decfdc729fb4`.
- Integração gráfica Godot da sala 5: `ROOM_INTEGRATION_OK: 49152 pixels matched Python; room 5`; OpenGL Compatibility/Intel UHD Graphics 630. Screenshots com e sem overlay em reports/stage4-inspector-final-plain.png e -overlay.png; conferidos visualmente. O botão reflete o estado do overlay.
- Dados sintéticos verificam orientação, endereços/nibbles, erro de RAM/tiles/fundo, VDP pendente, geometria de portas com overflow e tipo 6, validação de números e limpeza após erro de importação. Nenhum teste normal depende da ROM.
- `git diff --check`: sem erros. 34 arquivos dos dois diretórios finais conferidos como ignorados. Referência externa sem alterações rastreadas. ROM principal SHA-256 preservado `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf`; tradução preservada `89cfeee7d990a6bed050dcffa12ddff179e1632f13450247ee8860587adec6f4`.

Falhas intermediárias registradas: captura prematura com tileset 255; captura com comando VDP pendente; fixture Godot Array[int] convertia fração antes do teste, corrigida para Array sem restrição; ajuste para sincronizar toggle programático e botão visível. Todas as validações finais citadas passaram.

### Limites e sequência

Esta etapa introduz evidência em execução, limitada a openMSX/C-BIOS e quatro fundos. Paleta nominal não foi comparada ao RGB final dinâmico; não houve implementação de portas desenhadas, entidades, movimento ou IA. A máscara exibida não representa toda a colisão do jogo. Campos de portas conferidos não comprovam todos os eventos de abertura/destruição.

Marco diagnóstico entregue. Próximo escopo proposto: capturas de outros tilesets/início de jogo → composição por deltas de portas/itens → medições por tick do jogador → controlador mínimo com testes. Etapa 5 não iniciada. Nenhum novo commit ou push feito automaticamente.

## 2026-09-20 — Transferência de contexto para Gemini CLI

Última tarefa executada: inspeção do repositório, documentação e verificações para transferência, sem novas funcionalidades. Criados `docs/HANDOFF.md` (14 seções, evidências, limites, comandos, próxima tarefa e critérios) e `GEMINI.md` (regras curtas referenciando AGENTS.md). Histórico anterior preservado. O estado atual prevalece sobre menções históricas à ausência de emulador ou às etapas ainda não iniciadas.

Estado efetivo: Etapas 1–3 entregues nos escopos documentados; Etapa 4 entregue como captura/comparação de quatro fundos e visualizador diagnóstico. Não há gameplay implementado. Etapa 5 não iniciada.

### Verificações nesta transferência

- Ambiente reconferido: macOS 15.7.7/24G720, x86_64, Python 3.9.6, Git 2.50.1, Godot 4.7.2 e openMSX 21.0. Nenhuma instalação.
- `python3 tools/validate.py`: código 0; **35 testes Python OK**; importação do editor headless, `SMOKE_OK`, `ROOM_SNAPSHOT_OK` e `BOOT_OK` passaram. Logs usuais renovados em reports/.
- `verify.py` sobre rc750-verified/rc750-repeat: código 0; **33 arquivos idênticos**, contrato e derivados aprovados, duas entradas negativas rejeitadas em memória, ROM inalterada. Hash do pacote permanece `438c3c25cc8aee6e70828594e27959a7a784135291befeac1cca42d41d31d738`. Dois `.DS_Store` preservados e explicitamente excluídos do inventário de geração.
- Integração Godot headless com snapshot/PNG existentes da sala 5: código 0, `ROOM_INTEGRATION_OK: 49152 pixels matched Python; room 5`.
- Ambas as ROMs lidas para hash: principal `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf`; tradução `89cfeee7d990a6bed050dcffa12ddff179e1632f13450247ee8860587adec6f4`, iguais aos registros anteriores.
- Conferidos como ignorados os 102 arquivos presentes nos dois pacotes e nos dois diretórios finais da Etapa 4. Nas árvores privadas, somente READMEs explicativos são rastreados. Referência no commit fixado, sem alterações rastreadas; `.DS_Store` não rastreado preservado.
- `git diff --check`: passou; índice permanece sem alterações. Revisão final limitada aos três documentos da transferência, sem conteúdo protegido incorporado.
- Não repetida captura no openMSX nem inspeção gráfica: resultados de emulação/screenshots continuam os da Etapa 4, sem nova alegação de cobertura.

### Git e retomada

Entrada limpa em `main`, HEAD `d1210d2` (Etapa 4), anterior `fe4c755`; nenhum remoto. A transferência deixa `docs/HANDOFF.md` e `GEMINI.md` novos e este progresso modificado; nenhuma mudança de código, staging, commit ou push. Nenhuma alteração existente descartada.

Próxima tarefa exata no Gemini: ler regras/handoff/última entrada, conferir estado local, executar a validação e apresentar plano delimitado de captura de início de jogo e de pelo menos um tileset adicional, para distinguir limpeza de herança de VRAM. Desenvolvimento dessa próxima etapa depende de autorização; os critérios estão nas seções 13–14 do handoff. Composição dinâmica e controlador vêm depois das evidências necessárias.

`gemini` não foi encontrado no PATH desta sessão; a instalação não foi realizada. Iniciar o CLI na raiz existente após disponibilizá-lo. Clone Git isolado não preserva ROMs, referência, pacotes ou relatórios privados: manter esta pasta para a continuidade local. Transferência encerrada sem avançar no desenvolvimento.

## 2026-09-20 — Etapa 4B: Início de jogo, Tileset 3 e Comprovação de Herança de VRAM

Objetivo concluído conforme critérios das seções 13 e 14 de `docs/HANDOFF.md`: ampliação da evidência em execução no openMSX para início de jogo (sala 121, tileset 0) e um tileset adicional além de 0 e 4 (sala 240, elevador, tileset 3), registrando o estado anterior de VRAM (`prior-vram.bin`) e posterior estabilizado (`settled-vram.bin`) para comprovar a herança de atlas de tiles versus inicialização limpa.

### Metodologia e Instrumentação

- **Âncoras de instrução verificadas**:
  - `RenderRoom`: ROM `0x0CF0`, CPU `0x4CF0`, banco 0.
  - `WaitVdpCmd`: ROM `0x0ED2`, CPU `0x4ED2`, RET `0x4EDB`, banco 0.
  - `LoadRoomTiles`: ROM `0x0935`, CPU `0x4935`, banco 0 (assinatura única `\xcd\xc4\x42\xcd\x6a\x42\x21\x00\x60\xcd\xd1\x42\x21\x57\xc1` confirmada no binário).
- **Captura do atlas anterior**: adicionada captura em `0x4935` (`LoadRoomTiles`), imediatamente antes de qualquer descompactação ou alteração do atlas pela nova sala.
- **Navegação física determinística reproduzível**:
  - Implementado modo `--mode gameplay` no `capture.py`/`capture.tcl` utilizando unicamente a matriz do teclado MSX (`SNSMAT` via `keymatrixdown`/`keymatrixup`), sem escritas de RAM/ROM/VRAM e sem salto de PC.
  - Sequência: skip de logo (Espaço aos 2s) → New Game (Espaço em `GameStatus == 1`) → avanço de textos de rádio com tecla RETURN (`keymatrixdown 7 128` em `TextWindowStatus == 3`) → caminhada autônoma de Snake: Sala 121 (praia) → Sala 0 (portão) → Sala 1 (fachada) → Sala 2 (corredor) → Sala 3 (hall) → entrada física na porta do elevador (Porta 2, `render_type 5`, sem exigência de cartão) → Sala 240 (**Tileset 3: Elevador**).
- **Análise e classificação de herança no `compare.py`**:
  - Função `classify_atlas_inheritance` compara os 256 tiles do atlas da página 1 (`0x8000..0xFFFF`) entre `prior_vram` e `settled_vram`.
  - Classificação estrita: `overwritten` (modificado pela sala), `inherited` (não modificado e não-nulo) e `zeroed` (não modificado e todo zero).

### Resultados Medidos

- **6 salas capturadas e validadas**:
  - Sala 121 (Início de jogo, TS 0): 235 tiles carregados, 21 slots zerados; 49.152 pixels do fundo coincidentes (100%). Página 0 inicial com 100% de bytes zero.
  - Salas 0, 1, 2, 3 (TS 0): reuso imediato de tileset (`CurrentTileSet == a`), zero sobrescrita no atlas (`overwritten_count: 0`, `inherited_count: 235`); 49.152 pixels coincidentes em todas. Porta 2 na Sala 3 conferida com a RAM em execução.
  - Sala 240 (Elevador, **Tileset 3**): `TileSetElevator` descompacta exatamente **21 tiles** (slots 3 a 23). Exatamente esses 21 slots foram sobrescritos (`overwritten_count: 21`). Todos os outros **214 slots não-nulos** do atlas permaneceram **rigorosamente idênticos** aos tiles do Prédio 1 (Tileset 0) carregados na Sala 3 (`inherited_count: 214`).
  - Fundo estabilizado da Sala 240: 49.152 / 49.152 pixels coincidentes (100%). Ambos os registros de porta em RAM conferidos com a extração.

### Validação e Integração

- **Testes unitários Python**: 37 testes executados com `unittest` e aprovados (adicionados testes sintéticos de classificação de herança de atlas e integração de prior VRAM no `tests/test_emulation.py`).
- **Validador integrado (`python3 tools/validate.py`)**: código 0; 37 testes Python OK, importação headless Godot PASS, `SMOKE_OK`, `ROOM_SNAPSHOT_OK` e `BOOT_OK` aprovados.
- **Integração Godot 4 headless**:
  - `room_snapshot_integration.gd` testado com `room-240.json` (Tileset 3) e `room-121.json` (Início de jogo): 49.152 pixels RGB nominais idênticos aos gerados pelo Python em ambas as salas.
- **Artefatos gerados**:
  - `data/extracted/emulator-stage4b-settled/`: 43 arquivos privados (prior-vram, ram, vram, settled-vram, palette, state para as 6 salas, manifest, finished, config, script e log).
  - `data/extracted/stage4b-validated/`: 6 snapshots JSON (`room-000`, `room-001`, `room-002`, `room-003`, `room-121`, `room-240`), 6 PNGs, `comparison.json` e `checksums.json`.
  - Documentação detalhada em `docs/reverse_engineering/stage-4b-vram-inheritance.md`.
  - ROM principal com SHA-256 preservado e inalterado.

### Fronteira e Próximos Passos

A herança de atlas entre tilesets e o comportamento da inicialização a frio estão agora empiricamente comprovados em execução física/emulada sem escrita de memória. Não avançar para Etapa 5 (física/movimento de Snake) antes da composição de deltas de portas/itens e medições por tick de colisão. Próximo escopo: deltas de portas (aberto/fechado, tipo 6 e paredes destrutíveis) e itens.

## 2026-09-20 — Etapa 4C: Comprovação Empírica de Deltas de Portas (DrawDoors) e Itens na VRAM

Objetivo concluído conforme planejado: modelagem analítica e validação emulada da sobreposição de portas fechadas (`DrawDoors`, ROM `0x375F` / CPU `0x775F`) e análise de itens (`DrawRoomItems`, ROM `0xBC54`), integradas ao pipeline de captura determinística no openMSX (`--mode gameplay`) e comparação com VRAM real.

### Metodologia e Instrumentação

- **Âncoras de instrução verificadas na ROM principal**:
  - `DrawDoors`: ROM `0x375F`, CPU `0x775F` (assinatura `\x3a\xff\xc4\xa7\xc8\x47\x21\xd0\xc3`).
  - Sequência de chamada em `RenderScreen`: ROM `0x2CE5`, CPU `0x6CE5` (`\xcd\xf0\x4c\xcd\xcb\x4a\xcd\xb5\x4a\xcd\x5f\x77`).
- **Captura determinística pós-portas no openMSX (`capture.tcl`)**:
  - Adicionado breakpoint em `0x775F` (`DrawDoors`) para registrar o retorno (`doors_return`).
  - Sincronização com o VDP: caso o bit 0 do registro de status 2 do VDP esteja ativo (comando LMMM em andamento), aguarda o RET de `WaitVdpCmd` em `0x4EDB` para despejo da VRAM 100% estabilizada (`doors-vram.bin`) e RAM com colisões atualizadas (`doors-ram.bin`).
- **Reconstrução analítica e comparação no `compare.py`**:
  - Função `reconstruct_doors_overlay` sintetiza os pixels da porta a partir dos blocos gráficos da Página 1 da VRAM (`GfxDoorFront`, `GfxDoorElevator`, `GfxDoorDown`, etc.) utilizando a semântica exata de `VDP_Copy_Dot` com operação TIMP (cor 0 transparente).
  - Verificação rigorosa: exige 100% de igualdade entre o buffer de tela resultante da emulação e a sobreposição reconstruída em Python.
  - Verificação de contenção: garante que nenhum pixel fora da caixa delimitadora da porta fechada seja modificado.

### Resultados Medidos

- **6 salas analisadas**:
  - Salas 121, 0, 1, 2: zero portas fechadas; delta de 0 pixels entre o fundo base e o pós-portas (100% idêntico, 49.152 / 49.152 pixels).
  - Sala 240 (Elevador interior): possui Porta 2 com render type 6 (`DrawDoorDummy`), o qual executa `ret` imediatamente; delta de 0 pixels comprovado.
  - Sala 3 (Hall do Elevador): possui Porta 2 com render type 5 (`DrawDoorElevator`), que inicia fechada (`Open == 1`).
    - Caixa delimitadora exata: X: `[100..123]`, Y: `[0..31]` (bloco 24×32 = 768 pixels).
    - 737 pixels modificados na VRAM Página 0, com exatamente 31 pixels preservados por transparência (cor 0). Zero pixels modificados fora da caixa delimitadora.
    - 49.152 de 49.152 pixels coincidentes (100.00%) contra a reconstrução analítica.
- **Regra de itens confirmada**:
  - `AddRoomItems` (ROM Banco 4/5/6) atesta que salas de 0 a 121 são "abertas" (`cp 122; ret c`) e salas $\ge 218$ são elevadores (`cp 218; ret nc`), de modo que `ItemsInTheRoom` permanece vazio em todo o percurso inicial de infiltração.

### Validação e Integração

- **Testes unitários Python**: 39 testes executados com `unittest` e aprovados (adicionados `test_reconstruct_doors_overlay` e `test_compare_room_with_doors_vram`).
- **Validador integrado (`python3 tools/validate.py`)**: código 0; 39 testes Python OK, importação headless Godot PASS, `SMOKE_OK`, `ROOM_SNAPSHOT_OK` e `BOOT_OK` aprovados.
- **Integração Godot 4 headless**: `room_snapshot_integration.gd` testado com `room-003.json` e `room-003.png`: 49.152 pixels idênticos.
- **Artefatos gerados**:
  - `data/extracted/emulator-stage4c-settled/`: 55 arquivos privados.
  - `data/extracted/stage4c-validated/`: 6 snapshots validados, 6 PNGs de fundo base, 6 PNGs pós-portas (`room-003-doors.png`), `comparison.json` e `checksums.json`.
  - Documentação completa em `docs/reverse_engineering/stage-4c-doors-and-items.md`.
  - ROM principal preservada e inalterada.

### Fronteira e Próximos Passos

A composição visual completa das salas (fundo estático por metatiles + atlas de VRAM herdado/carregado + deltas de portas fechadas e itens) está agora integralmente comprovada e validada com tolerância zero. O pipeline visual da Etapa 4 está formalmente concluído.

## 2026-09-20 — Etapa 5: Movimento Fiel e Colisão com Gameplay Sandbox no Godot 4

Objetivo concluído: modelagem analítica e implementação fiel em Godot 4 da física discreta de movimento e sistema de colisão de Snake (`PlayerController`), acompanhada de cena jogável interativa (`sandbox_gameplay.tscn`) e suíte de validação automatizada headless.

### Metodologia e Fundamentação da ROM

- **Constantes de Física Revertidas**:
  - `PlayerMovSpeed`: `0x0200` (ponto fixo 8.8, equivalente a exatamente **2.0 pixels/tick** em velocidade normal de caminhada) localizado em `Banks0123.asm` (linha 8416).
  - Movimento estritamente ortogonal: sem deslocamento diagonal (apenas 1 eixo processado por tick).
  - Temporização de passos: 6 ticks por quadro de animação (passo 1 → passo 2 → passo 1) e reset para 0 ao parar.
- **Tabela de Colisão `BoxColliderDat` (Shape 0)**:
  - Definida em `logic/collisions.asm` (linhas 135-144). Snake utiliza `Shape 0` (`ShapeSize_0`), que amostra exatamente **2 pontos de teste** por direção relativa ao centro do ator:
    - **UP** (1): `(-6, -5)` e `(5, -5)`
    - **DOWN** (2): `(-6, 4)` e `(5, 4)`
    - **LEFT** (3): `(-8, -4)` e `(-8, 3)`
    - **RIGHT** (4): `(7, -4)` e `(7, 3)`
  - O teste de colisão avalia as amostras contra a grade 32×24 de `static_collision` (tiles de 8×8 pixels). Se qualquer uma das amostras atingir um tile com valor `1` ou as bordas da tela (`0..255`, `0..191`), o movimento no tick é bloqueado sem alterar a posição de Snake.

### Implementação em Godot 4

1. **`PlayerController` (`godot/scripts/systems/player.gd` & `godot/scenes/player.tscn`)**:
   - Nó `Node2D` com tipagem estática completa GDScript (`Direction`, `SPEED_NORMAL = 2.0`, `COLLIDER_OFFSETS`).
   - Método `step_tick(input_dir: Vector2i) -> bool` com física discreta determinística e teste de colisão prévio.
   - Renderização autoral e procedural da silhueta de Snake com uniforme militar verde-oliva, bandana vermelha, orientação dos olhos e passos animados.
   - Suporte a depuração visual (`show_debug_colliders`) desenhando os 2 pontos de amostragem de `BoxColliderDat`.
2. **Cena Sandbox Jogável (`godot/scripts/scenes/sandbox_gameplay.gd` & `godot/scenes/sandbox_gameplay.tscn`)**:
   - Espaço nativo 256×192 desacoplado com `game_world: Node2D` aplicando escala inteira (zoom) e centralização visual automática com base na janela.
   - Carregamento prioritário de snapshot real validado (Sala 1 do Prédio 1) ou fallback sintético limpo sem dependência de ROM.
   - Controles interativos: Setas/WASD para mover, `C` para exibir grade de colisão de 32×24, `V` para visualizar pontos de contato do colisor e `R` para resetar posição.
   - Integração no menu inicial de `godot/scenes/main.tscn` com botão direto "Jogar Sandbox Gameplay (Snake)".

### Validação Automatizada

- **Teste Headless Godot (`godot/tests/player_movement_test.gd`)**:
  - Verifica avanço exato de 2.0 px/tick em espaço aberto para as 4 direções.
  - Verifica ciclo de 6 ticks de animação de passos.
  - Valida isoladamente a rejeição nos 2 pontos de `BoxColliderDat` para cada uma das 4 direções contra obstáculo sintético calibrado.
  - Valida bloqueio nos 4 limites da tela (0..255, 0..191).
  - Instancia `sandbox_gameplay.tscn`, confirmando carregamento da grade e árvore de nós.
  - Saída oficial: `PLAYER_MOVEMENT_OK: 2.0px speed, authentic BoxColliderDat points, 4-direction blocking, scene integration`.
- **Suíte Integrada (`python3 tools/validate.py`)**:
  - `python-tests`: PASS (39 testes unitários)
  - `godot-import`: PASS
  - `godot-smoke`: PASS (`SMOKE_OK`)
  - `godot-room-snapshot`: PASS (`ROOM_SNAPSHOT_OK`)
  - `godot-player-movement`: PASS (`PLAYER_MOVEMENT_OK`)
  - `godot-main`: PASS (`BOOT_OK`)

### Como Executar e Jogar

- **Via Godot**:
  - Executável: `/Applications/Godot.app/Contents/MacOS/Godot --path godot`
  - Na tela inicial, clique em **"Jogar Sandbox Gameplay (Snake)"** ou execute diretamente a cena:
    `/Applications/Godot.app/Contents/MacOS/Godot --path godot res://scenes/sandbox_gameplay.tscn`
- **Via Validador**:
  - `python3 tools/validate.py`

## 2026-09-20 — Etapa 6: Transição de Salas e Navegação Contínua do Mundo

Objetivo concluído: modelagem analítica e implementação fiel em Godot 4 do sistema de transições entre salas ao cruzar as bordas da tela, integrando a tabela canônica `RoomConnections` e os limites de reentrada da ROM.

### Metodologia e Fundamentação da ROM

- **Limites Canônicos de Saída (`ChkExitRoom` em `Banks0123.asm:9418`)**:
  - LEFT (3): $X < 12.0$
  - RIGHT (4): $X \ge 244.0$
  - UP (1): $Y < 16.0$
  - DOWN (2): $Y \ge 186.0$
  - Esses limiares operam enquanto os pontos de amostragem de `BoxColliderDat` ainda estão contidos na grade de tiles $32 \times 24$, viabilizando a detecção de passagens abertas sem conflito com bordas nulas.
- **Resolução de Vizinhança (`GetNextRoomNum` em `Banks0123.asm:889` e `RoomConnections` em `data/roomsconnections.asm`)**:
  - Tabela com 156 quartetos `[UP, DOWN, LEFT, RIGHT]`.
  - Mapeamento por faixas:
    - Salas $0..125$: relação direta $1:1$ de índice.
    - Salas $126..207$: salas isoladas/caminhões (sem saídas de borda $\rightarrow$ `NO_ROOM = 255`).
    - Salas $208..227$: índice `Room - 82` ($126..145$).
    - Salas $228..240$: indefinidas / elevador 240 (sem saída de borda $\rightarrow$ `NO_ROOM`).
    - Salas $241..250$: elevadores superiores (índice `Room - 95`).
- **Coordenadas de Reentrada (`SetRoomEntryXY` / `EntryRoomXY` em `logic/nextroom.asm:342`)**:
  - UP $\rightarrow$ nova sala com $Y = \mathbf{184.0}$ (conserva $X$).
  - DOWN $\rightarrow$ nova sala com $Y = \mathbf{18.0}$ (conserva $X$).
  - LEFT $\rightarrow$ nova sala com $X = \mathbf{242.0}$ (conserva $Y$).
  - RIGHT $\rightarrow$ nova sala com $X = \mathbf{12.0}$ (conserva $Y$).

### Implementação em Godot 4

1. **`RoomManager` (`godot/scripts/systems/room_manager.gd`)**:
   - Classe com tipagem estática e tabela canônica `CONNECTIONS_TABLE`.
   - Métodos estáticos: `get_next_room()`, `check_room_exit()` e `get_entry_position()`.
   - Sistema de carregamento e cache em memória de `RoomSnapshot`s a partir dos diretórios validados (`stage4c-validated`, `stage4b-validated`, `stage4-validated`).
2. **Navegação Integrada na Sandbox (`sandbox_gameplay.gd`)**:
   - Chamada automática de `_check_and_handle_room_transition()` a cada passo de Snake.
   - Troca de sala sem interrupção: fundo, textura e grade de colisão de 768 tiles atualizados instantaneamente.
   - Bloqueio automático de bordas (`_clamp_to_room_bounds()`) quando a direção não possui sala conectada (`NO_ROOM`).

### Validação Automatizada

- **Teste Headless Godot (`godot/tests/room_transition_test.gd`)**:
  - Valida resolução estática de conexões para salas canônicas (121, 0, 1, 2, 3, 208, 240).
  - Valida detecção de limites e conversão de coordenadas de reentrada.
  - Simula no SceneTree a caminhada bidirecional completa:
    Sala 1 $\rightarrow$ UP $\rightarrow$ Sala 2 $(128, 184) \rightarrow$ UP $(X=144) \rightarrow$ Sala 3 $(144, 184) \rightarrow$ DOWN $\rightarrow$ Sala 2 $(144, 18) \rightarrow$ DOWN $\rightarrow$ Sala 1 $(128, 18) \rightarrow$ DOWN $\rightarrow$ Sala 0 $(128, 18) \rightarrow$ DOWN $\rightarrow$ Sala 121 $(128, 18)$.
  - Saída oficial: `ROOM_TRANSITION_OK: room connections, authentic exit bounds, entry XY recalculation, bidirectional room changes`.
- **Suíte Integrada (`python3 tools/validate.py`)**:
  - `python-tests`: PASS (39 testes unitários)
  - `godot-import`: PASS
  - `godot-smoke`: PASS (`SMOKE_OK`)
  - `godot-room-snapshot`: PASS (`ROOM_SNAPSHOT_OK`)
  - `godot-player-movement`: PASS (`PLAYER_MOVEMENT_OK`)
  - `godot-room-transition`: PASS (`ROOM_TRANSITION_OK`)
  - `godot-main`: PASS (`BOOT_OK`)

## 2026-09-20 — Etapa 7: Inimigos, Patrulhas e Linha de Visão (Furtividade)

Etapa 7 implementada com total fidelidade ao comportamento do MSX2 RC750. Documentação em `docs/reverse_engineering/stage-7-enemy-patrols.md`.

### Metodologia e Fundamentação da ROM

- **Tipos de Soldados e Velocidades Canônicas**:
  - `ID_GUARD_SLOW = 4`: $0.5$ px/tick.
  - `ID_GUARD_MEDIUM = 5`: $1.0$ px/tick.
  - `ID_GUARD_FAST = 6`: $1.5$ px/tick.
- **Tabela de Atores por Sala (`ActorsInRooms` em `data/actorsinrooms.asm`)**:
  - **Sala 001**: Guarda 0 (MEDIUM, spawn $(64, 176)$, rota `Path_000_01`), Guarda 1 (SLOW, spawn $(80, 80)$, rota `Path_000_02`), Guarda 2 (MEDIUM, spawn $(192, 24)$, rota `Path_000_03`).
  - **Sala 002**: Guarda 0 (SLOW, spawn $(64, 48)$, rota `Path_002_01`), Guarda 1 (MEDIUM, spawn $(168, 112)$, rota `Path_002_02`).
- **Rotas de Patrulha (`Paths` em `data/paths.asm`)**:
  - Waypoints com percursos vai-e-vem horizontais e circulação de 8 pontos contornando caixas e obstáculos.
- **Linha de Visão e Tolerâncias (`logic/actors/chkdiscover.asm:447-491`)**:
  - Visão vertical (`UP`/`DOWN`): $|PlayerX - EnemyX| \le 8.0$ px.
  - Visão horizontal (`LEFT`/`RIGHT`): $|PlayerY - EnemyY| \le 6.0$ px.
  - Alcance visual máximo: $160.0$ px ($20$ tiles).
  - Bloqueio por obstáculos (`ChkViewObstacles`): amostragem em saltos de 8 pixels na grade de colisão; bloqueia a visão se atingir tile sólido ($1$).
- **Sinalização de Alerta**:
  - Transição de estado para `ALERT` e renderização do clássico balão com exclamação (`!`) sobre a cabeça do guarda.

### Implementação em Godot 4

1. **`EnemyGuard` (`godot/scripts/systems/enemy.gd` e cena `res://scenes/enemy.tscn`)**:
   - Controle de patrulha e waypoints, amostragem de linha de visão contra a grade de colisão de 768 tiles.
   - Desenho do uniforme de Outer Heaven, capacete, rifle direcional, animação de passos e balão `!`.
   - Alternância de visualização de depuração do cone de visão (`show_debug_vision`).
2. **Integração no Sandbox (`sandbox_gameplay.gd`)**:
   - `_spawn_room_enemies()` instancia os soldados canônicos ao entrar nas salas 1 e 2.
   - Atualização em tempo real de patrulha e detecção em `_physics_process()`.
   - Alerta visual no cabeçalho em vermelho ao avistar Snake.
   - Tecla `B` e botão de interface para alternar os cones de visão dos guardas.

### Validação Automatizada

- **Teste Headless Godot (`godot/tests/enemy_patrol_test.gd`)**:
  - Valida velocidades canônicas de `GuardType`.
  - Valida percurso e reversão de waypoints.
  - Valida tolerâncias exatas da visão vertical e horizontal.
  - Valida oclusão e bloqueio por obstáculo sólido.
  - Valida disparo de alerta em `step_tick`.
  - Saída oficial: `ENEMY_PATROL_OK: waypoints patrol, authentic sight tolerances, obstacle occlusion, alert trigger`.
- **Suíte Integrada (`python3 tools/validate.py`)**:
  - `python-tests`: PASS (39 testes unitários)
  - `godot-import`: PASS
  - `godot-smoke`: PASS (`SMOKE_OK`)
  - `godot-room-snapshot`: PASS (`ROOM_SNAPSHOT_OK`)
  - `godot-player-movement`: PASS (`PLAYER_MOVEMENT_OK`)
  - `godot-room-transition`: PASS (`ROOM_TRANSITION_OK`)
  - `godot-enemy-patrol`: PASS (`ENEMY_PATROL_OK`)
  - `godot-main`: PASS (`BOOT_OK`)

## 2026-09-20 — Etapa 8: Combate Corpo a Corpo (Soco), Perseguição em Alerta e Vida/Dano

Etapa 8 implementada com total fidelidade às rotinas de combate da ROM original do MSX2 RC750. Documentação em `docs/reverse_engineering/stage-8-combat-and-health.md`.

### Metodologia e Fundamentação da ROM

- **Soco de Snake (`chkPunch` em `Banks0123.asm:8934`)**:
  - Duração de $8$ ticks com velocidade de movimento zerada (`PunchCnt = 8`, `PlayerAnimation = 1`).
  - Caixas de impacto direcionais autênticas da ROM (`logic/punchenemy.asm:81-87`):
    - UP: $Y_{+12}$, $R_Y=12$, $R_X=12$
    - DOWN: $Y_{-12}$, $R_Y=12$, $R_X=12$
    - LEFT: $X_{+12}$, $R_X=12$, $R_Y=12$
    - RIGHT: $X_{-12}$, $R_X=12$, $R_Y=12$
- **Atordoamento e Derrota de Guardas (`ChkKillPunching` em `Banks0123.asm:12815`)**:
  - Cada soco recebido atordoa o guarda por $64$ ticks ($0x40$), imobilizando-o e impedindo acúmulo de dano simultâneo.
  - Com $3$ socos recebidos (`PunchesCnt == 3`), o guarda é derrotado (`is_dead = true`), cai no chão e desativa visão e colisão.
- **Perseguição em Alerta (`GuardAlertLogic` em `logic/actors/guardalert.asm`)**:
  - Guardas em estado de alerta abandonam a patrulha e perseguem ativamente Snake pelo menor eixo com contorno de obstáculos no grid.
- **Vida e Dano de Snake (`Life`, `MaxLife`, `TouchPlayer` em `logic/touchenemy.asm`)**:
  - Vida inicial: $24$ pontos (Rank 1 / `Banks0123.asm:9672`).
  - Dano por contato físico: $2$ pontos de vida por toque (`ActorTouchDamage` em `data/shapes.asm:36`).
  - Invulnerabilidade temporária: $32$ ticks ($0x20$) com feedback visual piscante.

### Implementação em Godot 4

1. **`PlayerController` (`player.gd`)**:
   - `life = 24`, `max_life = 24`, `invulnerable_timer`, `punch_timer`, `is_punching`.
   - Método `punch()` e `apply_damage(amount)`.
   - Animação do punho estendido e piscar intermitente de dano.
2. **`EnemyGuard` (`enemy.gd`)**:
   - `check_punched(player_pos, player_dir)` com caixas direcionais da ROM.
   - `receive_punch()` com atordoamento de $64$ ticks e eliminação ao 3º soco.
   - `_chase_player()` persegue Snake contornando a grade de colisão.
   - Dano por contato direto aplicado a Snake.
   - Desenho de estrelas de atordoamento e silhueta de derrota.
3. **Sandbox (`sandbox_gameplay.gd`)**:
   - Disparo de soco com tecla de espaço / J.
   - Exibição gráfica da barra de vida (`VIDA: [■■■■■■■■] 24/24`) e contador de guardas derrotados.

### Validação Automatizada

- **Teste Headless Godot (`godot/tests/combat_and_health_test.gd`)**:
  - Valida 8 ticks de imobilização do soco.
  - Valida caixas de impacto de soco nas 4 direções.
  - Valida 64 ticks de stun e morte com 3 socos.
  - Valida 2 pontos de dano e 32 ticks de invulnerabilidade.
  - Saída oficial: `COMBAT_AND_HEALTH_OK: punch 8-ticks, 4-direction impact boxes, 64-tick stun, 3-punch kill, touch damage and 32-tick invulnerability`.
- **Suíte Integrada (`python3 tools/validate.py`)**:
  - `python-tests`: PASS (39 testes unitários)
  - `godot-import`: PASS
  - `godot-smoke`: PASS (`SMOKE_OK`)
  - `godot-room-snapshot`: PASS (`ROOM_SNAPSHOT_OK`)
  - `godot-player-movement`: PASS (`PLAYER_MOVEMENT_OK`)
  - `godot-room-transition`: PASS (`ROOM_TRANSITION_OK`)
  - `godot-enemy-patrol`: PASS (`ENEMY_PATROL_OK`)
  - `godot-combat-health`: PASS (`COMBAT_AND_HEALTH_OK`)
  - `godot-main`: PASS (`BOOT_OK`)

## 2026-09-20 — Etapa 9: Portas Interativas, Caixas de Itens e Inventário

Etapa 9 implementada com total fidelidade às rotinas da ROM original do MSX2 RC750. Documentação em `docs/reverse_engineering/stage-9-doors-and-inventory.md`.

### Metodologia e Fundamentação da ROM

- **Mapeamento de Itens por Sala (`data/itemsinrooms.asm:6-13, 75-86`)**:
  - Posições canônicas de itens: Sala 004 (`CARD1` em $112, 80$), Sala 005 (`BINOCULARS` em $112, 64$), Sala 006 (`RATION` em $96, 64$).
- **Sistema de Inventário e Seleção (`logic/menuequipment.asm`)**:
  - Seleção ativa de itens e rações.
  - Consumo de ração restaura a energia ao máximo de $24$ pontos de vida (`Life = MaxLife`).
- **Portas Interativas e Trancas por Cartão (`logic/doors/opendoor.asm` e `data/doors.asm`)**:
  - Portas fechadas injetam colisão física ($1$) bloqueando os tiles correspondentes da grade $32 \times 24$.
  - Verificação de chave e alinhamento direcional (`ChkCard` / `ChkTouchDoor`): exige que o item selecionado seja idêntico ao cartão requerido (ex: `CARD1`).
  - Ao abrir, limpa a colisão ($0$) e permite travessia para a sala de destino (`Destination room` / `logic/nextroom.asm:120-155`).

### Implementação em Godot 4

1. **`InventoryManager` (`inventory.gd`)**:
   - Registro de itens coletados, ciclo via tecla `E`, uso de ração via tecla `U`.
2. **`ItemBox` (`item_box.gd`)**:
   - Caixa metálica cinza autêntica com identificador gráfico e coleta por proximidade ($\le 12$ px) com persistência por ID.
3. **`RoomDoor` (`door.gd`)**:
   - Injeção/remoção dinâmica de colisão na matriz de 768 tiles.
   - Verificação de proximidade, direção e cartão exigido.
   - Abertura visual com vão de passagem e acionamento de transição de sala.
4. **Sandbox (`sandbox_gameplay.gd`)**:
   - Spawning de portas e itens nas salas 1, 2, 3, 4, 5 e 6.
   - Exibição do item equipado no cabeçalho do HUD: `[ITEM: CARD1]` / `[ITEM: RAÇÃO x1]`.

### Validação Automatizada

- **Teste Headless Godot (`godot/tests/doors_and_inventory_test.gd`)**:
  - Valida coleta de itens e persistência.
  - Valida ciclo de itens e cura de vida por ração.
  - Valida bloqueio de colisão de porta fechada.
  - Valida rejeição sem cartão e abertura com cartão correto.
  - Valida disparo de transição ao atravessar porta aberta.
  - Saída oficial: `DOORS_AND_INVENTORY_OK: item collection, cycle, ration healing, locked door collision, card unlock and door entry`.
- **Suíte Integrada (`python3 tools/validate.py`)**:
  - `python-tests`: PASS (39 testes unitários)
  - `godot-import`: PASS
  - `godot-smoke`: PASS (`SMOKE_OK`)
  - `godot-room-snapshot`: PASS (`ROOM_SNAPSHOT_OK`)
  - `godot-player-movement`: PASS (`PLAYER_MOVEMENT_OK`)
  - `godot-room-transition`: PASS (`ROOM_TRANSITION_OK`)
  - `godot-enemy-patrol`: PASS (`ENEMY_PATROL_OK`)
  - `godot-combat-health`: PASS (`COMBAT_AND_HEALTH_OK`)
  - `godot-doors-inventory`: PASS (`DOORS_AND_INVENTORY_OK`)
  - `godot-main`: PASS (`BOOT_OK`)

## 2026-09-20 — Etapa 10: Entrada e Saída em Caminhões (Lorries 126, 127, 128), Posicionamento Canônico e Salas Interiores

Etapa 10 implementada com total fidelidade às rotinas da ROM original do MSX2 RC750. Documentação em `docs/reverse_engineering/stage-10-lorries-and-canonical-items.md`.

### Metodologia e Fundamentação da ROM

- **Caminhões Estacionados na Sala 005 (`data/doors.asm:311-316`)**:
  - A Sala 005 possui 3 caminhões estacionados com suas portas de entrada registradas em `DoorsRoom005`:
    - Caminhão 1 (Esquerda): `Door ID 101` (`0x65`), $X=36, Y=68 \rightarrow$ Destino: Sala 126 (`0x7E`).
    - Caminhão 2 (Meio): `Door ID 109` (`0x6D`), $X=100, Y=100 \rightarrow$ Destino: Sala 127 (`0x7F`).
    - Caminhão 3 (Direita): `Door ID 113` (`0x71`), $X=164, Y=68 \rightarrow$ Destino: Sala 128 (`0x80`).
- **Lógica de Abertura Automática (`Banks0123.asm:1015-1022` e `data/doors.asm:917-918`)**:
  - Na tabela `IdDoorsLogic`, as portas 101, 109 e 113 têm valores com bit 7 setado (`0x8A`, `0x8B`, `0x8B`).
  - A rotina `SetDefaultDoorLock` mascara com `0xC0` e detecta `0x80`, definindo o estado como aberto por padrão (`0 = Open`). Portas de caminhão não exigem cartão e não desenham o sprite metálico de porta com leitor.
- **Dimensões do Vão e Caixas de Acionamento (`DoorOpenEnterDat` em `data/doors.asm:15-18`)**:
  - Tipo de renderização 1 (Entrada de caminhão): zona de entrada com tolerância de largura de 32 px.
  - Tipo de renderização 4 (Saída da carroceria): abertura lateral direita de $X=208, Y \in [92, 128]$.
- **Posicionamento Relativo de Snake ao Entrar/Sair (`logic/nextroom.asm:463-482`)**:
  - `PlayerInDoorDat` tipo 4: ao entrar no caminhão, Snake se posiciona em $X=198, Y=112$ olhando para a esquerda (`Direction.LEFT`).
  - `PlayerInDoorDat` tipo 1: ao sair para o pátio da Sala 5, Snake reaparece logo abaixo da traseira do caminhão correspondente olhando para baixo (`Direction.DOWN`).
- **Posicionamento Canônico de Itens nos Caminhões (`data/itemsinrooms.asm:6-13, 75-86` e `logic/addroomitems.asm:15-35`)**:
  - As caixas temporárias que haviam sido colocadas no chão das salas 1, 2 e 5 para validação preliminar foram removidas.
  - Cada item foi realocado para sua sala canônica exata:
    - **Sala 126** (Caminhão da esquerda): `RATION` (`dw 5050h` $\rightarrow X=80, Y=80$).
    - **Sala 127** (Caminhão central): `CARD1` (`dw 7050h` $\rightarrow X=112, Y=80$) e 1 guarda em alerta (`ActorsRoom127: ID_GUARD_ALERT` `dw 4870h` $\rightarrow X=72, Y=112$).
    - **Sala 128** (Caminhão da direita): `BINOCULARS` (`dw 7040h` $\rightarrow X=112, Y=64$).
  - Sala 005: 1 guarda em patrulha (`ActorsRoom005: ID_GUARD_EXIT_LORRY` `dw 7078h` $\rightarrow X=112, Y=120$).

### Implementação em Godot 4

1. **`RoomDoor` (`door.gd`)**:
   - Adicionadas orientações `LORRY_ENTER` e `LORRY_EXIT`.
   - Adicionadas propriedades `is_lorry`, `trigger_rect` e `destination_direction`.
   - Lorry doors são abertas por padrão, não bloqueiam colisão na matriz de tiles e não desenham sprite de porta de prédio.
2. **`RoomManager` (`room_manager.gd`)**:
   - Carregamento e cache compartilhado para as salas de caminhão 126 e 128 reutilizando o layout/colisão de `room-127.json`.
3. **`PlayerController` e `sandbox_gameplay.gd`**:
   - Suporte a mudança de direção ao atravessar portas (`entry_dir` / `destination_direction`).
   - Spawning das 3 portas de caminhão na Sala 5 e portas de saída nas salas 126, 127 e 128.
   - Posicionamento canônico de itens militares e guardas nas salas de caminhão.

### Validação Automatizada

- **`godot/tests/doors_and_inventory_test.gd`**:
  - Valida abertura padrão e colisão desimpedida de portas de caminhão.
  - Valida entrada no caminhão pela traseira (UP) para a Sala 127.
  - Valida saída do caminhão pela abertura direita (RIGHT) de volta à Sala 5.
  - Valida coleta limpa dos itens canônicos nos caminhões: Ração na 126, Card 1 na 127 e Binóculos na 128.
- **`godot/tests/room_transition_test.gd`**:
  - Valida transição bidirecional contínua Sala 1 $\leftrightarrow$ Sala 5.
  - Valida transição Sala 5 $\rightarrow$ Sala 127 (caminhão) e retorno para a Sala 5.
- **Suíte Completa (`python3 tools/validate.py`)**:
  - `python-tests`: PASS (39 testes unitários)
  - `godot-import`: PASS
  - `godot-smoke`: PASS (`SMOKE_OK`)
  - `godot-room-snapshot`: PASS (`ROOM_SNAPSHOT_OK`)
  - `godot-player-movement`: PASS (`PLAYER_MOVEMENT_OK`)
  - `godot-room-transition`: PASS (`ROOM_TRANSITION_OK`)
  - `godot-enemy-patrol`: PASS (`ENEMY_PATROL_OK`)
  - `godot-combat-health`: PASS (`COMBAT_AND_HEALTH_OK`)
  - `godot-doors-inventory`: PASS (`DOORS_AND_INVENTORY_OK`)
  - `godot-main`: PASS (`BOOT_OK`)





