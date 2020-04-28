#!/bin/sh -e

# Run gsutil config once to set up credentials

gsutil cp gs://topmed-allelic-depths-share/\* .
