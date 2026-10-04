# Parede quebrável da cela de Snake — 2026-10-02

Referência inspecionada: `external/MetalGear`, revisão `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`. ROM principal SHA-256 `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf`, aberta somente para leitura.

## Identificação e evidências primárias

A cela de captura usa **165 no original** (`logic/capturescene.asm:87-118`). O laboratório já possuía cópias dos snapshots 165/164 identificadas como 211/212. Esses aliases locais foram preservados; não existe ID 2100 no contrato de sala (0–250). A correção atua na porta 103, inclusive quando se carrega o ID original.

| Evidência | Resultado |
| --- | --- |
| `data/doors.asm:724-728` | Porta 103, tipo 14 em (32,32), 165 → 164; lado oposto tipo 15 em (208,32), 164 → 165. |
| `data/doors.asm:1001-1031` | `TilesWallPrison1`: bloco 3×13 tiles; `TilesWallPrison`: 2×12. É desenho de tiles de cenário, não sprite VDP de ator. |
| `logic/doors/drawdoors.asm:272-319` | Guarda os tiles de fundo e sobrepõe o bloco fechado. |
| `Banks0123.asm:1480-1531,4789-4809` | Percorre linhas/colunas, atualiza buffer de tiles e desenha com TIMP (índice zero transparente). |
| `Banks0123.asm:11797-11799` | Vida inicial `PrisonWall1Life = 0x28` (40). |
| `logic/doors/opendoor.asm:285-319,379-387,401-434` | Confere direção, modo de soco e retângulo; decrementa a vida em **cada chamada válida**, sem trava por pressionamento. Abre quando chega a zero. |
| `data/doors.asm:28-29` | Lado esquerdo: `32 ≤ X < 58`, `64 ≤ Y < 80`, direção LEFT; lado oposto: `198 ≤ X < 224`, mesma faixa Y, direção RIGHT. |
| `Banks0123.asm:8949-8954,9062-9069`; `logic/common.asm:21` | Soco começa com contador 8; volta ao modo normal ao zerar. Não há constante “4 socos” para esta parede. |
| `logic/doors/erasedoor.asm:25-26,365-367,385-387,399-414` | Restaura exatamente o fundo 3×13 ou 2×12 salvo antes de desenhar a parede. Não pinta um retângulo de chão. |
| `logic/doors/enterdoor.asm:64-88`; `data/doors.asm:28-29` | Travessia por porta aberta, não pela borda da tela. Retângulos: (40,64,8,32) e (208,64,8,32). |
| `logic/nextroom.asm:398-453,476-477` | Emparelha pelo ID 103; destino (200,80), direção LEFT; retorno (56,80), RIGHT. |

Blocos conferidos binariamente pelo localizador de fontes existente:

- `TilesWallPrison1`: banco 15, CPU `0xB1B2`, offset ROM `0x1F1B2`, 41 bytes.
- `TilesWallPrison`: banco 15, CPU `0xB1DB`, offset ROM `0x1F1DB`, 26 bytes.
- Gráficos, paleta e bits de colisão vêm do pacote reconstruído com `build()`, usando o conjunto gráfico e paleta da respectiva sala. O bloco esquerdo tem flags de colisão `[1,1,0]` por linha; o direito `[1,1]`.

## Correção

`PrisonWallDoor` desenha o bloco extraído e preserva os indicadores de colisão anteriores à sobreposição. Ao abrir, remove somente a sobreposição e restaura os indicadores salvos. A textura estática da sala não é modificada. O filtro de portas passa a aceitar os tipos 14/15 da porta 103. O estado compartilhado permite sair e voltar sem recriar a parede.

Foram removidos a pintura com cor sólida, a limpeza indiscriminada de 6×4 tiles até a borda, o gatilho ampliado por aproximação e o contador de quatro pressionamentos. O soco completo contribui oito iterações válidas; cinco socos completos e alinhados esgotam os 40 pontos. Golpes fora da posição/direção correta não contribuem. O acumulador utiliza o relógio de soco já existente no jogador (8/60 s), sem alterar a cadência global do jogo.

## Reprodução

```sh
python3 tools/extractors/extract_prison_wall.py   # ROM canônica resolvida por tools/rom.py
python3 tools/validate.py
/Applications/Godot.app/Contents/MacOS/Godot --path godot \
  --script res://tests/prison_wall_integration_test.gd -- --render-check
```

A extração escreve em `data/extracted/prison-walls/`, ignorado; recusa sobrescrever diretório existente. Use `--output` para uma nova comparação. O Godot carrega os JSONs `wall-14.json` e `wall-15.json` desse diretório padrão. Ausência/dados inválidos geram aviso; não são substituídos por arte inventada. O teste de integração reporta SKIP se essa extração privada não estiver instalada; os testes sintéticos continuam independentes da ROM.

