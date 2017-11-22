#!/bin/bash

# ============================================================================
# import.sh - automated commands to import an assembly from FASTA and GFF
#
# Usage:
# cd
# git clone https://github.com/genomehubs/demo
# cd demo
# ./import.sh
#
# Prerequisites:
# Requires Docker
# ============================================================================

echo Step 1. Set up mySQL container

docker run -d \
           --name genomehubs-mysql \
           -e MYSQL_ROOT_PASSWORD=rootuserpassword \
           -e MYSQL_ROOT_HOST='172.17.0.0/255.255.0.0' \
           mysql/mysql-server:5.5 &&

sleep 10 &&

echo Step 2. Set up template database using EasyMirror &&

INSTALL_DIR=$(pwd)

docker run --rm \
           --name genomehubs-ensembl \
           -v $INSTALL_DIR/genomehubs-import/ensembl/conf:/ensembl/conf:ro \
           --link genomehubs-mysql \
           -p 8081:8080 \
          genomehubs/easy-mirror:17.03.23 /ensembl/scripts/database.sh /ensembl/conf/database.ini &&

echo Step 3. Import sequences, prepare gff and import gene models &&

docker run --rm \
           -u $UID:$GROUPS \
           --name easy-import-operophtera_brumata_v1_core_32_85_1 \
           --link genomehubs-mysql \
           -v $INSTALL_DIR/genomehubs-import/import/conf:/import/conf \
           -v $INSTALL_DIR/genomehubs-import/import/data:/import/data \
           -e DATABASE=operophtera_brumata_v1_core_32_85_1 \
           -e FLAGS="-s -p -g" \
           genomehubs/easy-import:17.03.23 &&

echo Step 4. Export sequences, export json and index database for imported Operophtera brumata &&

docker run --rm \
           -u $UID:$GROUPS \
           --name easy-import-operophtera_brumata_v1_core_32_85_1 \
           --link genomehubs-mysql \
           -v $INSTALL_DIR/genomehubs-import/import/conf:/import/conf \
           -v $INSTALL_DIR/genomehubs-import/import/data:/import/data \
           -v $INSTALL_DIR/genomehubs-import/download/data:/import/download \
           -v $INSTALL_DIR/genomehubs-import/blast/data:/import/blast \
           -e DATABASE=operophtera_brumata_v1_core_32_85_1 \
           -e FLAGS="-e -j -i" \
           genomehubs/easy-import:17.03.23 &&

ls $INSTALL_DIR/genomehubs-import/download/data/sequence/Operophtera* 2> /dev/null &&

echo Step 5. Export sequences, export json and index database for mirrored Melitaea cinxia &&

docker run --rm \
           -u $UID:$GROUPS \
           --name easy-import-melitaea_cinxia_core_32_85_1 \
           --link genomehubs-mysql \
           -v $INSTALL_DIR/genomehubs-import/import/conf:/import/conf \
           -v $INSTALL_DIR/genomehubs-import/import/data:/import/data \
           -v $INSTALL_DIR/genomehubs-import/download/data:/import/download \
           -v $INSTALL_DIR/genomehubs-import/blast/data:/import/blast \
           -e DATABASE=melitaea_cinxia_core_32_85_1 \
           -e FLAGS="-e -i -j" \
           genomehubs/easy-import:17.03.23 &&

ls $INSTALL_DIR/genomehubs-import/download/data/sequence/Melitaea* 2> /dev/null &&

echo Step 6. Startup h5ai downloads server &&

docker run -d \
           --name genomehubs-h5ai \
           -v $INSTALL_DIR/genomehubs-import/download/conf:/conf \
           -v $INSTALL_DIR/genomehubs-import/download/data:/var/www/demo \
           -p 8082:8080 \
           genomehubs/h5ai:17.03 &&

echo Step 7. Startup SequenceServer BLAST server &&

docker run -d \
           -u $UID:$GROUPS \
           --name genomehubs-sequenceserver \
           -v $INSTALL_DIR/genomehubs-import/blast/conf:/conf \
           -v $INSTALL_DIR/genomehubs-import/blast/data:/dbs \
           -p 8083:4567 \
           genomehubs/sequenceserver:17.03.23 &&

echo Step 8. Startup GenomeHubs Ensembl mirror &&

docker run -d \
           --name genomehubs-ensembl \
           -v $INSTALL_DIR/genomehubs-import/ensembl/gh-conf:/ensembl/conf:ro \
           --link genomehubs-mysql \
           -p 8081:8080 \
           genomehubs/easy-mirror:17.03.23 &&

echo Step 9. Waiting for site to load &&

until $(curl --output /dev/null --silent --head --fail http://127.0.0.1:8081//i/placeholder.png); do
    printf '.'
    sleep 5
done &&

echo done &&

echo Visit your mirror site at 127.0.0.1:8081 &&

exit

echo Unable to set up GenomeHubs site, removing containers

docker stop genomehubs-mysql && docker rm genomehubs-mysql
docker stop genomehubs-ensembl && docker rm genomehubs-ensembl
docker stop genomehubs-h5ai && docker rm genomehubs-h5ai
docker stop genomehubs-sequenceserver && docker rm genomehubs-sequenceserver
