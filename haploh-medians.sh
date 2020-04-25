#!/bin/sh -e

for file in Depths/*; do
    printf "$file: "
    ../../local/bin/basic-stats --median 1 < $file
done