## Verificação e limites

- Extração: blocos conferidos com a fonte fixada; hash da ROM preservado.
- Suíte completa `python3 tools/validate.py`: 92 testes Python e todas as etapas Godot passaram; captura/prisão com 190 verificações e zero falhas.
- Testes sintéticos: montagem de pixels/colisão, tamanhos inválidos, tiles ausentes, limites do soco, direção, resistência, restauração de sólidos e temporização em 30/60/120 Hz.
- Integração Godot: aproximação por movimento real, bloqueio antes da quebra, saída para 212, spawn (200,80), retorno (56,80), persistência e reset.
- Renderização OpenGL real em viewport 256×192: **0 divergências em 49.152 pixels para cada estado**, fechado e aberto, comparados com fundo + bloco extraído. Imagens locais: `reports/prison-wall-closed.png`, `reports/prison-wall-open.png`. Inspeção visual realizada.
- Não foi feita nova captura dinâmica desta parede no openMSX; a evidência comportamental desta entrega é o assembly. A comparação de pixels valida a implementação contra a extração, não contra uma nova captura do emulador.
- A infraestrutura atual não reproduz os SFX de parede do MSX (`0x0A` durante dano e `0x1E` na quebra, `opendoor.asm:369-372`, `erasedoor.asm:65-76`). Não se declara fidelidade sonora nem de duração absoluta da execução Z80.
- A bolsa colocada artificialmente no alias 212 e a saída sul/Grey Fox pertencem à implementação anterior; não foram revalidadas como reproduções integrais da prisão original nesta correção.

## Extensão — parede sul da sala 212 (2026-10-02)

Confirmada a mesma mecânica para a **porta 12**, tipo 13, da sala original 164 (alias local 212) para 54. Evidências adicionais:

- `data/doors.asm:724`: desenho em (96,152); `:992-994`: `TilesWallPrison2`, bloco 4×1 tiles (32×8 pixels).
- `logic/doors/drawdoors.asm:262-269`: tipos 12/13 usam esse bloco. `logic/doors/erasedoor.asm:24,380-382,399-414`: o tipo 13 restaura o fundo 4×1.
- `logic/doors/opendoor.asm:307-316`: porta 12 usa **PrisonWall2Life**, separado de **PrisonWall1Life** da porta 103. Ambos começam em 40 (`Banks0123.asm:11797-11799`). Quebrar uma parede não abre nem causa dano à outra.
- `data/doors.asm:27`; `opendoor.asm:385`: soco DOWN dentro de `104 ≤ X < 120`, `142 ≤ Y < 160`. Entrada após quebra: `96 ≤ X < 128`, `152 ≤ Y < 160`.
- `data/doors.asm:427,26` e `opendoor.asm:384`: lado externo em 54 usa tipo 12, (96,128), mesma porta/estado, direção UP, soco em (104,160,16,8) e entrada em (96,144,32,16).
- `Banks0123.asm:1005-1020,1308-1325`: o estado inicial vem de `IdDoorsLogic`/`DoorOpenArray`, não do fato de o render type ser 12/13. A regra da porta 12 é `0x2F` (fechada). Foi removida sua abertura automática pelo caminho de porta genérica, usando `PrisonWallDoor` nos dois lados.
- `logic/nextroom.asm:474-475`: spawn na sala 54 (112,168), DOWN; retorno para 212 (112,144), UP. Removido também o atalho artificial pela borda sul do alias 212.

Extração de `TilesWallPrison2` confirmada na revisão fixada: banco 15, CPU `0xB1AC`, ROM `0x1F1AC`, 6 bytes. O extrator agora exporta também `wall-12.json` e `wall-13.json`, usando as paletas/conjuntos gráficos de cada lado. Nesta entrega, execução em `data/extracted/prison-walls-south-20261002/` e instalação dos dois novos JSONs no diretório privado padrão; arquivos anteriores preservados.

Integração ampliada: colisão caminhando para baixo, resistência independente, quatro socos sem abertura, quinto soco completo abre, restauração dos quatro indicadores originais de colisão, passagem 212 → 54 → 212, persistência e reset. Renderização real: zero diferenças em 49.152 pixels tanto em `south-closed` quanto em `south-open`, comparada à composição da extração. Capturas em `reports/prison-wall-south-{closed,open}.png`. A ressalva anterior sobre a parede de Grey Fox não validada é substituída por estes resultados; permanecem pendentes os SFX e a medição dinâmica em openMSX.
