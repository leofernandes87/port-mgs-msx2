# Proposta de dados intermediários — versão de projeto 0.1

**Todo nome de campo abaixo é proposto para a reimplementação**, não é uma estrutura nativa da ROM. Separar dados estáticos, regras confirmadas e estado de execução. Não alterar a arquitetura da Etapa 1: Python → dados neutros privados → adaptador Godot; sem dependência de Resource, Vector2, TileMap ou cenas nos arquivos intermediários.

## Formatos

JSON UTF-8 para manifestos, índices, registros, regras declarativas simples e proveniência. Arrays pequenos (48/768 valores) podem ser JSON inicialmente, facilitando revisão; imagens futuras em PNG indexado e palettes com valores originais + conversão documentada. Dados binários maiores podem usar arquivos próprios com dimensão, encoding, ordem e hash no manifesto. Não usar serialização de objetos Godot. Um futuro backend SNES poderá reorganizar tiles/paletas/VRAM sem alterar a identidade lógica das salas; limitações do SNES não foram estudadas aqui.

## Registros propostos e fundamentação

| Registro | Campos propostos | Origem / motivo |
| --- | --- | --- |
| SourceManifest | format_version, input_sha256/sha1/crc32, size_bytes, reference_commit, tool_version, verification_scope | Checksum integral não basta: indicar quais regiões foram comprovadas. Registrar também hashes da fonte e parâmetros. |
| Evidence | source_file, symbol, line, bank, cpu_address, rom_offset, length, status, method | Um endereço CPU exige contexto de banco; campos desconhecidos devem ser null, nunca inventados. |
| Room | id, layout_ref, metatile_set_ref, graphics_set_ref, connections_ref, doors_ref, entities_ref, items_ref, event_refs, evidence | Room é byte; tabelas usam referências distintas. Layouts podem ser compartilhados. |
| Layout | grid_width=8, grid_height=6, metatile_ids, id_base=1 | RenderRoom e UnpackMetatiles. Não presumir todas as entradas idxRooms válidas. |
| MetatileSet | id, tile_width=4, tile_height=4, definitions | Cada definição tem 16 índices; ordem por linhas demonstrada pela cópia. |
| TileSet | id, tile_pixel_width=8, tile_pixel_height=8, tiles_ref, palette_ref, collision_ref | Graphics e propriedades dependem de conjunto. Transformações de flip devem ser explícitas quando compreendidas. |
| CollisionProfile | movement_blocked_by_tile, view_exceptions_ref, projectile_exceptions_ref, dynamic_overlays_ref | 32 bytes originais viram 256 flags; visão/tiros e portas exigem regras separadas, não uma máscara universal. |
| ConnectionSet | north, south, west, east, original_table_index | 0xFF original vira null no formato normalizado. Preservar índice e valor bruto como metadado privado para auditoria. |
| DoorPlacement | door_id, render_type_id, draw_x, draw_y, destination_room_id, open_rule_ref, region_profile_ref | Cinco bytes de ROM mais tabelas IdDoorsLogic/DoorOpenEnterDat. Estado aberto pertence ao save, não ao layout estático. |
| EntitySpawn | ordinal, actor_type_id, x, y, path_ref, init_rule_ref | Triplas e ordem importam para escolha de caminho. Não serializar a estrutura ACTOR inteira como spawn. |
| PatrolPath | id, points_yx, source_count | Contagem e pares de data/paths.asm. Conversão futura para x/y deve declarar ordem. |
| ItemPlacement | item_type_id, x, y, availability_rule_ref | Triplas de ROM, filtradas por coleta/eventos em AddRoomItems. |
| EventSpec | id, trigger_description, condition_refs, effects_description, implementation_status, evidence | Abstração proposta; eventos originais muitas vezes estão em código. Regras não compreendidas permanecem unresolved; não gerar bytecode fictício. |
| RuntimeState | current_room_id, player_position_fixed8_8, control_mode, animation_mode, game_mode, inventory, door_states, progression_flags | Estado mutável separado dos dados extraídos; posições podem usar inteiros brutos para determinismo. |

## Regras de normalização

1. Preservar IDs originais e aliases; não renumerar salas por ordem física.
2. Registrar dimensões e unidades. Coordenadas de spawn são bytes inteiros; posições em RAM usam frações e não são o mesmo formato.
3. Normalizar endianess/BCD somente quando a codificação do campo estiver demonstrada. Manter valor original em relatórios privados para auditoria.
4. Distinguir layout estático da composição em execução (portas, itens, chefes, buracos, mudanças de ambiente).
5. Campos sem evidência ficam ausentes/null com pendência explícita. ID desconhecido deve gerar diagnóstico, não correção silenciosa.
6. Todo arquivo extraído leva hash da entrada, revisão e versão do pipeline. Não expor caminhos pessoais absolutos no pacote portátil.
7. Schema futuro deve rejeitar tamanhos inconsistentes, referências quebradas e entradas especiais tratadas como normais. Uma fixture sintética deve passar em qualquer máquina, sem ROM.

Esta etapa entrega o contrato conceitual, não um schema congelado para todos os sistemas. Na Etapa 3, formalizar e testar primeiro SourceManifest/Layout/MetatileSet/CollisionProfile, expandindo somente após validar os próximos formatos. Não foi criado importador Godot nem formato específico para SNES.
