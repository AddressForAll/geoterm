
## Códigos-fonte do Projeto GeoTerm
Nesta pasta todos os fontes. 
O projeto também depende do esquema Optim definido no projeto geral, [WS](http://git.AddressForAll.org/WS).

## Backup dos dados aqui no git

Os dados da pasta /data/in para o português foram gerados por:

```sql
COPY (
 select * from tstore.ns order by nsid
) TO '/tmp/pg_io/ns.csv' CSV HEADER
;
COPY (
  select id,fk_ns,term,fk_canonic,fk_source,is_canonic,is_cult,is_suspect,created,jinfo
  from tstore.term
  where fk_ns=1 order by term
) TO '/tmp/pg_io/ns1_vianameprefix.csv' CSV HEADER
;
COPY (
  select id,fk_ns,term,fk_canonic,fk_source,is_canonic,is_cult,is_suspect,created,jinfo
  from tstore.term
  where fk_ns=4 order by term
) TO '/tmp/pg_io/ns4_vianameprefix-abv.csv' CSV HEADER
;
```
Para a pasta /data/out:
```sql
COPY (
  SELECT id,jurisd_osm_id,ctype,pack_id,fhash,fname,fversion,is_valid,
       fmeta -'fpath' -'is_dir' -'creation' -'modification' AS fmeta,
       config,ingest_instant
  FROM optim.origin
  ORDER BY id
) TO '/tmp/pg_io/br-origin.csv' CSV HEADER
;
```
