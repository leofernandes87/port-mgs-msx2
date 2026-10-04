# Índices de contexto

Atalhos determinísticos para não reler arquivos grandes. Sem RAG: tudo é texto gerado por
`tools/context/build_index.py` ou curado e validado por ele. `python3 tools/validate.py` roda
`build_index --check` e falha se algo estiver desatualizado ou com referência quebrada.

| Arquivo | Conteúdo | Origem |
|---|---|---|
| `mechanics.json` | mecânica → asm → extrator/dados → Godot → integração → teste → docs | curado, validado |
| `asm-citations.md` | trecho `arquivo.asm:linhas` → arquivos do projeto que o citam | gerado |
| `tests.md` | etapa do validate → script → marcador → sistemas usados; testes Python | gerado |
| `godot-outline.md` | `.gd` com 300+ linhas: sinais, constantes, variáveis, faixa de cada função | gerado |
| `rooms.md` | aliases locais de sala e faixas da numeração original | curado, validado |
| `../progress/INDEX.md` | todas as entradas do progresso com arquivo e linha | gerado |
| `data/extracted/index/asm-symbols.tsv` | rótulos e `equ` → arquivo:linha, grupo de bancos, ramo | gerado, local |
| `data/extracted/index/ram-map.tsv` | variáveis de RAM → endereço, tamanho, linha | gerado, local |

Os dois últimos derivam da desmontagem de terceiros e ficam fora do Git; são refeitos
automaticamente quando `external/MetalGear` muda.

```sh
python3 -m tools.context.build_index            # regenera tudo e rotaciona o progresso
python3 -m tools.context.build_index --check    # só confere
python3 -m tools.context.lookup -h              # asm, ram, cites, gd, mech, progress
```

Ao mudar uma cadeia de mecânica, edite `mechanics.json`; ao mudar aliases de sala, edite
`rooms.md` junto com `export_local_aliases.ALIASES`.
