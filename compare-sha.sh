#!/bin/sh -e

for sample in $(cat failing-samples2.txt); do
    echo $sample
    xzcat 9949/combined.$sample.vcf.xz | sha256
done
