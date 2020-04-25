#!/bin/csh -ef

#SBATCH --array=1-864%100
##SBATCH --cpus-per-task=3
#SBATCH --mem=1g
##SBATCH --exclude=compute-[001-008,012]
#SBATCH --output=Josh-results/slurm-%j.out
#SBATCH --error=Josh-results/slurm-%j.err

# Dummy value for testing outside SLURM env
if ( ! $?SLURM_ARRAY_TASK_ID ) then
    setenv SLURM_ARRAY_TASK_ID 1
endif

# Samples from Josh
set vcf_dir=Josh-results
cd $vcf_dir
set filenames=(`ls *.vcf.xz`)

# set samples=(`ls ../../SRR6990379/*.cram | cut -d / -f 4 | cut -d . -f 1`)
# set sample=$samples[$SLURM_ARRAY_TASK_ID]
# set vcf_dir=10058

set filename=$filenames[$SLURM_ARRAY_TASK_ID]
set filename_prefix=`echo $filename | cut -d - -f 1`
set output_dir=Haplo-output

printf "$filename $filename_prefix $output_dir\n"

mkdir -p $output_dir

set path=(../../../local/bin $path)
echo $PATH
which vcf2hap haplohseq

rm -f $filename_prefix-ad.hap
# Generate hap file from VCF
printf "\nSTEP 2: GENERATING HAPLOTYPE FILES...\n"
if ( ! -e $filename_prefix-ad.hap ) then
    if ( ! -e $filename_prefix-ad.vcf ) then
	printf "Uncompressing VCF for vcf2hap and haplohseq...\n"
	unxz --keep $filename_prefix-ad.vcf.xz
    endif
    printf "Generating .hap file...\n"
    vcf2hap $filename_prefix < $filename_prefix-ad.vcf > $filename_prefix-ad.hap
endif

# Identify allelic imbalance (AI) given a tumor
# exome VCF file generated using the UnifiedGenotyper
# of the GATK. This involves the following 3 steps.

#printf "STEP 1: PHASING 1KG HET SITES ...\n"
#python ../scripts/simple_phaser.py \
#  --ldmap ../ldmap/hg19.exome.ldmap \
#  --vcf example_input/tumor_exome.vcf \
#  -o example_output/tumor_exome

printf "\nSTEP 2: IDENTIFYING REGIONS OF AI ...\n"
if ( -e $output_dir/$filename_prefix.posterior.dat ) then
    printf "haplohseq already done.\n"
else
    if ( ! -e $filename_prefix-ad.vcf ) then
	# haplohseq needs a raw VCF input?
	printf "Uncompressing VCF for haplohseq...\n"
	unxz --keep $filename_prefix-ad.vcf.xz
    endif
    time haplohseq \
	--vcf $filename_prefix-ad.vcf \
	--phased $filename_prefix-ad.hap \
	--event_prevalence 0.1 \
	-d $output_dir \
	-p $filename_prefix
endif

# Save space
# rm -f $filename_prefix-ad.vcf $filename_prefix-ad.hap
exit 0

if ( -e $output_dir/${filename}_haplohseq.png ) then
    printf "Plotting already done.\n"
else
    printf "\nSTEP 3: PLOTTING HAPLOHSEQ GENOMIC AI PROFILE ...\n"
    time Rscript /usr/local/share/examples/haplohseq/scripts/haplohseq_plot.R \
	--file $output_dir/$filename_prefix.posterior.dat \
	--out $output_dir \
	--prefix ${filename}_haplohseq
endif
