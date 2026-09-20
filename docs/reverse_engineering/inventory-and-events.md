# Inventário, combate e eventos

Conclusões **E**, obtidas pela leitura do disassembly fixado. Nenhum sistema foi validado executando ROM.

| Sistema | Fontes / símbolos | Estrutura e relações comprovadas estaticamente |
| --- | --- | --- |
| Inventário | Variables.asm:214 Weapons, :235 Equipment; logic/items.asm AddItemAmount, AddAmmo | Registros de inventário usam IDs e quantidades; AddAmmo usa DAA para unidades/dezenas e carry para centenas. Não interpretar toda munição como inteiro LE bruto. Flags WeaponsTaken/ItemsTaken são separadas dos registros e da seleção. |
| Itens de sala | logic/addroomitems.asm:8 AddRoomItems; data/itemsinrooms.asm idxRoomItemsIdx/idxRoomItems | Seleção por sala−122 para salas 122–217; 0 indica ausência, demais índices são base 1. Listas ROM contêm triplas ID/Y/X e terminador FF. Filtra flags de coleta e eventos; cria slots RAM com passo 16 bytes. |
| Coleta | logic/items.asm:7 ChkTakeItems, ChkTakeItem | Percorre até três slots; usa posição e tamanho para proximidade. Atualiza inventário, apaga bitmap e pode iniciar texto. STRUCT ITEM só descreve primeiros quatro bytes; não confundir sizeof descritivo com stride real 0x10. |
| Armas | logic/weaponuse.asm:8 ChkWeaponShot | Sete caminhos: pistola, SMG, granada, foguete, explosivo plástico, mina e míssil. Seleção, sala e estado de água/caixa/paraquedas restringem disparo. Implementações em logic/weapon/*.asm. |
| Projéteis | logic/weaponuse.asm:52 GetEmptyShotDat; Variables.asm PlayerShotsList | Procura seis slots com passo 0x40; STRUCT PLAYER_SHOT descreve campos mas não basta para deduzir tamanho alocado. |
| Dano ao ator | logic/damagetoenemy.asm:7 ChkPlayerShots; data/weapondamage.asm; logic/punchenemy.asm | Testes de tiros/soco e dano por tipo; impactos escrevem estado do ator. Chefes podem ter regras próprias. |
| Dano ao jogador | logic/touchenemy.asm:8 ChkTouchEnemies, :188 DecrementLife; logic/hud.asm:107 DecrementLife_B | Contato e tabelas determinam dano; armadura reduz alguns casos por shift. DecrementLife_B reduz Life até zero e chama SetDead, alterando controle/animação. Gás, eletricidade, água e veneno têm rotas próprias. |
| Portas | Banks0123.asm:1270 AddDoorsData; logic/doors/opendoor.asm:8 ChkOpenDoor | Tipo de abertura separado do tipo gráfico, máscara 0x1F e despacho para cartão, elevador, soco, caminhão, eventos e paredes. DoorOpenArray preserva estado por ID. |
| Cartões | logic/doors/opendoor.asm:121 ChkCard | Compara SelectedItem com o cartão exigido e direção com tipo de porta; carregar um cartão superior não é tratado aqui como autorização universal. |
| Progressão | Variables.asm flags; logic/madnarbigbossevent.asm, capturescene.asm, destructiontimer.asm | Flags de resgate, chefes, equipamento confiscado, eventos de Madnar/Big Boss e contagem de destruição influenciam salas e interações. Não há evidência de uma máquina genérica de scripts de eventos. |
| Textos | Banks0123.asm:5274 GetText, :5305 DecodeText; data/texts.asm, textsjp.asm | Índice de ponteiros por TextId−1; tipo de janela; FF final, FE linha, FD página; valores >=A1 entram no dicionário. Variantes são condicionais; não exportar texto japonês usando tabela inglesa por suposição. |
| Rádio | Banks0123.asm RadioLogic, UpdateRadio e ChkRadioCalls; data/radiocalls*.asm | Frequências, interlocutores e textos se relacionam com área, estado e flags. Não é apenas uma lista de legendas. |
| Persistência | logic/checkpoints.asm:10 ChkSaveGameStatus; saveload.asm, passwords.asm | Checkpoints verificam pares sala atual/anterior, 31 candidatos nesse caminho; não salvam após MetalGear_KO. Estruturas de estado e checksum devem ser mapeadas antes de portá-las. |

## Interações relevantes

CommonLogic testa tiros, contato, ponte, eletricidade e gás; se o jogador continuar vivo, portas e itens. InitRoom aplica eventos/checkpoints antes de carregar recursos e atores. Portanto, a sala precisa de referências para entidades e condições persistentes, além do layout visual.

O disassembly contém condicionais JAPANESE na coleta: descrições de vários itens são puladas no caminho inglês (`logic/items.asm`, ErasePickedItem3). Isso demonstra que variantes podem alterar lógica, além de textos. **P:** a variante exata de cada ROM local e equivalência dessas rotinas.

Alguns comentários são inconsistentes com as instruções. Exemplo: DecrementLife_4 em hud.asm sempre carrega B=4 antes da redução, independentemente do valor de B preparado pelo chamador; não confiar no sufixo ou num comentário externo para inferir quantidade. Este documento não enumera todas as tabelas de dano nem atribui unidades modernas aos contadores.

P: catálogo integral de flags de progressão e portas especiais, todas as quantidades BCD, ordens de explosivos e finais, regras de respawn/coleta, codificação textual completa, formato de save/password. As estruturas e módulos estão localizados para extração incremental.
