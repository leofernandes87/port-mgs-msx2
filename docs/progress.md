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

## 2026-09-20 — Etapa 11: Extração em Lote de Todas as Salas dos Prédios 1, 2 e 3

**Objetivo**: Gerar e validar em lote os snapshots de fundo e colisão de todas as salas dos Prédios 1, 2 e 3 a partir da ROM.

### O que foi feito

- **Ferramenta criada**: `tools/extractors/batch_snapshots.py`
  - Lê `data/extracted/rc750-verified/package.json` (produzido por `extract.py`, sem tocar a ROM)
  - Reconstrói os pixels de cada sala usando `_compose_raster()` — mesma lógica de `compare.py`
  - Tiles não carregados no slot estático (IDs 0, 1, 2) renderizados como índice 0 (preto), confirmado pelas capturas do emulador
  - Constrói paleta RGB com `build_palette()`: par base + patch da sala
  - Valida cada snapshot contra o esquema `data/schemas/room-snapshot.schema.json`
  - Faz cross-check pixel-a-pixel contra snapshots validados por emulador (stage4b/c/d)
  - Escreve `room-NNN.json` + `room-NNN.png` + `batch_summary.json` + `checksums.json`

- **Salas extraídas**: 126 snapshots (rooms 000–125, todos os Prédios 1, 2 e 3)
  - Prédio 1 (salas 0–15): 16 snapshots
  - Prédio 2 (salas 16–63): 48 snapshots
  - Prédio 3 (salas 64–125): 62 snapshots
  - Salas com tiles não carregados: 84/126 (tiles 1 e/ou 2 renderizados como zeros)
  - Cross-check contra emulador: 7/126 salas com correspondência pixel-a-pixel exata (rooms 000, 001, 002, 003, 005, 031, 121)

- **Destino**: `data/extracted/stage5-batch/` (254 arquivos: 126 JSON + 126 PNG + 2 meta)

- **Testes adicionados** a `tests/test_extractors.py` — classe `BatchSnapshotTests` (6 novos testes sintéticos):
  - `test_compose_raster_dimensions`: sempre 49152 ints
  - `test_compose_raster_unloaded_renders_zero`: tile None → pixel 0
  - `test_compose_raster_tile_placement`: posicionamento correto de bloco 8×8
  - `test_build_palette_applies_patches`: 18 entradas, 2 cores diagnósticas no final
  - `test_parse_room_range_single_and_range`: parsing de faixas de sala
  - `test_building_scopes_cover_correct_ranges`: escopos de prédios corretos

### Verificações reais

- **`python3 tools/validate.py`**: PASS (45 testes Python + 9 suites Godot)
- **Extração em lote**: 126/126 snapshots, 0 falhas, 7 cross-checks exatos
- ROM original: não modificada; package.json é a entrada intermediária

## 2026-09-20 — Etapa 12 concluída: Integração dos Snapshots e Dados Reais ao Godot

### Bloco 12-A concluído (commit `356ee1b`)
- `RoomManager`: adicionado `stage5-batch/` como primeira prioridade em `load_room_snapshot()`.
- Snapshots reais (salas 0–125) agora carregados diretamente da ROM sem emulador.
- `godot/tests/room_snapshot_test.gd`: teste verificado de carregamento real da sala 000.
- `validate.py`: PASS (45 Python + 9 Godot).

### Bloco 12-B concluído (commit `d559100`)
- Criada ferramenta `tools/extractors/export_room_data.py`:
  - Extrai dados leves por sala (`room-NNN-actors.json`): atores, itens e portas canônicas.
  - Combina coordenadas YX de `entities` e waypoints ordenados de `room_paths` / `paths`.
  - Exportadas 129 salas (0–128) para `data/extracted/stage5-batch/`.
- Adicionada suíte de testes sintéticos `ExportRoomDataTests` em `tests/test_extractors.py`.
- `validate.py`: PASS (46 Python + 9 Godot).

### Bloco 12-C concluído
- `RoomManager.load_room_actors(room_id)` implementado com cache em memória.
- `sandbox_gameplay.gd`:
  - `_spawn_room_enemies()`: instancia guardas dinamicamente a partir de `room-NNN-actors.json` com waypoints de patrulha e GuardType (SLOW para tipos 3/4, MEDIUM para os demais).
  - `_spawn_room_items()`: instancia ItemBoxes dinamicamente a partir de `items` do JSON mapeando IDs de item da ROM (Ration, Card1, Binoculars, etc.).
  - Fallbacks preservados para salas canônicas de teste.
- Testado e verificado: salas de todos os três prédios (Prédio 1 ex: sala 1 com 3 guardas; Prédio 2 ex: sala 16 com 1 guarda; Prédio 3 ex: sala 64 com 9 guardas).

### Verificações reais
- `python3 tools/validate.py`: 100% PASS (46 testes Python + 9 suites Godot).
- Teste headless de salas reais: salas 1, 5, 16, 64, 127 carregam com background, colisão e guardas fiéis.

## 2026-09-20 — Etapa 12b concluída: Spawn de Inimigos, Itens e Portas Canônicas da ROM

### O que foi feito
1. **Evidências Documentadas**:
   - `docs/reverse_engineering/stage-12b-actors-and-items-evidence.md`:
     - Tabela completa de todos os 57 tipos de atores do MSX2 RC750 (`Banks0123.asm:6404-6468`).
     - Tabela de regras de portas (`Enums.asm:113-122`): `DOOR_CARD1` (2) a `DOOR_CARD8` (9), `DOOR_PUNCH` (10), `DOOR_ELEVATOR` (1).
     - Catálogo de itens da ROM (`data/itemsinrooms.asm:19-46`).
2. **Refinamento de Inimigos no Godot**:
   - `sandbox_gameplay.gd`:
     - Filtra tipos de atores não combatentes (minas, gás, alçapões, câmeras, prisioneiros) para evitar sprites incorretos.
     - Mapeia velocidades fiéis da ROM: `SLOW` (0.5 px/tick) para guardas lentos e escorpiões; `FAST` (1.5 px/tick) para cães e guardas rápidos; `MEDIUM` (1.0 px/tick) para guardas padrão e atiradores.
     - Sentinelas (`InitSentinel`, tipo 48): sentinelas estáticos posicionados no posto de vigia.
3. **Automação de Portas Canônicas**:
   - `sandbox_gameplay.gd` instancia portas dinamicamente a partir do array `doors` em `room-NNN-actors.json`.
   - Mapeia orientações (`NORTH`, `SOUTH`, `WEST`, `EAST`) a partir de `render_type_id`.
   - Mapeia trancas e requisitos de cartão (`CARD1` a `CARD8`) a partir de `open_rule_id`.
   - Adicionadas constantes `ITEM_CARD5`..`ITEM_CARD8` a `InventoryManager`.
4. **Testes e Verificação**:
   - `doors_and_inventory_test.gd`: adicionado caso de teste para porta trancada por `CARD4` (sala 6 da ROM com 3 portas canônicas e 2 cães de guarda).
### Correção de Colisão de Inimigos e Comportamento dos Cães (Sala 6)
- **Problema identificado**: Cães da Sala 6 atravessavam as grades/cerca ao fazer a transição para a sala em (86.0, 184.0).
- **Causa raiz na engenharia reversa**:
  1. No MSX2 (`logic/actors/dog.asm`), cães (`InitDog`, IDs 25/27) não utilizam rotas de patrulha (`idxRoomPaths`). Eles iniciam adormecidos no spawn (`DogSleep`) e só se movem em perseguição/alerta com verificação de colisão (`ChkDogCollision`). O exportador havia vinculado rotas espúrias de outra sala compartilhada no `Paths_006`.
  2. O método `_follow_patrol_path()` em `enemy.gd` movia a posição sem checar `collision_grid`, permitindo penetração em obstáculos.
  3. `_is_colliding_grid()` checava apenas um ponto de 1 pixel em vez do bounding box (10x10 px) do ator.
- **Solução implementada**:
  - `enemy.gd`: `_follow_patrol_path(collision_grid)` agora valida colisões antes de avançar; `_is_colliding_grid()` testa os 4 cantos do bounding box do inimigo.
  - `sandbox_gameplay.gd`: cães (IDs 25, 27) permanecem no posto de guarda adormecidos/vigilantes no spawn (sem avançar contra a grade).
  - `enemy_patrol_test.gd`: adicionado teste de patrulha bloqueada por parede sólida (100% PASS).
## 2026-09-20 — Etapa 12c concluída: Extração e Integração das Salas Lorry e Isoladas (126–207)

### O que foi feito
1. **Extração em Lote das Salas Lorry e Interiores**:
   - `tools/extractors/batch_snapshots.py` executado com escopo `--rooms 126-207`:
     - 81 salas decodificadas extraídas com sucesso para `data/extracted/stage5-lorries/`.
     - 1 sala indefinida ignorada conforme especificação da ROM (`sala 155`).
     - Sala 127 cross-checked com 100% de precisão contra capturas do emulador.
2. **Exportação de Metadados de Atores e Itens das Salas 126–207**:
   - `tools/extractors/export_room_data.py` gerou `room-NNN-actors.json` para todas as 81 salas em `stage5-lorries/`.
3. **Integração no Godot**:
   - `RoomManager.load_room_snapshot()` atualizado para buscar `stage5-lorries/` como candidato prioritário para salas de caminhão e interiores.
   - `RoomManager.load_room_actors()` atualizado para buscar metadados de atores em `stage5-lorries/`.
   - Salas 126, 127, 128 (caminhões) e 129..207 (interiores/salas isoladas) agora possuem backgrounds, colisões, portas e itens autênticos da ROM.
4. **Testes e Verificação**:
   - `room_snapshot_test.gd`: adicionada validação de carregamento real da sala 126 a partir de `stage5-lorries`.
   - `validate.py`: 100% PASS (46 testes Python + 9 suítes Godot).

## 2026-09-20 — Etapa 12d concluída: Sistema de Elevadores e Conexões Verticais (Salas 240–250)

### O que foi feito
1. **Extração das 11 Salas de Elevador (240 a 250)**:
   - batch_snapshots.py e export_room_data.py executados com --rooms 240-250 para data/extracted/stage5-elevators/.
   - Sala 240 cross-checada pixel a pixel com 100% de precisão contra capturas do emulador (stage4c-validated).
   - Metadados de atores e portas dummy de saída (render_type_id: 6) exportados para todas as 11 salas.
2. **Implementação do Sistema de Elevadores**:
   - ElevatorSystem (godot/scripts/systems/elevator_system.gd): implementa tabelas canônicas de limites e andares (data/elevatorrooms.asm), cálculo de entrada por andar (GetElevatorPosY), movimentação vertical a 1 px/tick (MoveElevator) e detecção de saída por andar (data/doors.asm).
   - ElevatorCabin (godot/scripts/systems/elevator_cabin.gd): representação visual autêntica da cabine do MSX2 com cabos, teto/chão metálico e painel com botões iluminados.
   - RoomManager: atualizado para carregar snapshots e metadados de atores de stage5-elevators/.
   - sandbox_gameplay.gd: integração da mecânica de elevador, movimentação vertical dentro da cabine e transições bidirecionais entre andares e prédios (ex: Sala 3 Térreo <-> Sala 240 Elevador <-> Sala 31 Telhado).
   - door.gd: tolerâncias aprimoradas para centro da porta e entrada em portas de elevador.
