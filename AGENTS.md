# Regras permanentes

Projeto de aprendizagem: engenharia reversa do Metal Gear original MSX2 RC750, reimplementação fiel em Godot 4 e, posteriormente, remake com arte própria desenhada à mão e melhorias opcionais.

1. Trabalhar com autonomia: investigar, executar comandos e corrigir erros quando permitido.
2. Não inventar estruturas da ROM ou mecânicas. Registrar evidências, endereços, bancos, arquivos, revisão da fonte e hipóteses separadamente.
   - **CONSULTA OBRIGATÓRIA DO CÓDIGO ORIGINAL (`external/MetalGear/`)**: Todo o código-fonte desmontado do jogo está disponível em `external/MetalGear/` (pastas `logic/`, `data/`, `gfx/` e arquivo `Banks0123.asm`).
   - **Passo zero não-negociável**: Antes de escrever ou alterar qualquer linha de código em GDScript ou Python para qualquer mecânica, cutscene, animação, temporizador, velocidade, colisão ou comportamento, é OBRIGATÓRIO inspecionar a rotina assembly Z80 correspondente e citar o arquivo e linhas exatas como evidência primária.
   - **Zero suposições**: É terminantemente proibido supor, estimar ou inferir comportamentos por intuição ou memória quando o código-fonte original está presente no projeto.
3. Nunca modificar a ROM original. Ferramentas devem abrir entradas em modo somente leitura e escrever em outro destino.
 - A única ROM canônica é a inglesa oficial definida em `data/rom-profiles.json`, obtida sempre por `tools/rom.py` (identificação por SHA-256, nunca por nome, ordem ou offset fixo). A ROM japonesa é ignorada salvo pedido explícito: não misturar, traduzir nem usar como fallback.
4. Não versionar ROMs, código de terceiros ou assets protegidos sem verificar permissões. Referências externas ficam isoladas em external/, ignoradas. Não usar git add -f para contornar essa política.
5. Priorizar ferramentas automáticas reutilizáveis em Python 3.
6. Usar Godot 4 e GDScript com tipagem estática; sistemas pequenos e independentes.
7. Manter dados extraídos separados da implementação Godot.
8. Executar testes e relatar resultados reais, inclusive falhas.
9. Atualizar docs/progress.md a cada entrega.
10. Não declarar funcionalidade concluída sem verificar seu funcionamento.
11. Não avançar para nova etapa principal antes de concluir e apresentar os resultados da anterior.
12. Não executar ações destrutivas nem instalar componentes de sistema sem autorização apropriada.
13. Verificar arquitetura e versões reais no macOS, sem presumir configurações.

## Arquitetura proposta

- docs/: evidências, decisões, progresso e planos.
- tools/reverse_engineering/: identificação, inventário e tradução de endereços, somente após evidência.
- tools/extractors/: extração reproduzível, sem modificar entradas.
- roms/ e external/: entradas privadas, fora do conteúdo versionado.
- data/schemas/: contratos neutros; data/fixtures/: dados sintéticos próprios; data/extracted/: resultados locais ignorados.
- assets/original/: fontes autorais; assets/protected/: referências privadas ignoradas.
- godot/: projeto independente; scenes/, scripts/systems/, assets/original/, tests/.
- tests/: testes Python com unittest e fixtures sintéticas.
- reports/: logs locais ignorados; resultados consolidados em docs/progress.md.

Fluxo futuro: ROM somente leitura → ferramentas Python → dados intermediários validados → importação explícita para Godot. A cena inicial não depende de ROM. Sistemas futuros (salas, movimento, colisão, atores, alerta, inventário, áudio) só serão implementados após especificação baseada em evidências. Melhorias modernas deverão ser opcionais e separadas do comportamento fiel.

## Verificação

Executar `python3 tools/validate.py`. GODOT_BIN pode selecionar o executável. Não adicionar dependências Python sem necessidade. Versionar arquivos .gd.uid; ignorar .godot/. Testes de dados devem usar fixtures próprias, não bytes do jogo. Antes de commits, revisar `git diff --cached` e arquivos candidatos para conteúdo protegido; .gitignore não substitui revisão.
