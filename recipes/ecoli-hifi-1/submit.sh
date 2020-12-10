#!/bin/sh

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

if [ -e canu/build/bin/canu ] ; then
  inst="build"
else
  inst="$syst-$arch"
fi

#  To make this script a little bit less specific to each assembly,
#  it needs the name of the assembly as the only argument.
#
#  Unfortunately, you still need to customize this script for genome
#  size and any special options.

recp=$1

if [ x$recp = x ] ; then
  echo "usage: $0 <recp>"
  exit 1
fi

if [ ! -e "../recipes/$recp/success.sh" ] ; then
  echo "Failed to find '../recipes/$recp/success.sh'."
  exit 1
fi

if [ ! -e "../recipes/$recp/failure.sh" ] ; then
  echo "Failed to find '../recipes/$recp/failure.sh'."
  exit 1
fi

#  SPECIFIC to this recipe: pick the compression format that exists on this system.
#
if [ -e "../recipes/$recp/reads/m54316_180808_005743.fastq.gz" ] ; then ext="gz" ; fi
if [ -e "../recipes/$recp/reads/m54316_180808_005743.fastq.xz" ] ; then ext="xz" ; fi


./canu/$inst/bin/canu \
  -p asm \
  -d $recp \
  genomeSize=4800000 \
  maxInputCoverage=60 readSamplingBias=1.1  \
  onSuccess=../../recipes/$recp/success.sh \
  onFailure=../../recipes/$recp/failure.sh \
  -pacbio-hifi ../recipes/$recp/reads/m54316_180808_005743.fastq.$ext

exit 0