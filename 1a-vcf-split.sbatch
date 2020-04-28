#!/bin/sh -e

##########################################################################
#   Script description:
#       
#   History:
#   Date        Name        Modification
#   2019-12-08  Jason Bacon Begin
##########################################################################

# Notes:
#
# Filtering out calls with no het sites is probably useless with 137k
# samples per call.  Every call is likely to have at least one het site.
# Does not seem to work in conjunction with --samples.
# --samples NWDXXXX --genotype het produces lines with 1|1 or 0|0.
# Maybe checking all samples for het instead of just selected samples?
#
# vcftools is much slower than bcftools

# From bcf-bench:
# --min-ac + --genotype about doubles run time
# --min-ax + --samples increases run time by order of magnitude

##########################################################################
# vcf-split is limited by the number of open files your filesystem can
# write at once.  Tens of thousands are usually feasible on a high-end
# server.
# Keep in mind that they add up with parallel jobs accessing the same
# file server. Output initially to compute node local disk and use
#
#   #SBATCH --ntasks-per-node=1
#
# to get past this limit.

#SBATCH --array=1-22 --cpus-per-task=2
#SBATCH --mem=100
#SBATCH --output=SLURM-outputs/vcf-split-%A_%a.out
#SBATCH --error=SLURM-outputs/vcf-split-%A_%a.err

# If running outside scheduler, SLURM_ARRAY_TASK_ID will not be set.
# Create a dummy task ID of 21 for single-sample testing on dev server.
# 21 is the smallest of the chromosomes for which errors were reported
: ${SLURM_ARRAY_TASK_ID:=21}

if [ -e /raid-01/UITS/bacon/Pkgsrc/pkg-2019Q4 ]; then
    source /etc/bashrc
    module load /raid-01/UITS/bacon/Pkgsrc/pkg-2019Q4/etc/modulefiles/pkgsrc/2019Q4
fi

# ../../../local/bin version should be built with portable optimizations
# On FreeBSD, can also use ports version optimized for each compute node
export PATH=../../local/bin:$PATH
which bcftools vcf-split

# Make output file names sort lexically by chromosome number
chromosome=$(printf "%02d" $SLURM_ARRAY_TASK_ID)
echo $chromosome

output_dir=Split-vcfs
mkdir -p $output_dir
bcftools view --min-ac 2 --exclude-types indels \
    ../../phased/freeze.8.chr$SLURM_ARRAY_TASK_ID.pass_only.phased.bcf \
    | vcf-split --het-only --sample-id-file LLS_WHIMS_NWDID_TOPMED.csv \
    $output_dir/chr$chromosome. 1 137977