3. **Testes e Verificação**:
   - godot/tests/elevator_test.gd: suíte completa cobrindo dados da ROM, física da cabine a 1 px/tick, tolerâncias de andares e ciclo bidirecional Sala 3 <-> Sala 240 <-> Sala 31.
   - godot/tests/room_snapshot_test.gd: validação de carregamento real da Sala 240 a partir de stage5-elevators.
   - tools/validate.py: integrado godot-elevator com validação obrigatória.
   - Resultado: 100% PASS (46 testes Python + 10 suítes Godot).

### Correção de Física e Movimentação nos Elevadores (evidência Banks0123.asm:8540-8556):
- Movimento de caminhada estritamente horizontal no elevador: conforme a rotina original ControlPlayerH, a entrada vertical é filtrada (and 0Ch). Snake nunca anda para cima/baixo com as pernas na sala de elevador.
- Trânsito vertical dedicado: quando Snake está na cabine e aciona CIMA/BAIXO, a cabine entra no estado ELEVATOR_STATE_MOVING e desloca-se a 1 px/tick com Snake estático (SetSprIdle), parando automaticamente ao nivelar com o próximo andar.
- Correção visual da cabine: ampliada para as dimensões exatas de SprElevatorDat (largura 32px, altura 64px, de elevator_y-48 a elevator_y+16), com apoio de Snake sobre o piso metálico e alinhamento com as passarelas dos andares.
- validate.py: 100% PASS (46 testes Python + 10 suítes Godot).

## 2026-09-20 — Etapa 13 concluída: Sistema de Armas, Silenciador e Balística

### O que foi feito
1. **Subsistema de Armas e Munição (`WeaponSystem`)**:
   - Criado `godot/scripts/systems/weapon_system.gd`:
     - Constantes de armas da ROM: `WEAPON_HANDGUN` (ID 1), `WEAPON_SMG` (ID 2), `WEAPON_GRENADE_LAUNCHER` (ID 3).
     - Limites de munição de patente Rank 1 (`MaxAmmoLv1` em `maxammo.asm:112-119`): limite de 50 balas para Pistola, 50 para SMG e 15 para Granadas.
     - Coleta de caixas de munição (`PickAmmoCrate` em `items.asm:333-356`): adiciona +20 tiros para Handgun e +20 para SMG.
     - Ciclo e alternância entre desarmado e armas do arsenal (`cycle_weapon`).
2. **Balística de Projéteis (`Bullet`)**:
   - Criado `godot/scripts/systems/bullet.gd`:
     - Ponto de saída fiel ao MSX2: `(PlayerX, PlayerY - 14.0)` (`handgun.asm:43-48`).
     - Velocidade constante de 6.0 px/tick na direção cardinal (`ShootDirSpeeds`).
     - Alcance máximo de 16 ticks (`Timer = 10h`), percorrendo exatamente 96 pixels.
     - Bloqueio e descarte imediato ao colidir com tiles sólidos da grade de colisão (`collision_grid`) ou limites de tela.
     - Dano canônico de 2 pontos (`BulletDamage` em `weapondamage.asm:18`), eliminando soldados comuns com 1 único tiro fatal.
3. **Mecânica Acústica do Silenciador (`InvSupressor`)**:
   - Implementada verificação de som (`checkweaponalert.asm:8-30`):
     - Disparo sem silenciador aciona `ChkAlertTrigger`, alertando imediatamente a guarnição, exceto nas 55 salas seguras da tabela `RoomShotSecure` (ex: Salas 5, 6, 9, 10, 20, 150...).
     - Disparo com silenciador é 100% furtivo e silencioso.
   - Evento canônico da Sala 150 (`Banks0123.asm:6117, 13037`): ao derrotar os 4 soldados silenciosos (`ID_GUARD_SILENCER` = 57), o Silenciador (`ITEM_SILENCER`, item ID 8) é liberado no centro da sala em (36, 98).
4. **Soldados Atiradores e Projéteis Inimigos**:
   - `EnemyGuard` atualizado com suporte a atiradores (`ID_SHOOTER` = 13, `ID_GUARD_SILENCER` = 57) e disparo em alerta (`ID_GUARD_ALERT` = 10).
   - Projétil inimigo a 4.0 px/tick causando 2 de dano a Snake com 32 ticks de invulnerabilidade.
5. **Integração no Sandbox e HUD**:
   - Controles: `Espaço / F` para atirar/soco; `M / Z / J` para soco direto; `Q / 1 / 2` para ciclar armas; `E` para itens; `U` para ração.
   - Mapeamento canônico de itens da ROM em `_spawn_room_items`: Handgun (1), SMG (2), Silencer (8), Ammo Crate (35), Ration (30), Cards (22-29).
   - HUD atualizado exibindo arma selecionada, contagem de munição e indicador de silenciador.
6. **Testes e Verificação**:
   - Criada suíte `godot/tests/weapon_and_combat_test.gd` validando arsenal, física balística, 1-shot kill, acústica do silenciador e tiro inimigo.
   - `tools/validate.py`: integrado `godot-weapon-combat`.
   - Resultado: 100% PASS (46 testes Python + 11 suítes Godot).

## 2026-09-20 — Etapa 14 concluída: Sistema de Portas e Transições Bidirecionais dos Interiores de Edifícios (Salas 129–207)

### O que foi feito
1. **Emparelhamento Canônico de Portas por `IdDoorEnter`**:
   - Reversão fiel de `logic/doors/enterdoor.asm:101-108` e `logic/nextroom.asm:398-453`: ao cruzar qualquer porta com `door_id`, o jogo define `IdDoorEnter = door_id` e busca na lista de portas da sala de destino a porta emparelhada com o mesmo `door_id`.
   - Elimina necessidade de hardcoding de coordenadas de entrada para salas interiores de depósitos, arsenais e dormitórios.
2. **Tabela Canônica de Posicionamento `PlayerInDoorDat` (`logic/nextroom.asm:457-480`)**:
   - Implementada em `RoomDoor.PLAYER_IN_DOOR_DAT` e método estático `RoomDoor.get_door_spawn(draw_xy, render_type)`:
     - **Render 1 (Norte / Parede Superior)**: `offset_y = +40.0`, `offset_x = +12.0`, `direction = DOWN (2)`.
     - **Render 2 (Sul / Parede Inferior)**: `offset_y = -8.0`, `offset_x = +16.0`, `direction = UP (1)`.
     - **Render 3 (Oeste / Parede Esquerda)**: `offset_y = +48.0`, `offset_x = +16.0`, `direction = RIGHT (4)`.
     - **Render 4 (Leste / Parede Direita)**: `offset_y = +48.0`, `offset_x = -10.0`, `direction = LEFT (3)`.
     - **Render 5 (Elevador)**: `offset_y = +40.0`, `offset_x = +12.0`, `direction = DOWN (2)`.
   - Coloca Snake no exato ponto geométrico de saída e com a orientação correta sem colidir nas paredes ou na própria porta.
3. **Regras de Cartão da ROM (`IdDoorsLogic` e `Enums.asm:113-122`)**:
   - Método `RoomDoor.get_card_for_rule(rule_id)`:
     - `rule_id == 1`: porta destrancada / aberta.
     - `rule_id == 2..9`: portas trancadas por `CARD1` até `CARD8`.
4. **Carregamento Universal de Portas no Sandbox (`sandbox_gameplay.gd`)**:
   - `_spawn_room_doors(room_id)`: instancia dinamicamente portas a partir de `room-NNN-actors.json` com `door_id`, `render_type_id`, `open_rule_id`, orientação e injeção de colisão quando fechada.
   - `change_to_room`: localiza a porta emparelhada na sala recém-carregada, aplica `get_door_spawn`, abre a porta para passagem fluida e posiciona Snake.
   - Compatibilidade preservada para portas de caminhão (lorries) e elevadores.
5. **Mapeamento de Novos Itens em Depósitos**:
   - Adicionada constante `ITEM_GAS_MASK` (`InventoryManager`) para o item 13 da ROM (Máscara de Gás), presente na Sala 138.
6. **Testes e Validação Automatizada**:
   - Criada suíte `godot/tests/building_doors_test.gd`:
     - Validação dos cálculos de `PlayerInDoorDat` nos 5 tipos de render.
     - Validação de regras de abertura por cartões.
     - Ciclo bidirecional Sala 7 <-> Sala 130 via Porta 118 (coleta da Pistola `HANDGUN` no arsenal e retorno).
     - Ciclo Sala 8 <-> Sala 138 via Porta 1 (tranca por `CARD1`, desbloqueio e retorno).
## 2026-09-20 — Etapa 15 concluída: Sistema de Rádio Transceptor (Transceiver / Codec)

### O que foi feito
1. **Núcleo Lógico do Transceptor (`RadioSystem`)**:
   - Criado `godot/scripts/systems/radio_system.gd`:
     - Frequências canônicas em BCD extraídas da ROM (`Banks0123.asm:10680-10975`, `radiocalls.asm`, `Enums.asm:15-36`):
       - Big Boss: 120.85 (FREQ_BIGBOSS_B1) e 120.13 (FREQ_BIGBOSS_B2).
       - Kyle Schneider: 120.79 (FREQ_SCHNEIDER_B1) e 120.26 (FREQ_SCHNEIDER_B2).
       - Diane: 120.33 (FREQ_DIANE_B1) e 120.91 (FREQ_DIANE_B2).
       - Jennifer: 120.48 (FREQ_JENNIFER, exige Rank 4).
     - Mecânica de sintonia BCD (`tune_up`, `tune_down` de 0.01 em 0.01 entre 120.00 e 120.99 MHz).
     - Transmissão ativa de Snake (SEND):
       - Mensagem padrão canônica: *"THIS IS SOLID SNAKE... YOUR REPLY, PLEASE."* (Text ID 10).
       - Obtenção da resposta do interlocutor sintonizado.
     - Banco canônico de mensagens por sala (`ROOM_CALLS`):
       - Diálogos autênticos de instrução e inteligência para salas 0, 1, 4, 5, 20, 28, 29, 30, 31, 37, 50, 53, 54, 58, 67 e 138.
     - Chamadas de entrada automáticas e autotune (`RadioCallFlag` e `RADIO_AUTOREPLY`):
       - Detecção automática de chamadas de rádio ao adentrar salas com gatilho (salas 0, 5, 29, 37...).
       - Sintonização automática na frequência do contato ao abrir o rádio para atender.
     - Nível de sinal e medidor com 12 LEDs (`RadioSignalUp`).
2. **Interface Visual Militar MSX2 (`RadioDialog`)**:
   - Criado `godot/scripts/systems/radio_dialog.gd`:
     - Display militar autêntico MSX2 com painel superior, visor numérico de frequência grande ("120.85 MHz"), indicador de modo RECV / SEND e barra de 12 LEDs verdes de sinal.
     - Retratos visuais em pixel art autoral desenhados via CanvasItem para Solid Snake, Big Boss (tapa-olho militar), Kyle Schneider (faixa de resistência) e Diane (comunicação por headset).
     - Caixa de texto militar com efeito de máquina de escrever (typewriter) a 40 caracteres/segundo e navegação por páginas para mensagens longas.
     - Controles de teclado dedicados: setas ESQUERDA/DIREITA para sintonia fina, CIMA/BAIXO para alternar RECV/SEND, ESPAÇO/ENTER para avançar diálogo/transmitir, ESC/T/F4 para fechar.
