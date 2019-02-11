#!/bin/bash

## # NOTE : 06.07.2018 : Threads divided also for each Java process
## # NOTE : 06.07.2018 : Threads divided for GATK programs with "-nct" paramter
## For info about parallelis m in GATK :
## 	https://gatkforums.broadinstitute.org/gatk/discussion/1975/how-can-i-use-parallelism-to-make-gatk-tools-run-faster

# Sample parameters (potentially needs to be modified
# Input and output directories
FASTQ_DIR=$1
thread=$2
memory=$3
export _JAVA_OPTIONS="-Xmx""$memory""G"
for FASTQ_FULL_PATH in $(ls $FASTQ_DIR)
do
	ls $FASTQ_DIR
	if [[ $FASTQ_FULL_PATH == *"001.fastq"* ]]
	then
		SAMPLE_NAME=$(echo $FASTQ_FULL_PATH | cut -d _ -f 1)
		SAMPLE_LIBRARY=$(echo $FASTQ_FULL_PATH | cut -d _ -f 2)
		SAMPLE_NUMBER=$(echo $FASTQ_FULL_PATH | cut -d _ -f 2)
		SAMPLE_PREFIX="$SAMPLE_NAME"_"$SAMPLE_NUMBER"
	fi
done
SAMPLE_DIR="/gpfs/user/abayraktar/FASTQ-OUTPUTS/""$(basename $FASTQ_DIR)"_"BRONZE_HardFiltered"
PLATFORM="illumina"

mkdir $SAMPLE_DIR
########################################

LANE1_R1=$SAMPLE_PREFIX\_L001_R1_001.fastq.gz
LANE2_R1=$SAMPLE_PREFIX\_L002_R1_001.fastq.gz
LANE3_R1=$SAMPLE_PREFIX\_L003_R1_001.fastq.gz
LANE4_R1=$SAMPLE_PREFIX\_L004_R1_001.fastq.gz
LANE1_R2=$SAMPLE_PREFIX\_L001_R2_001.fastq.gz
LANE2_R2=$SAMPLE_PREFIX\_L002_R2_001.fastq.gz
LANE3_R2=$SAMPLE_PREFIX\_L003_R2_001.fastq.gz
LANE4_R2=$SAMPLE_PREFIX\_L004_R2_001.fastq.gz

BQSR_DIR=$SAMPLE_DIR/BQSR_output
FILTER_DIR=$SAMPLE_DIR/Filtered_output
VAR_DIR=$SAMPLE_DIR/Variants_output

# Genome reference and tool paths used in pipeline: PICARD, GATK, AnnoVar
REF_DIR=~/refs/refs/broad_human_bundle_hg37
GENOME_FASTA=$REF_DIR/Homo_sapiens_assembly19.fasta
PICARD=~/tools/picard-tools-1.140/picard.jar
GATK=~/tools/GATK_3.8.0/GenomeAnalysisTK.jar
ANNOVAR=~/tools/annovar

# Calibration sets used in BQSR and VQSR
HAPMAP=$REF_DIR/hapmap_3.3.hg19.sites.vcf
OMNI=$REF_DIR/1000G_omni2.5.hg19.sites.vcf
G1000G=$REF_DIR/1000G_phase1.snps.high_confidence.hg19.sites.vcf
DBSNP=$REF_DIR/dbsnp_138.hg19.vcf
INDEL=$REF_DIR/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf

#Step 1.1.1
mkdir $SAMPLE_DIR/Lane1 $SAMPLE_DIR/Lane2 $SAMPLE_DIR/Lane3 $SAMPLE_DIR/Lane4
bwa mem -t $((thread/4)) -M -p $GENOME_FASTA $FASTQ_DIR/$LANE1_R1 $FASTQ_DIR/$LANE1_R2 > $SAMPLE_DIR/Lane1/aligned_reads.sam &
wait
bwa mem -t $((thread/4)) -M -p $GENOME_FASTA $FASTQ_DIR/$LANE2_R1 $FASTQ_DIR/$LANE2_R2 > $SAMPLE_DIR/Lane2/aligned_reads.sam &
wait
bwa mem -t $((thread/4)) -M -p $GENOME_FASTA $FASTQ_DIR/$LANE3_R1 $FASTQ_DIR/$LANE3_R2 > $SAMPLE_DIR/Lane3/aligned_reads.sam &
wait
bwa mem -t $((thread/4)) -M -p $GENOME_FASTA $FASTQ_DIR/$LANE4_R1 $FASTQ_DIR/$LANE4_R2 > $SAMPLE_DIR/Lane4/aligned_reads.sam &

# Wait end of previous step
wait

