`urn:lex:br;sp;sao.paulo:associacao;dns-addressforall.org:norma.tecnica:2020;spec03A1`

Parte de "Spec03 - Modelo de Dados", **DOCUMENTO  PRIVADO**.

# Anexo 1 - CEP


CONTEÚDO

[Apresentação](#Apresentação)        [1](#h.xbf6f29awxt5)

[Leiaute dos arquivos eleitos para ingestão](#h.arv11o7ymwcv)        [1](#h.arv11o7ymwcv)

[LOG\_LOCALIDADE.TXT](#h.gm0r7s2a3d5j)        [2](#h.gm0r7s2a3d5j)

[LOG\_BAIRRO.TXT](#h.qijmkslonmkj)        [2](#h.qijmkslonmkj)

[LOG\_LOGRADOURO\_XX.TXT](#h.823o844tluw9)        [4](#h.823o844tluw9)

[Diagrama de relacionamento](#h.gxenb73p57oa)        [5](#h.gxenb73p57oa)

[Processamento](#h.o1kg72nmxh88)        [6](#h.o1kg72nmxh88)

-----

## Apresentação

Apesar de todos os horrores do CEP, a base dos correios é uma das poucas
bases organizadas do Brasil.

Para a atualização sistemática e atualizada dos dados do CEP ver
[https://github.com/elo7/edne-correios](https://www.google.com/url?q=https://github.com/elo7/edne-correios&sa=D&ust=1591296174740000) 

Dados de amostra inicial provenientes de
[eDNE\_Basico\_1907.zip](https://www.google.com/url?q=https://web.archive.org/web/20200604135157/http://shopping.correios.com.br/wbm/store/script/wbm2400901p01.aspx?cd_company%3DErZW8Dm9i54%3D%26cd_product%3D6b2FxMrtKxs%3D%26cd_department%3DSsNp3FlaUpM%3D&sa=D&ust=1591296174741000) ou
[http://www.buscacep.correios.com.br](https://www.google.com/url?q=http://www.buscacep.correios.com.br&sa=D&ust=1591296174742000)

Este anexo é um resumo da documentação dos Correios, “DNE - Leiautes - Setembro 2016 - Versão 1.1”.

## Leiaute dos arquivos eleitos para ingestão

A seguir cópia apenas da documentaão relativa aos arquivos de interesse
para a captura de nomes de rua por cidade e/ou localidade. Em todos eles
vale a definição do fornecedor:

> (...)  os arquivos que compõem a Base de dados do Diretório Nacional de
> Endereços – DNE, nos formatos “.txt” (...). Os campos dos arquivos
> estão delimitados por um caracter separador padrão (`@`). As chaves de
> identificação (Primary Key) dos registros desses arquivos estão
> destacadas em vermelho.

Todos eles serão ingeridos na base ingest2 com as definições abaixo, e
pressupondo PostgreSQL v12.

```sql
CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER IF NOT EXISTS files FOREIGN DATA WRAPPER file_fdw;
-- DROP SCHEMA ingest_fwd_cep CASCADE;
-- DROP SCHEMA inges_final CASCADE;
CREATE SCHEMA IF NOT EXISTS ingest_fwd_cep;
CREATE SCHEMA  IF NOT EXISTS ingest_final;
CREATE or replace FUNCTION exec_alter_fwd(
  p_fwd_name text,
  p_value text,
  p_param text DEFAULT 'filename'
) RETURNS void AS $f$
 BEGIN
  EXECUTE format(
      'ALTER FOREIGN TABLE %s  OPTIONS (SET %s %L)',
      p_fwd_name, p_param, p_value
   );
 END
$f$ LANGUAGE PLpgSQL;
```

-----

## LOG\_LOCALIDADE.TXT

O arquivo LOG\_LOCALIDADE contempla os municípios, distritos e povoados
do Brasil. Os CEPs presentes neste arquivo valem para todos os
logradouros da cidade, não necessitando consulta nos demais arquivos.

<table>
<colgroup>
<col style="width: 33%" />
<col style="width: 33%" />
<col style="width: 33%" />
</colgroup>
<tbody>
<tr class="odd">
<th><p>CAMPO</p></th>
<th><p>DESCRIÇÃO DO CAMPO</p></th>
<th><p>TIPO</p></th>
</tr>
<tr class="even">
<td><p>LOC_NU</p></td>
<td><p>chave da localidade</p></td>
<td><p>NUMBER(8)</p></td>
</tr>
<tr class="odd">
<td><p>UFE_SG</p></td>
<td><p>sigla da UF</p></td>
<td><p>CHAR(2)</p></td>
</tr>
<tr class="even">
<td><p>LOC_NO</p></td>
<td><p>nome da localidade</p></td>
<td><p>VARCHAR(72)</p></td>
</tr>
<tr class="odd">
<td><p>CEP</p></td>
<td><p>CEP da localidade (para  localidade  não codificada, ou seja loc_in_sit = 0) (opcional)</p></td>
<td><p>CHAR(8)</p></td>
</tr>
<tr class="even">
<td><p>LOC_IN_SIT</p></td>
<td><p>situação da localidade:</p>
<p>0 = não codificada em nível de Logradouro,</p>
<p>1 = Localidade codificada em nível de Logradouro e</p>
<p>2 = Distrito ou Povoado inserido na codificação em nível de Logradouro.</p></td>
<td><p>CHAR(1)</p></td>
</tr>
<tr class="odd">
<td><p>LOC_IN_TIPO_LOC</p></td>
<td><p>tipo de localidade:</p>
<p>D – Distrito,</p>
<p>M – Município,</p>
<p>P – Povoado.</p></td>
<td><p>CHAR(1)</p></td>
</tr>
<tr class="even">
<td><p>LOC_NU_SUB</p></td>
<td><p>chave da localidade de subordinação (opcional)</p></td>
<td><p>NUMBER(8)</p></td>
</tr>
<tr class="odd">
<td><p>LOC_NO_ABREV</p></td>
<td><p>abreviatura do nome da localidade (opcional)</p></td>
<td><p>VARCHAR(36)</p></td>
</tr>
<tr class="even">
<td><p>MUN_NU</p></td>
<td><p>Código do município IBGE (opcional)</p></td>
<td><p>CHAR(7)</p></td>
</tr>
</tbody>
</table>

## LOG\_BAIRRO.TXT

| CAMPO          | DESCRIÇÃO DO CAMPO                       | TIPO         |
| -------------- | ---------------------------------------- | ------------ |
| BAI\_NU        | chave do bairro                          | NUMBER(8)    |
| UFE\_SG        | sigla da UF                              | CHAR(2)      |
| LOC\_NU        | chave da localidade                      | NUMBER(8)    |
| BAI\_NO        | nome do bairro                           | VARCHAR2(72) |
| BAI\_NO\_ABREV | abreviatura do nome do bairro (opcional) | VARCHAR2(36) |

A título de ilustração de como foi desenvolvido o script de conversão, a
especificação acima foi expressa em SQL do PostgreSQL com FDW:

```sql
CREATE FOREIGN TABLE ingest_fwd_cep.LOG_BAIRRO (
    BAI_NU numeric(8), -- chave do bairro
    UFE_SG CHAR(2),    -- sigla da UF
    LOC_NU numeric(8), -- chave da localidade
    BAI_NO text,       -- nome do bairro
    BAI_NO\_ABREV text -- abreviatura do nome do bairro
) SERVER files OPTIONS (
    filename '/tmp/pg\_io/Delimitado/LOG\_BAIRRO.TXT',
    format 'csv',
    header 'true',
    delimiter '@'
);
```

Em alguns casos como este, ao realizar SELECT surge uma falha,

COPY log\_bairro, line 961: "50850@BA@1094@Boca D"Água@B D"Água"

O arquivo original foi então editado e corrigido para:

   50850@BA@1094@Boca D'Água@B D'Água


## LOG\_LOGRADOURO\_XX.TXT

Logradouro, onde XX representa a sigla da UF.

Este arquivo contém os registros das localidades codificadas por
logradouro(LOC\_IN\_SIT=1). Para encontrar o bairro do logradouro,
utilize o campo BAI\_NU\_INI (relacionamento com LOG\_BAIRRO, campo
BAI\_NU) 🡪 o bairro final, campo BAI\_NU\_FIM, está sendo desativado.


| CAMPO            | DESCRIÇÃO DO CAMPO                                                | TIPO          |
| ---------------- | ----------------------------------------------------------------- | ------------- |
| LOG\_NU          | chave do logradouro                                               | NUMBER(8)     |
| UFE\_SG          | sigla da UF                                                       | CHAR(2)       |
| LOC\_NU          | chave da localidade                                               | NUMBER(8)     |
| BAI\_NU\_INI     | chave do bairro inicial do logradouro                             | NUMBER(8)     |
| BAI\_NU\_FIM     | chave do bairro final do logradouro (opcional)                    | NUMBER(8)     |
| LOG\_NO          | nome do logradouro                                                | VARCHAR2(100) |
| LOG\_COMPLEMENTO | complemento do logradouro (opcional)                              | VARCHAR2(100) |
| CEP              | CEP do logradouro                                                 | CHAR(8)       |
| TLO\_TX          | tipo de logradouro                                                | VARCHAR2(36)  |
| LOG\_STA\_TLO    | indicador de utilização do tipo de logradouro (S ou N) (opcional) | CHAR(1)       |
| LOG\_NO\_ABREV   | abreviatura do nome do logradouro (opcional)                      | VARCHAR2(36)  |


## Diagrama de relacionamento

Modelo entidade-relacionamento “pé de galinha”. As tabelas
LOG\_VAR\_LOC, LOG\_VAR\_BAI e LOG\_VAR\_LOG referem-se a variantes
terminológicas, porém terão que ser carregadas com cuidado  depois de
uma primeira avaliação das terminologias canônicas.

![](images/image1.jpg)

# Processamento

Os scripts Shell e SQL e encontram-se respectivamenete em

  - [https://gitlab.com/addressforall/sql-term/-/blob/master/make\_cep.sh](https://www.google.com/url?q=https://gitlab.com/addressforall/sql-term/-/blob/master/make_cep.sh&sa=D&ust=1591296174928000)
  - [https://gitlab.com/addressforall/sql-term/-/blob/master/src/ingestBR\_CEP.sql](https://www.google.com/url?q=https://gitlab.com/addressforall/sql-term/-/blob/master/src/ingestBR_CEP.sql&sa=D&ust=1591296174928000)

A seguir alguns lembretes e explicações.

A conversão de arquivos em Linux requer instalação de dois aplicativos,

```sh
# nao precisa sudo apt install unzip
sudo apt install recode
sudo apt install dos2unix  
```

O recode melhor, apesar de perigoso (\!), pois `iconv -f WINDOWS-1252 -t UTF-8 filename.txt` não troca, requer script para criar e renomear
arquivo. Cabe fazer teste com `iconv` e só depois aplicar recode.

Conversões efetuadas sobre os arquivos do zip:

dos2unix  /tmp/pg\_io/Delimitado/\*.TXT  /tmp/pg\_io/Delimitado/\*.txt

recode WINDOWS1252..utf8  /tmp/pg\_io/Delimitado/\*.TXT
 /tmp/pg\_io/Delimitado/\*.txt

A conversão dos dados já ocorrerá no ato da criação das tabelas de
transferência, no esquema ingest\_final.

As localidades podem ser distritos, portanto uma importante VIEW é a
redução de distritos e povoados a seus respectivos municípios. Quando
for oportuno essa regionalização será espacializada.

No script SQL completo, a principal função para o processo de ingestão é
ingest\_final.via\_load() . Exemplo de resultado:

           filename         | count\_inserts

\-----------------------+---------------

 LOG\_LOGRADOURO\_SC.TXT |        39063

 LOG\_LOGRADOURO\_DF.txt |        31419

 LOG\_LOGRADOURO\_SP.TXT | 225679

 LOG\_LOGRADOURO\_AC.txt | 2858

 LOG\_LOGRADOURO\_GO.TXT |        36489

 LOG\_LOGRADOURO\_BA.TXT |        40297

...

 LOG\_LOGRADOURO\_PE.TXT |        42255

 LOG\_LOGRADOURO\_PA.TXT |        15743

 LOG\_LOGRADOURO\_PB.TXT |        11891

 LOG\_LOGRADOURO\_RO.TXT | 5108

 LOG\_LOGRADOURO\_AP.TXT | 2239

 LOG\_LOGRADOURO\_RR.TXT | 1905

(27 rows)
