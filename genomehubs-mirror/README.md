# Step-by-step GenomeHubs Mirror Setup Part II

View the [full tutorial](http://genomehubs.org/documentation/mirror-setup-part-ii/) at genomehubs.org.

These instructions set up a full GenomeHubs mirror of [Ensembl](http://ensembl.org)/[EnsemblGenomes](http://ensemblgenomes.org)
species, including a [SequenceServer](http://sequenceserver.com) BLAST server, an
[h5ai](https://larsjung.de/h5ai/) downloads server and the GenomeHubs Ensembl plugin.

If you haven't already done so, try out the [basic mirror tutorial](http://genomehubs.org/documentation/mirror-setup-part-i/)
to get started on a simpler version.

## Clone this tutorial

```
ubuntu@hostname:~$ git clone https://github.com/genomehubs/demo.git
ubuntu@hostname:~$ cd demo/genomehubs-mirror
ubuntu@hostname:~$ tree
.
├── blast
│   ├── conf
│   │   ├── links.rb
│   │   └── sequenceserver.conf
│   └── data
├── download
│   ├── conf
│   │   └── _h5ai.headers.html
│   └── data
├── ensembl
│   ├── conf
│   │   ├── database.ini
│   │   └── setup.ini
│   ├── gh-conf
│   │   └── setup.ini
│   └── logs
├── import
│   ├── conf
│   └── data
├── mysql
│   └── data
└── README.md
```

## Docker containers

### mySQL container

```
docker run -d \
           --name genomehubs-mysql \
           -v ~/demo/genomehubs-mirror/mysql/data:/var/lib/mysql \
           -e MYSQL_ROOT_PASSWORD=rootuserpassword \
           -e MYSQL_ROOT_HOST='172.17.0.0/255.255.0.0' \
           mysql/mysql-server:5.5
```

### EasyMirror (Ensembl) container

```
docker run -d \
           --name genomehubs-ensembl \
           -v ~/demo/genomehubs-mirror/ensembl/conf:/ensembl/conf \
           -v ~/demo/genomehubs-mirror/ensembl/logs:/ensembl/logs \
           --link genomehubs-mysql \
           -p 8081:8080 \
          genomehubs/easy-mirror:latest
```

### EasyImport container

```
docker run -d \
           --name easy-import-bombyx_mori_core_32_85_1 \
           --link genomehubs-mysql \
           -v ~/demo/genomehubs-mirror/import/conf:/import/conf \
           -v ~/demo/genomehubs-mirror/import/data:/import/data \
           -v ~/demo/genomehubs-mirror/download/data:/import/download \
           -v ~/demo/genomehubs-mirror/blast/data:/import/blast \
           -e DATABASE=bombyx_mori_core_32_85_1 \
           -e FLAGS="-e -j -i" \
           easy-import
```

### h5ai (downloads) container

```
docker run -d \
           --name genomehubs-h5ai \
           -v ~/demo/genomehubs-mirror/download/conf:/conf \
           -v ~/demo/genomehubs-mirror/download/data:/var/www/demo \
           -p 8082:8080 \
           genomehubs/h5ai:latest
```

### SequenceServer (BLAST) container

```
docker run -d \
           --name genomehubs-sequenceserver \
           -v ~/demo/genomehubs-mirror/blast/conf:/conf \
           -v ~/demo/genomehubs-mirror/blast/data:/dbs \
           -p 8083:4567 \
           genomehubs/sequenceserver:latest
```

### Restart EasyMirror container

```
docker stop genomehubs-ensembl && docker rm genomehubs-ensembl
docker run -d \
           --name genomehubs-ensembl \
           -v ~/demo/genomehubs-mirror/ensembl/gh-conf:/ensembl/conf \
           -v ~/demo/genomehubs-mirror/ensembl/logs:/ensembl/logs \
           --link genomehubs-mysql \
           -p 8081:8080 \
          genomehubs/easy-mirror:latest
```
