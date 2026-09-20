# Etapa 3 — Extração automatizada dos dados

Estado: **autorizada e entregue no escopo comprovado em 2026-09-19**. Resultados e limitações em [stage-3-results.md](stage-3-results.md). Plano abaixo preservado como critérios de trabalho. Objetivo: transformar as estruturas comprovadas em dados intermediários verificáveis, sem implementar o jogo.

## 1. Fixar entradas e contratos

- Selecionar explicitamente a ROM de 128 KiB por SHA-256, preservando a de 160 KiB como comparação. Aceitar outra ROM somente mediante relatório de compatibilidade por região.
- Formalizar SourceManifest, Evidence, Layout, MetatileSet e CollisionProfile como JSON Schema. Versionar schemas e fixtures sintéticas; dados reais em data/extracted/.
- CLI com entrada e saída explícitas, modo dry-run, versão de ferramenta, hash antes/depois e proibição de sobrescrever entrada (incluindo symlinks/hardlinks). Manifesto deve permitir reconstruir a execução sem caminhos pessoais.
- Critério de aceite: entrada desconhecida gera diagnóstico claro; dados inválidos não produzem pacote aparentemente completo.

## 2. Extrair salas e metatiles

- Ler idxRooms no offset confirmado 0x1A000; validar 251 ponteiros e contexto de banco. Preservar aliases e distinguir RoomUndefined/IDs especiais.
- Investigar os intervalos maiores que 48 bytes e seletores 0/7 antes de decidir quais entradas exportar. Não transformar padding/conteúdo adjacente em salas jogáveis.
- Ler 48 IDs por layout válido, seletores por nibble e definições 4×4. Expandir para 32×24 apenas como saída derivada, preservando a representação compacta.
- Testar contagens, referências, IDs base 1, cruzamento D/E/F, truncamento e comparação entre decoder do contrato e bytes da entrada.
- Critério: cada sala exportada tem proveniência, validação e status; exceções são listadas e não omitidas silenciosamente.

## 3. Extrair gráficos e paletas

- Documentar primeiro cada família de formato: 1/2/3 bpp, flip e stream de repetição/literais de UnpackGfx. Não usar o decoder de sprites em todos os tilesets.
- Confirmar ponteiros e limites de idxTileSets/IdxColisTiles, quantidade/destino dos blocos e seleção de paletas. Esclarecer templates de flip antes de decodificá-los.
- Exportar imagens e paletas apenas para área privada. Gerar folha de contato de amostras para inspeção; imagens de referência permanecem externas.
- Critério: amostras Building/Basement/Roof/Elevator e casos de flip conferidos; PNG derivado não substitui teste de índices/paleta original. Relatar separadamente comparação visual e binária.

## 4. Colisões, conexões e portas

- Expandir sete máscaras de 32 bytes MSB-first e testar correspondência de cada bit.
- Aplicar índices reais de RoomConnections (três faixas), sentinelas e transições especiais, sem fabricar vizinhança por número da sala.
- Documentar/exportar idxDoors, registros de cinco bytes, IdDoorsLogic e DoorOpenEnterDat. Separar geometria, abertura persistente e regras não compreendidas.
- Gerar relatórios de referências inexistentes e overlays de colisão; reciprocidade de conexões é diagnóstico, não obrigação universal.
- Critério: portas e transições de amostras com cartão, elevador e parede especial rastreáveis até a fonte; grade estática não é anunciada como toda a colisão do jogo.

## 5. Entidades, caminhos e itens

- Resolver idxActorsRooms, contagens e triplas; exportar ordem original e relacionar idxRoomPaths sem perder ordinal.
- Auditar convenções de direção 0–3/1–4, campos reutilizados e regras de inicialização antes de nomear estados normalizados.
- Exportar itens das salas elegíveis, mantendo regras de disponibilidade referenciadas. Não confundir slots RAM de 16 bytes com triplas ROM.
- Critério: fixtures de listas vazias, terminadores ausentes, ponteiros fora da faixa e limites de slots; catálogo de regras ainda não implementadas.

## 6. Reproduzir, auditar e entregar

- Dois runs da mesma entrada devem produzir hashes idênticos (datas fora do conteúdo determinístico). Verificar que a ROM e referência continuam inalteradas e saídas privadas ignoradas.
- Rodar testes Python sem ROM; integração local com ROM opcional e claramente identificada. Validar schemas, limites e preservação da entrada.
- Para comparação integral do executável, obter Sjasm compatível e montar em cópia privada, registrando versão/comando. Instalação de componente de sistema requer autorização; não é pré-requisito para exportar regiões já comprovadas.
- Se houver emulador/debugger autorizado, capturar RAM após RenderRoom e comparar o buffer com o decoder; só então declarar validação em execução. Medições de tick/IA pertencem a um trabalho posterior ou subescopo autorizado, não serão inventadas para cumprir o extrator.
- Entregar ferramenta, contrato versionado, fixtures próprias, relatório de cobertura/pendências e dados reais locais. Nenhum asset protegido ou assembly de terceiros entra no Git. Godot continua mínimo; importador e gameplay não são requisito desta etapa.

Atualizar docs/progress.md e apresentar resultados antes de qualquer Etapa 4. Se um formato não for compreendido, exportar apenas os componentes confirmados e registrar a limitação.
