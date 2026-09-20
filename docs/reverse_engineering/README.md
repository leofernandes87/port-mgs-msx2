# Engenharia reversa — Etapas 2 a 4

Análise em 2026-09-19. Referência local: external/MetalGear, revisão `30d1b940bede10fdabbaf9767ad4f0ad8dd33291`, sem alterações rastreadas. Todas as referências `arquivo:linha` abaixo são relativas a essa cópia; símbolos permitem localizar novamente a evidência. Não foram incorporados fontes, tabelas ou imagens do jogo ao projeto versionável.

## Como interpretar os resultados

- **Comprovado — estático (E):** instruções, declarações e chamadas foram inspecionadas; descreve o disassembly fixado, não garante que a rotina da ROM do usuário seja idêntica.
- **Comprovado — binário (B):** bytes de uma região/tabela foram comparados integralmente com a ROM, sem alteração. A conclusão vale apenas para as regiões descritas.
- **Hipótese (H):** inferência plausível ainda sem teste suficiente.
- **Pendente (P):** não investigado a ponto de permitir conclusão.

Na entrega da Etapa 2 nenhuma rotina havia sido validada em emulador. A Etapa 4 adicionou comparação em execução de quatro fundos e sete registros de portas; veja o relatório específico. Não há prova de identidade integral da ROM. O principal resultado é que a ROM de 128 KiB pode ser usada como candidata de trabalho: salas/metatiles, conexões, seleção de tileset e sete máscaras de colisão correspondem à referência. A versão regional/revisão exata permanece desconhecida. A tradução de 160 KiB também preserva essas regiões.

## Documentos

- [Arquitetura](architecture.md): inicialização, interrupção, estados, vídeo e áudio.
- [Memória e bancos](memory-and-banks.md): endereços CPU, offsets físicos e RAM.
- [Mapas](maps.md): salas, metatiles, colisões, portas e associações.
- [Movimentação](movement-and-collision.md): coordenadas, controles, estados e colisões.
- [Inimigos](enemies.md): estruturas, despacho, patrulha, percepção e alerta.
- [Inventário e eventos](inventory-and-events.md): armas, dano, itens, portas, rádio e persistência.
- [Compatibilidade](rom-compatibility.md): hashes, comparação, limites e reprodução.
- [Modelo intermediário](intermediate-data-model.md): proposta independente de engine.
- [Validação](validation.md): comandos, testes, limitações das ferramentas.
- [Plano da Etapa 3](stage-3-plan.md): escopo autorizado e critérios.
- [Resultados da Etapa 3](stage-3-results.md): pacote, formatos, evidências, testes e limitações.

- [Etapa 4](stage-4-results.md): fundos comparados em openMSX e visualizador Godot.

## Referência e direitos

O README do autor descreve disassembly RC750, versões inglesa/japonesa, Sjasm 0.39 e montagem `sjasm MetalGear.asm MetalGear.rom`. `MetalGear.asm:38` seleciona JAPANESE; includes diferentes escolhem textos/rádio e condicionais alteram lógica. Reproduzir uma montagem futura apenas em cópia privada sob external/ ou temporários; nunca usar a entrada do usuário como saída.

Não há LICENSE/COPYING no inventário local. O aviso do README declara finalidade educacional e ressalvas; não é tratado como autorização geral para redistribuir código ou assets. A implementação deve permanecer própria e conteúdos extraídos privados. Não foi emitida conclusão jurídica sobre usos futuros.

Inventário automatizado: 225 arquivos .asm, 224 diretivas include resolvidas e 8.657 declarações lexicais de símbolos. Não são necessariamente símbolos únicos: STRUCTs e condicionais repetem nomes. As duas alternativas de includes condicionais aparecem no inventário; ele não simula o assembler. `constants/` define BIOS, variáveis de sistema, enums e estruturas; `Variables.asm` declara RAM; `logic/` contém módulos de jogo; `data/` tabelas; `gfx/` dados gráficos; `sound/` driver/instrumentos/músicas/SFX; `room_images/` PNGs de referência não usados como assets.
