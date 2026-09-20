# Laboratório Metal Gear MSX2

Projeto educacional para estudar o original RC750, construir uma reimplementação fiel em Godot 4 e posteriormente um remake com arte autoral e melhorias opcionais. Etapas 1–4: infraestrutura, análise, extração e verificação de fundos em emulador, com visualizador diagnóstico no Godot. Mecânicas ainda não implementadas; dados e imagens do jogo permanecem privados e ignorados.

## Requisitos verificados

macOS 15.7.7 (24G720), Macmini8,1 com Intel Core i5-8500B, x86_64; Git 2.50.1 (Apple Git-155); Python 3.9.6; Godot 4.7.2 stable oficial. O binário Godot é universal (x86_64/arm64) e está em `/Applications/Godot.app/Contents/MacOS/Godot`, fora do PATH. Nenhuma biblioteca Python externa é necessária.

## Executar

Na raiz do projeto:

```sh
python3 tools/validate.py
/Applications/Godot.app/Contents/MacOS/Godot --editor --path godot
/Applications/Godot.app/Contents/MacOS/Godot --path godot
```

Alternativamente, importe `godot/project.godot` pelo gerenciador Godot e pressione F6 na cena principal ou F5 para executar o projeto. A cena mostra o status do laboratório. A resolução 960×540 é apenas da interface provisória; não representa uma conclusão sobre o hardware original.

Para outro caminho de instalação:

```sh
GODOT_BIN=/caminho/para/godot python3 tools/validate.py
```

O validador executa unittest, importação headless do editor, teste de ciclo de vida da cena e inicialização do projeto; exige códigos de saída válidos e marcadores de conclusão. Logs ficam em reports/. O Godot grava caches/configurações normais em Library no macOS, podendo precisar de autorização em ambientes restritos.

## Organização e arquivos

```text
AGENTS.md                 regras e arquitetura
README.md                 objetivos e operação
.gitignore / .gitattributes
 docs/                    progresso, referência e plano da Etapa 2
 tools/validate.py         comando único de validação
 tools/reverse_engineering/ e tools/extractors/
 tests/test_repository.py  política de versionamento
 tests/fixtures/           fixtures próprias
 data/schemas/ e data/fixtures/
 data/extracted/           saída privada ignorada
 assets/original/ e assets/protected/
 roms/                     ROM privada ignorada
 external/                 referência local ignorada
 godot/project.godot
 godot/scenes/main.tscn
 godot/scripts/main.gd     GDScript tipado
 godot/scripts/systems/    reservado para sistemas futuros
 godot/tests/smoke_test.gd teste real de cena
 godot/assets/original/ e godot/assets/protected/
 reports/                  logs ignorados
```

Pastas reservadas têm README para preservar sua finalidade no Git. Os arquivos .gd.uid gerados pelo Godot pertencem ao código original e podem ser versionados. Git inicializado em main; identidade existente preservada, sem remoto de publicação configurado.

## Referência e conteúdo privado

Consulte docs/reference.md. A cópia local da referência está em external/MetalGear, ignorada integralmente. Para reproduzir sua obtenção:

```sh
git clone https://github.com/GuillianSeed/MetalGear.git external/MetalGear
git -C external/MetalGear checkout 30d1b940bede10fdabbaf9767ad4f0ad8dd33291
```

Há duas ROMs privadas em roms/, de 128 e 160 KiB. Ambas apresentam compatibilidade parcial comprovada nas tabelas analisadas; identidade integral ainda pendente. DSK e ZIP anteriores também permanecem ignorados. Consulte docs/reverse_engineering/rom-compatibility.md. Coloque uma cópia obtida legitimamente em roms/ quando necessário; não a altere. Na Etapa 3 foram exportados dados e prévias somente para data/extracted/. Não foi montada uma ROM nem copiado código da referência para a implementação. Disponibilidade pública não é permissão de redistribuição. Não há licença de terceiros presumida nem licença geral atribuída ao jogo. Documentar procedência e permissão de qualquer recurso antes de incorporá-lo.

O .gitignore cobre pastas privadas independentemente da extensão, ROMs, imagens de disco, arquivos binários, arquivos compactados, caches e builds. Revisão humana ainda é necessária para arquivos colocados fora dessas pastas.

Análise atual e resultados: [docs/reverse_engineering/README.md](docs/reverse_engineering/README.md). Extração entregue: [resultados da Etapa 3](docs/reverse_engineering/stage-3-results.md) e [procedimentos do extrator](tools/extractors/README.md). Etapa 4 entregue no marco de fundos verificados: [resultados](docs/reverse_engineering/stage-4-results.md) e [como abrir as salas](tools/emulation/README.md). Gameplay permanece pendente. O plano anterior da Etapa 2 foi preservado como histórico.

Para repetir a análise local: `python3 tools/reverse_engineering/analyze.py`. Exige a referência na revisão fixada e ROMs em roms/. Produz apenas metadados em reports/reverse-engineering.json; não gera pacote de assets.

## Visualizador de salas — Etapa 4

Abra `godot/scenes/room_inspector.tscn` no editor e pressione F6. Use **Abrir snapshot local** e selecione `data/extracted/stage4-validated/room-005.json` (ou 001, 031, 127). O botão **Colisão estática** alterna o diagnóstico. Os arquivos reais são locais/ignorados; não fazem parte de um clone público.

O projeto principal continua independente de ROM. O visualizador não implementa movimento, portas ou entidades; mostra fundos comparados com execução em openMSX 21.0/C-BIOS, com paleta nominal. `tools/validate.py` inclui o teste sintético do novo visualizador.
