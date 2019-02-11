#!/bin/bash

thread=$1
memory=$2
dir1=$3
dir2=$4
dir3=$5
ped=$6
family=$7

## Use with pedigree (PED) file as:
#################################################################################################
#################################################################################################
BQSR_DIR1=/gpfs/user/abayraktar/FASTQ-OUTPUTS/"$dir1"_BRONZE_HardFiltered/BQSR_output/
BQSR_DIR2=/gpfs/user/abayraktar/FASTQ-OUTPUTS/"$dir2"_BRONZE_HardFiltered/BQSR_output/
BQSR_DIR3=/gpfs/user/abayraktar/FASTQ-OUTPUTS/"$dir3"_BRONZE_HardFiltered/BQSR_output/

VAR_DIR1=/gpfs/user/abayraktar/FASTQ-OUTPUTS/"$dir1"_BRONZE_HardFiltered/Variants_output/
VAR_DIR2=/gpfs/user/abayraktar/FASTQ-OUTPUTS/"$dir2"_BRONZE_HardFiltered/Variants_output/
VAR_DIR3=/gpfs/user/abayraktar/FASTQ-OUTPUTS/"$dir3"_BRONZE_HardFiltered/Variants_output/


REF_DIR=/gpfs/user/abayraktar/refs/refs/broad_human_bundle_hg37
GENOME_FASTA=$REF_DIR/Homo_sapiens_assembly19.fasta
PICARD=/gpfs/user/abayraktar/tools/picard-tools-1.140/picard.jar
GATK=/gpfs/user/abayraktar/tools/GATK_3.8.0/GenomeAnalysisTK.jar
ANNOVAR=/gpfs/user/abayraktar/tools/annovar
TRIO=/gpfs/user/abayraktar/FASTQ-OUTPUTS/$family_trio
#################################################################################################
#################################################################################################
mkdir $TRIO

# HaplotypeCaller with GVCF
java -jar $GATK -T HaplotypeCaller -R $GENOME_FASTA -I $BQSR_DIR1/recal_reads.bam \
-ERC GVCF -o $VAR_DIR1/raw_variants.g.vcf &
java -jar $GATK -T HaplotypeCaller -R $GENOME_FASTA -I $BQSR_DIR2/recal_reads.bam \
-ERC GVCF -o $VAR_DIR2/raw_variants.g.vcf &
java -jar $GATK -T HaplotypeCaller -R $GENOME_FASTA -I $BQSR_DIR3/recal_reads.bam \
-ERC GVCF -o $VAR_DIR3/raw_variants.g.vcf &

#wait

# Joint Genotyping :: 18/12/18 :--annotateNDA (-nda): Annotate number of alleles observed
java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $GATK -T GenotypeGVCFs -R $GENOME_FASTA --variant $VAR_DIR1/raw_variants.g.vcf --variant $VAR_DIR2/raw_variants.g.vcf --variant $VAR_DIR3/raw_variants.g.vcf -o $TRIO/jointGenotype.vcf -nda true &

#wait

# PED file usage
java -Xmx"$memory"G -XX:ParallelGCThreads=$thread -jar $GATK -T PhaseByTransmission -R $GENOME_FASTA -V $TRIO/jointGenotype.vcf -ped $ped -o $TRIO/trio.vcf -mvf $TRIO/mendelianViolations.txt &

wait
 
# Annotation
perl $ANNOVAR/convert2annovar.pl -format vcf4 $TRIO/trio.vcf -outfile $TRIO/trio_outfile.avinput -allsample -withfreq -include &
wait

perl $ANNOVAR/table_annovar.pl $TRIO/trio_outfile.avinput  $ANNOVAR/humandb_hg37/ -buildver hg19 -out $TRIO/trio.annotation -remove -protocol refGene,knownGene,esp6500siv2_all,1000g2015aug_all,exac03,avsnp147,dbnsfp33a,clinvar_20170905,gnomad_exome,kaviar_20150923 -operation g,g,f,f,f,f,f,f,f,f -nastring .
wait

~/4combined_scripts/trio-act.f $TRIO/
