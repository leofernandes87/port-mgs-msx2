# Índices de contexto

Atalhos determinísticos para não reler arquivos grandes. Sem RAG: tudo é texto gerado por
`tools/context/build_index.py` ou curado e validado por ele. `python3 tools/validate.py` roda
`build_index --check` e falha se algo estiver desatualizado ou com referência quebrada.

| Arquivo | Conteúdo | Origem |
|---|---|---|
| `mechanics.json` | catálogo canônico: features, classificação, evidências, escopo e cadeia de implementação | curado, validado |
| `coverage.md` | relatório para leitura humana; não é contexto padrão de agentes | gerado de `mechanics.json` |
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
python3 -m tools.context.lookup -h              # todas as consultas disponíveis
```

Ao mudar uma cadeia de mecânica, edite `mechanics.json`; ao mudar aliases de sala, edite
`rooms.md` junto com `export_local_aliases.ALIASES`.

## Consultas para agentes

É proibido ler integralmente arquivos grandes quando existir lookup apropriado. O comando
lê os índices internamente e entrega somente a seleção solicitada; não despeje os arquivos
completos no contexto do agente.

```sh
python3 -m tools.context.lookup domain actors-bosses  # ID, título e status do domínio
python3 -m tools.context.lookup status PARTIAL        # ID, título e status, todos os domínios
python3 -m tools.context.lookup unmapped              # mesmo resumo de status UNMAPPED
python3 -m tools.context.lookup mech grey-fox         # detalhes somente desta feature
python3 -m tools.context.lookup asm GuardLogic -n 30  # trecho de uma rotina
python3 -m tools.context.lookup gd godot/scripts/systems/enemy.gd step_tick
python3 -m tools.context.lookup progress "Inventário progressivo: atores e bosses"
```

Listagens de features têm três colunas separadas por tabulação: ID, título e status.
`lookup mech` sem ID lista apenas esse resumo; `—` identifica cadeia ainda não classificada.
Status aceita maiúsculas/minúsculas. Filtro válido sem resultados produz saída vazia e exit 0;
domínio/ID desconhecido retorna exit 1; status inválido retorna exit 2. Detalhes completos
exigem `lookup mech ID`, sem opção de expandir todas as features de um domínio/status.

Isso substitui leitura integral de `mechanics.json` e `coverage.md`. Para `Banks0123.asm`,
`sandbox_gameplay.gd`, `enemy.gd` e histórico de progresso, use `asm`, `gd` e `progress`;
quando precisar de declarações adjacentes, leia apenas a faixa localizada pelos índices.
**`coverage.md` é relatório para leitura humana, não contexto padrão de agentes.**

## Cobertura progressiva

O catálogo inclui features originais mesmo sem implementação. Os domínios auditados são
**actors-bosses** (famílias do despacho e comportamentos transversais) e **weapons-items**
(armas do jogador, soco, inventários, coleta, consumo, equipamentos e limites por rank).
Consulte `python3 -m tools.context.lookup domain weapons-items` para o resumo do segundo.
As cadeias legadas sem `domain` ainda não foram auditadas;
não possuem status implícito e não entram nas contagens. Contagem de famílias não é percentual
de conclusão do jogo. Agentes usam as consultas acima; para leitura humana, [coverage.md](coverage.md).

O campo `status` aceita somente `IMPLEMENTED`, `PARTIAL`, `PROVISIONAL`, `NOT_STARTED`,
`DEFERRED`, `UNMAPPED` e `INVESTIGATING`; as definições estão em `status_definitions` no próprio
catálogo. Uma busca sem match não justifica `NOT_STARTED`: é preciso cruzar o comportamento
original com os fluxos de criação, sistemas, extração, testes e histórico. Incerteza de
correspondência permanece `UNMAPPED`. Testes verdes não comprovam fidelidade integral.

Cada feature auditada registra `domain`, `original_scope`, `rationale`,
`implemented_scope`, `missing_scope`, `evidence_notes` e as cadeias existentes. `godot` e
`tests` podem apontar código relacionado ou testes de contrato, sem significar implementação
da feature; o escopo e as notas distinguem esses casos. `history` usa arquivo + `::` + título
exato da entrada; `related_features` referencia IDs do catálogo. `audits` registra recorte,
revisões, método, IDs esperados e exclusões justificadas. Os namespaces de IDs são
`actor_ids` (1–65), `weapon_ids` (1–7), `pickup_ids` (1–35) e `equipment_ids` (1–25);
cada entrada contém as listas declaradas na auditoria de seu domínio, vazias para aspectos
transversais. IDs de namespaces distintos não são intercambiáveis. Outros domínios não foram auditados.

Os limites de escopo e possíveis sobreposições com cadeias legadas estão em `audits` e nas
relações de cada feature: por exemplo, cartões versus portas, máscara versus gás e bolsa
versus captura. Não somar essas cadeias como funcionalidades independentes já concluídas.

O validador confere status, campos obrigatórios, relações entre features, cobertura dos IDs,
arquivos, etapas de testes, funções de integração, títulos históricos e referências asm
(arquivo, faixa, símbolo e ramo inglês). Dados privados são relativos ao diretório canônico:
quando presente, os alvos devem existir; caminhos que escapem dele são sempre rejeitados.
Sem a desmontagem local, a sintaxe asm é validada, mas sua resolução é pulada explicitamente
pelo comando. `coverage.md` nunca deve ser editado diretamente.