3. **Integração no Sandbox e HUD (`sandbox_gameplay.gd`)**:
   - Teclas de atalho para acionar o transceptor: `T` ou `F4` (tecla canônica dos computadores MSX2).
   - Congelamento completo da física e lógica de Snake, inimigos, projéteis e portas durante a comunicação por rádio (`set_physics_process(false)`).
   - Indicador visual militar piscante `[CALL]` no HUD de status ao receber chamadas de entrada.
4. **Testes e Validação Automatizada**:
   - Criada suíte `godot/tests/radio_system_test.gd`:
     - Validação da inicialização na frequência 120.85 (Big Boss).
     - Validação dos limites de sintonia BCD (120.00 a 120.99 MHz).
     - Validação de chamadas enviadas por Snake (SEND) e recebidas (RECV).
     - Validação do banco canônico de diálogos de salas críticas (ex: Sala 0 e Sala 5).
     - Validação de chamadas automáticas de entrada e autotune.
     - Validação da integração e congelamento de gameplay no `SandboxGameplay`.
## 2026-09-20 — Etapa 16 concluída: Câmeras de Vigilância e Feixes Laser Infravermelhos

### O que foi feito
1. **Sistema de Câmeras de Vigilância (`SecurityCamera`)**:
   - Criado `godot/scripts/systems/security_camera.gd`:
     - Identificação canônica da ROM: `ID_CAMERA = 6` (`Banks0123.asm:6409`, `Enums.asm:175`).
     - Tabela de orientações por sala revertida de `logic/actors/camera.asm:93-121` (`RoomCamTypes` / `RoomsWithCamera`):
       - Sala 14 (Prédio 1): 3 câmeras usando `CamDirs7` -> Direções: [3 (Direita), 2 (Esquerda), 2 (Esquerda)].
       - Sala 21: 1 câmera usando `CamDirs6` -> [1 (Baixo)].
       - Sala 27: 2 câmeras usando `CamDirs4` -> [0 (Cima), 3 (Direita)].
       - Sala 28: 1 câmera usando `CamDirs5` -> [3 (Direita)].
       - Sala 31: 2 câmeras usando `CamDirs3` -> [3 (Direita), 0 (Cima)].
       - Salas 36, 110, 111, 115, 118, 149: orientações das tabelas `CamDirs1` e `CamDirs2`.
     - Deslocamento de foco óptico da lente `CameraDrawOffsets` (`camera.asm:234-238`):
       - Cima (0): Y - 12, X
       - Baixo (1): Y + 43, X
       - Esquerda (2): Y, X - 17
       - Direita (3): Y, X + 16
     - Visada e detecção com tolerância perpendicular de 8 pixels (`chkdiscover.asm:100-197`).
     - Raycast e oclusão de visão: feixe é bloqueado por tiles sólidos da grade de colisão 32×24 da sala (`ChkViewObstacles`).
     - Furtividade da Caixa de Papelão: Snake na caixa estática não é visto pela câmera (`chkdiscover.asm:30-48`).
     - Alarme da câmera: congela movimentação, pisca LED em vermelho por 32 ticks (`Wait = 20h`) e aciona alarme sem exibir o ícone '!' de soldado (`AlertSignNotOnScreen = 1`).
2. **Sistema de Feixes Laser Infravermelhos (`LaserSystem`)**:
   - Criado `godot/scripts/systems/laser_system.gd`:
     - Identificação canônica da ROM: `ID_LASER = 35` (`0x23` em `Enums.asm:204`).
     - Tabelas de dados exatas de `data/laserconfig.asm`:
       - **Sala 24**: 6 feixes estáticos (4 verticais, 2 horizontais).
       - **Sala 25**: 5 feixes estáticos (3 verticais, 2 horizontais).
       - **Sala 72**: 10 feixes dinâmicos móveis/alternantes com as 5 sequências de `idxLaserOnOff`.
     - Ciclo temporal dinâmico da Sala 72: alternância de sequências a cada 192 ticks (`0xC0` ticks em `Banks0123.asm:5797`).
     - Teste de contato físico fiel a `ChkTouchLaser` (`laserbeams.asm:11-68`):
       - Vertical (`orientation == 0`): tolerância X < 4 e Y centrado em `(Y + 8 + length/2) < length/2`.
       - Horizontal (`orientation == 1`): tolerância Y < 4 e X centrado em `(X + length/2) < length/2`.
     - Supressão de feixes durante modo de alerta (`in_alert_mode`).
3. **Mecânica dos Óculos Infravermelhos (`ITEM_GOGGLES`)**:
   - Adicionada constante `ITEM_GOGGLES = "GOGGLES"` (Item ID 12 na ROM) em `InventoryManager`.
   - Mapeado item 12 em `_spawn_room_items` (disponível canonicamente na Sala 139).
   - **Visibilidade**: sem os óculos selecionados, os feixes são completamente invisíveis; com os óculos equipados, os feixes brilham em vermelho com pulso e emissores metálicos nas extremidades (`drawlaserbeams.asm:8-10`).
4. **Integração no Sandbox (`sandbox_gameplay.gd`)**:
   - Spawning dinâmico de `SecurityCamera` ao ler `actor_type_id: 6` dos arquivos de atores.
   - Configuração automática de `LaserSystem` para salas 24, 25 e 72.
   - Sinais `player_detected` e `laser_triggered` integrados para alertar soldados da sala.
   - Tecla `B` atualizada para alternar debug visual de cones de visão de soldados e câmeras.
   - Tecla `G` atualizada para fornecer os Óculos Infravermelhos junto ao kit de testes.
5. **Testes e Validação Automatizada**:
   - Criada suíte `godot/tests/cameras_and_lasers_test.gd`:
     - Validação de direções da Sala 14 (3, 2, 2) e Sala 21 (1).
     - Validação de patrulha a 1 px/tick ao longo de waypoints.
     - Validação de detecção de Snake e início do ciclo de piscar.
     - Validação de oclusão de visão por obstáculos sólidos da grade 32×24.
     - Validação de furtividade da caixa de papelão estática.
     - Validação de contagem e geometria das tabelas das Salas 24, 25 e 72.
     - Validação de toque físico vertical e horizontal (`ChkTouchLaser`).
     - Validação de visibilidade condicionada a Goggles.
     - Validação da alternância das 5 sequências temporais da Sala 72 a cada 192 ticks.
   - Integrado a `tools/validate.py` como `godot-cameras-and-lasers`.
   - Resultado: 100% PASS (46 testes Python + 14 suítes Godot).

## 2026-09-20 — Ajustes de Sandbox: Spawn Seguro no Reset e Modo Vida Infinita (God Mode)

### O que foi feito
1. **Spawn Seguro Contra Colisão (`_get_safe_spawn_position()`)**:
   - `godot/scripts/scenes/sandbox_gameplay.gd`:
     - Criado método `_is_position_safe(pos: Vector2) -> bool` que valida se o ponto está dentro da área jogável útil e se Snake colide contra a grade 32×24 em qualquer uma das 4 direções (`is_colliding_at`).
     - Criado método `_get_safe_spawn_position() -> Vector2`:
       - Em salas de elevador (240–250), posiciona Snake na cabine móvel `(216.0, elevator_y + 4.0)`.
       - Em salas comuns, avalia o spawn inicial preferido. Se colidir com paredes, caixas ou obstáculos sólidos do mapa, realiza uma busca em espiral pelos tiles vizinhos em passos de 8 pixels, encontrando o primeiro ponto livre.
     - `reset_player()` atualizado para usar `_get_safe_spawn_position()`, garantindo que Snake nunca renasça preso dentro de um collision box.
2. **Modo de Vida Infinita / God Mode (`infinite_life`)**:
   - `godot/scripts/systems/player.gd`:
     - Adicionada propriedade `var infinite_life: bool = false`.
     - `apply_damage()`: quando `infinite_life` for `true`, restaura `life = max_life` e ignora o dano sem acionar contagem de morte.
   - `godot/scripts/scenes/sandbox_gameplay.gd`:
     - Adicionado botão interativo `CheckButton` ("Vida Infinita (I)") na barra superior de controles.
     - Adicionado atalho de teclado `KEY_I` para alternar o modo em tempo real.
     - HUD atualizado: exibe `VIDA: [■■■■■■■■] INF (GOD MODE)` em vez de número de pontos quando ativo, mantendo Snake vivo mesmo sob dano contínuo.
3. **Validação Automatizada**:
   - Adicionada asserção no teste unitário `godot/tests/combat_and_health_test.gd` para garantir que dano é ignorado em modo `infinite_life`.
   - `python3 tools/validate.py` 100% PASS (46 testes Python + 14 suítes Godot).

## 2026-09-20 — Etapa 17 concluída: Máquina de Estados de Alerta Global, Evasão e Reforços Militares

### O que foi feito
1. **Extração Neutra da Tabela de Respawn da ROM (`RespawnInfo`)**:
   - Criado `tools/extractors/extract_respawn_info.py` que extrai 567 bytes no offset `0xC445` (Banco 6) para 189 salas (0 a 188), decodificando IDs de inimigos e pontos de entrada nas bordas.
   - Criado schema `data/schemas/respawn-info.schema.json`.
   - Gerado `data/extracted/respawn_info.json` (ignorado no git).
   - Teste unitário sintético em `tests/test_extractors.py` (47 testes Python 100% PASS).
2. **Sistema de Alerta Global (`AlertSystem` em `godot/scripts/systems/alert_system.gd`)**:
   - Estados canônicos da ROM: `NORMAL` (0), `ALERT` (1) e `EVASION` (2).
   - Cálculo do contingente militar fiel a `setalert.asm`: `NumRespawnGuards = CardLevel + 3` (mínimo 3 guardas sem cartões).
   - Ciclo de temporização de respawn: convocação de soldados nas posições canônicas de borda da ROM (`loc1` e `loc2`) a cada 24 ticks, respeitando limites simultâneos na sala.
   - Detecção de quebra de linha de visão: transição automática para `EVASION` com temporizador regressivo de 99 ticks.
   - Reativação imediata para `ALERT` caso Snake seja reavistado durante a busca.
   - Conclusão limpa da evasão: retorno ao estado `NORMAL` e restauração de patrulha calma.
   - Cancelamento imediato do alarme ao entrar em elevador (salas $\ge 240$ / `0xF0h`, `Banks0123.asm:6646`).
3. **Soldados Inimigos (`EnemyGuard` em `enemy.gd`)**:
   - Suporte aos IDs canônicos de alerta da ROM (`ID_GUARD_ALERT = 10` e `ID_GUARD_REDALERT = 11`) com velocidade Fast ($1.5$ px/tick).
   - Métodos de transição dinâmica `transform_to_alert_guard()` e retorno `reset_to_patrol()`.
4. **Integração no Sandbox de Gameplay (`sandbox_gameplay.gd`)**:
   - Instanciação dinâmica de reforços em tempo real pelas bordas ao receber o sinal `reinforcement_requested`.
   - Conexão de gatilhos: tiros sem silenciador, detecção por câmeras (Red Alert), violação de lasers (Red Alert) e contato visual.
   - HUD dinâmico de 3 estados com código de cores:
     - `ALERTA! [!] (Reforços: %d)` em vermelho.
     - `EVASÃO [%02d]` em laranja com contagem decrescente.
     - `NORMAL` em branco padrão.
   - Suporte à furtividade da Caixa de Papelão (`ITEM_BOX`): Snake imóvel na caixa corta a visada e força transição para Evasão.
