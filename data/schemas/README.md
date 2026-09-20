# Contratos independentes de engine

`extraction.schema.json`: JSON Schema draft 2020-12, versão 0.1.0. Define o pacote e SourceManifest, Evidence, Layout, MetatileSet e CollisionProfile. Contrato próprio, não uma alegação de que esses objetos JSON existam na ROM. Fixture totalmente sintética em ../fixtures/synthetic-layout.json.

Layouts preservam IDs de metatile base 1 em 8×6; metatiles têm 4×4 IDs de tiles; salas referenciam layout, gráficos e paleta e incluem expansão derivada 32×24. Tiles gráficos armazenam 64 índices de paleta em ordem de linha ou null quando não reconstruídos. Paletas guardam valores originais de registradores. Colisão cobre apenas a máscara estática. Portas guardam regras/geometria cruas; caminhos distinguem pontos e direções cruas. Não há estados de gameplay inventados.

`tools/extractors/schema.py` implementa somente o subconjunto de JSON Schema utilizado aqui, sem dependências nem referências de rede. Rejeita palavras-chave desconhecidas; não deve ser apresentado como validador genérico de todo draft 2020-12. Também verifica IDs, referências, expansão de metatiles e correspondência da grade de colisão. Uma mudança de contrato exige atualizar schema, validador e testes juntos.

Manifesto vincula revisão externa e hashes; Evidence delimita bytes e declaração de origem. `binary_verified` significa comparação de dados, não execução Z80. Nenhum arquivo de dados reais pertence a esta pasta. Uso futuro em Godot ou SNES exige importador explícito; não há dependência dessas engines no contrato.
