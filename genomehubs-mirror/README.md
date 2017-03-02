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
│   │   ├── default.ini
│   │   └── overwrite.ini
│   └── data
├── mysql
│   └── data
└── README.md
```

## Docker containers

The [basic mirror tutorial](http://genomehubs.org/documentation/mirror-setup-part-i/)
demonstrated an Ensembl mirror using just two containers (mySQL and EasyMirror), but a
standard GenomeHubs site uses five. The additional containers provide a BLAST server
([SequenceServer](http://sequenceserver.com)), a downloads site
([h5ai](https://larsjung.de/h5ai/)) and the [EasyImport](http://easy-import.readme.io)
scripts to import into and export from Ensembl databases. EasyImport is used as a component
of a GenomeHubs Ensembl mirror as it provides scripts to export sequences for the downloads
and BLAST servers and to index the databases for search.

### mySQL container

Note that if you have followed the [basic mirror tutorial](http://genomehubs.org/documentation/mirror-setup-part-i/),
this example sets up an entirely separate database, reusing the `mysql-server:5.5`
image (that you will already have a local copy of) but creating a separate container
using a separate data directory. This demonstrates the ease with which multiple GenomeHubs
may be hosted on a single server. It is also possible to reuse the existing mysql container
but that will require updating all instances of `genomehubs-mysql` in these instructions
and the configuration files, changing it to the name of the existing container.

Run the mysql container with a password set by passing an environment variable on the
command line, for more secure options see the [mysql Docker Hub entry](https://hub.docker.com/_/mysql/mysql-server).
A second environment variable grants the root user access from any container on the default Docker
subnet, which allows the EasyMirror container to create databases and configure users.

```
docker run -d \
           --name genomehubs-mysql \
           -v ~/demo/genomehubs-mirror/mysql/data:/var/lib/mysql \
           -e MYSQL_ROOT_PASSWORD=rootuserpassword \
           -e MYSQL_ROOT_HOST='172.17.0.0/255.255.0.0' \
           mysql/mysql-server:5.5
```

This command simply starts the mySQL server but no databases are set up yet. To check the
container is running user `docker ps` or check `docker logs genomehubs-mysql`.

### EasyMirror (Ensembl) container

As in the previous tutorial, the `easy-mirror` container creates local copies of any databases
specified in `demo/genomehubs-mirror/ensembl/conf/database.ini` and hosts an Ensembl site
using databases and plugins specified in `demo/genomehubs-mirror/ensembl/conf/setup.ini`.

```
docker run -d \
           --name genomehubs-ensembl \
           -v ~/demo/genomehubs-mirror/ensembl/conf:/ensembl/conf \
           -v ~/demo/genomehubs-mirror/ensembl/logs:/ensembl/logs \
           --link genomehubs-mysql \
           -p 8081:8080 \
          genomehubs/easy-mirror:latest
```

Once the container has had time to create local copies of databases and configure the Ensembl
(depending on connection speed this should only take a minute or two) the Ensembl mirror should
be available at `http://127.0.0.1:8081`. At this stage it should resemble an
[Ensembl Metazoa](metazoa.ensembl.org) site but with a single species, the Glanville fritillary
butterfly, *Melitaea cinxia*.

### EasyImport container

The EasyImport container writes to and reads from the mySQL container and creates files
for the SequenceServer and h5ai containers so the run command is dominated by the volumes to
mount. Configuration of this container uses files in `demo/genomehubs-mirror/import/conf`
along with some environment variables. Two configuration files are provided in this tutorial,
`.defaults.ini` contains parameters that are likely to remain constant across all assemblies is
loaded first and `.overwrite.ini` which is designed to allow quick updating of database connection
settings, passwords, etc. is loaded last.  A third file is required `<database name>.ini`, which
will be loaded in between the two provided files. `<database name>.ini` contains parameters specific
to the current assembly (particularly metadata) if the database already exists (as is the case in this
example) a `<database name>.ini` file can be generated automatically using the `DATABASE` environment
variable and connection settings specified in the other `.ini` files.

`FLAGS` are used to control which EasyImport scripts are run, in this example `-e` runs the
`export_sequences.pl` script to generate sequence files for downloading and BLAST, `-j` runs the
`export_json.pl` script to generate json files used by the [assembly-stats](https://github.com/rjchallis/assembly-stats)
and [codon-usage](https://github.com/rjchallis/codon-usage) visualisations on species
home pages and `-i` runs the `index_database.pl` script to provide search. Full details of
these scripts and configuration options is available at [easy-import.readme.io](http://easy-import.readme.io).

```
docker run -d \
           --name easy-import-melitaea_cinxia_core_32_85_1 \
           --link genomehubs-mysql \
           -v ~/demo/genomehubs-mirror/import/conf:/import/conf \
           -v ~/demo/genomehubs-mirror/import/data:/import/data \
           -v ~/demo/genomehubs-mirror/download/data:/import/download \
           -v ~/demo/genomehubs-mirror/blast/data:/import/blast \
           -e DATABASE=melitaea_cinxia_core_32_85_1 \
           -e FLAGS="-e -j -i" \
           easy-import
```

Since these scripts extract and process all entries in the Ensembl database, they will take
a few minutes to run. progress can be monitored by checking `docker logs easy-import-melitaea_cinxia_core_32_85_1`
or using `top`/`htop`

Once all scripts have finished, remove the container using

```
docker stop easy-import-melitaea_cinxia_core_32_85_1 && docker rm easy-import-melitaea_cinxia_core_32_85_1
```

### h5ai (downloads) container

Once the files have been generated using EasyImport, they are ready to be viewed on the h5ai
downloads server. The `~/demo/genomehubs-mirror/download/data` directory can be mounted anywhere
under `/var/www` but not directly to `/var/www`.

```
docker run -d \
           --name genomehubs-h5ai \
           -v ~/demo/genomehubs-mirror/download/conf:/conf \
           -v ~/demo/genomehubs-mirror/download/data:/var/www/demo \
           -p 8082:8080 \
           genomehubs/h5ai:latest
```

Check that the downloads server is available at `http://127.0.0.1:8082` and that it
contains some browsable directories/files.

### SequenceServer (BLAST) container

The SequenceServer BLAST container can be started in a similar way. Several configuration
options are available by placing files in `demo/genomehubs-mirror/blast/conf`. Of particular
note is the `links.rb` file, which specifies how to parse the sequence IDs to generate links
back to the ensembl site, and the base url for that site.

```
docker run -d \
           --name genomehubs-sequenceserver \
           -v ~/demo/genomehubs-mirror/blast/conf:/conf \
           -v ~/demo/genomehubs-mirror/blast/data:/dbs \
           -p 8083:4567 \
           genomehubs/sequenceserver:latest
```

Check that SequenceServer is available at `http://127.0.0.1:8083` and that it contains some
BLAST databases.

### Restart EasyMirror container

With all the components set up you are now ready to convert the basic Ensembl Mirror into a
GenomeHubs site by reloading the EasyMirror container with an updated configuration,
found in `demo/genomehubs-mirror/ensembl/gh-conf`. This uses the
[gh-ensembl-plugin](https://github.org/genomehubs/gh-ensembl-plugin)

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



## Visit site

The Ensembl mirror should be available at http://127.0.0.1:8081
