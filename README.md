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
