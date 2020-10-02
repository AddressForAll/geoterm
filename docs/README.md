## Uso do geoterm no Brasil

## Termo canônico

Em Linguíguistica ([morfologia canônica](https://en.wikipedia.org/wiki/Lemma_(morphology)) 
e Computação ([forma canônica](https://en.wikipedia.org/wiki/Canonical_form)) o *elemento canônico*
de um conjunto de variantes é uma amostra utilizada como representante ou como "forma preferida". 

No Projeto Geoterm, que lida com termos, principalmente nomes próprios de entidades geográficas,
o elemento canônico requer a definição prévia ou contextualização de "termos variantes".
Tomemos o caso dos nomes de rua, cujas variações ocorrem por falhas de digitação e problemas similares.

* Variantes ortográficas: tipicamente nomes de rua grafados com ou sem acento não podem ser aceitos pela Câmara Municipal como nomes diferentes, portanto sempre será possível eleger a forma correta, que é o "nome de batismo" fixado por Lei.
* Variantes locais: num mesmo bairro ou município as variantes como Sylvio Limma e Silvio Lima podem ser consideradas nomes da mesma rua, mas entre diferentes municípios deve-se respeitar o nome oficial.

No primeiro caso em geral poderemos "canonizar" os termos diretamente no Geoterm, enquanto no segundo caso, das variantes locais, 
as variantes precisam ser tratadas na atribuição de nome de rua. 
Na prática temos a tabela `tstore.term` registrando as variantes ortográficas e as tabelas específicas, 
por exemplo `optim.vianame` e `optim.via` registrando variantes locais. 
No caso a tabela `optim.via` define o termo canônico adotado oficialmente como nome de rua,
e tabela `optim.vianame_synonym` registrando variantes locais válidas e suas respectivas canônicas. 

## Processo de canonização ortográfica

Infelizmente a determinação do termo canônico não é simples e nem sempre estará pronto quando os dados
são inseridos na base de dados. É um processo que, em geral, requer confirmação estatítica (portanto tempo para a acumulação de dados)
ou havaliação humana (tempo na fila de espera para alguém avaliar).

Alguns processos, como o uso de acento, podem ser automatizados. Por exemplo os nomes de rua oficiais,
fornecidos pela prefeitura de Pato Branco, não apresentavam acento, mas puderam ser "corrigidos" pelos 
dados do OpenStreetMap ([planilha](https://docs.google.com/spreadsheets/d/1jxlR0hBPiEwxkGYoULQjTwQasXpOId62Mndo3FhyBTU/)).
Ainda assim algumas falhas da comunidade OSM podem passar desapercebidas, 
sendo que a revisão humana é que determina a finalização do processo... Até que por exemplo a
Câmara Municipal de Pato Branco forneça as leis e os nomes oficiais conforme grafados nas leis, 
e uma correção final possa ser realizada.

Outros processos, como a revisão de nomes "quase iguais", mesmo podendo ser automatizados,
requerem a decisão humano de "tratar como erro ortgrático" ou "tratar como variante local".
Ainda tomando Pato Branco como exemplo,
as [variantes por Metaphone-ptBR](https://docs.google.com/spreadsheets/d/1hdK_3DH-fuq888iAu2CVtub2IMBZJFBOkB-ob2vCvXU/),
é difícil decidir o que seria ou não erro ortográfico. Tupi e Tupy são certamente variantes sonoras, e Tupi o nome oficial,
portanto canônico. Já "Pedro Vieira" e "Padre Vieira" poderiam até ser nomes de rua distintos, não podendo constar como variantes
ortigráficas do mesmo nome: apenas localmente, no município, pode-se eventualmente considerar variantes.

Uma vez decidido que um termo tem variante ortográfica, a distinção entre termo canônico e seus variantes (sinônimos) 
fica registrada na tabela `tstore.term`  e a eleição do canônico precisa
ser "propagada" para a tabela de `optim.vianame`, o que é um processo crítico, precisa ser sempre monitorado e homologado.

## Processo de canonização entre variantes locais

Sempre que um nome de rua for aceitável como entrada, a sua conversão para canônico, caso cabível, precisa ser realizada.
Essa regra vale para nomes de rios, de bairros, etc. E se a conversão não for tratada como ortográfica, ela necessaiamente
será tratada como variação local.

..
