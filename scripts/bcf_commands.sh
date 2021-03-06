#!/bin/bash

chrom="$1"
#filename="$2"
path="$3"
#tag="$4"

dtset="$4"
echo $chrom
echo $path
bcftools view -H -T $path/temp_chr${chrom}.txt ~/height_prediction/input/${dtset}/chr${chrom}_*.vcf.gz > $path/temp2_chr${chrom}.txt; #-T is much faster than -R