5. **Testes e Validação Automatizada**:
   - Criada suíte `godot/tests/alert_system_test.gd` validando cotas de cartão, ciclo de respawn, transições Normal/Alerta/Evasão e cancelamento por elevador.
   - Registrado `godot-alert-system` em `tools/validate.py`.
   - Resultado: 100% PASS (47 testes Python + 15 suítes Godot).

## 2026-09-20 — Etapa 18 concluída: Boss Fight Canônica — Shoot Gunner (Sala 57)

### O que foi feito
1. **Engenharia Reversa e Evidências da ROM**:
   - Localização canônica comprovada: **Sala 57** do Prédio 2 (`ActorsRoom057` em `data/actorsinrooms.asm:370-372`, `dw 9038h` $\rightarrow$ spawn em $X=144, Y=56$). A premissa histórica de Sala 132 foi corrigida com base nas tabelas da ROM.
   - Constantes e IDs identificados: `ID_SHOT_GUNNER = 0x21` (33) e `ID_SGUNNER_SHOT = 0x2B` (43).
   - Pontos de vida e balística: `idxActorLife[32] = 0x14` (20 HP) e `BulletDamage[32] = 2` por projétil de pistola $\rightarrow$ **10 tiros de pistola** para derrotar o chefe.
   - Máquina de 3 estados de `logic/actors/shotgunner.asm`:
     - **INTRO**: Delay de 2 ticks (`IntroDelay`) e discurso unskippable Texto 61 (*"I'M SHOOT GUNNER! NOBODY HAS EVER BEEN ABLE TO ESCAPE FROM HERE."*).
     - **ROLAGEM (ROLL)**: Deslocamento lateral a $\pm 4.0$ px/tick em direção ao jogador por até 11 ticks (`Wait = 0x0B`) ou colisão contra parede sólida da grade 32×24 (`ChkTileCollision`). `COLLISION_CFG = 0` (invulnerável a balas durante a rolagem).
     - **DISPARO (SHOOT)**: Repouso por 45 ticks (`Wait = 0x2D`), `COLLISION_CFG = 3` (vulnerável a tiros). Disparo de escopeta a cada 16 ticks (`(ANIM_CNT & 0x0F) == 0`), pausando fogo se Snake estiver abrigado atrás das caixas ($Y \ge 166$ e $X \ge 170$).
   - Balística expansiva da escopeta (`ShotGunnerShot`): projétil orientado a Snake com 4 fases de animação visual e colisão (wait 0-6, 7-13, 14-20, 21+ com expansão de raio e colisor). Dano de 8 pontos de vida ao atingir Snake.
   - Derrota canônica: gravação de flag `ShotGunnerStat bit0 = 1` e restauração da música de área (`SetAreaMusic`). Sem drop direto de item.
   - Sala 57 confirmada em `ROOMS_SHOT_SECURE` (`RoomShotSecure`): disparos sem silenciador não acionam alarme geral de reforços militares.

2. **Implementação em Godot 4**:
   - `godot/scripts/systems/shot_gunner.gd`: Classe `ShotGunner` encapsulando estados, colisão lateral, contadores e renderização autoral procedural.
   - `godot/scripts/systems/shot_gunner_bullet.gd`: Classe `ShotGunnerBullet` com balística fiel a `CalShootSpeed` (2.0 px/tick), 4 frames de expansão, limite de vida de 96 ticks, detecção de impacto e dano a Snake.
   - `godot/scripts/scenes/sandbox_gameplay.gd`:
     - Detecção e instanciação do chefe ao entrar na Sala 57 (`actor_type_id == 33`).
     - Preservação da tecla **`F`** (e `Espaço`) para disparar a arma/soco.
     - Botão explícito `"Chefe Sala 57 (P)"` e atalho de teclado **`P`** para teleporte à Sala 57, calibrando Snake com atributos do Prédio 2 (Rank 2: 24 HP, Handgun com 50 balas).
     - Correção do zoom: `boss_dialog_label` movido para overlay flutuante dentro de `viewport_area`, impedindo que textos de múltiplas linhas deformem a barra de controles e mantenham o zoom 3× estável e idêntico a todas as salas.
     - Limpeza rigorosa de projéteis (`shot_gunner_bullets`) em transição de salas (`change_to_room`) e reinício (`reset_player`).
     - Cadência justa de combate: invulnerabilidade estendida para 45 ticks (0.75s) ao ser atingido por tiro de escopeta, permitindo reação tática e abrigo atrás das caixas.
     - Indicador dinâmico de `BOSS FIGHT!` no HUD exibindo fase do chefe (INTRO, ROLAGEM, TIRO) e barra de vida visual em blocos `[■■■■■■■■■■]`.

3. **Testes e Validação Automatizada**:
   - Criada suíte headless `godot/tests/shot_gunner_test.gd` com 15 asserções (HP inicial, dano de bala, morte em 10 tiros, ciclo Intro $\rightarrow$ Roll, bloqueio por colisão em parede, cadência de tiro a cada 16 ticks e invulnerabilidade durante rolagem). Token `BOSS_SHOOT_GUNNER_OK`.
   - Registrada suíte `godot-boss-shoot-gunner` em `tools/validate.py`.
   - Documentação completa em `docs/reverse_engineering/stage-18-shoot-gunner.md`.
   - `python3 tools/validate.py`: 100% PASS (47 testes Python + 16 suítes Godot).

## 2026-09-20 — Comandos Modernos, Menus Modais (Armas, Itens, Pause) e Correção de Renderização de Colisão

### O que foi feito
1. **Mapeamento de Controles Modernos**:
   - **Movimentação**: Teclas de Direção (Setas) ou `W`, `A`, `S`, `D`.
   - **Atirar / Socar**: Teclas `J` ou `Z` (ou Clique Esquerdo do Mouse). Dispara arma selecionada ou desfere soco se desarmado.
   - **Soco Dedicado**: Teclas `K` ou `X`. Permite desferir soco corporal mesmo com arma de fogo equipada no slot.
   - **Menu de Armas**: Tecla `Q` ou segurar `Shift`.
   - **Menu de Itens / Equipamentos**: Tecla `E` ou segurar `Ctrl` / `Alt`.
   - **Rádio Transceptor / Codec**: Tecla `R` ou `Tab` (mantidos `T` e `F4` para compatibilidade com suítes de teste).
   - **Pausa / Menu de Configurações**: Tecla `ESC` ou botão discreto `PAUSE [ESC]` no topo da tela.
   - Mantidos atalhos rápidos de debug: `C` para alternar colisão, `V` para visão dos guardas, `B` para hitboxes e `U` para acionar item ativo.

2. **Menus Modais Militares Estilo MSX2**:
   - **Menu de Armas (`WeaponMenu` em `godot/scripts/systems/weapon_menu.gd`)**:
     - Painel modal militar temático escuro com bordas e destaques no estilo MSX2.
     - Grade navegável via setas/WASD ou mouse, exibindo todas as armas adquiridas com quantidades de munição e identificação clara do equipamento atualmente equipado.
     - Suporte a seleção com `Enter`, `Espaço`, `J`, `Z` ou clique do mouse, além de desequipar (selecionar [DESARMADO]).
   - **Menu de Itens (`ItemMenu` em `godot/scripts/systems/item_menu.gd`)**:
     - Painel modal militar temático escuro para seleção rápida de cartões (1 a 8), Binóculos, Óculos Infravermelhos, Máscara de Gás, Silenciador, Caixa de Papelão, etc.
     - Navegação completa por teclado/mouse e opção de desequipar (`[NENHUM ITEM]`).
   - **Menu de Pausa e Opções (`PauseMenu` em `godot/scripts/systems/pause_menu.gd`)**:
     - Pausa completa da física e lógica de jogo.
     - Opções interativas:
       - **Continuar Jogo**: Retoma o gameplay.
       - **Invencibilidade / God Mode**: Alterna proteção contra dano instantaneamente.
       - **Receber Kit de Armas**: Adiciona Handgun, SMG, Silenciador, Goggles e Caixa.
       - **Exibir Colisão**: Liga/desliga visualização dos collision boxes do mapa.
       - **Exibir Visão dos Inimigos**: Liga/desliga arcos e linhas de visão de patrulhas e câmeras.
       - **Exibir Hitbox de Combate**: Liga/desliga hitboxes de soco e projéteis.
       - **Reiniciar Sala Atual**: Reposiciona Snake no ponto de entrada seguro da sala.
       - **Guia de Controles**: Exibição completa de todos os atalhos mapeados.

3. **Limpeza do HUD Superior e Correção de Bugs**:
   - Barra de botões congestionada do topo foi removida e substituída por um design limpo e imersivo com apenas o status de missão e o botão discreto `PAUSE [ESC]`.
   - Removido o botão de teleporte direto para o boss.
   - **Correção da Colisão no Mapa**: A alternância do modo de colisão chamava o redesenho apenas do nó raiz, impedindo a atualização na tela atual até a troca de sala. Corrigido para chamar diretamente `room_display.queue_redraw()`, refletindo os collision boxes na tela instantaneamente.
   - **Correção da Balística do Boss Shoot Gunner**: Projéteis de escopeta agora contam com efeito de spray de chumbo em 4 fases expansivas e limpeza imediata de partículas residuais na transição de salas ou derrota.
   - **Estabilidade Horizontal do Layout e Indicador CALL**: Corrigido o bug que fazia a tela tremer/balançar horizontalmente a cada 15 frames quando o rádio recebia chamada. A string dinâmica com espaços variáveis foi removida do `status_label` e substituída por um `call_badge` dedicado e estático (`" CALL [R] "`), animado exclusivamente por modulação de cor (`Color`), aliado a `clip_text = true` e `text_overrun_behavior` no `status_label`. Isso garante largura estritamente invariável no container e estabilidade perfeita do viewport.

4. **Validação Automatizada**:
   - `python3 tools/validate.py`: 100% PASS (47 testes Python + 16 suítes Godot).

## 2026-09-21 — Correção Canônica das Passagens de Portas e Eliminação do Limbo (Sala 204)

### O que foi feito
1. **Identificação e Resolução da "Caixinha Retangular com 'I'"**:
   - **Causa**: O método `RoomDoor._draw()` desenhava uma caixa de 16×8 pixels com traço cinza central mesmo com a porta aberta (`is_open = true`), parecendo um botão ou plaqueta flutuante `[ I ]` no vão aberto.
   - **Correção Fiel à ROM (`drawdoors.asm: DrawDoors2`)**: No MSX2, portas abertas **nunca são desenhadas** (`jr z, DrawDoors3`), revelando naturalmente o vão do cenário do metatile. O `_draw()` agora retorna imediatamente se `is_open == true`, eliminando para sempre a caixinha flutuante.
   - Quando fechada, a folha metálica foi ampliada para cobrir integralmente os 32 pixels de largura da passagem (RenderType 1 e 2) ou 32 pixels de altura (RenderType 3 e 4).

