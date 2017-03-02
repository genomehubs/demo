#!/bin/bash

# ============================================================================
# demo.sh - automated commands to set up a GenomeHubs mirror
#
# Usage:
# cd
# git clone https://github.com/genomehubs/demo
# cd demo
# ./demo.sh
# ============================================================================

echo Step 1. Set up mySQL container

docker run -d \
           --name genomehubs-mysql \
           -v ~/demo/genomehubs-mirror/mysql/data:/var/lib/mysql \
           -e MYSQL_ROOT_PASSWORD=rootuserpassword \
           -e MYSQL_ROOT_HOST='172.17.0.0/255.255.0.0' \
           mysql/mysql-server:5.5

sleep 10

echo Step 2. Set up databases using EasyMirror

docker run --rm \
           --name genomehubs-ensembl \
           -v ~/demo/genomehubs-mirror/ensembl/conf:/ensembl/conf \
           -v ~/demo/genomehubs-mirror/ensembl/logs:/ensembl/logs \
           --link genomehubs-mysql \
           -p 8081:8080 \
          genomehubs/easy-mirror:latest /ensembl/scripts/database.sh /ensembl/conf/database.ini &&

echo Step 3. Export sequences, export json and index database

docker run --rm \
           --name easy-import-melitaea_cinxia_core_32_85_1 \
           --link genomehubs-mysql \
           -v ~/demo/genomehubs-mirror/import/conf:/import/conf \
           -v ~/demo/genomehubs-mirror/import/data:/import/data \
           -v ~/demo/genomehubs-mirror/download/data:/import/download \
           -v ~/demo/genomehubs-mirror/blast/data:/import/blast \
           -e DATABASE=melitaea_cinxia_core_32_85_1 \
           -e FLAGS="-e -j -i" \
           easy-import &&

echo Step 4. Startup h5ai downloads server

docker run -d \
           --name genomehubs-h5ai \
           -v ~/demo/genomehubs-mirror/download/conf:/conf \
           -v ~/demo/genomehubs-mirror/download/data:/var/www/demo \
           -p 8082:8080 \
           genomehubs/h5ai:latest

echo Step 5. Startup SequenceServer BLAST server

docker run -d \
           --name genomehubs-sequenceserver \
           -v ~/demo/genomehubs-mirror/blast/conf:/conf \
           -v ~/demo/genomehubs-mirror/blast/data:/dbs \
           -p 8083:4567 \
           genomehubs/sequenceserver:latest

echo Step 6. Startup GenomeHubs Ensembl mirror

docker run -d \
           --name genomehubs-ensembl \
           -v ~/demo/genomehubs-mirror/ensembl/gh-conf:/ensembl/conf \
           -v ~/demo/genomehubs-mirror/ensembl/logs:/ensembl/logs \
           --link genomehubs-mysql \
           -p 8081:8080 \
           genomehubs/easy-mirror:latest

echo Step 7. Waiting for site to load

until $(curl --output /dev/null --silent --head --fail http://127.0.0.1:8081//i/placeholder.png); do
    printf '.'
    sleep 5
done

echo done

echo Visit your mirror site at 127.0.0.1:8081