#Step 1.1.2
java -Xmx"$memory"G -jar $PICARD SortSam INPUT=$SAMPLE_DIR/Lane1/aligned_reads.sam OUTPUT=$SAMPLE_DIR/Lane1/sorted_reads.bam SORT_ORDER=coordinate &
java -Xmx"$memory"G -jar $PICARD SortSam INPUT=$SAMPLE_DIR/Lane2/aligned_reads.sam OUTPUT=$SAMPLE_DIR/Lane2/sorted_reads.bam SORT_ORDER=coordinate &
java -Xmx"$memory"G -jar $PICARD SortSam INPUT=$SAMPLE_DIR/Lane3/aligned_reads.sam OUTPUT=$SAMPLE_DIR/Lane3/sorted_reads.bam SORT_ORDER=coordinate &
java -Xmx"$memory"G -jar $PICARD SortSam INPUT=$SAMPLE_DIR/Lane4/aligned_reads.sam OUTPUT=$SAMPLE_DIR/Lane4/sorted_reads.bam SORT_ORDER=coordinate &

# Wait end of previous step
wait

#Step 1.1.3
java -Xmx"$memory"G -jar $PICARD AddOrReplaceReadGroups INPUT=$SAMPLE_DIR/Lane1/sorted_reads.bam  OUTPUT=$SAMPLE_DIR/Lane1/sorted_reads_RG.bam  ID=$SAMPLE_NAME\_L001 SM=$SAMPLE_NUMBER LB=$SAMPLE_LIBRARY PU=L001 PL=$PLATFORM &
java -Xmx"$memory"G -jar $PICARD AddOrReplaceReadGroups INPUT=$SAMPLE_DIR/Lane2/sorted_reads.bam  OUTPUT=$SAMPLE_DIR/Lane2/sorted_reads_RG.bam  ID=$SAMPLE_NAME\_L002 SM=$SAMPLE_NUMBER LB=$SAMPLE_LIBRARY PU=L002 PL=$PLATFORM &
java -Xmx"$memory"G -jar $PICARD AddOrReplaceReadGroups INPUT=$SAMPLE_DIR/Lane3/sorted_reads.bam  OUTPUT=$SAMPLE_DIR/Lane3/sorted_reads_RG.bam  ID=$SAMPLE_NAME\_L003 SM=$SAMPLE_NUMBER LB=$SAMPLE_LIBRARY PU=L003 PL=$PLATFORM &
java -Xmx"$memory"G -jar $PICARD AddOrReplaceReadGroups INPUT=$SAMPLE_DIR/Lane4/sorted_reads.bam  OUTPUT=$SAMPLE_DIR/Lane4/sorted_reads_RG.bam  ID=$SAMPLE_NAME\_L004 SM=$SAMPLE_NUMBER LB=$SAMPLE_LIBRARY PU=L004 PL=$PLATFORM &

# Wait end of previous step
wait

#Step 1.2.1
java -Xmx"$memory"G -jar $PICARD MarkDuplicates INPUT=$SAMPLE_DIR/Lane1/sorted_reads_RG.bam OUTPUT=$SAMPLE_DIR/Lane1/dedup_reads.bam METRICS_FILE=$SAMPLE_DIR/Lane1/metrics.txt &
java -Xmx"$memory"G -jar $PICARD MarkDuplicates INPUT=$SAMPLE_DIR/Lane2/sorted_reads_RG.bam OUTPUT=$SAMPLE_DIR/Lane2/dedup_reads.bam METRICS_FILE=$SAMPLE_DIR/Lane2/metrics.txt &
java -Xmx"$memory"G -jar $PICARD MarkDuplicates INPUT=$SAMPLE_DIR/Lane3/sorted_reads_RG.bam OUTPUT=$SAMPLE_DIR/Lane3/dedup_reads.bam METRICS_FILE=$SAMPLE_DIR/Lane3/metrics.txt &
java -Xmx"$memory"G -jar $PICARD MarkDuplicates INPUT=$SAMPLE_DIR/Lane4/sorted_reads_RG.bam OUTPUT=$SAMPLE_DIR/Lane4/dedup_reads.bam METRICS_FILE=$SAMPLE_DIR/Lane4/metrics.txt &

# Wait end of previous step
wait

#Step 1.2.2
java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $PICARD MarkDuplicates INPUT=$SAMPLE_DIR/Lane1/dedup_reads.bam INPUT=$SAMPLE_DIR/Lane2/dedup_reads.bam INPUT=$SAMPLE_DIR/Lane3/dedup_reads.bam INPUT=$SAMPLE_DIR/Lane4/dedup_reads.bam OUTPUT=$SAMPLE_DIR/dedup_reads.bam METRICS_FILE=$SAMPLE_DIR/dedup_metrics.txt 

#Step 1.2.3
java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $PICARD BuildBamIndex INPUT=$SAMPLE_DIR/dedup_reads.bam