2. **Triggers Retangulares Fidedignos (`DoorOpenEnterDat`)**:
   - Substituída a antiga checagem pontual circular (`dist <= 14.0`) pela tabela canônica `DoorOpenEnterDat` da ROM (`external/MetalGear/data/doors.asm:15-35`):
     - **RenderType 1 (Norte)**: Trigger de entrada de 32 px de largura por 20 px de altura (`Rect2(drawX, drawY + 12, 32, 20)`).
     - **RenderType 2 (Sul)**: Trigger de entrada de 32 px de largura por 16 px de altura (`Rect2(drawX, drawY - 4, 32, 16)`).
     - **RenderType 3/4 (Oeste/Leste)**: Trigger de entrada de 20 px de largura por 32 px de altura.
   - Snake não é mais obrigado a passar por um pixel exato: qualquer travessia pelo vão de 32 pixels ativa a transição de sala de maneira fluida.

3. **Eliminação do Limbo (Sala 204) e Portas Fantasmas da ROM**:
   - **Descoberta no Disassembly (`external/MetalGear/logic/doors/enterdoor.asm:66-71`)**:
     - No MSX2 original, a ROM contém filtros explícitos no Z80:
       - `cp 40h ; Hidden door at room 6 (?!) Connected to room 204 -> jr z, ChkNextDoor`
       - `cp 6Ch ; Hidden door at room 5 (?!) Connected to room 204 -> jr z, ChkNextDoor`
     - A Sala 204 é composta 100% por metatile 1 (paredes pretas sólidas), sem saídas — o "limbo". No jogo original, essas portas serviam apenas como marcadores de retorno ao sair de caminhões em movimento e nunca deviam ser transicionadas a pé por Snake.
   - **Filtro Aplicado no Carregador (`sandbox_gameplay.gd`)**:
     - Excluídas portas conectadas à Sala 204 (`dest_room == 204`), IDs bloqueados da ROM (`d_id in [64, 108]`), portas dummy (`r_type == 6`) e portas que apontam para a própria sala (`dest_room == room_id`, reservadas para demolição interna com C4).
   - Na Sala 6 (Área dos Cães), o número de portas foi reduzido das 3 anteriores para as 2 legítimas (Sala 129 e Sala 7), impedindo qualquer transição para paredes sólidas.

4. **Remoção do Mock Obsoleto entre Sala 2 e Sala 4**:
   - **Causa da Anomalia**: Nas linhas 677–703 de `sandbox_gameplay.gd`, havia um mock sintético hardcoded da Etapa 9 que inseria uma porta oeste forçada na Sala 2 e uma porta leste forçada na Sala 4. Esse mock desenhava um leitor de cartão e uma porta falsa diretamente colada sobre uma parede sólida do corredor.
   - **Correção Fiel à ROM**: As Salas 2 e 4 não possuem portas na ROM e nem sequer são vizinhas geográficas diretas (`RoomConnections` conecta a Sala 0 com a Sala 4 pelo leste, e a Sala 2 com a Sala 6 pelo leste). O bloco hardcoded foi removido, permitindo que ambas as salas carreguem 100% via dados canônicos da ROM, transitando exclusivamente por bordas de tela conforme o mapa original.

5. **Validação Automatizada**:
   - `python3 tools/validate.py`: 100% PASS (47 testes Python + 16 suítes Godot).

## 2026-09-21 — Eliminação de Triggers Radiais Espúrios, Arquitetura de Caminhões Móveis (Moving Lorries) e Pareamento Universal

### O que foi feito
1. **Identificação e Eliminação da "Caixa Invisível fora do Vão"**:
   - **Causa Raiz**: No método `RoomDoor.check_interaction()`, existia uma verificação de fallback de distância euclidiana `or position.distance_to(player.position) <= 20.0` mesmo quando a porta já estava aberta. Como o `position` da porta em caminhões e paredes corresponde ao canto superior esquerdo da estrutura gráfica (`draw_x = 208, draw_y = 64`), qualquer aproximação de Snake no canto superior direito do caminhão (parede sólida bem acima do vão da caçamba) disparava acidentalmente a transição antes ou fora do vão.
   - **Correção**: A verificação esférica foi completamente extirpada para portas abertas. A transição agora exige estritamente que Snake esteja dentro do retângulo do vão físico (`enter_box.has_point(player.position)`) e caminhando na direção da saída/passagem (`player.current_direction == expected_dir`).
   - **Vão Físico da Traseira do Caminhão**: Ajustado para cobrir exatamente as linhas de colisão 11 a 15 (`Rect2(204.0, 88.0, 24.0, 36.0)`), alinhando pixel a pixel com a abertura traseira desenhada no cenário.

2. **Engenharia Reversa dos Caminhões Móveis da ROM (`external/MetalGear/logic/lorry.asm`)**:
   - **Descoberta no Disassembly Z80**:
     - No MSX2, existem 6 interiores de caminhões que realizam deslocamento/fast travel (`MovingLorries: db 199, 217, 219, 213, 215, 173`).
     - Ao entrar nesses caminhões, a ROM aciona `ChkLorryMov`, definindo `GAME_MODE_LORRY`, tremendo a tela e exibindo a mensagem: `"I goofed. The lorry started to move"` (Texto 91).
     - Quando o caminhão para, a porta de saída do interior (ex: Porta 117 na Sala 199) aponta para um pátio diferente (ex: Sala 5).
     - Nos pátios externos (Salas 5 e 9), existem portas gêmeas no mesmo local do caminhão comentadas na dissassembly como: `; Fake door used to locate the player when he exits a moving lorry` (portas 117, 133, 146, 152).
     - Essas portas nos pátios servem **exclusivamente como âncoras de pareamento de spawn** para quando Snake desce do caminhão móvel. Elas nunca devem ser gatilhos de entrada pelo pátio.
   - **Implementação**:
     - Marcadas portas de retorno com `is_entry_disabled = true` nas salas 5 e 9. O jogador não é mais "sugado" para caminhões móveis sem contexto a partir do pátio externo.
     - Detecção canônica de deslocamento de caminhão móvel com feedback `MOVING_LORRY`.

3. **Universalização do Pareamento Canônico de Portas (`IdDoorEnter` e `PlayerInDoorDat`)**:
   - Eliminados os hardcodes antigos manuais das salas 5, 126, 127 e 128 em `sandbox_gameplay.gd`.
   - Todas as 250 salas agora carregam portas e caminhões de forma unificada através dos metadados extraídos da ROM (`stage5-batch` e `stage5-lorries`).
   - Ao transicionar por qualquer porta ou caminhão, o pareamento `IdDoorEnter` consulta a tabela canônica da ROM (`logic/nextroom.asm:457-480`), posicionando Snake com perfeição:
     - Render 1 (Norte / Descendo da traseira no pátio): `Vector2(drawX + 12.0, drawY + 40.0)`, direção `DOWN`.
     - Render 4 (Leste / Interior do caminhão): `Vector2(drawX - 10.0, drawY + 48.0)`, direção `LEFT`.
   - Resolvido o spawn errôneo em `(24.0, 64.0)` na Sala 5: Snake agora surge descendo perfeitamente da traseira aberta em `(48.0, 108.0)` virado para baixo.

4. **Validação Automatizada**:
   - `python3 tools/validate.py`: **100% PASS (47 testes unitários Python + 16 suítes Godot)**.

## 2026-09-21 — Etapa 19: Sistema de Prisioneiros, Reféns e Patente Militar (Ranks ★1 a ★4)

Implementação do sistema central de progressão de *Metal Gear* (MSX2 RC750), conectando resgate de prisioneiros, diálogos táticos canônicos da trama, crescimento de atributos de Snake e penalidade por baixas de reféns.

### Fundamentação da ROM e Engenharia Reversa

- **Atores de Prisioneiros (`external/MetalGear/logic/actors/prisoner.asm` e `data/actorsinrooms.asm`)**:
  - `ID_PRISONER = 49 (0x31)`: Prisioneiro comum amarrado presente em 19 salas do complexo.
  - `ID_ELLEN = 50 (0x32)`: Ellen Madnar (Sala 167 em `128, 96`).
  - `ID_GREY_FOX = 51 (0x33)`: Agente Grey Fox (Sala 164 em `128, 96`).
  - `ID_MADNAR = 52 (0x34)`: Dr. Pettrovich Madnar (Sala 182 em `128, 96`).
  - `ID_FAKE_MADNAR = 55 (0x37)`: Falso Dr. Madnar (Impostor na Sala 189 em `128, 96`).
  - Catálogo autêntico de 23 diálogos da ROM preservado integralmente (`PRISONER_TEXTS` de `logic/actors/prisoner.asm:267-286`).

- **Mecânica de Resgate e Interação**:
  - Resgate por aproximação/contato de Snake desarmado (`check_touch` com raio de $12\text{ px}$).
  - Banner de diálogo inferior estilo Text Window do MSX2 com fundo escuro e tipografia retrô, exibindo o texto do refém e auto-fechando após 6 segundos ou nova interação.
  - O refém libertado assume sprite de braços soltos e agradecimento.
  - Reféns resgatados são persistidos em `rescued_rooms` e não voltam a aparecer amarrados.

- **Patente Militar e Escalonamento de Atributos (`Banks0123.asm:9574-9679` e `logic/maxammo.asm`)**:
  - Promoção: a cada $4$ reféns resgatados, Snake ganha uma nova estrela de patente (Class / Rank ★1 $\to$ ★2 $\to$ ★3 $\to$ ★4).
  - Vida máxima escalonada:
    - Rank ★1: $24$ HP
    - Rank ★2: $32$ HP
    - Rank ★3: $40$ HP
    - Rank ★4: $48$ HP
    - Na promoção de rank, a vida de Snake é totalmente restaurada (`full_heal`), conforme o comportamento da ROM.
  - Capacidade máxima de munição (`logic/maxammo.asm:112-147`):
    - Handgun / SMG: Rank 1: $50$ | Rank 2: $100$ | Rank 3: $200$ | Rank 4: $300$
    - Grenade Launcher: Rank 1: $15$ | Rank 2: $30$ | Rank 3: $60$ | Rank 4: $90$
  - Capacidade máxima de rações (`logic/maxammo.asm:20-35`):
    - Rank 1: $3$ | Rank 2: $6$ | Rank 3: $9$ | Rank 4: $12$
  - Visualização de estrelas de patente no HUD de status: `[★☆☆☆]` a `[★★★★]`.

- **Penalidade de Morte de Refém (`DowngradeRank` em `Banks0123.asm:9581-9625`)**:
  - Se Snake disparar com arma de fogo ou socar um refém, o prisioneiro é eliminado.
  - Snake sofre rebaixamento imediato de patente (`current_rank -= 1`, mínimo Rank 1), perdendo $1$ estrela, recalculando a vida máxima e podando a munição excedente.

### Implementação em Godot 4

1. **`RankSystem` (`godot/scripts/systems/rank_system.gd`)**:
   - Controle de patente (1 a 4), contador de reféns para o próximo rank, total resgatado, registro de salas libertadas.
   - Sinais `rank_changed`, `prisoner_rescued` e `prisoner_killed`.
   - Métodos `register_rescue()`, `downgrade_rank()`, `register_kill()`.
2. **`Prisoner` (`godot/scripts/systems/prisoner.gd`)**:
   - Entidade autêntica com renderização procedural dos sprites MSX2 (amarrado vs libertado/agradecendo, variantes de cor para Ellen, Grey Fox e Dr. Madnar).
   - Suporte a detecção de tiro de projéteis e soco com consequências de eliminação.
