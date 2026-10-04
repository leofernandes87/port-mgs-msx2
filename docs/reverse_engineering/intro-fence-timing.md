# Abertura: espera junto à grade e temporização — 2026-10-01

Análise solicitada pelo usuário; nenhuma alteração de gameplay nesta entrega. Referência primária lida: `external/MetalGear`, revisão `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`. Conferência dinâmica adicional no openMSX 21.0, C-BIOS_MSX2_JP e ROM principal SHA-256 `254ffcd94d9ba2322c00df88b21b33b338e3238b90962820bbcaa2bb621e18cf`.

## Resultado

A pausa percebida existe na execução original. Snake chega à colisão da grade em **(128,133)**, permanece nessa posição por aproximadamente **1,069 s** e só então é reposicionado para **Y=136** e muda para escalada. Portanto, (128,136) é a posição definida na transição de animação, não a posição medida durante a espera.

A espera não tem um estado próprio: o contador de IntroScene10 continua decrementando enquanto a colisão impede movimento. O Godot atual não reproduz isso, pois substitui essa etapa por um trajeto de 32 atualizações diretamente até Y=136.

## Evidências assembly

Caminhos abaixo relativos a `external/MetalGear/`:

- `logic/introscene.asm:224–235`: IntroScene8 chama ExitRadio, define contador 0x28 e velocidade 0x0200, avançando imediatamente de estado. **0x28 não é uma pausa parada após o rádio.**
- `logic/introscene.asm:243–267`: IntroScene9 decrementa antes de mover; no zero apenas transita. São 40 chamadas, 39 tentativas de movimento à direita; ao final prepara 0x30.
- `logic/introscene.asm:275–285`: IntroScene10 tem 48 chamadas, com 47 tentativas de mover ao norte pela rotina comum.
- `logic/introscene.asm:255–261` e `Banks0123.asm:8972–8997`: a tentativa passa por controle, colisão e atualização; colisão zera a velocidade. Não há ordem para iniciar escalada ao tocar a grade.
- `logic/introscene.asm:288–299`: somente no zero do contador são definidos Y=0x8800 (136), velocidade 0x0100, animação 5 e contador 0x1C.
- `logic/introscene.asm:307–333`: 28 chamadas na escalada, 27 movimentos de 1 pixel; ao final Y é explicitamente redefinido para 102. Não é interpolação de 34 pixels ao longo de 28 movimentos.
- `logic/introscene.asm:341–364,380–391`: bounce usa offsets nos contadores ímpares após decremento; não usa seno/interpolação. Na amostra, termina em Y=87.
- `Banks0123.asm:8850–8895,9549–9572`: velocidade e integração de posição 8.8.
- `Banks0123.asm:440–466`: interrupção só inicia lógica quando a iteração anterior terminou. **Não se pode converter todos os contadores para segundos presumindo 60 chamadas da lógica por segundo.** Não há, nessa rotina, divisão fixa universal por dois.

## Medição em execução

Breakpoint na entrada de IntroSceneLogic: CPU 0xAE8F, banco 9, offset ROM 0x12E8F. Âncora de nove bytes `3a20c92198aec30cb5` localizada uma única vez antes da execução; condição adicional confirma BankInA0=9. RAM consultada: IntroSceneStatus/Cnt em 0xC920/0xC921 (`Variables.asm:359–360`), X/Y 8.8 em 0xC183/0xC181, velocidade em 0xC143, animação em 0xC18B. Leituras feitas antes da execução do estado; CSV usa índices de estado base zero.

Usadas somente teclas para iniciar jogo e avançar o texto do rádio. Sem escrita em RAM, VRAM, ROM ou PC. A abertura foi executada naturalmente. Renderer desativado; tempos abaixo são **tempo emulado**, não tempo de parede do computador acelerado.

| Rotina | Chamadas | Posição inicial | Última posição antes da transição | Duração até entrada da rotina seguinte |
| --- | ---: | --- | --- | ---: |
| IntroScene9, direita | 40 | (50,165) | (128,165) | 1,335 s |
| IntroScene10, norte | 48 | (128,165) | (128,133) | 1,603 s |
| IntroScene11, escalada | 28 | (128,136) | (128,109) | 0,935 s |
| IntroScene12, bounce | 12 | (128,102) | (128,87) | 0,401 s |

Intervalo mediano entre chamadas nessas quatro rotinas: aproximadamente 33,37 ms, perto de 30 Hz. É resultado desta ROM/máquina/sequência; não uma alegação universal de frequência constante em todos os modos ou MSX.

IntroScene10: 16 movimentos de 2 pixels levam de Y=165 a 133. Nas 32 entradas restantes (contador 32 até 1), Y permanece 133; 31 chamadas tentam avançar e são bloqueadas, a última transita. Intervalo entre primeira entrada parada e entrada de escalada: 1,06865 s.

Há ainda aproximadamente 0,428 s entre a entrada de IntroScene8 e a de IntroScene9, envolvendo ExitRadio/restauração. Isso é distinto de inventar mais um contador de 40 chamadas parado.

## Divergências no Godot atual

`godot/scripts/systems/intro_cutscene.gd`:

- `state_counter` usa 60 Hz; velocidades também multiplicam por 60. A captura demonstra cadência diferente nessa sequência.
- SCENE_8 adiciona pausa de 40 atualizações e SCENE_9 conta outras 40; essa duplicação não existe no assembly.
- SCENE_10 usa 32 atualizações, velocidade de 1 pixel/atualização e troca imediatamente para escalada. Original usa contador 48, velocidade 2 e mantém tentativa/colisão até expirar.
- SCENE_11 interpola 34 pixels em 28 atualizações: cerca de 0,467 s, versus 0,935 s medido para a rotina original.
- A etapa anterior ao rádio já chega a (48,168) em vez de (50,165). Essa diferença precisa entrar na correção de trajeto; um atraso isolado na grade apenas esconderia parte da divergência.
- Bounce termina em (128,80) com arco senoidal; execução original observada encerra a sequência em (128,87).

