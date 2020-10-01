# run explicitally by "sh make.sh"

echo -n "Limpar e criar esquema 'tstore' para qual database? (ex. dl03t_main) "
read base
if [ -z "$base" ]; then
   exit
fi

#echo -n "Do you wish to DROP the SQL schema 'tstore' of database "$base"? (y/n) "
#read answer
#if [ "$answer" != "${answer#[Yy]}" ] ;then
#    echo Yes
#else
#    exit
#fi

psql "$base" -c "DROP SCHEMA tStore CASCADE"

date # para cronomeetrar

mkdir -p /tmp/pg_io
cp data/ns_pt/nsPair-viaNamePrefix.csv /tmp/pg_io/

psql "$base" < src/step1_libDefs.sql
if [ $? -ne 0 ]; then
    exit 1
fi  # avoid typical database (exist) errors

psql "$base" < src/step2_struct.sql
psql "$base" < src/step3_lib.sql

psql "$base" -c "SELECT tStore.ns_upsert('viaNamePrefix', 'pt', 'Prefixo de nome de via (tipo de logradouro)', 1::boolean);"
psql "$base" -c "SELECT tStore.ns_upsert('viaName',       'pt', 'Nome de via sem prefixo e por extenso',       1::boolean);"
psql "$base" -c "SELECT tStore.ns_upsert('viaNamePrefix-abv', 'pt', 'Abreviação de prefixo de nome de via',    0::boolean);"
psql "$base" -c "SELECT tStore.ns_upsert('adminCode',         '  ', 'Códogo ISO de país ou código hierárquico',1::boolean);"
psql "$base" -c "SELECT tStore.ns_upsert('adminCode-expand',  'pt', 'Nome expandido do código de país/hierarquia',   0::boolean);"
psql "$base" -c "SELECT tStore.ns_upsert('secOfCity',         'pt', 'Nome artificial de setor ou oficial de bairro', 1::boolean);"
psql "$base" -c "SELECT tStore.ns_upsert('secOfCity-code',    '  ', 'Código de setor (N, NE, NO, S, SE, etc.)',      0::boolean);"
psql "$base" -c "SELECT tStore.ns_upsert('aquaBodyName',      'pt', 'Nome de corpo d’água (rio, lago, etc)',         1::boolean);"

psql "$base" < src/step4_ins.sql

date # fim

echo " (use make_cep.sh to load CEP to $base)"
