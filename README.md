# GenomeHubs example configuration and demo script

Example configuration to set up custom [Ensembl](http://ensembl.org) site using [GenomeHubs](http://genomehubs.org)

- [GenomeHubs import](genomehubs-import) - a full GenomeHubs site hosting the
  an assembly and gene models imported from FASTA + GFF

Either follow the full tutorial at [genomehubs.gitbooks.io](https://genomehubs.gitbooks.io/genomehubs) or
try out the example script to get a GenomeHubs Ensembl site up and running as quickly as
possible.

```
cd
git clone https://github.com/genomehubs/demo
cd demo
./demo.sh 
```

Sets up a GenomeHubs site hosting a mirror of the core database for the Glanville fritillary, *Melitaea cinxia*
and imports the genome of the winter moth, *Operophtera brumata*, into a GenomeHubs site from FASTA and GFF

## Troubleshooting

- If the easy-mirror container is unable to connect to the mysql-server container this is usually
  because the mysql-server cintainer configuration did not finish before the easy-mirror container
  started. This will usually be resolved by rerunning the script.

- If the containers already exist when either demo script is run, they will be removed. Rerun the
  the script to continue.

- If any of the containers fail to run correctly with a permissions error this is likely to be
  due to running the scripts as a user with a UID other than 1000. There are work arounds for this
  but we are unable to support problems caused by incompatible users/permissions. Try again on a
  server/vm wher you are able to run Docker as UID 1000.

- If you are not running Docker on a local machine and are unable to access the site on 127.0.0.1:8881,
  try following [these suggestions](https://genomehubs.gitbooks.io/genomehubs/content/demo.html)
  to access the site.
