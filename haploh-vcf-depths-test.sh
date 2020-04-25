#!/bin/sh -e

../../local/bin/haploh-vcf-depths \
    'Josh-results/Haplo-output/3m/freeze.8.*.events.dat' \
    '../Jobs/864-samples/Josh-results/freeze.8.*-ad.vcf.xz'
