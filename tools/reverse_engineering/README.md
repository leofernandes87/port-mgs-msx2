# Ferramentas de análise

`python3 tools/reverse_engineering/analyze.py` executa inventário lexical, mapa RAM, hashes e comparações limitadas de tabelas com ROMs privadas em roms/. A referência deve estar em external/MetalGear na revisão fixada. Não altera entradas nem salva dados de mapa/imagens, apenas relatório privado em reports/.

Parser deliberadamente restrito: labels e DB/DW de literais/ponteiros locais; rejeita sintaxe desconhecida. Não é assembler Z80 nem extrator completo. Inventário de includes não resolve condicionais. Testes sintéticos: `python3 -m unittest discover -s tests -v`.

Documentação: docs/reverse_engineering/validation.md e rom-compatibility.md.
