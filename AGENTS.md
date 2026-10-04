# Regras permanentes

Projeto de aprendizagem: engenharia reversa do Metal Gear MSX2 RC750, reimplementação fiel 1:1 em
Godot 4 e, depois, remake com arte própria desenhada à mão. Melhorias modernas só opcionais e
separadas do comportamento fiel.

## Fonte de verdade

1. `external/MetalGear/` (edição inglesa, `JAPANESE equ 0`) define o comportamento. **Passo zero
   não negociável:** antes de escrever ou alterar código de qualquer mecânica, cutscene, animação,
   temporizador, velocidade, colisão ou comportamento, inspecione a rotina Z80 e cite
   `arquivo.asm:linhas` como evidência primária. Sem evidência, registre hipótese ou pendência;
   não suponha, estime nem modernize.
2. Separe evidência (arquivo, linha, banco, revisão) de hipótese. Ausência de feature não é bug.
3. `external/` é invisível às buscas padrão: use `python3 -m tools.context.lookup` ou
   `rg --no-ignore`. Procedimento: skill `inspect-msx-disassembly`.

## ROM

4. Única ROM canônica: a inglesa oficial `en-eu-rc750` de `data/rom-profiles.json`, obtida só por
   `tools/rom.py` (SHA-256; nunca nome, ordem ou offset fixo). A japonesa é ignorada salvo pedido
   explícito: não misturar, traduzir nem usar como fallback.
5. ROMs são somente leitura. Não versionar ROMs, código de terceiros, textos ou assets protegidos;
   `external/`, `roms/` e `data/extracted/` ficam ignorados; nunca `git add -f`.

## Trabalho

6. Autonomia para investigar, executar e corrigir. Escopo mínimo; preserve alterações não
   commitadas fora da tarefa (inclusive o `godot/project.godot` local).
7. Python 3 só com biblioteca padrão, ferramentas reutilizáveis; Godot 4 com GDScript tipado e
   sistemas pequenos; dados extraídos separados do Godot; testes com fixtures próprias, nunca bytes
   do jogo. Versionar `.gd.uid`; ignorar `.godot/`.
8. Entrega = código + teste + `python3 tools/validate.py` (fora do sandbox) + entrada curta em
   `docs/progress.md` + `docs/STATUS.md`. Relate resultados reais, inclusive falhas; não declare
   pronto sem verificar; apresente uma etapa principal antes de iniciar a próxima. Skill `delivery`.
9. Sem commit, tag ou push sem autorização; revisar `git diff --cached` antes. Sem ações
   destrutivas ou instalação de sistema sem autorização. Verificar versões reais do macOS.

## Contexto: ler por índice, não por inteiro

- Estado atual: `docs/STATUS.md`. Histórico: `docs/progress/INDEX.md` e
  `python3 -m tools.context.lookup progress "título"`.
- **Proibido ler integralmente arquivos grandes quando houver lookup apropriado.**
  `docs/index/mechanics.json`: use `lookup domain DOMÍNIO`, `lookup status STATUS` ou
  `lookup unmapped` (só ID, título e status); detalhes somente por `lookup mech ID`.
  Todos os comandos abreviados usam `python3 -m tools.context.lookup`.
- `docs/index/coverage.md` é relatório gerado para leitura humana, não contexto padrão de
  agentes. Não o leia integralmente nem o use como atalho para despejar o catálogo.
- Índices: `docs/index/` (mecânicas, citações reversas, testes, esboço Godot, salas) e
  `data/extracted/index/` (símbolos asm, RAM). Regenerar: `python3 -m tools.context.build_index`.
- `Banks0123.asm`: `lookup asm SÍMBOLO -n N`; `sandbox_gameplay.gd` e `enemy.gd`:
  `lookup gd ARQUIVO FUNÇÃO`; progresso atual/arquivado: `lookup progress "título"`.
  Sem leitura integral; consulte faixas pelos índices quando necessário. Isso também vale
  para `data/extracted/**/package.json`. Mapa do repositório: `docs/README.md`.
- Skills (`.agents/skills/`): `inspect-msx-disassembly`, `implement-faithful-mechanic`,
  `rom-extraction`, `godot-testing`, `openmsx-probe`, `delivery`.
