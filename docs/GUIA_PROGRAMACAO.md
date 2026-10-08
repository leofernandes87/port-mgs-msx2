# Guia de Programação Manual (Godot 4)

Este guia foi criado para você entender a arquitetura do projeto e saber exatamente **onde mexer** caso queira programar novas mecânicas, inimigos ou alterar o funcionamento do jogo manualmente.

## 1. O Coração do Jogo (`sandbox_gameplay.gd`)
**Local:** `godot/scripts/scenes/sandbox_gameplay.gd`
Este é o arquivo mais importante (e maior) do projeto. Ele é o "Game Manager".
* **O que ele faz:** Carrega as salas, desenha o cenário, controla a vida do Snake, inventário, pausa, e gerencia todos os inimigos da sala atual.
* **Onde mexer:**
  * `_ready()`: Se você quiser criar uma tela de título antes do jogo, é aqui que o jogo inicializa e decide qual a "sala zero".
  * `_process(delta)`: Roda a cada frame. Verifica os tiros, movimentação dos guardas e regras gerais da sala atual.
  * `_check_and_handle_room_transition()`: Lógica que detecta se o Snake pisou na borda da tela e precisa carregar a próxima sala.
  * `_on_player_died()`: O que acontece quando a vida do Snake chega a zero (Game Over).

## 2. O Personagem (Solid Snake) (`player.gd`)
**Local:** `godot/scripts/systems/player.gd`
* **O que ele faz:** Controla exclusivamente a matemática do Snake. Hitbox (colisão), movimentação em grid (8 pixels por passo), sistema de socos e recebimento de dano.
* **Onde mexer:**
  * `step_tick()`: Função chamada pela engine para mover o Snake. Se quiser que ele ande mais rápido ou na diagonal, é aqui.
  * `is_colliding_at()`: O "olho" do Snake. Verifica se o próximo passo vai bater numa parede do MSX.
  * `take_hit()`: Gerencia quando o Snake toma um tiro. Se quiser adicionar invencibilidade temporária piscando de vermelho, coloque aqui.
  * `_draw()`: Desenha o Sprite. É aqui que você altera a sombra ou a escala HD (`visual_scale`).

## 3. O Mapa e as Portas (`room_manager.gd`)
**Local:** `godot/scripts/systems/room_manager.gd`
* **O que ele faz:** É a enciclopédia do mapa. Ele lê os arquivos `.json` e sabe quais inimigos, portas e itens existem na sala número 15, por exemplo.
* **Onde mexer:**
  * `check_room_exit()`: Define em quais coordenadas da tela o jogo acha que você está "saindo" por uma porta.

## 4. Inimigos e IA
**Local:** Vários scripts dentro de `godot/scripts/systems/`, como `soldier.gd`, `dog.gd`, `tank.gd`.
* **Como funciona:** Eles não usam física real da Godot (CharacterBody2D), eles usam matemática pura para se manter fiéis ao MSX.
* **Onde mexer:** Se você quiser criar um inimigo novo, crie um arquivo `meu_monstro.gd`. Ele precisa ter uma variável `position` e uma função `step_tick()` para você programar a inteligência dele (perseguir o Snake, atirar, etc), e depois você o adiciona na tela lá no `sandbox_gameplay.gd`.

## 5. Interface e Armas
**Local:** `godot/scripts/scenes/` (`weapon_menu.gd`, `item_menu.gd`)
* **O que faz:** Controla a tela de pausa e os itens consumíveis.
* **Onde mexer:** Se quiser criar uma arma nova, você precisa adicioná-la no dicionário de armas do `weapon_menu.gd` e programar o comportamento do tiro no `sandbox_gameplay.gd` (na área onde ele cria a bala `Bullet`).

## Regra de Ouro da Nossa Arquitetura
Como esse é um porte fiel do MSX, **não usamos** o sistema de colisão nativo da Godot (`Area2D`, `CollisionShape2D`) para paredes. Nós usamos **Grids Matemáticos**. O mapa inteiro é uma "planilha" invisível de blocos 8x8. O número `1` é parede, `0` é chão livre. 
Quando programar algo novo, sempre pergunte ao Grid se a coordenada está livre antes de mover seu personagem!
