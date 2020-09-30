# run explicitally by "sh make_cep.sh"

echo "Please check database 'ingest2' or make it by make.sh"

echo -n "Ingest CEP on ingest2, from zip? (y/n) "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Loading CEP database to ingest2..."
else
    exit
fi

date # ini

mkdir -p /tmp/pg_io # precisa?
mkdir -p /tmp/pg_io/cep

unzip -d /tmp/pg_io/cep  /home/filipe/eDNE_Basico_1907.zip

dos2unix  /tmp/pg_io/cep/Delimitado/*.TXT  /tmp/pg_io/cep/Delimitado/*.txt

recode WINDOWS1252..utf8  /tmp/pg_io/cep/Delimitado/*.TXT  /tmp/pg_io/cep/Delimitado/*.txt

psql ingest2 < ~/gits/sql-term/src/ingestBR_CEP.sql

date # end

echo -n "Tudo bem até aqui? vamos tombar para a base testing? (y/n) "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Tombando..."
else
    exit
fi