Os testes atuais afirmam explicitamente a pausa artificial, o percurso de 32 atualizações e a aterrissagem em Y=80. Um resultado PASS desses testes verifica o comportamento atual, não comprova fidelidade ao original.

## Reproduzir e continuar

Evidências privadas preservadas em `data/extracted/intro-timing-20261001/{trace.tcl,trace.csv,manifest.json}`; log `reports/intro-timing-emulator.log`. O Tcl abre trace.csv para escrita: usar uma cópia em **novo diretório** ao repetir para preservar esta captura. Comando utilizado na época, com o dump japonês (histórico; capturas novas usam a ROM canônica de `tools/rom.py` e `-machine C-BIOS_MSX2_EU`):

```sh
/Applications/openMSX.app/Contents/MacOS/openmsx -machine C-BIOS_MSX2_JP -cart 'roms/Metal Gear - Konami (1987) [Does not work on Non Japanese systems] [RC-750] [1473].rom' -script data/extracted/intro-timing-20261001/trace.tcl
```

Próxima correção deve portar a sequência por atualizações discretas, preservar a ordem decremento→transição/movimento, consultar colisão real e conferir o traço por estado/posição/tempo. Usar fixtures sintéticas para testar contadores e colisão; a captura privada é evidência de integração. Não introduzir uma pausa arbitrária ou alterar a velocidade global do jogo com base apenas nesta medição.

## Correção implementada após autorização — 2026-10-01

A análise acima descreve o estado anterior. `IntroCutscene` agora mantém contador inteiro e acumulador de tempo, executando passos nominais de 1/30 s apenas nesta cutscene. Cada passo decrementa antes de decidir entre movimento e transição, como o assembly. O resto do gameplay conserva sua cadência existente.

- Corrigida também a aproximação anterior ao rádio (0x20 chamadas ao norte e colisão real), necessária para iniciar o trecho seguinte em (50,165).
- Removida a espera artificial de 40 chamadas ao fechar o rádio. SCENE_8 apenas prepara SCENE_9 na atualização seguinte ao callback da UI.
- SCENE_9 move 2 pixels por chamada não terminal; SCENE_10 conserva 48 chamadas e consulta `PlayerController.is_colliding_at`. O obstáculo interrompe deslocamento, não o contador. Nenhum limite Y=133 foi fixado no código.
- SCENE_11 move 1 pixel por chamada sem colisão, seguindo o caminho ControlPlayerV do original; ajustes Y=136/102 acontecem só nas transições documentadas.
- Bounce passou a aplicar os offsets ímpares decrescentes da tabela existente. O fim natural libera controle na posição calculada, sem teleporte para Y=80. Skip local usa a posição final medida (128,87).
- Animações de mergulho/escalada avançam pelos contadores de quatro/seis chamadas em `Banks0123.asm:9827–9877`. Indicador equivalente a StopPlayerFlag continua ativo na tentativa bloqueada, pois `ResetPlayerSpd:8956–8962` apenas zera velocidade.
- Tempo acumulado não atravessa espera de rádio; replay e skip limpam o acumulador.

### Verificação da implementação

`godot/tests/intro_cutscene_test.gd` agora usa duas barreiras sintéticas próprias e verifica: decremento antes de mover, sequência de posições, espera com contador vivo na grade, transição de animação, valores do bounce por chamada, fim/skip/replay, ausência de pausa hardcoded sem obstáculo e equivalência em 30/60/120 Hz e delta grande. O teste acumula falhas e retorna código 1, evitando que um quit(0) posterior esconda asserção anterior.

Novo teste opcional `godot/tests/intro_trace_integration.gd` (e UID) carrega a sala real 121 por RoomManager e compara entrada por entrada com a captura privada. **417 entradas coincidiram em estado, contador, posição e modo de animação**, incluindo os trechos antes/depois do rádio e a entrada no estado final. Estados de UI do rádio (índices originais 5–7) são excluídos explicitamente; padrões de sprite por quadro não integram essa comparação.

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/intro_trace_integration.gd -- --trace /Users/leofernandes/Desktop/WorkSpace/projeto-game/data/extracted/intro-timing-20261001/trace.csv
```

Logs: `reports/intro-correction-test.log`, `intro-correction-trace.log`, `intro-correction-validation.log`. Suíte completa: 90 testes Python e todas as etapas Godot PASS, código 0. Após o ajuste final do indicador de movimento, repetidos teste sintético e integração privada: ambos PASS. Primeira execução focada no sandbox teve marcador de sucesso mas erros de logger/certificados do ambiente; execuções autorizadas seguintes passaram sem esses erros.

Durações nominais agora: direita 40/30≈1,333 s, norte 48/30=1,600 s, escalada 28/30≈0,933 s, bounce 12/30=0,400 s. Espera observada na barreira: 32/30≈1,067 s. Diferem em poucos milissegundos dos tempos emulados medidos, pois não há emulação de ciclos Z80/VDP. A restauração ExitRadio do MSX (aprox. 0,428 s na captura) continua substituída pelo fechamento da UI Godot, sem atraso artificial adicionado. Não se declara fidelidade completa da UI, áudio ou todos os sprites da intro.
