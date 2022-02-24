#!/usr/bin/env  bash

# This is a test using a set of barley contigs and the Viridiplantae DB of proteins.
# This example does not have a BAM file nor RNASeq data.

### make a Workdir
workdir='/efs/Gabriel/braker2_test'
mkdir -p $workdir

### Select a repeat masked genome (2 contigs in this case)
maskedGenome="/efs/Gabriel/braker_test/genome_mask/bbarley.asm.2BLP.ctgs.fasta.masked"

### Select proteins DB, previosuly created according to BRAKER guidelines
proteins="$HOME/Viridiplantae/proteins.fasta"

### Copy the input data to the Workdir
cp -Rfv $maskedGenome $workdir
cp -Rfv $proteins $workdir

### RUN BRAKER from docker
docker run --rm \
  -u $UID:$GROUPS \
  -v $workdir:/data \
  braker2 \
   braker.pl \
   --genome="bbarley.asm.2BLP.ctgs.fasta.masked" \
   --prot_seq="proteins.fasta" \
   --species="Hordeum_vulgare" \
   --cores=8 \
   --workingdir=/data \
   --softmasking && \
echo "Finished"
