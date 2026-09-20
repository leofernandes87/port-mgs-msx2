# Transferência para Gemini CLI — 2026-09-20

## 1. Resumo do projeto

Laboratório educacional de engenharia reversa de Metal Gear MSX2 RC750. Código próprio em Python extrai estruturas comprovadas; Godot apresenta uma interface inicial e um visualizador diagnóstico. Não existe jogo reimplementado jogável.

Estado de referência: branch `main`, HEAD `d1210d2` (`feat: valida fundos em openMSX e adiciona visualizador Godot`). Árvore e índice estavam limpos ao iniciar esta transferência; nenhum remoto configurado. A tarefa atual é exclusivamente documentação e verificação. Etapas 1–3 entregues nos escopos delimitados; Etapa 4 entregue no marco de fundos verificados. Etapa 5 não iniciada.

Leia primeiro `GEMINI.md`, `AGENTS.md`, este documento e a última entrada de `docs/progress.md`. Os documentos antigos mantêm conclusões da data em que foram escritos: referências à ausência de emulador ou à Etapa 4 ainda não iniciada são históricas, superadas por `docs/reverse_engineering/stage-4-results.md`.

## 2. Objetivo final

Estudar o original, especificar seu comportamento com evidências e construir uma reimplementação fiel em Godot 4. Posteriormente criar remake com arte própria desenhada à mão e melhorias opcionais, separadas do comportamento fiel. Não presumir permissão para redistribuir ROM, disassembly ou imagens do jogo.

## 3. Arquitetura atual

Fluxo: ROM em leitura → ferramentas Python e referência fixada → pacote JSON validado e PNGs privados → captura RAM/VRAM no openMSX → comparação → snapshot diagnóstico → abertura explícita no Godot.

- Extração 0.1.0 preserva dados originais, derivados e procedência; não depende de Godot.
- Snapshot 1.0.0 contém imagem indexada 256×192, 18 cores nominais e 768 indicadores de colisão estática.
- Implementação Godot não lê ROM nem importa automaticamente recursos privados para `res://`.
- Saídas reais ficam em `data/extracted/`; fixtures próprias ficam em `data/fixtures/` e nos testes.
- Publicação dos extratores exige destino novo dentro da árvore privada; recusa sobrescrita e aliases perigosos. Não executar publicações concorrentes no mesmo destino.

## 4. Tecnologias utilizadas

Reconferidas na transferência: macOS 15.7.7 (24G720), x86_64, Python 3.9.6, Git 2.50.1 (Apple Git-155), Godot 4.7.2.stable.official.ed1daf0bf e openMSX 21.0. Histórico identifica Macmini8,1/Intel UHD Graphics 630.

Python usa somente biblioteca padrão, `unittest`, JSON, hashes e codecs próprios. Godot usa GDScript tipado e GL Compatibility. Captura usa Python/Tcl e máquina `C-BIOS_MSX2_JP` fornecida pelo openMSX. Sjasm não foi usado para montar o executável. Nenhum componente foi instalado nesta transferência.

Executáveis locais fora do PATH:

- `/Applications/Godot.app/Contents/MacOS/Godot`
- `/Applications/openMSX.app/Contents/MacOS/openmsx`

## 5. Histórico resumido das etapas

| Etapa | Entrega e limite |
| --- | --- |
| 1, 19/09 | Estrutura, regras, Git, cena inicial independente de ROM e validação Python/Godot. |
| 2, 19/09 | Identificação das entradas, inventário da referência, bancos, RAM e especificações estáticas; compatibilidade parcial, não identidade integral. |
| 3, 19/09 | Extração de regiões comprovadas, contratos, prévias privadas, reprodução e testes negativos; sem frame dinâmico completo. |
| 4, 20/09 | Captura em demo, comparação de quatro fundos e sete registros de portas, visualizador Godot e integração de imagem. |
| Transferência, 20/09 | Handoff, instruções Gemini e revalidação; nenhuma funcionalidade nova. |

Histórico Git existente: `fe4c755` reúne laboratório/extração; `d1210d2` reúne captura/visualizador. As observações antigas de “nenhum commit nesta etapa” descrevem aquelas entregas, não o HEAD atual.

## 6. Trabalho efetivamente concluído

