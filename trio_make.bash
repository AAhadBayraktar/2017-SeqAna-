#!/bin/bash

#################################################################################################
#################################################################################################
VQSR_DIR1=/home/abdullahad/exomAnalysis/example_data/1003573/VQSR_output
VQSR_DIR2=/home/abdullahad/exomAnalysis/example_data/1003575/VQSR_output
VQSR_DIR3=/home/abdullahad/exomAnalysis/example_data/1003576/VQSR_output
PED_DIR=/home/abdullahad/exomAnalysis/example_data/

GENOME_FASTA=/home/abdullahad//exomAnalysis/refs/broad_human_bundle/Homo_sapiens_assembly38.fasta
GATK=/home/abdullahad/exomAnalysis/tools/GATK_3.8.0/GenomeAnalysisTK.jar
ANNOVAR=/home/abdullahad/exomAnalysis/tools/annovar
TRIO=/home/abdullahad/exomAnalysis/example_data/trio
#################################################################################################
#################################################################################################
mkdir $TRIO

# Joint Genotyping
java -jar $GATK -T GenotypeGVCFs -R $GENOME_FASTA --variant $VQSR_DIR1/recalibrated_variants.vcf --variant $VQSR_DIR2/recalibrated_variants.vcf --variant $VQSR_DIR3/recalibrated_variants.vcf -o $TRIO/jointGenotype.vcf

# PED file usage
java -jar $GATK -T PhaseByTransmission -R $GENOME_FASTA -V $TRIO/jointGenotype.vcf -ped $PED_DIR/pedigree.ped -o $TRIO/trio.vcf
 
# Annotation 
perl $ANNOVAR/convert2annovar.pl -format vcf4 $TRIO/trio.vcf -outfile $TRIO/trio_outfile.avinput -allsample -withfreq -include 

perl $ANNOVAR/table_annovar.pl $TRIO/trio_outfile.avinput $ANNOVAR/humandb/ -buildver hg38 -out $TRIO/trio.annotation -remove -protocol refGene,knownGene,esp6500siv2_all,1000g2015aug_all,exac03,avsnp150,dbnsfp33a,clinvar_20170130,gnomad_exome,kaviar_20150923  -operation g,g,f,f,f,f,f,f,f,f -nastring .