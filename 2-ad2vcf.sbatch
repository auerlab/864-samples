#!/bin/csh -ef

#SBATCH --array=1-22
#SBATCH --cpus-per-task=3
#SBATCH --mem=1g

# Create array of filenames (1-based)
# set samples=(`ls ../../SRR6990379/*.cram | cut -d / -f 4 | cut -d . -f 1`)

# Samples that failed for Josh
set samples=(`cat buffer-overflow-samples.txt`)

if ( -e /sharedapps/pkg-2019Q2/bin/samtools ) then
    source /etc/csh.cshrc
    module load /sharedapps/pkg-2019Q2/etc/modulefiles/pkgsrc/2019Q2
endif

cd $vcf_dir

# Version from ports is built with -march=native on all nodes
setenv PATH ../../../local/bin:${PATH}
which ad2vcf

printf "ad2vcf: processing $samples[$SLURM_ARRAY_TASK_ID]...\n"
samtools view -@ 2 --input-fmt-option required_fields=0x208 \
	../../../SRR6990379/$samples[$SLURM_ARRAY_TASK_ID].b38.irc.v1.cram \
    | ad2vcf combined.$samples[$SLURM_ARRAY_TASK_ID].vcf.xz
echo $status
