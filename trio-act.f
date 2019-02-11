#!/bin/bash
GENOME_FASTA=~/refs/refs/broad_human_bundle_hg37/Homo_sapiens_assembly19.fasta
GATK=~/tools/GATK_3.8.0/GenomeAnalysisTK.jar
SAMPLE_DIR=$1

#### Depth, Zygosity, Quality
java -Xmx320G -XX:ParallelGCThreads=96 -jar $GATK -T VariantsToTable \
-R $GENOME_FASTA -V $SAMPLE_DIR/trio.vcf -F CHROM -F POS -F REF -F ALT \
-F DP -GF AD -GF GQ -GF GT -raw -o $SAMPLE_DIR/trio.table.tmp

sed -i -r \
"1s/CHROM/Chr/g;1s/POS/Start/g;1s/REF/Ref/g;1s/ALT/Alt/g;1s/DP/Depth/g;1s/\S+variant2/INDEL/g;1s/\S+variant/SNP/g" \
$SAMPLE_DIR/trio.table.tmp

# merge ANNOVAR and VCF tables
join -t $'\t' -1 1 -2 1 -a1 \
<(paste <(sed "s/\s/<>/g" <(awk '{print $1,$2,$4,$5}' $SAMPLE_DIR/trio.annotation.hg19_multianno.txt)) \
$SAMPLE_DIR/trio.annotation.hg19_multianno.txt | sort -k1) \
<(paste <(sed "s/\s/<>/g" <(awk '{print $1,$2,$3,$4}' $SAMPLE_DIR/trio.table.tmp)) \
<(cut -f 5- $SAMPLE_DIR/trio.table.tmp) |sort -k1) \
| sort -k2,2 -V -s > $SAMPLE_DIR/report.table.tmp

cut -f 2- $SAMPLE_DIR/report.table.tmp > $SAMPLE_DIR/report.table

# Change headers of individuals - trio
child=$(sed -n 1p $SAMPLE_DIR/ped.ped | awk '{print $2}')
father=$(sed -n 1p $SAMPLE_DIR/ped.ped | awk '{print $3}')
mother=$(sed -n 1p $SAMPLE_DIR/ped.ped | awk '{print $4}')
sed -i "1s/$child/child/g" $SAMPLE_DIR/report.table
sed -i "1s/$father/father/g" $SAMPLE_DIR/report.table
sed -i "1s/$mother/mother/g" $SAMPLE_DIR/report.table

# Additional columns : zygosity
python3 ~/4combined_scripts/zygosityMaker.py $SAMPLE_DIR/report.table "child"
python3 ~/4combined_scripts/zygosityMaker.py $SAMPLE_DIR/report.table "father"
python3 ~/4combined_scripts/zygosityMaker.py $SAMPLE_DIR/report.table "mother"

# Additional columns : AD scores
python3 ~/4combined_scripts/ADScoresMaker.py $SAMPLE_DIR/report.table "child"
python3 ~/4combined_scripts/ADScoresMaker.py $SAMPLE_DIR/report.table "father"
python3 ~/4combined_scripts/ADScoresMaker.py $SAMPLE_DIR/report.table "mother"

#header_row=$(grep -nP "Chr<>" $SAMPLE_DIR/report.table.tmp)
#sed -i ${header_row}d $SAMPLE_DIR/report.table.tmp
#cat header.line $SAMPLE_DIR/report.table.tmp | cut -f 2- > $SAMPLE_DIR/report.table && rm header.line


rm $SAMPLE_DIR/*tmp*

### Filtration
sed -n 1p $SAMPLE_DIR/report.table > $SAMPLE_DIR/filtered_variants.txt && \
awk -F "\t" -v OFS="\t" \
-v exonic=$(sed -n 1p $SAMPLE_DIR/trio.annotation.hg19_multianno.txt | tr '\t' '\n' | grep -n "ExonicFunc.refGene" | cut -d : -f 1) \
-v exac_all=$(sed -n 1p $SAMPLE_DIR/trio.annotation.hg19_multianno.txt | tr '\t' '\n' | grep -n "ExAC_ALL" | cut -d : -f 1) \
-v sift=$(sed -n 1p $SAMPLE_DIR/trio.annotation.hg19_multianno.txt | tr '\t' '\n' | grep -n "SIFT_pred" | cut -d : -f 1) \
-v pphen=$(sed -n 1p $SAMPLE_DIR/trio.annotation.hg19_multianno.txt | tr '\t' '\n' | grep -n "Polyphen2_HVAR_pred" | cut -d : -f 1) \
-v prov=$(sed -n 1p $SAMPLE_DIR/trio.annotation.hg19_multianno.txt | tr '\t' '\n' | grep -n "PROVEAN_pred" | cut -d : -f 1) \
'{if($exonic=="frameshift insertion"||$exonic=="frameshift deletion"||\
$exonic=="stoploss"||$exonic=="stopgain"||$exonic=="nonsynonymous SNV")\
if($exac_all<0.002)\
if($sift=="D")if($pphen=="D"||$pphen=="P")if($prov=="D")print $_}' \
$SAMPLE_DIR/report.table >> $SAMPLE_DIR/filtered_variants.txt

## Manipulate columns
awk -F "\t" -v OFS="\t" \
-v exac_all=$(sed -n 1p $SAMPLE_DIR/report.table | tr '\t' '\n' | grep -n "ExAC_ALL" | cut -d : -f 1) \
'{if($exac_all==".")$exac_all="-1"}\
{print $_}' $SAMPLE_DIR/report.table > $SAMPLE_DIR/report.table.temp && \
cat $SAMPLE_DIR/report.table.temp > $SAMPLE_DIR/report.table

awk -F "\t" -v OFS="\t" \
-v exac_all=$(sed -n 1p $SAMPLE_DIR/filtered_variants.txt | tr '\t' '\n' | grep -n "ExAC_ALL" | cut -d : -f 1) \
'{if($exac_all==".")$exac_all="-1"}\
{print $_}' $SAMPLE_DIR/filtered_variants.txt > $SAMPLE_DIR/filtered_variants.txt.temp && \
cat $SAMPLE_DIR/filtered_variants.txt.temp > $SAMPLE_DIR/filtered_variants.txt

rm $SAMPLE_DIR/*temp*


# Column sort and Iranome
perl ~/4combined_scripts/iranome.pl $SAMPLE_DIR/filtered_variants.txt \
> $SAMPLE_DIR/fltr.tmp && cat $SAMPLE_DIR/fltr.tmp > $SAMPLE_DIR/filtered_variants.txt
rm $SAMPLE_DIR/fltr.tmp

~/4combined_scripts/columnSorter.bash $SAMPLE_DIR/report.table
~/4combined_scripts/columnSorter.bash $SAMPLE_DIR/filtered_variants.txt
