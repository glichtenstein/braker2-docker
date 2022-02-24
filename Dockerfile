FROM ubuntu:focal
LABEL maintainer "gabriel.lichtenstein@gmail.com"
# Build a Docker image based on Ubuntu 20.04 (focal)

# Inspired by Blaxter's Lab braker-docker:
# https://raw.githubusercontent.com/blaxterlab/braker-docker/master/Dockerfile

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=Asia/Israel

# Enable this ENVs if running from within Weizamnn Institute's AWS
ENV https_proxy=http://10.150.50.52:8080
ENV http_proxy=http://10.150.50.52:8080
ENV NO_PROXY=169.254.169.254,.s3.eu-west-1.amazonaws.com,.ec2.eu-west-1.amazonaws.com,.ecs.eu-west-1.amazonaws.com,.ecs-agent.amazonaws.com,.ecr.eu-west-1.amazonaws.com,.ec2messages.eu-west-1.amazonaws.com,.cloudformation.eu-west-1.amazonaws.com,.ssm.eu-west-1.amazonaws.com,.ssmmessages.eu-west-1.amazonaws.com

RUN apt update && apt upgrade -y -q

####################################################################################
# Install dependencies with aptitude
####################################################################################
RUN apt install -y -q \
    git cmake cpanminus build-essential autoconf automake make gcc perl python \
    zlib1g-dev libbz2-dev liblzma-dev libcurl4-gnutls-dev libssl-dev libncurses5-dev \
    libboost-iostreams-dev libboost-system-dev libboost-filesystem-dev \
    wget gzip

####################################################################################
# Install required Perl CPAN modules
####################################################################################
RUN cpanm File::Spec::Functions Hash::Merge List::Util MCE::Mutex \
    Module::Load::Conditional Parallel::ForkManager POSIX Scalar::Util::Numeric \
    YAML Math::Utils File::HomeDir threads;

####################################################################################
# Get GeneMark-ES/ET/EP
####################################################################################
# Manually download GenMark ES Software and Licence from:
# http://topaz.gatech.edu/GeneMark/license_download.cgi
# For example, select: GeneMark-ES/ET/EP ver 4.69_lic for LINUX 64
# and save it inside the folder where the Dockerfile is located
COPY gmes_linux_64.tar.gz /
RUN tar -xzf gmes_linux_64.tar.gz
# Set PATH
ENV GENEMARK_PATH /gmes_linux_64/

####################################################################################
# BRAKER
####################################################################################
#http://topaz.gatech.edu/GeneMark/braker.html
RUN git clone https://github.com/Gaius-Augustus/BRAKER.git;
# Set perms
RUN chmod a+x BRAKER/scripts/*.pl; chmod a+x BRAKER/scripts/*.py
# Set PATH
ENV PATH $PATH:/BRAKER/scripts/

####################################################################################
# SAMTOOLS & BAMTOOLS
####################################################################################
RUN apt-get install samtools -y -q
RUN apt-get install bamtools -y -q

####################################################################################
# DIAMOND
####################################################################################
RUN wget http://github.com/bbuchfink/diamond/releases/download/v0.9.24/diamond-linux64.tar.gz
RUN tar xzvf diamond-linux64.tar.gz
# Set PATH
ENV DIAMOND_PATH /diamond-linux64

####################################################################################
# ProtHint
####################################################################################
RUN git clone https://github.com/gatech-genemark/ProtHint.git
# Set PATH
ENV PROTHINT_PATH /ProtHint/bin

####################################################################################
# cdbfasta
####################################################################################
RUN git clone https://github.com/gpertea/cdbfasta.git
WORKDIR "/cdbfasta"
RUN make all
#RUN make install
# Set PATH
ENV CDBTOOLS_PATH /cdbfasta

####################################################################################
# AUGUSTUS
####################################################################################
### START
# source: https://github.com/Gaius-Augustus/Augustus/blob/master/Dockerfile
# Install required packages
RUN apt-get update
RUN apt-get install -y build-essential wget git autoconf

# Install dependencies for AUGUSTUS comparative gene prediction mode (CGP)
RUN apt-get install -y libgsl-dev libboost-all-dev libsuitesparse-dev liblpsolve55-dev
RUN apt-get install -y libsqlite3-dev libmysql++-dev

# Install dependencies for the optional support of gzip compressed input files
RUN apt-get install -y libboost-iostreams-dev zlib1g-dev

# Install dependencies for bam2hints and filterBam
RUN apt-get install -y libbamtools-dev

# Install additional dependencies for bam2wig
RUN apt-get install -y samtools libhts-dev

# Install additional dependencies for homGeneMapping and utrrnaseq
RUN apt-get install -y libboost-all-dev

# Install additional dependencies for scripts
RUN apt-get install -y cdbfasta diamond-aligner libfile-which-perl libparallel-forkmanager-perl libyaml-perl libdbd-mysql-perl
RUN apt-get install -y --no-install-recommends python3-biopython

# Install hal - required by homGeneMapping
# execute the commented out code if you want to use this program - see auxprogs/homGeneMapping/Dockerfile
#RUN apt-get install -y libhdf5-dev
#RUN git clone https://github.com/benedictpaten/sonLib.git /opt/sonLib
#WORKDIR /opt/sonLib
#RUN make
#RUN git clone https://github.com/ComparativeGenomicsToolkit/hal.git /opt/hal
#WORKDIR /opt/hal
#ENV RANLIB=ranlib
#RUN make
#ENV PATH="${PATH}:/opt/hal/bin"

# Clone AUGUSTUS repository
RUN git clone https://github.com/Gaius-Augustus/Augustus.git /Augustus;

# Build AUGUSTUS
WORKDIR "/Augustus"
RUN pwd
RUN ls -hal ./
RUN make clean
RUN make
RUN make install
# Set PATH
ENV PATH="/Augustus/bin:/Augustus/scripts:${PATH}"
ENV AUGUSTUS_CONFIG_PATH /Augustus/config/
RUN chmod 0777 -Rfv /Augustus/config
# Test AUGUSTUS
RUN make unit_test
### END

####################################################################################
# DOCKERUSER
####################################################################################
RUN adduser --disabled-password --gecos '' ec2-user
RUN mkdir /data
RUN chown -R ec2-user /data
USER ec2-user
WORKDIR /data

####################################################################################
# GENEMARK KEY
####################################################################################
COPY gm_key_64.gz /
RUN zcat /gm_key_64.gz > ~/.gm_key