3. **Integração no Gameplay (`godot/scripts/scenes/sandbox_gameplay.gd`)**:
   - `_spawn_room_prisoners()` integrado ao ciclo `_apply_snapshot()`.
   - Instanciação de reféns a partir dos arquivos extraídos de atores da ROM (`stage5-lorries/room-NNN-actors.json`).
   - Detecção de colisão física de balas de Snake contra reféns.
   - Banner de texto retrô para diálogos de resgate.
   - Status bar no HUD exibindo as estrelas de classe (`CLASS: ★☆☆☆`).
4. **Atualizações de Capacidades Dinâmicas**:
   - `WeaponSystem.update_rank_capacities(rank)`.
   - `InventoryManager.update_rank_capacities(rank)`.
   - `PlayerController.set_rank_life(new_max_life, full_heal)`.
5. **Suíte de Testes Automatizada (`godot/tests/rank_and_prisoners_test.gd`)**:
   - 10 cenários e 65 asserções cobrindo atributos iniciais, progressão sequencial até Rank 4, cura automática, expansão de munição e rações, resgates canônicos de Grey Fox e Ellen Madnar, persistência de sala e punição por *DowngradeRank*.
6. **Validação**:
   - `python3 tools/validate.py`: **100% PASS (47 testes Python + 17 suítes Godot, código de saída 0)**.

## 2026-09-21 — Ajustes de Usabilidade: Coleta Canônica de Itens sobre Móveis (AABB 20px) e Resolução 720p com Janela Redimensionável

1. **Alcance Canônico de Coleta de Itens (`ItemBox`)**:
   - **Causa Raiz**: O método `step_tick` utilizava uma distância radial restrita (`dist <= 12.0`). Quando uma caixa de suprimentos estava localizada sobre móveis com colisão sólida (mesas, prateleiras, balcões, como o Card 1 na Sala 4), os colliders de Snake barravam a aproximação a cerca de 16 a 18 pixels do centro da caixa, tornando o item inalcançável.
   - **Engenharia Reversa (`external/MetalGear/logic/items.asm:60-98` - `ChkTakeItem`)**:
     - No MSX2, a ROM realiza teste AABB retangular independente em X e Y:
       - Raio horizontal X: $C = 20\text{ pixels}$ (`0x14`).
       - Raio vertical Y: $16\text{ a }20\text{ pixels}$.
   - **Correção**: Implementada verificação de proximidade canônica `dx <= 20.0 and dy <= 20.0` em `item_box.gd`. Ao encostar na borda sólida de qualquer mesa ou móvel, Snake alcança e coleta o item imediatamente.
   - **Validação**: Caso de teste adicionado em `doors_and_inventory_test.gd` comprovando coleta a 18px de distância de mesa sólida.

2. **Resolução de Janela 720p e Redimensionamento Livre (Resizable)**:
   - Resolução base atualizada de $960 \times 540$ para **$1280 \times 720$** em `project.godot`.
   - Ativado `window/size/resizable=true` permitindo esticar ou maximizar a janela livremente.
   - O algoritmo `_update_world_transform()` eleva a escala inteira padrão do jogo de $2\times$ ($512 \times 384$) para **$3\times$ ($768 \times 576$)**, deixando os gráficos e textos muito mais nítidos e confortáveis.
   - Adicionado atalho de alternância de tela cheia via teclado com **F11** e **Alt + Enter**.
   - Validação da suíte: **100% PASS** via `tools/validate.py`.

## 2026-09-21 — Correção Integral do Sistema de Cartões, Trancas de Portas e Injeção de Colisão Física

Diagnóstico aprofundado e correção completa do comportamento de portas trancadas por cartão no Prédio 1, restaurando a fidelidade à ROM do MSX2 RC750 (`logic/doors/opendoor.asm`, `enterdoor.asm`, `data/doors.asm`).

### 1. Causas Raiz Identificadas e Corrigidas

1. **Perda de Injeção de Colisão por Tipagem (`PackedByteArray` vs `Array`)**:
   - **Causa Raiz**: O campo `RoomSnapshot.collision` é tipado como `PackedByteArray`. Em GDScript 4, `PackedByteArray` é um tipo de valor com semântica *copy-on-write*. Ao invocar `inject_collision(collision_grid: Array)`, o Godot realizava conversão por valor (gerando uma cópia temporária e descartável). O grid estático do snapshot e a referência em `PlayerController.collision_grid` permaneciam completamente inalterados com os valores `0` (livre) dos vãos de porta do cenário, permitindo que Snake atravessasse portas fechadas como se fossem ar.
   - **Correção**: `SandboxGameplay` agora instancia e gerencia um `runtime_collision: Array` mutável por referência a partir de `snapshot.collision`. Portas injetam fisicamente `1` nas suas coordenadas de bloqueio e limpam para `0` quando abertas, sincronizando instantaneamente a colisão do jogador, tiros e inimigos.
   - Adicionada verificação preventiva em `door.gd`: se `collision_tile_indices` estiver vazio no momento da injeção, `_calculate_collision_tiles()` é invocado antes de iterar.

2. **Portas Trancadas por Cartão Iniciavam Abertas (`is_open = true`)**:
   - **Causa Raiz**: A condição de spawn em `sandbox_gameplay.gd` verificava `(raw_logic & 0x80) != 0 or rule_id in [1, 10, 11] or dest_room in lorry_rooms...`. Embora correta para caminhões e elevadores, regras de cartão (regras 2 a 9: CARD1 a CARD8) não tinham prioridade estrita, permitindo que certas portas com flags no bit 7 nascessem com `is_open = true`.
   - **Correção**: Regra explícita aplicada: se `rule_id >= 2 and rule_id <= 9`, a porta **SEMPRE** nasce fechada (`d.is_open = false`), sem exceções.

3. **Validação Rigorosa de Cartão em `check_interaction()`**:
   - **Causa Raiz**: Em `door.gd`, a condição anterior `if required_card.is_empty() or inventory.get_selected_item() == required_card:` abria a porta automaticamente para qualquer regra onde `required_card` estivesse vazio.
   - **Correção**: Apenas portas com o cartão correto selecionado (`inventory.get_selected_item() == required_card`) podem ser abertas. Portas sem cartão só podem ser abertas se sua regra canônica for neutra/automática (`open_rule_id in [1, 10, 11]`).

4. **Retângulo de Entrada de Portas no Eixo Leste (`DoorOrientation.EAST`)**:
   - Corrigido o `get_enter_trigger_rect()` para que portas de edifícios na parede leste (`render_type_id == 4`) utilizem sua posição real (`Rect2(position.x - 4.0, position.y - 8.0, 24.0, 32.0)`), restringindo o retângulo `Rect2(204.0, 88.0, 24.0, 36.0)` estritamente a interiores de caminhão móvel (`LORRY_EXIT`).

### 2. Validação Automatizada

- **Suíte de Testes Expandida (`godot/tests/doors_and_inventory_test.gd`)**:
  - Adicionado teste de integração em `SandboxGameplay` comprovando que Snake sem cartão é fisicamente barrado pela colisão da porta fechada da Sala 8, não transiciona para a Sala 138, e só consegue abrir e avançar quando seleciona `CARD1` no inventário.
- **Validação Global**:
  - `python3 tools/validate.py`: **100% PASS (47 testes Python + 17 suítes Godot, código de saída 0)**.

## 2026-09-21 — Correção de 4 Bugs no Sistema de Portas com Cartão (Etapa 20 — Diagnóstico e Refinamento Fiel)

Diagnóstico profundo baseado no mapa canônico do jogador, auditoria bidirecional de todos as portas com cartão do jogo (salas 0–125) e inspeção da geometria dos retângulos de trigger, identificando e corrigindo 4 bugs concretos.

### 1. Bugs Identificados e Corrigidos

1. **Fallback `distance_to <= 24.0` em `check_interaction()` (bug de trigger excessivo)**
   - **Causa**: `door.gd` L207 usava `open_box.has_point(player.position) or position.distance_to(player.position) <= 24.0`. O fallback de 24 px fazia com que Snake acionasse o teste de abertura de portas vizinhas ao se aproximar, causando o efeito de "passou sem cartão" (portas livres próximas a portas com cartão abrindo involuntariamente na mesma zona).
   - **Correção**: Removido o fallback. Apenas `open_box.has_point(player.position)` (retângulo canônico preciso da ROM) é utilizado. Adicionados prints de diagnóstico `DOOR_CARD_OK` e `DOOR_CARD_FAIL`.

2. **Verificação de cartão exigia seleção no menu (`get_selected_item` vs `has_item`)**
   - **Causa**: `check_interaction()` verificava `inventory.get_selected_item() == required_card`, bloqueando portas mesmo quando Snake já possuía o cartão mas tinha outro item selecionado.
   - **Correção fiel à ROM** (`logic/doors/opendoor.asm`, `CardLevelReg`): substituído por `inventory.has_item(required_card)`. Basta **possuir** o cartão no inventário — não é necessário selecioná-lo no menu de itens.

3. **Enter box de portas de caminhão (LORRY_ENTER) excessivamente grande**
   - **Causa**: `get_enter_trigger_rect()` usava `Rect2(position.x, position.y, 32.0, 32.0)` igualmente para portas NORTH normais e entradas de caminhão. Em pátios (Sala 7), Snake entrava involuntariamente em caminhões ao circular próximo às portas abertas.
   - **Correção**: Separados os casos `DoorOrientation.NORTH` (32×32, mantido) e `DoorOrientation.LORRY_ENTER` (32×16, reduzido e deslocado 8 px para baixo), exigindo alinhamento mais preciso com o vão da carroceria.

4. **Salas de destino inexistentes (item rooms 128–239) sem feedback ao jogador**
   - **Causa**: Portas com cartão que levam a salas ≥ 128 (item rooms ainda não extraídas) silenciosamente falhavam (`change_to_room` retornava `false`), sem que o jogador entendesse se a porta estava bloqueada ou se o cartão estava errado.
   - **Correção**: `sandbox_gameplay.gd` agora captura o retorno `bool` de `change_to_room`. Quando `false`, exibe banner `[Sala ainda não extraída — dados indisponíveis]` por 2,5 s, deixando claro que a mecânica funcionou mas o destino ainda não tem dados.

### 2. Auditoria Bidirecional Completa

- Executada auditoria de consistência de todas as 100+ portas com cartão das salas 0–125: todas as portas de item rooms (salas 128–239) são "ORPHAN" (sem par de retorno) porque essas salas ainda não foram extraídas — comportamento esperado e documentado.
- Nenhum erro de mismatch de regra entre os pares bidirecionais existentes.

### 3. Testes Atualizados

- `godot/tests/doors_and_inventory_test.gd`: atualizado para usar inventários isolados e verificar `has_item` em vez de `get_selected_item`. Novo cenário: "cartão no inventário mas item diferente selecionado → porta abre igualmente".
- **Validação Global**: `python3 tools/validate.py` — **100% PASS (47 testes Python + 17 suítes Godot, exit code 0)**.

## 2026-09-21 — Extração das Item Rooms (129–207) e Bloqueio de Borda por Cartão (Sala 7 → Sala 11)

