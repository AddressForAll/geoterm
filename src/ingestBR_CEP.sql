-- 
-- -- INGEST CEP -- --
-- Usar na base "ingest2". Maiores detalhes na Spec03A1-cep. 
-- Executar no terminal atraves de "make_cep.sh"
--

-- -- -- -- -- -- -- -- -- 
-- -- Inicializações Gerais:

CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER    IF NOT EXISTS files FOREIGN DATA WRAPPER file_fdw;
DROP SCHEMA      IF NOT EXISTS ingest_fwd_cep CASCADE;
DROP SCHEMA      IF NOT EXISTS ingest_final CASCADE;
CREATE SCHEMA    IF NOT EXISTS ingest_fwd_cep;
CREATE SCHEMA    IF NOT EXISTS ingest_final;


CREATE or replace FUNCTION exec_alter_fwd(
  p_fwd_name text,
  p_value text,
  p_param text DEFAULT 'filename'
) RETURNS void AS $f$
 BEGIN
   EXECUTE format(
      'ALTER FOREIGN TABLE %s  OPTIONS (SET %s %L)',
      p_fwd_name, p_param, p_value
   );
 END
$f$ LANGUAGE PLpgSQL;

CREATE or replace FUNCTION array_distinct_sort (
  ANYARRAY,
  p_no_null boolean DEFAULT true
) RETURNS ANYARRAY AS $f$
  SELECT CASE WHEN array_length(x,1) IS NULL THEN NULL ELSE x END -- same as  x='{}'::anyarray
  FROM (
  	SELECT ARRAY(
        SELECT DISTINCT x
        FROM unnest($1) t(x)
        WHERE CASE
          WHEN p_no_null  THEN  x IS NOT NULL
          ELSE  true
          END
        ORDER BY 1
   )
 ) t(x)
$f$ language SQL strict IMMUTABLE;


-- -- -- -- -- -- -- -- -- --
-- -- Definição de cada carga:

CREATE FOREIGN TABLE ingest_fwd_cep.LOG_LOCALIDADE (
        LOC_NU   numeric(8), -- chave da localidade
        UFE_SG   CHAR(2),    -- sigla da UF
        LOC_NO   VARCHAR(72), -- nome da localidade
        CEP      CHAR(8), --  CEP da localidade (para loc_in_sit = 0)
        LOC_IN_SIT      CHAR(1),  -- situação da localidade (0=sem cep, 1 e 2 com cep)
        LOC_IN_TIPO_LOC CHAR(1), -- D – Distrito, M – Município, P – Povoado.
        LOC_NU_SUB      numeric(8), -- chave da localidade de subordinação
        LOC_NO_ABREV    VARCHAR(36), -- abreviatura do nome da localidade
        MUN_NU          CHAR(7) -- Código do município IBGE
) SERVER files OPTIONS (
        filename '/tmp/pg_io/cep/Delimitado/LOG_LOCALIDADE.txt',
        format 'csv',
        header 'true',
        delimiter '@'
);

CREATE FOREIGN TABLE ingest_fwd_cep.LOG_BAIRRO (
        BAI_NU numeric(8), -- chave do bairro
        UFE_SG CHAR(2),    -- sigla da UF
        LOC_NU numeric(8), -- chave da localidade
       BAI_NO text,       -- nome do bairro
       BAI_NO_ABREV text  -- abreviatura do nome do bairro
) SERVER files OPTIONS (
        filename '/tmp/pg_io/cep/Delimitado/LOG_BAIRRO.TXT',
        format 'csv',
        header 'true',
        delimiter '@'
);

CREATE FOREIGN TABLE ingest_fwd_cep.LOG_LOGRADOURO_XX (
        LOG_NU numeric(8), -- chave do logradouro
        UFE_SG CHAR(2),   -- sigla da UF
        LOC_NU numeric(8), -- chave da localidade
        BAI_NU_INI numeric(8), -- chave do bairro inicial do logradouro
        BAI_NU_FIM numeric(8), -- chave do bairro final do logradouro
        LOG_NO text, -- nome do logradouro
        LOG_COMPLEMENTO text, -- complemento do logradouro
        CEP CHAR(8),                   -- CEP do logradouro
        TLO_TX text,           -- tipo de logradouro
        LOG_STA_TLO CHAR(1),           -- flag utilização do tipo de logradouro (S ou N)
        LOG_NO_ABREV text      -- abreviatura do nome do logradouro
) SERVER files OPTIONS (
        filename '/tmp/pg_io/cep/Delimitado/LOG_LOGRADOURO_XX.TXT', -- ALTER here
        format 'csv',
        header 'true',
        delimiter '@'
);


