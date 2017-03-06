# GenomeHubs example configurations

Example configurations to set up custom [Ensembl](http://ensembl.org) sites using [GenomeHubs](http://genomehubs.org)

- [Basic mirror setup](basic-mirror) - the simplest Ensembl mirror site setup
- [GenomeHubs mirror setup](genomehubs-mirror) - an Ensembl mirror site using the
  GenomeHubs plugin, including separate BLAST and download containers
- [GenomeHubs import](genomehubs-import) - a full GenomeHubs site hosting the
  an assembly and gene models imported from FASTA + GFF

Either follow the full tutorials at [genomehubs.org](http://genomehubs.org/documentation/) or
try out the example scripts to get a GenomeHubs Ensembl site up and running as quickly as
possible.

- `demo.sh` - set up a GenomeHubs site hosting a mirror of the core database for the Glanville fritillary, *Melitaea cinxia*
- `import.sh` - import the genome of the winter moth, *Operophtera brumata*, into a GenomeHubs site from FASTA and GFF

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