#Step 1.3.1 - Analyze patterns of covariation in the sequence dataset - BQSR
mkdir $BQSR_DIR

java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $GATK -T BaseRecalibrator -nct $thread -R $GENOME_FASTA -I $SAMPLE_DIR/dedup_reads.bam \
-knownSites $INDEL -knownSites $DBSNP \
-o $BQSR_DIR/recal_data.table

#Step 1.3.2 - Secondary analysis after recalibration

java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $GATK -T BaseRecalibrator -nct $thread -R $GENOME_FASTA -I $SAMPLE_DIR/dedup_reads.bam \
-knownSites $INDEL -knownSites $DBSNP \
-BQSR $BQSR_DIR/recal_data.table \
-o $BQSR_DIR/post_recal_data.table

#Step 1.3.3 - before/after plots

java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $GATK -T AnalyzeCovariates -R $GENOME_FASTA \
-before $BQSR_DIR/recal_data.table \
-after $BQSR_DIR/post_recal_data.table \
-plots $BQSR_DIR/recalibration_plots.table

#Step 1.3.4- Recalibration to sequence data

# PrintReads has problem with nt and nct parameters
# Source: https://github.com/bcbio/bcbio-nextgen/issues/2145
# Source: https://gatkforums.broadinstitute.org/gatk/discussion/10353/gatk-3-8-0-printreads-fatal-error#latest
# Also dont use Java Xmx or other memory functions; let it run its own params
# Halfen memory?
java -jar $GATK -jdk_deflater -jdk_inflater -T PrintReads -R $GENOME_FASTA -I $SAMPLE_DIR/dedup_reads.bam \
-BQSR $BQSR_DIR/post_recal_data.table -o $BQSR_DIR/recal_reads.bam
wait
#Step 2.1
## Call Variants
mkdir $VAR_DIR

java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $GATK -T HaplotypeCaller -nct $thread -R $GENOME_FASTA -I $BQSR_DIR/recal_reads.bam \
-gt_mode DISCOVERY -stand_call_conf 30 -o $VAR_DIR/raw_variants.vcf

## Recalibrate variant recalibrate scores and produce a callset filtered for desired levels of sensitivity and specificity

#Step 2.4.filter - Extract the SNPs from the call set
mkdir $FILTER_DIR

java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $GATK -T SelectVariants -R $GENOME_FASTA \
-V $VAR_DIR/raw_variants.vcf \
-selectType SNP \
--out $FILTER_DIR/raw_snps.vcf

#Step 2.4.filter - Apply the filter to the SNP call set

java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $GATK -T VariantFiltration -R $GENOME_FASTA \
-V $FILTER_DIR/raw_snps.vcf \
--filterExpression "QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0" \
--filterName "GATK_snp_filter" \
--out $FILTER_DIR/filtered_snps.vcf

#Step 2.4.filter - Extract the INDELs from the call set
mkdir $FILTER_DIR

java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $GATK -T SelectVariants -R $GENOME_FASTA \
-V $VAR_DIR/raw_variants.vcf \
-selectType INDEL \
--out $FILTER_DIR/raw_indels.vcf

#Step 2.4.filter - Apply the filter to the INDEL call set

java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $GATK -T VariantFiltration -R $GENOME_FASTA \
-V $FILTER_DIR/raw_indels.vcf \
--filterExpression "QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0" \
--filterName "GATK_indel_filter" \
--out $FILTER_DIR/filtered_indels.vcf

#Step 2.4.filter - Extra: Combine both VCFs
java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $GATK -T CombineVariants -R $GENOME_FASTA \
--variant $FILTER_DIR/filtered_snps.vcf \
--variant $FILTER_DIR/filtered_indels.vcf \
--out $FILTER_DIR/filtered_variants.vcf \
-genotypeMergeOptions UNIQUIFY

#Step 3.2 - FINAL - ANNOTATE

perl $ANNOVAR/convert2annovar.pl -format vcf4 $FILTER_DIR/filtered_variants.vcf -outfile  $FILTER_DIR/outfile.avinput \
-allsample -withfreq -include

perl $ANNOVAR/table_annovar.pl $FILTER_DIR/outfile.avinput $ANNOVAR/humandb_hg37/ -buildver hg19 \
-out $SAMPLE_DIR/recalibrated_variants.annotation -remove \
-protocol refGene,knownGene,esp6500siv2_all,1000g2015aug_all,exac03,avsnp147,dbnsfp33a,clinvar_20170905,gnomad_exome,kaviar_20150923 \
-operation g,g,f,f,f,f,f,f,f,f -nastring .

/gpfs/user/abayraktar/4combined_scripts/act.f $SAMPLE_DIR