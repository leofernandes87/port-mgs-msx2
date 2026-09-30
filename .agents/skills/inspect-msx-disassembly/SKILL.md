---
name: inspect-msx-disassembly
description: >-
  Mandatory procedure to inspect the original MSX2 Metal Gear disassembly in external/MetalGear/
  before implementing, fixing, or modifying any gameplay mechanics, cutscenes, sprites, animations,
  or physics.
---

# Inspeção Mandatória da Desmontagem Original MSX2 (external/MetalGear/)

Este procedimento é o **Passo Zero Não-Negociável** de qualquer tarefa de reimplementação fiel do Metal Gear MSX2 (RC750, Konami 1987).

## Regra de Ouro
**NUNCA adivinhe, estime ou deduza comportamentos por memória ou intuição.**
Todo o código-fonte original em assembly Z80 está extraído e disponível localmente no repositório na pasta `external/MetalGear/`. Qualquer mecânica deve ser comprovada com arquivo e número de linha antes de ser escrita.

---

## 1. Mapa de Arquivos da Desmontagem

Pasta / Arquivo | Conteúdo Principal
---|---
`Banks0123.asm` | Núcleo da engine: loop principal, animações do jogador (`AnimatePlayer`), rotinas de colisão (`ChkPlayerColl`), transceptor/rádio (`DrawRadio`), sprites e comandos VDP.
`Variables.asm` | Mapa de variáveis na RAM (`0xC000..0xDFFF`): `PlayerAnimation`, `PlayerDirection`, `PlayerMovSpeed`, `IntroSceneStatus`, etc.
`logic/introscene.asm` | Máquina de estados completa da abertura, infiltração na água, chamada do rádio, nado até a grade, escalada e salto para terra firme.
`logic/weapon/*.asm` | Balística e lógica de armas (`handgun.asm`, `smg.asm`, `grenade.asm`, `missile.asm`, `plasticbomb.asm`, `landmine.asm`).
`logic/actors/*.asm` | Inteligência artificial e lógica de atores (`guard.asm`, `dog.asm`, `camera.asm`, `laser.asm`, `powerswitch.asm`).
`logic/damagegas.asm` | Perigo de gás tóxico e máscara de gás.
`logic/damageelectric.asm` | Pisos eletrificados e painéis de força.
`logic/elevator.asm` | Elevadores e transições entre andares.
`data/rooms.asm` | Conexões e definições de salas.
`data/tileblocks.asm` | Mapeamento de blocos de tiles de salas, portas e transceptor (`RadioTilesMap`, `SnakeTilesMap`).
`data/palettes.asm` | Paletas de cores do VDP (`DefaultPalette`, `RadioPalette`).
`data/texts.asm` e `radiocalls.asm` | Banco de diálogos e chamadas do Codec.
`gfx/*.asm` | Dados brutos de sprites e tiles (`radio.asm`, `snakeportrait.asm`, `font.asm`, etc.).

---

## 2. Procedimento Operacional Passo a Passo

Sempre que uma nova tarefa ou correção for solicitada:

1. **Localizar a rotina no Assembly**:
   Execute busca com `grep_search` em `external/MetalGear/` para o termo ou mecânica:
   - Exemplo: `IntroScene8`, `SetSprWater`, `PlayerAnimation`, `ChkPlayerColl`.

2. **Ler a lógica Z80**:
   Verifique os registradores e flags exatas:
   - Qual é o valor atribuído a `PlayerAnimation`? (0=Normal, 1=Punch, 2=Water, 4=Deep water, 5=Ladder/Climb).
   - Qual é o contador de frames (`IntroSceneCnt`)?
   - Qual é a velocidade (`PlayerMovSpeed`)? (ex: `100h` = 1.0 px/tick, `200h` = 2.0 px/tick).
   - Quais controles virtuais estão ativos (`ControlsHold`, `PlayerDirection`)?

3. **Documentar a Evidência**:
   No raciocínio e no código, cite explicitamente o arquivo e linhas:
   ```gdscript
   # Conforme external/MetalGear/logic/introscene.asm:224-245 (IntroScene8 / IntroScene9)
   # Snake permanece em PlayerAnimation = 2 (Water / SWIM_SURFACE) a 2.0 px/tick.
   ```

4. **Implementar a Lógica Fiel**:
   Escreva o GDScript ou Python mapeando exatamente a máquina de estados Z80.

5. **Validar com Testes**:
   Execute `python3 tools/validate.py` e garanta 100% de aprovação.