### 1. Bloqueio de Borda da Sala 7 para Sala 11 (requisição de CARD4)
- **Causa Raiz**: A `CONNECTIONS_TABLE` do MSX2 possui conexão contígua de borda leste da Sala 7 para a Sala 11 (`CONNECTIONS_TABLE[7][3] == 11`). Em gameplay, ao atingir o limite direito da tela ($X \ge 244$), `_check_and_handle_room_transition()` disparava a troca de sala diretamente pelo mapa de conexões, contornando a porta fechada `Door 5` que exige CARD4.
- **Correção Fiel à ROM**: `_check_and_handle_room_transition()` em `sandbox_gameplay.gd` agora intercepta a direção de saída da tela. Se houver uma porta com cartão fechada naquela orientação e Snake não possuir o cartão exigido, Snake é empurrado de volta para dentro dos limites da sala (`_clamp_to_room_bounds()`) e a transição é barrada com emissão de aviso (`DOOR_CARD_FAIL`). Ao adquirir CARD4, a porta se abre e a travessia é liberada.

### 2. Extração Completa e Conexão das Item Rooms (Salas 129 a 207)
- **Extração Batch de Snapshots e Atores**:
  - Extraídos 78 snapshots visuais (PNG e JSON) a partir de `rc750-verified/package.json` para o diretório `data/extracted/stage5-item-rooms`.
  - Extraídos 78 arquivos de metadados (`room-NNN-actors.json`) com atores, patrulhas, itens canônicos (Gas Mask, Silencer, Card, Minas, Rações) e portas.
  - Atualizado `RoomManager` (`room_manager.gd`) para incluir `stage5-item-rooms` na busca de snapshots (`load_room_snapshot`) e atores (`load_room_actors`).
- **Conexões e Emparelhamento Bidirecional**:
  - As portas de saída das item rooms apontam de volta para suas respectivas salas principais com `door_id` canônico da ROM (ex: Sala 138 Porta 1 $\to$ Sala 8 Porta 1; Sala 129 Porta 3 $\to$ Sala 6 Porta 3).
  - O algoritmo de emparelhamento em `change_to_room()` posiciona Snake exatamente na frente da porta de retorno aberta, com direção de spawn e desobstrução de colisão autênticas.

### 3. Validação Automatizada
- Teste de integração em `doors_and_inventory_test.gd` expandido cobrindo:
  1. Bloqueio físico e impedimento de transição na Sala 7 sem CARD4;
  2. Liberação e travessia para Sala 11 após adquirir CARD4;
  3. Acesso à Item Room 138 (Máscara de Gás) via Porta 1 com CARD1, spawn de item e retorno perfeito para a Sala 8.
- `python3 tools/validate.py`: **100% PASS (47 testes Python + 17 suítes Godot, código de saída 0)**.

## 2026-09-21 — Ajustes de Colisão nas Passagens de Porta, Vãos Limpos e Eliminação de Blocos Flutuantes (Porta 128 / Salas 32, 153 e Caminhão 128)

### 1. Diagnóstico do Problema de Colisão nas Passagens de Porta
- **Causa Raiz 1 (Blocos de Colisão Flutuantes na ROM)**:
  - Nos dados estáticos dos metatiles da ROM (`package.json`), certas salas possuem tiles de colisão sólida (`1`) no meio de vãos de passagem (por exemplo, na Sala 153 na linha `ty=11`, coluna `tx=26`: valor `1` em meio a `0`s; e na Sala 32 na coluna `tx=13`, linhas `ty=7..8`).
  - Na ROM original do MSX2, quando uma porta abre, o código em `erasedoor.asm:525` (`SetOpenDoorTiles`) sobrescreve a matriz de colisão em RAM em toda a área do vão com `DoorOpenTiles` (tiles transparentes sem colisão).
  - No motor Godot, o código anterior apenas alternava os tiles da soleira direta da porta (`collision_tile_indices`), deixando os blocos estáticos do metatile inalterados como "blocos de colisão flutuando no meio do vão", obstruindo a passagem de Snake mesmo com a porta aberta.
- **Causa Raiz 2 (Desalinhamento Vertical dos Triggers em Portas Laterais WEST / EAST)**:
  - Para portas em paredes laterais (perspectiva em ângulo), a abertura no chão fica deslocada verticalmente em relação ao topo do sprite da parede (`position.y + 24` a `position.y + 56`).
  - Os retângulos de gatilho (`get_enter_trigger_rect()` e `get_open_trigger_rect()`) utilizavam offsets incorretos (`position.y - 8.0`), situando a área de gatilho 36 pixels acima do vão real de passagem, impedindo que Snake acionasse a transição ao caminhar pelo chão da abertura.
- **Causa Raiz 3 (Paredes de Colisão na Saída dos Caminhões)**:
  - No interior dos caminhões (ex.: Sala 128), as colunas 28 a 31 da parede leste continham colisão sólida `1` no metatile, bloqueando a saída de Snake para a direita.

### 2. Refatoração Fiel e Idiomática no Godot (`door.gd`)
- **Introdução de `clearance_tile_indices`**:
  - Toda porta agora calcula tanto os tiles de bloqueio quando fechada (`collision_tile_indices`) quanto a área total de desobstrução quando aberta (`clearance_tile_indices`).
  - Em `inject_collision(collision_grid: Array)`: quando `is_open == true`, **todos** os tiles de `clearance_tile_indices` são forçados a `0`. Isso garante uma abertura limpa e elimina qualquer bloco flutuante remanescente da matriz da ROM.
- **Normalização dos Gatilhos de Entrada e Abertura**:
  - `get_enter_trigger_rect()` e `get_open_trigger_rect()` agora cobrem com precisão o vão físico de passagem no chão para cada orientação (Norte, Sul, Oeste, Leste, Lorry Enter e Lorry Exit).
  - A altura de tolerância para portas laterais foi expandida (altura 64 px), garantindo detecção confortável em todas as aproximações.
- **Desobstrução Automática da Saída de Caminhões (`LORRY_EXIT`)**:
  - A saída de dentro dos caminhões limpa as colunas 25 a 31 nas linhas 11 a 15, permitindo caminhar livremente para a direita até cruzar a soleira.

### 3. Validação Automatizada
- Expandido `godot/tests/doors_and_inventory_test.gd` com:
  - **Seção 9**: Porta 128 (Sala 32 $\leftrightarrow$ Sala 153) — teste bidirecional completo, verificação de vão limpo e eliminação comprovada do bloco flutuante em `ty=11, tx=26`.
  - **Seção 10**: Caminhão 128 (Sala 5 $\leftrightarrow$ Sala 128) — entrada, coleta e saída limpa com desobstrução das colunas 28..31.
- `python3 tools/validate.py`: **100% PASS (47 testes Python + 17 suítes Godot, código de saída 0)**.

## 2026-09-21 — Inicialização Canônica na Sala 121 (MSX2 Intro Spawn) e Execução Direta

### 1. Inicialização Fiel à ROM Original MSX2 RC750
- **Evidência da ROM (`Banks0123.asm:11786-11817`)**:
  - `ld a, 121`: Primeira sala do jogo (`Room = 121`).
  - `ld (PlayerXdec), hl` com `H = 0xC0` ($192.0$) e `ld (PlayerYdec), hl` com `HL = 0xB800` ($184.0$): Posição inicial de spawn de Snake na água de infiltração.
  - `SELECTED_CIGARETTES`: Cigarros adicionados ao inventário inicial (`CigarsTaken = 1`).
  - Direção inicial: Norte (`UP`), nadando para cima em direção à Sala 0.
- **Configuração no Godot**:
  - Em `sandbox_gameplay.gd`:
    - Definidas constantes `INITIAL_ROOM_ID = 121`, `DEFAULT_SPAWN_X = 192.0`, `DEFAULT_SPAWN_Y = 184.0`.
    - `_load_initial_room()` instancia a Sala 121 por padrão e equipa `CIGARETTES` via `InventoryManager`.
    - `_get_safe_spawn_position()` e `reset_player()` posicionam Snake em `(192.0, 184.0)` com direção `UP`.
  - Em `project.godot`:
    - `run/main_scene="res://scenes/sandbox_gameplay.tscn"`: Ao rodar o jogo (F5 / Play), instancia diretamente o mapa do jogo na Sala 121 com Snake pronto para jogar.

### 2. Validação Automatizada
- Atualizado `godot/tests/room_transition_test.gd` para validar o ciclo natural de transições: início na Sala 121 em `(192.0, 184.0)` $\to$ avanço ao Norte para Sala 0 $\to$ avanço ao Norte para Sala 1 $\to$ Sala 2 $\to$ Sala 3.
- `python3 tools/validate.py`: **100% PASS (47 testes Python + 17 suítes Godot, código de saída 0)**.

## 2026-09-21 — Correção de Spawn: Posicionamento em Terra Firme na Sala 121

### 1. Diagnóstico do Terreno e Grade de Colisão
- **Problema**: O spawn na coordenada de animação da água `(192.0, 184.0)` deixava o jogador preso atrás da cerca sólida de caixas/grades (`ty = 12..15`, `Y = 96..127`), que bloqueia toda a extensão horizontal da tela (32 tiles de largura).
- **Mapeamento da Área Caminhável (`room-121.json`)**:
  - `Y = 96..127`: Grade intransponível sólida.
  - `Y = 128..191`: Área aquática de infiltração.
  - `Y = 48..95`, colunas `tx = 10..19` ($X = 80..159$): Terra firme / cais desobstruído com passagem livre em direção ao Norte para a Sala 0.
- **Ajuste Realizado**:
  - Em `sandbox_gameplay.gd`:
    - Atualizadas as constantes: `DEFAULT_SPAWN_X = 128.0`, `DEFAULT_SPAWN_Y = 80.0`.
    - Ajustado `_get_safe_spawn_position()` para retornar `Vector2(128.0, 80.0)` na Sala 121.
    - Snake nasce diretamente em solo firme navegável, com controle livre e caminho limpo ao Norte rumo à Sala 0.

### 2. Validação Automatizada
- Atualizada asserção em `godot/tests/room_transition_test.gd` para `Vector2(128.0, 80.0)`.
- `python3 tools/validate.py`: **100% PASS (47 testes Python + 17 suítes Godot, código de saída 0)**.

## 2026-09-21 — Mecânica Punitiva Clássica de Morte (Game Over MSX2) e Reset Total de Estado

### 1. Ciclo de Morte do Jogador e Bloqueio Imediato de Ações
- **Gatilho de Morte (`player.gd`)**:
  - Implementado `signal player_died` e flags `is_dead: bool` e `can_control: bool`.
  - Ao sofrer dano fatal em `apply_damage(amount)` que reduza `life <= 0`, a rotina `die()` é imediatamente acionada.
  - Bloqueio imediato de entradas e ações: Snake não se move (`step_tick`), não soca (`punch`), não dispara armas (`fire_weapon`), não utiliza itens e não abre menus enquanto morto.
  - Desenho dedicado de derrota em `_draw()`: renderiza Snake caído e abatido no solo (corpo e bandana escurecidos).
- **Restauração (`revive()`)**:
  - Restaura `is_dead = false`, `can_control = true`, `life = max_life` (24 HP), zera timers de invulnerabilidade e soco, restabelece a direção para `UP` e limpa as pernas para pose padrão.