-- -- -- -- -- -- -- -- -- -- -- -- -- --
-- -- Preparo para carga e transferência:

CREATE VIEW ingest_fwd_cep.vw_LOG_LOCALIDADE AS
  SELECT loc.LOC_NU, loc.UFE_SG uf, loc.LOC_IN_TIPO_LOC,
      CASE WHEN loc.LOC_IN_TIPO_LOC='M' THEN loc.LOC_NO ELSE locmae.LOC_NO END AS name,
      CASE WHEN loc.LOC_IN_TIPO_LOC='M' THEN loc.MUN_NU ELSE locmae.MUN_NU END::int AS ibge_id
  FROM ingest_fwd_cep.LOG_LOCALIDADE loc LEFT JOIN ingest_fwd_cep.LOG_LOCALIDADE locmae
    ON loc.LOC_NU_SUB = locmae.LOC_NU
;
CREATE TABLE ingest_final.sys_origem (
   id int PRIMARY KEY,      -- not serial
   name text,  -- nome livre ou rótulopadronizado ou nome do arquivo
   vatID text, -- ‘CNPJ:valor’ com semantica de https://schema.org/vatID
   info jsonb
);
CREATE TABLE ingest_final.via (
   city_ibge_id int, city_uf text,
   name_prefix text, name text,
   info jsonb,
   sys_origem int DEFAULT 1 REFERENCES ingest_final.sys_origem(id),
   UNIQUE(sys_origem, city_ibge_id, name_prefix, name)
);
COMMENT ON TABLE ingest_final.via
  IS 'para migrar entidade via, CUIDADO migrar indicando sistema origem correto!'
;
CREATE FUNCTION ingest_final.via_load(p_file text) RETURNS int AS $f$
  SELECT exec_alter_fwd(
     'ingest_fwd_cep.LOG_LOGRADOURO_XX',
     p_file
  ); -- preparing
  WITH rows AS (
    INSERT INTO ingest_final.via
      SELECT m.ibge_id, m.uf,
      x.TLO_TX as prefix,
      x.LOG_NO as name,
      jsonb_build_object(
            'cep',          to_jsonb( array_distinct_sort(array_agg(DISTINCT x.CEP)) ),
            'use_prefix',   min(x.LOG_STA_TLO),
            'LOC_NU' ,      min(m.LOC_NU),
            'LOC_NU_count', count(*)
        ) as info
      FROM ingest_fwd_cep.LOG_LOGRADOURO_XX x INNER JOIN ingest_fwd_cep.vw_LOG_LOCALIDADE m
       ON x.LOC_NU = m.LOC_NU
      GROUP BY 1,2,3,4
      ORDER BY 1,2,3,4
     RETURNING 1
   ) SELECT COUNT(*)::int FROM rows
$f$ LANGUAGE SQL;
COMMENT ON FUNCTION ingest_final.via_load(text)
  IS 'insere dados base CEP em ingest_final.via'
;

-- -- -- --
-- -- Carga:

DELETE FROM ingest_final.sys_origem; -- cuisado, supondo só esta carga no momento.

INSERT INTO ingest_final.sys_origem (id,name,vatID,info)
 VALUES (1,'eDNE_Basico_1907.zip', 'cnpj:034028316/0001-03',
   jsonb_build_object(
    'last_update','2019-07-25',
    'org_wikidata_id','Q3375004',
    'dataset_descr_url', 'https://web.archive.org/web/20200604135157/http://shopping.correios.com.br/wbm/store/script/wbm2400901p01.aspx?cd_company=ErZW8Dm9i54=&cd_product=6b2FxMrtKxs=&cd_department=SsNp3FlaUpM='))
;
DELETE FROM ingest_final.via
;
SELECT f filename, ingest_final.via_load(p||'/'||f) count_inserts
FROM (SELECT p, pg_ls_dir(p,false,false) f FROM (VALUES ('/tmp/pg_io/cep/Delimitado')) t1(p)) t2
WHERE f ~* '^LOG_LOGRADOURO_..\.txt'
;

CREATE TABLE ingest_final.city AS
  SELECT  DISTINCT ibge_id, uf, name
  FROM ingest_fwd_cep.vw_LOG_LOCALIDADE
;

