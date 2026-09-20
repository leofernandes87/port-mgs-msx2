# Verificações reproduzíveis

Executar na raiz do projeto, com a referência local no commit documentado:

```sh
python3 -m unittest discover -s tests -v
python3 tools/reverse_engineering/analyze.py > reports/analysis-summary.json
python3 tools/validate.py
git diff --check
```

Para conferir determinismo: execute `shasum -a 256 reports/reverse-engineering.json`, repita analyze.py e execute shasum novamente; os valores devem coincidir para as mesmas entradas e fontes.

A pasta reports já é criada pelo projeto; para um clone novo, criar `mkdir -p reports` antes do redirecionamento (o próprio analyze.py cria a pasta quando executado sem redirecionamento).

## Método e resultados

- 12 testes Python passaram: 2 da política de versionamento e 10 novos testes de checksum conhecido, literais, ponteiros forward/little-endian, sintaxe inválida, delimitação de probes, assinaturas ambíguas, bancos/limites/ida-volta, mapa RAM, posicionamento de metatiles e rejeição de truncamento/IDs inválidos. Fixtures totalmente sintéticas.
- Análise local: ambas as ROMs têm zero diferenças nos 18.176 bytes de rooms+metatiles em 0x1A000. 11 probes de blocos literais por ROM localizaram ocorrências únicas: quatro iniciais (uma delas Room000, já contida no segmento) e sete máscaras de colisão.
- Room000 expandida somente em memória para 768 bytes, hash idêntico nas duas ROMs. Não houve exportação de imagem, tiles ou mapas.
- Hashes de entradas antes/depois coincidem; git check-ignore confirma que ROMs permanecem privadas.
- Inventário: 225 fontes assembly com hashes, 224 includes lexicalmente resolvidos, 8.657 declarações de símbolos (inclui repetições e condicionais). Há relatórios de bancos e RAM.
- Repetição da análise é conferida por igualdade do SHA-256 do relatório completo; resultado final no progresso.
- Validação Godot permanece a suíte da Etapa 1; resultado da rodada desta entrega está em docs/progress.md. Nenhum código Godot foi alterado.

## Limites das ferramentas

`analyze.py` não é assembler Z80. data_segment aceita apenas DB/DW de literais e labels, valida intervalos, resolve ponteiros locais em duas passagens e rejeita diretivas/expressões não suportadas. A organização rooms+metatiles é específica da revisão fixada; outra revisão ou alterações rastreadas nos .asm abortam a análise. Os valores derivados ficam associados à revisão e hashes das fontes.

literal_block lê apenas DB literais consecutivos; nunca pula instruções para concatenar dados não contíguos. hits retorna todas as ocorrências, inclusive sobrepostas; unicidade não é presumida. O inventário de includes/símbolos não avalia IF/ELSE e lê fontes em Latin-1 para preservar bytes não UTF-8 enquanto reconhece sintaxe ASCII. O mapa de RAM aceita reservas e MAP; não é um snapshot de memória real.

A comparação por região demonstra igualdade desses dados, não uma versão exata do cartucho. Não montamos a ROM, não executamos emulador, não validamos todos os pointers nem todo recurso gráfico. Endereços de rotinas sem prova binária são indicados por arquivo/símbolo, não números fabricados.

## Falhas reais durante o desenvolvimento

A primeira rodada do mapa RAM rejeitou `CardBoardBoxTaken # 1` por não ter dois-pontos. O parser foi ajustado para essa sintaxe explícita e ganhou teste. O primeiro inventário completo rejeitou fonte não UTF-8; leitura lexical passou a Latin-1, sem alterar arquivos externos. Nenhuma falha foi ignorada para reportar sucesso.

Não há nova dependência Python. Sjasm e openMSX não foram encontrados no PATH; varredura de nomes de aplicativos também não revelou MSX/Retro. Nenhum componente foi instalado. Relatórios locais: reports/reverse-engineering.json, analysis-summary.json e logs do validador.