- Analisador de fontes, checksums, probes únicas, mapeamento limitado de bancos/RAM e metatiles, com rejeição de sintaxe não suportada; não é assembler Z80.
- Extrator: 251 entradas de salas, 235 decodificadas e 16 indefinidas; 172 layouts distintos, seis conjuntos de metatiles, oito tilesets parcialmente carregados, sete perfis de colisão, 16 patches de paleta, 304 ocorrências de portas, 396 atores, 114 caminhos e 60 ocorrências de itens. Ocorrência não significa objeto único nem sala alcançável.
- Codecs próprios: gráficos planares, flip, paleta, PNG e stream limitado UnpackGfx. Não há exportação completa de todas as famílias gráficas.
- Pacotes reproduzíveis: 33 arquivos gerados, incluindo 30 PNGs; dois runs idênticos. `.DS_Store` é listado e excluído apenas do inventário de geração.
- Capturador observa demo natural sem escrever RAM/VRAM/ROM ou mudar PC; verifica SHA e âncoras antes dos breakpoints.
- Comparador exige igualdade do mapa, tiles carregados, registros de portas e fundo estabilizado. Visualizador abre snapshots e alterna overlay estático.

Revalidação nesta transferência: 35 testes Python OK; importação do editor Godot, `SMOKE_OK`, `ROOM_SNAPSHOT_OK` e `BOOT_OK` passaram com código 0. Integração headless da sala 5: `ROOM_INTEGRATION_OK`, 49.152 pixels RGB iguais ao PNG Python. `verify.py` recompôs pacote, conferiu dois runs/33 arquivos, validou contrato/derivados e rejeitou duas entradas negativas em memória. Nenhuma nova captura ou inspeção gráfica foi realizada; capturas e screenshots da Etapa 4 são evidência histórica preservada.

## 7. Descobertas confirmadas sobre a ROM

Referência local: `external/MetalGear`, origem https://github.com/GuillianSeed/MetalGear, revisão `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`. Revisão reconferida; nenhuma alteração rastreada, apenas `.DS_Store` não rastreado preservado. Não foi encontrada licença explícita de redistribuição.

| Entrada privada | Bytes | CRC32 | SHA-256 reconferido |
| --- | ---: | --- | --- |
| `roms/Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom` | 131072 | BE84C94F | `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf` |
| `roms/Metal Gear - Konami (1987) [English Version - Nekura_Hoka v.1.995c] [RC-750] [Translated] [7660].rom` | 163840 | 87EC113E | `89cfeee7d990a6bed050dcffa12ddff179e1632f13450247ee8860587adec6f4` |

CRC32 de referência declarado: japonês FAFE1303, inglês E85C5731; nenhuma entrada coincide. Ambas começam com AB e entrada LE 0x41F3, sem evidência de cabeçalho externo removível. Compatibilidade comprovada em nove segmentos/45.982 bytes, não no executável integral. Offsets e extensões de cada segmento: `reverse_engineering/stage-3-results.md`. Salas/metatiles: 18.176 bytes iguais em 0x1A000.

Evidência estática da revisão: bancos de 8 KiB; janelas em 0x6000/0x8000/0xA000; SCREEN 5; sala normal com 8×6 metatiles de 4×4 tiles = 32×24 tiles de 8×8 pixels. Gráficos principais 3 bpp/24 bytes por tile, planos intercalados por linha, bit 7 à esquerda; flip horizontal por tile. Colisão estática deriva de 32 bytes MSB-first por perfil. Jogador usa coordenadas 8.8 e duas amostras de colisão por direção; atores ocupam 16 slots de 128 bytes; quantidades de inventário usam BCD. Essas observações de código não são testes dinâmicos dessas mecânicas.

Evidência em execução na ROM principal/openMSX/C-BIOS, registrada na Etapa 4:

| Sala | Tileset | Mapa coincidente | Tiles carregados | Fundo coincidente | Portas RAM |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 0 | 768/768 | 235/235 | 49152/49152 | 0 |
| 5 | 0 | 768/768 | 235/235 | 49152/49152 | 5 |
| 31 | 0 | 768/768 | 235/235 | 49152/49152 | 1 |
| 127 | 4 | 768/768 | 158/158 | 49152/49152 | 1 |

RenderRoom: ROM 0x0CF0, CPU 0x4CF0, banco fixo 0; WaitVdpCmd: CPU 0x4ED2, RET 0x4EDB. Room/CurrentTileSet: RAM 0xC130/0xC157; mapa em 0xE000, portas em 0xC3D0 e estados em 0xC450. Referências precisas: `reverse_engineering/stage-4-results.md` e `tools/emulation/README.md`.

Retorno de RenderRoom pode ocorrer com VDP ocupado: três amostras diferiam em 42 pixels; captura após WaitVdpCmd eliminou todas as diferenças. Slots nulos referenciados nessas amostras continham índice 0. Portas foram comparadas como registros RAM, não como animação ou pixels desenhados. RGB do visualizador usa paleta nominal, não paleta dinâmica do frame.

