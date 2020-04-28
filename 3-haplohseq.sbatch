#!/usr/bin/env bash

#SBATCH --array=1-864%100
#SBATCH --mem=1g
#SBATCH --output=SLURM-outputs/haplohseq-%A_%a.out
#SBATCH --error=SLURM-outputs/haplohseq-%A_%a.err

# Exit on any failed command
set -e

# Dummy value for testing outside SLURM env
: ${SLURM_ARRAY_TASK_ID:=1}

# ad2vcf outputs from Josh
vcf_dir=Josh-results
cd $vcf_dir

output_dir=Haplo-output
mkdir -p $output_dir

filenames=(`ls *.vcf.xz`)
filename=${filenames[$SLURM_ARRAY_TASK_ID]}
filename_prefix=`echo $filename | cut -d - -f 1`
printf "$filename $filename_prefix $output_dir\n"

# ../../../local/bin version should be built with portable optimizations
# On FreeBSD, can also use ports version optimized for each compute node
export PATH=../../../local/bin:$PATH
which vcf2hap haplohseq

# Generate hap file from VCF
printf "\nSTEP 1: GENERATING HAPLOTYPE FILES...\n"

if [ ! -e $filename_prefix-ad.hap ]; then
    # haplohseq needs a raw VCF input, so we might as well unpack it now
    # and avoid uncompressing the .xz twice
    if [ ! -e $filename_prefix-ad.vcf ]; then
	printf "Uncompressing VCF for vcf2hap and haplohseq...\n"
	if ! unxz --keep $filename_prefix-ad.vcf.xz; then
	    mkdir -p Broken-xz
	    mv $filename_prefix-ad.vcf.xz Broken-xz
	    exit 1
	fi
    fi
    printf "Generating .hap file...\n"
    vcf2hap $filename_prefix \
	< $filename_prefix-ad.vcf > $filename_prefix-ad.hap
fi

# Identify allelic imbalance (AI) given a tumor
# exome VCF file generated using the UnifiedGenotyper
# of the GATK. This involves the following 3 steps.

# Our files are already phased
# printf "STEP 1: PHASING 1KG HET SITES ...\n"
# python ../scripts/simple_phaser.py \
#  --ldmap ../ldmap/hg19.exome.ldmap \
#  --vcf example_input/tumor_exome.vcf \
#  -o example_output/tumor_exome

printf "\nSTEP 2: IDENTIFYING REGIONS OF AI ...\n"

if [ -e $output_dir/$filename_prefix.posterior.dat ]; then
    printf "haplohseq already done.\n"
else
    time haplohseq \
	--vcf $filename_prefix-ad.vcf \
	--phased $filename_prefix-ad.hap \
	--event_prevalence 0.1 \
	-d $output_dir \
	-p $filename_prefix
fi

# Save space
# rm -f $filename_prefix-ad.vcf $filename_prefix-ad.hap
exit 0

# Should not be needed
if [ -e $output_dir/${filename}_haplohseq.png ]; then
    printf "Plotting already done.\n"
else
    printf "\nSTEP 3: PLOTTING HAPLOHSEQ GENOMIC AI PROFILE ...\n"
    time Rscript /usr/local/share/examples/haplohseq/scripts/haplohseq_plot.R \
	--file $output_dir/$filename_prefix.posterior.dat \
	--out $output_dir \
	--prefix ${filename}_haplohseq
fi
