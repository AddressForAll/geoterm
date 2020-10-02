

insert into tstore.source (name) values('addressforall'),('osm2020-09'),('pref. pato branco'); -- supposing id=1

create table lixo (viaNamePrefix text,"viaNamePrefix-abv" text, is_pref boolean);
COPY lixo FROM '/tmp/pg_io/nsPair-viaNamePrefix.csv' CSV HEADER;
-- SELECT tlib.normalizeterm("viaNamePrefix-abv") abv, tlib.normalizeterm(vianameprefix) FROM lixo;

SELECT tstore.upsert_normalize(vianameprefix,1,null,true,null,false,true,1) as is_ok
FROM ( SELECT distinct vianameprefix  FROM LIXO order by 1) t;

SELECT tstore.upsert_normalize(
   "viaNamePrefix-abv",4,null, false, tlib.n2c_check(tlib.normalizeterm(vianameprefix),1), not(is_pref), is_pref, 1
  ) as is_ok
FROM lixo where "viaNamePrefix-abv">'';

update tstore.term set fk_ns=1 where fk_ns=4 AND term in ('rodo anel','vicinal');

SELECT tstore.upsert_normalize(
   trim(term,'.'),4,null, false, fk_canonic, is_suspect, is_cult, 1
  ) as is_ok
FROM (select * from tstore.term where fk_ns=4 and trim(term,'.')=replace(term,'.','') order by term) t;

SELECT tstore.upsert_normalize(
   unaccent(term),1,null, false, id, is_suspect, false, 1
  ) as is_ok
FROM (select * from tstore.term where fk_ns=1 and unaccent(term)!=term order by term) t;

DROP table lixo;
