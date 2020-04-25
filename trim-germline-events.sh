#!/bin/sh -e

# Samples from Josh
event_dir=Josh-results/Haplo-output
cd $event_dir
mkdir -p 3m

# (1) Remove any events < 3Mb in length.
for filename in freeze.8.*.events.dat; do
    filename_3m="3m/$filename"
    #printf "$filename $filename_3m\n"
    
    # (1) Remove any events < 3Mb in length.
    awk 'NR == 1 || $3 - $2 >= 3000000 { print $0 }' $filename > $filename_3m
    #wc -l $filename_3m | awk '{ print $1 }'
    if [ $(wc -l $filename_3m | awk '{ print $1 }') = 1 ]; then
	rm $filename_3m
    fi
done

cd 3m
wc -l *
printf "Total events = %u\n" $(fgrep -v BEGIN * | wc -l | awk '{ print $1 }')

# (2) Remove any events that overlap with known germ-line events as defined in the attached.
# Sasha in Paul's lab suggests 50% reciprocal overlap as the criteria. Here is the relevant
# bedtools command:
printf "Overlaps with known germline events:\n"
for file in *.dat; do
    bedtools intersect -a $file -b ../../../hg38gains.all.autosomes.bed \
	-wa -wb -f 0.5 -r
done
wc -l *

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

for file in *.dat; do
    printf "$file\n"
    awk '{ print $2 $3 }' $file
done
