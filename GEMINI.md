# Continuidade do laboratório Metal Gear MSX2

Objetivo: engenharia reversa do RC750, reimplementação fiel em Godot 4 e depois remake com arte autoral e melhorias opcionais.

- Leia e siga `AGENTS.md` (regras permanentes compartilhadas).
- Antes de agir, leia `docs/HANDOFF.md` e a última entrada de `docs/progress.md`. Continue o trabalho existente; não reinicie nem substitua a arquitetura.
- Python 3 com biblioteca padrão; Godot 4/GDScript tipado; dados extraídos separados da implementação. Convenções e comandos estão no handoff.
- Nunca modifique a ROM original nem invente estruturas, endereços ou mecânicas. Separe evidência e hipótese; documente fonte, revisão, banco e offset quando aplicáveis.
- **PASSO ZERO MANDATÓRIO - CONSULTA AO CÓDIGO ORIGINAL (`external/MetalGear/`)**: Todo o código Z80 está disponível no projeto (`logic/`, `Banks0123.asm`, `data/`, `gfx/`). NUNCA suponha comportamentos, animações, estados, sprites, temporizadores ou coordenadas. Antes de propor ou implementar qualquer alteração, abra e inspecione o arquivo `.asm` correspondente e cite as linhas como evidência primária.
- Execute `python3 tools/validate.py` e verificações pertinentes; relate falhas reais. Atualize `docs/progress.md` a cada entrega e documente descobertas em `docs/reverse_engineering/`.
- Preserve arquivos e alterações existentes; mantenha ROMs, referências e assets protegidos privados. Não faça commits sem autorização.
- Etapa 4 entregue no marco diagnóstico; Etapa 5 não iniciada. Siga a próxima tarefa e os critérios do handoff, respeitando o escopo autorizado pelo usuário.
