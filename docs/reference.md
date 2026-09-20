# Inspeção da referência — 2026-09-19

Fonte: https://github.com/GuillianSeed/MetalGear
Revisão inspecionada: `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`.
Cópia local somente para consulta em `external/MetalGear/`, ignorada pelo Git do projeto. README, entrada de montagem, cabeçalhos dos cinco grupos de bancos, includes e inventário dos diretórios foram inspecionados. Isso não constitui validação integral do disassembly.

## Evidências

- `README.md`, seções How to assemble e Japanese vs English versions: montagem com Sjasm 0.39 ou compatível; CRC32 japonês FAFE1303 e inglês E85C5731. São valores declarados pelo autor, ainda não calculados contra uma ROM do usuário.
- `MetalGear.asm:38`: JAPANESE=0. Linhas 46–50 incluem constantes e Variables.asm; linhas 59–63 incluem cinco grupos de bancos (confirmar numeração ao trocar revisão).
- `Banks0123.asm:7`: org #4000; linhas seguintes declaram cabeçalho e entrada Start.
- `Banks456.asm:9`: org #6000; inclui sound/sound.asm, tabelas de dano, paletas, conexões de salas e atores.
- `Banks789.asm:9`: org #6000; inclui data/roomtileset.asm e arquivos gráficos.
- `BanksABC.asm:9`: org #6000; inclui atributos de sprites, gráficos e textos selecionados por JAPANESE.
- `BanksDEF.asm:9`: org #6000; inclui rooms, metatiles, doors, tileblocks e rotinas de sprites, save/load e encerramento.

As origens acima são endereços declarados ao assembler, não offsets de arquivo. A relação banco/endereço/offset ainda precisa ser demonstrada; não usar diretamente esses números para extrair ROM.

## Diretórios observados

constants contém definições BIOS, variáveis de sistema, estruturas e enumerações; data contém tabelas; logic contém rotinas; gfx contém fontes gráficas em assembly; sound contém driver, músicas e efeitos; room_images contém PNGs de salas. Nomes indicam candidatos para investigação, não provam formato ou comportamento. Variables.asm é uma fonte adicional de símbolos.

## Uso e permissões

O README apresenta finalidade educacional e ressalvas de direitos. Nenhum arquivo LICENSE/COPYING foi encontrado no inventário. Não inferimos autorização para redistribuir código, imagens, música ou ROM. Consultar a referência para registrar especificações e rastreabilidade; implementar código próprio. Não foi feita montagem nem extração nesta etapa. O Sjasm indicado e openMSX não foram encontrados no PATH; não foram instalados.

## Compatibilidade

Não havia ROM no diretório inicial. Compatibilidade permanece não verificada. Na Etapa 2, calcular tamanho, SHA-256 e CRC32 em leitura, comparar os CRC32 documentados e tratar divergências como variante desconhecida. CRC32 isolado é indicação, não prova suficiente de equivalência. Não corrigir, remover cabeçalhos ou aplicar patches à entrada original automaticamente.


### Entrada observada ao final da preparação

Após a inspeção inicial apareceram na raiz `Metal Gear (1987)(Konami).dsk` e o ZIP correspondente. Foram apenas lidos para inventário, sem modificação ou extração. Ambos são ignorados pelo Git. DSK: 737280 bytes, CRC32 B4F2C508, SHA-256 2627e6cfd9849d756d0295c0486f147f3c7ea7a8fac3ebdbe376c5c7ef5a1ee3. ZIP: 94965 bytes; seu diretório lista um DSK de mesmo nome/tamanho/CRC. Inventário local completo: reports/input-inventory.json.

Trata-se de imagem de disco, não de uma ROM de cartucho identificada. Comparar o CRC do disco aos CRCs de cartucho do README não estabelece compatibilidade. A Etapa 2 deve primeiro identificar o conteúdo e a variante em leitura, ou usar uma ROM de cartucho correspondente quando disponível. Não foi validada equivalência ao RC750 nem executado o disco.