## 8. Hipóteses ainda não confirmadas

- Região/revisão exata, motivo dos CRCs divergentes e equivalência integral ao disassembly.
- Identificação física formal do mapper (padrão compatível com Konami sem SCC); semântica dos quatro bancos extras da tradução.
- Herança de VRAM em outras sequências/transições: não generalizar slots ausentes para zero.
- Associação exata de caminhos por ator/tipo/contador, alcançabilidade de todas as salas e interpretação dos três bytes excedentes de `Path_031_02`.
- Fidelidade de temporização, colisão dinâmica, IA, eventos e frame final; não verificados em hardware MSX físico.

## 9. Arquivos e diretórios relevantes

| Caminho | Finalidade |
| --- | --- |
| `AGENTS.md`, `GEMINI.md` | Regras compartilhadas e entrada do novo agente. |
| `README.md`, `docs/progress.md` | Operação e histórico cronológico, incluindo falhas reais. |
| `docs/reverse_engineering/` | Evidências por sistema, planos e resultados das Etapas 3/4. |
| `tools/reverse_engineering/analyze.py` | Identificação, inventário, parser limitado, bancos/RAM. |
| `tools/extractors/{reference,codecs,extract,schema,verify}.py` | Localização, decodificação, publicação e verificação. |
| `tools/emulation/{capture.py,capture.tcl,compare.py}` | Captura e comparação em execução. |
| `tools/validate.py`, `tests/test_*.py` | Validação integrada e quatro módulos de testes Python. |
| `data/schemas/`, `data/fixtures/` | Contratos e fixtures sintéticas próprias. |
| `godot/project.godot`, `godot/scenes/` | Projeto, cena principal e room_inspector. |
| `godot/scripts/systems/` | RoomSnapshot e RoomCanvas; não há sistemas de gameplay. |
| `godot/tests/` | Smoke, snapshot sintético e integração opcional com dados privados. |
| `assets/original/`, `godot/assets/original/` | Reservas de arte autoral; sem remake artístico entregue. |
| `roms/`, `external/`, `assets/protected/`, `godot/assets/protected/` | Entradas/referências privadas ignoradas. |
| `data/extracted/rc750-verified/`, `rc750-repeat/` | Pacotes finais da Etapa 3; cada um tem 33 gerados + `.DS_Store`. |
| `data/extracted/emulator-stage4-settled/` | 24 arquivos de captura/manifesto. |
| `data/extracted/stage4-validated/` | Quatro JSONs, quatro PNGs, comparison.json e checksums.json. |
| `reports/` | Logs e screenshots privados ignorados. |

Preservar também os runs intermediários (`rc750-v1`, `emulator-stage4`, `stage4-snapshots`) e DSK/ZIP antigos. Um clone Git não contém ROMs, referência ou saídas privadas: para continuar nesta máquina, usar esta pasta existente. Transferência para outra máquina exige preservar separadamente esses arquivos privados, sem publicá-los. Não é necessário obter novamente o material nesta máquina.

## 10. Comandos de configuração, execução e testes

Na raiz existente:

```sh
cd /Users/leofernandes/Desktop/WorkSpace/projeto-game
python3 tools/validate.py
# Alternativa quando Godot estiver em outro local:
GODOT_BIN=/caminho/para/godot python3 tools/validate.py
python3 -m unittest discover -s tests -v
git diff --check
git status --short
/Applications/Godot.app/Contents/MacOS/Godot --editor --path godot
/Applications/Godot.app/Contents/MacOS/Godot --path godot
```

Nenhum pip install é necessário. Logs do validador são renovados em `reports/`. Aplicativos podem precisar de permissão para caches/configurações normais do macOS.

Conferência do pacote existente, sem publicar outra extração:

```sh
ROM_INPUT='roms/Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom'
python3 tools/extractors/verify.py --rom "$ROM_INPUT" --package data/extracted/rc750-verified --repeat-package data/extracted/rc750-repeat
```

