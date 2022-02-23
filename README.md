# braker2-docker
Docker container for running braker2 gene finder 

# Inspired by https://github.com/blaxterlab/braker-docker

To use this docker you should

    checkout this repo:

git clone https://github.com/glichtenstein/braker2-docker.git
cd braker2-docker

    Download your OWN copy of the genemark executables and key which you can get from http://exon.gatech.edu/GeneMark/license_download.cgi (pick the GeneMark-ES / ET v.4.64 LINUX 64 option for this docker) and save gm_key_64.gz and gmes_linux_64.tar.gz in the braker2-docker folder

    Run docker build:

docker build -t braker2 .

    Go to the folder where you have the aligned.bam and genome.fasta files (or replace pwd with the absolute path of that folder) and run braker:

docker run --rm \
  -u $UID:$GROUPS \
  -v `pwd`:/data \
  braker \
  braker.pl --species=YOURSPECIESNAME --UTR=on --cores=8 \
  --genome=/data/genome.fasta \
  --bam=/data/aligned.bam
