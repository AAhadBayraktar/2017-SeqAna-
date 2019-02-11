#!/bin/bash
# Abdulahad Bayraktar

myfile=$1

awk -F "\t" -v OFS="\t" \
-v depth=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "Depth" | cut -d : -f 1) \
-v childZyg=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "child.Zygosity" | cut -d : -f 1) \
-v motherZyg=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "mother.Zygosity" | cut -d : -f 1) \
-v fatherZyg=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "father.Zygosity" | cut -d : -f 1) \
-v childGQ=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "child.GQ" | cut -d : -f 1) \
-v motherGQ=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "mother.GQ" | cut -d : -f 1) \
-v fatherGQ=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "father.GQ" | cut -d : -f 1) \
-v childGT=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "child.GT" | cut -d : -f 1) \
-v motherGT=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "mother.GT" | cut -d : -f 1) \
-v fatherGT=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "father.GT" | cut -d : -f 1) \
-v childAD=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "child.AD$" | cut -d : -f 1) \
-v motherAD=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "mother.AD$" | cut -d : -f 1) \
-v fatherAD=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "father.AD$" | cut -d : -f 1) \
-v childADR=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "child.ADR$" | cut -d : -f 1) \
-v motherADR=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "mother.ADR$" | cut -d : -f 1) \
-v fatherADR=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "father.ADR$" | cut -d : -f 1) \
-v childADRL=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "child.ADRL" | cut -d : -f 1) \
-v motherADRL=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "mother.ADRL" | cut -d : -f 1) \
-v fatherADRL=$(sed -n 1p $myfile | tr '\t' '\n' | grep -n "father.ADRL" | cut -d : -f 1) \
'{print $1,$2,$3,$4,$5,\
$childZyg,$motherZyg,$fatherZyg,\
$childGT,$motherGT,$fatherGT,\
$childGQ,$motherGQ,$fatherGQ,\
$depth,\
$childAD,$motherAD,$fatherAD,\
$childADR,$motherADR,$fatherADR,\
$childADRL,$motherADRL,$fatherADRL,\
$0}' $myfile > $myfile.colTmp && cat $myfile.colTmp > $myfile

rm $myfile.colTmp

# Zygosity
# VCF - genotype
# VCF - genotype quality
# VCF - overall depth
# VCF - allelic depth
# AD Scores - ADR
# AD Scores - ADRL