Visualizador: abrir `godot/scenes/room_inspector.tscn` e pressionar F6; escolher `data/extracted/stage4-validated/room-005.json`. Não escolher package.json. Integração real reproduzida nesta transferência:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/room_snapshot_integration.gd -- --snapshot /Users/leofernandes/Desktop/WorkSpace/projeto-game/data/extracted/stage4-validated/room-005.json --expected /Users/leofernandes/Desktop/WorkSpace/projeto-game/data/extracted/stage4-validated/room-005.png
```

Procedimentos completos de nova extração/captura: `tools/extractors/README.md` e `tools/emulation/README.md`; sempre escolher destinos inexistentes. O capturador atual limita-se a até quatro salas de demo, 120 segundos emulados e watchdog de 45 segundos reais; não possui interface pronta para qualquer sala ou entrada determinística.

Para iniciar Gemini CLI instalado, executar `gemini` nesta raiz. `command -v gemini` não encontrou executável no PATH desta sessão; nada foi instalado. Se necessário, seguir a [instalação oficial](https://geminicli.com/docs/get-started/installation/). O [GEMINI.md de contexto](https://geminicli.com/docs/cli/gemini-md/) referencia as regras existentes. Primeiro pedido sugerido: “Leia GEMINI.md, AGENTS.md, docs/HANDOFF.md e a última entrada de docs/progress.md. Confira o estado local e apresente o plano da próxima tarefa descrita no handoff; não implemente a Etapa 5 ainda.”

## 11. Estado atual do Godot

Carrega e inicia em headless nesta transferência. Cena principal `res://scenes/main.tscn` mostra status do laboratório; viewport 960×540 é interface provisória. `room_inspector.tscn` usa filtro nearest, escala inteira, abertura explícita de arquivo e overlay.

RoomSnapshot valida campos consumidos, inteiros/faixas, dimensões, tamanho máximo de arquivo de 2 MiB e formato textual do hash de origem; isso não autentica a ROM nem substitui validação completa de contrato/procedência em Python. Erro limpa estado anterior. RoomCanvas desenha a imagem e a máscara; não executa colisão física.

Sem jogador controlável, transições, portas desenhadas, entidades, IA, combate, inventário funcional ou áudio. UIDs `.gd.uid` são versionados; `.godot/` é ignorado.

## 12. Pendências e problemas conhecidos

- Fundos verificados cobrem somente quatro amostras e tilesets 0/4; não constituem frame completo.
- Composição pós-DrawDoors/itens, paletas dinâmicas, paredes destruídas e estados persistentes ainda pendentes.
- `SetDefaultDoorLock`: discrepância documentada de 160 iterações/156 dados ainda não resolvida.
- Salas indefinidas 155, 222, 223, 227–239; conexões 226→227 e 227→228 diagnosticadas, sem correção inventada.
- Sprites, texto e áudio não exportados integralmente; disponibilidade de itens depende de progressão.
- Ausência de licença explícita e identidade integral da ROM não resolvidas; manter referências privadas.
- Nenhuma falha na rodada de testes desta transferência. Falhas antigas e correções estão em progress.md.
- Git iniciou limpo; esta entrega deixa apenas documentação nova/modificada, sem staging, commit ou push. Conferir `git status` ao retomar. Não descartar alterações posteriores do usuário.

## 13. Próxima tarefa exata a executar

Na primeira sessão Gemini: ler os documentos indicados, conferir `git status`, disponibilidade dos artefatos e executar `python3 tools/validate.py`; apresentar um plano delimitado de ampliação da evidência de inicialização/herança de VRAM. Esta transferência não autoriza iniciar a Etapa 5.

Próximo trabalho de desenvolvimento proposto, após autorização: ampliar captura para início de jogo e pelo menos um tileset além de 0/4, registrando sequência de entrada/transição e estado anterior de VRAM para distinguir limpeza inicial de herança. Começar por instrumentação/captura e comparação de fundos; preservar os pacotes e as quatro amostras existentes. Não implementar controlador antes das medições por tick.

Sequência posterior, ainda proposta: deltas pós-portas/itens → estados aberto/fechado, tipo 6 e parede destrutível → medições de jogador/colisão/transições → controlador mínimo fiel.

## 14. Critérios de aceitação dessa tarefa

Para a retomada: documentos lidos, estado Git e ambiente conferidos, testes relatados e plano apresentado com escopo/limites; sem avanço de etapa sem autorização.

Para o marco de captura proposto:

1. Sequência reproduzível de inicialização/transição, ROM identificada por hash, revisão fixa e âncoras de instrução verificadas.
2. Ao menos um tileset adicional e comparação explícita de VRAM anterior/posterior; origem dos slots classificada como observada ou ainda indeterminada, sem preenchimento global arbitrário.
3. Captura após estabilização do VDP; mapas/tiles/fundo comparados integralmente, divergências quantificadas e investigadas, sem tolerância para declarar igualdade.
4. Testes sintéticos relevantes para qualquer alteração de ferramenta; suíte Python/Godot aprovada e quatro casos anteriores preservados.
5. ROMs com hashes preservados, saídas novas privadas/ignoradas, fontes/endereço/banco/offset e limitações documentados; atualização de progress.md.
6. Resultados apresentados antes de avançar para composição dinâmica ou movimento; nenhuma alegação de fidelidade além da evidência obtida.
