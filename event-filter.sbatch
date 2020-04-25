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
set event_dir=Josh-results/Haplo-output/3m
cd $event_dir
set filenames=(`ls freeze.8.*.events.dat`)

set filename=$filenames[$SLURM_ARRAY_TASK_ID]
set filename_3m="3m/$filename"

printf "$filename $filename_3m\n"
exit

# (1) Remove any events < 3Mb in length.
awk 'NR == 1 || $3 - $2 >= 3000000 { print $0 }' $filename > $filename_3m
if [ $(wc -l $filename_3m) = 1 ]; then
    rm $filename_3m
fi
exit

# (2) Remove any events that overlap with known germ-line events as defined in the attached.
# Sasha in Paul's lab suggests 50% reciprocal overlap as the criteria. Here is the relevant
# bedtools command:
bedtools intersect -a $filename_3m -b ../../hg38gains.all.autosomes.bed \
    -wa -wb -f 0.5 -r

# (3) For any remaining events, check the "median depth" as we discussed last
# week. Specifically, calculate the median depth at the event interval in the
# corresponding -ad.vcf file. Then calculate the median depth on the same
# interval across all the other -ad.vcf files. Store the result in some other
# text file in the output directory.

# Example:
#
# freeze.8.NWD171090.events.dat:
# CHR     BEGIN   END     EVENT_STATE     NUM_INFORMATIVE_MARKERS MEAN_POSTPROB   PHASE_CONCORDANCE
# chr6    57261075        60300322        S1      1157    0.979014        0.896283
#
# freeze.8.NWD171090-ad.vcf
# chr6    57261075        .       T       C       .       .       .       GT:AD:DP
#   1|0:16,25:41


# You'll see that I created a "make_plots.R" function in the ~/Data/TOPMed/
# directory. For any events that pass the (1)-(2) filters above, we can then
# create the relevant plots. I can show you how the R script works, should
# only take ~5-10 mintues to explain.