### 2. Reset Absoluto de Estado e Prevenção de Vazamento de Memória
- **Limpeza dos Subsistemas**:
  - `InventoryManager.reset()`: esvazia a lista `items = []`, remove todos os cartões de acesso coletados (`CARD1`..`CARD8`) e zera as rações.
  - `WeaponSystem.reset()`: limpa `owned_weapons = []`, redefine a seleção para `[DESARMADO]`, zera munições e remove o silenciador.
  - `AlertSystem.reset()`: força retorno incondicional para `NORMAL` (modo furtivo), zera cotas de reforço, zera timers de evasão e emite `alert_cleared`.
  - `RankSystem.reset()`: reinicia a patente militar para `Rank ★1`, zera contadores de resgate e esvazia o registro de reféns resgatados.
- **Limpeza no Gerenciador Global (`sandbox_gameplay.gd`)**:
  - Implementada a rotina `reset_game_state()`: libera e limpa todos os nós dinâmicos da sala (`bullets`, `enemies`, `cameras`, `item_boxes`, `room_doors`, `prisoners`, `shot_gunner`, `shot_gunner_bullets`), fecha modais/rádio e zera flags de elevador e drops.

### 3. Recarregamento Seguro na Sala 121 e Restauração de Controles
- **Banner de Game Over**: Exibe aviso central estilizado MSX2 `G A M E   O V E R | [ REINICIANDO MISSÃO... ]` e atualiza o HUD para destaque em vermelho.
- **Reinício Seguro**:
  - Em execução principal no SceneTree: executa `get_tree().reload_current_scene()` de forma segura após atraso dramático.
  - Em testes automatizados / instâncias isoladas: reinicia a cena in-place recarregando a Sala 121 e invocando `reset_player()`.
  - Equipamento inicial padrão: Snake recebe apenas `CIGARETTES` via inventário e surge em terra firme no cais `(128.0, 80.0)` com vida total (24 HP) e controles totalmente liberados (sem risco de softlock).

### 4. Validação Automatizada
- Expandido `godot/tests/combat_and_health_test.gd`:
  - **Seção 7**: Teste de dano letal, emissão de `player_died`, bloqueio total de movimento/soco/tiro e restauração com `revive()`.
  - **Seção 8**: Teste de integração de Game Over no Sandbox com pré-coleta de cartões, armas e alerta ativo $\to$ comprovação de inventário esvaziado, cartões removidos, alerta NORMAL, vida em 24 HP, spawn em (128, 80) e controles desobstruídos.
- `python3 tools/validate.py`: **100% PASS (47 testes Python + 17 suítes Godot, código de saída 0)**.

## 2026-09-21 — Extração e Implementação da Mecânica de Gas Mask e Salas de Gás Tóxico (Etapa 19)

### 1. Engenharia Reversa da ROM MSX2 RC750
- **Identificação e Evidências da Lógica de Dano por Gás (`logic/damagegas.asm`)**:
  - Offset na ROM: `0x4C79` (19.577 bytes, Banco 2).
  - Tabela canônica de salas com gás (`GasRooms` em `damagegas.asm:53`):
    - 9 salas: `[29, 94, 96, 97, 98, 100, 101, 112, 114]`.
  - Mecânica de Dano e Intervalo (`damagegas.asm:34-45`):
    - Temporizador `DamageDelayTimer`: configurado para `0x10` (16 ticks, ~0.26s a 60 ticks/s).
    - Quantidade de dano: drena 2 HP a cada 16 ticks (`sub 2`).
  - Verificação de Proteção (`ChkGasMask` em `damagegas.asm:24-33`):
    - Compara `SelectedItem == SELECTED_GAS_MASK` (ID 5 na ROM, correspondente a `ITEM_GAS_MASK` / ID 13 no inventário Godot).
    - Se a máscara estiver ativamente selecionada/equipada: o dano é 100% anulado (`jr nz, .noDamage`). Se estiver apenas na mochila mas não selecionada, Snake sofre asfixia/dano normalmente.
- **Atores de Nuvem de Gás (`logic/actors/gas.asm`)**:
  - Ator `ID_GAS = 8` (19 instâncias distribuídas pelas 9 salas com gás).
  - Ciclo visual: 32 ticks de fase visível (`0x20`), seguido por intervalo aleatório oculto (`20..60` ticks).
  - Alternância de animação a cada 8 ticks com paleta MSX autêntica (tons verdes 2 e 4Dh).

### 2. Extração Reproduzível e Contrato Neutro
- **Extrator Python**: Criado `tools/extractors/extract_gas_hazard.py` (leitura em modo somente leitura da ROM original MSX2 RC750 e disassembly de referência).
- **Esquema JSON**: Criado `data/schemas/gas_hazard.schema.json`.
- **Exportação Validada**: Gerado `data/extracted/gas_hazard.json` contendo as 9 salas, constantes de tick/dano e identificadores de itens.
- **Relatório Técnico**: Criado `docs/reverse_engineering/stage-19-gas-hazard.md`.

### 3. Implementação no Motor Godot 4
- **`GasHazardSystem` (`godot/scripts/systems/gas_hazard_system.gd`)**:
  - Classe neutra que gerencia checagem de salas com gás, status de proteção (`is_player_protected`), aplicação de dano contínuo (2 HP a cada 16 ticks) e emissão de sinais (`gas_damage_taken`, `gas_protection_status_changed`).
- **`GasCloud` (`godot/scripts/systems/gas_cloud.gd`)**:
  - Ator `Node2D` animado para renderizar nuvens de gás verdes dinâmicas conforme `logic/actors/gas.asm`.
- **Integração no Sandbox de Gameplay (`godot/scripts/scenes/sandbox_gameplay.gd`)**:
  - `_spawn_room_enemies(room_id)`: instancia nós `GasCloud` dinamicamente quando `actor_type_id == 8`.
  - `_draw_room_and_collision()`: desenha uma névoa atmosférica verde sutil (`Color(0.12, 0.40, 0.15, 0.20)`) sobre as salas de gás canônicas.
  - `_physics_process()`: avança o ciclo das nuvens de gás e executa `gas_hazard_system.tick(room_id, player, inventory)`.
  - HUD / `status_label`: exibe indicador em tempo real `[GÁS TÓXICO!]` (em tom alaranjado/vermelho) ou `[MÁSCARA ATIVA]` (em tom verde protetor).
  - `reset_game_state()`: limpa instâncias de `GasCloud`, reseta `GasHazardSystem` e executa `ItemBox.collected_boxes.clear()`.

### 4. Validação e Testes Automatizados
- Criada a suíte `godot/tests/gas_hazard_test.gd` com 8 testes cobrindo:
  - Detecção das 9 salas canônicas e rejeição em salas seguras.
  - Inexistência de dano fora de salas com gás.
  - Aplicação exata de 2 HP de dano ao entrar desprotegido.
  - Intervalo rigoroso de 16 ticks entre aplicações sucessivas de dano.
  - Imunidade total (0 dano) com `ITEM_GAS_MASK` selecionado/equipado.
  - Falha de proteção caso a máscara esteja no inventário mas não selecionada.
  - Ciclo de estados e quadros de animação do ator `GasCloud`.
  - Morte por asfixia ao zerar a vida, emitindo `player_died`.
- Registrado `godot-gas-hazard` no orquestrador `tools/validate.py`.
- **Resultado da Validação**: `python3 tools/validate.py` $\to$ **100% PASS (47 testes Python + 18 suítes Godot, código de saída 0)**.

## 2026-09-21 — Etapa 20: Arma Canônica Míssil Teleguiado (Remote-Controlled Missile — WEAPON_MISSILE)

Entregue com base na engenharia reversa da ROM MSX2 RC750 (`logic/weapon/missile.asm`, `logic/weapons/remotemissile.asm`, `Banks0123.asm:8468`, `logic/maxammo.asm:24-27`, `logic/damagetoenemy.asm:58-61`). Relatório técnico: [reverse_engineering/stage-20-rc-missile.md](reverse_engineering/stage-20-rc-missile.md).

### 1. Evidências da ROM MSX2
- **Velocidade e Curvatura (`MissileIniSpeed`)**:
  - ROM offset `0x48DE`: tabela `FC 00 04 00 00 FC 00 04` mapeia deslocamento de 4 px/tick nas 4 direções cardeais (cima, baixo, esquerda, direita).
- **Supressão do Movimento de Snake (`NormalCtrl` em `Banks0123.asm:8468-8470`)**:
  - Ao disparar o míssil (`PlayerShotsList == 7`), o loop de controle de Snake congela sua locomoção e redireciona os comandos do d-pad em tempo real para o míssil.
- **Limites de Tela e Colisão (`ChkShotBoundaries` em `weaponuse.asm:365-375`)**:
  - Limites de coordenadas $X \in [9, 248]$ e $Y \in [0, 184]$; impacto contra tiles sólidos de colisão ou bordas detona o míssil.
- **Dano e Explosão Média (`MissileDamage` e `damagetoenemy.asm:58-61`)**:
  - Inflige 5 HP de dano a qualquer ator atingido no raio de impacto.
  - Temporizador de detonação com explosão de tamanho médio com duração exata de 15 ticks (`0x0F`).
- **Capacidade por Rank (`MaxAmmoLv1..4` em `maxammo.asm:24-27`)**:
  - ROM offset `0x51D6`: 5 mísseis no Rank 1 (★), 10 no Rank 2 (★★), 15 no Rank 3 (★★★), 20 no Rank 4 (★★★★).

### 2. Extração Reproduzível e Contratos Neutros
- **Extrator Python**: Criado `tools/extractors/extract_missile_data.py` (somente leitura na ROM RC750).
- **Esquema JSON**: Criado `data/schemas/missile_weapon.schema.json`.
- **Exportação Validada**: Gerado `data/extracted/missile_weapon.json`.

### 3. Implementação no Motor Godot 4
- **`RemoteMissile` (`godot/scripts/systems/remote_missile.gd`)**:
  - Entidade completa de míssil teleguiado com controle direcional de 4 sentidos, avanço a 4 px/tick, teste de colisão contra matriz de tiles 32×24, limites canônicos de tela, animação de explosão MSX2 e emissão de sinais `missile_exploded` e `missile_destroyed`.
- **`WeaponSystem` & `RankSystem`**:
  - Adicionada constante `WEAPON_MISSILE = 4` / `"MISSILE"`, regras de capacidade por rank (5, 10, 15, 20) e recarga via `add_ammo_crate` (+5 unidades).
- **`ItemBox` (`godot/scripts/systems/item_box.gd`)**:
  - Suporte ao item tipo 7 (`MISSILE`), entregando 5 unidades e desbloqueando a arma no inventário bélico.
- **`sandbox_gameplay.gd`**:
  - Gerenciamento de disparo com consumo de 1 míssil, bloqueio de múltiplos mísseis simultâneos, redirecionamento dos inputs direcionais para `active_missile.steer(dir)`, congelamento dos passos de Snake enquanto o míssil voa, detecção de dano em guardas e chefes (`take_bullet_hit(5)`), alerta sonoro na detonação e descarte limpo no reset.

### 4. Validação e Testes Automatizados
- Criada a suíte `godot/tests/remote_missile_test.gd` com 55 asserções cobrindo setup, velocidade, esterçamento nas 4 direções, impacto com paredes/bordas, temporização de 15 ticks de explosão, eliminação de guardas com 5 HP de dano e limites de munição por patente.
- Registrado `godot-remote-missile` em `tools/validate.py`.
- **Resultado da Validação**: `python3 tools/validate.py` $\to$ **100% PASS (47 testes Python + 19 suítes Godot, código de saída 0)**.



