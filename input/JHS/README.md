## Getting JHS_afr data ready for all downstream analyses

Goal: go from plink to vcf format.

*copy files to my local directory*
```
PATH_to_data=/project/mathilab/data/JHS #change this accordingly.

*copy files to my local directory*
```

*copy files to my local directory*
```
cp ${PATH_to_data}/data/JHS_b37_strand.* .
cp ${PATH_to_data}/data/JHS_phenotypes.txt .
cp ${PATH_to_data}/admixture/JHS_b37_strand_prune.2.Q . ##order comes from file below
```
*convert to vcf format*

```
plink --allow-extra-chr --allow-no-sex --autosome \
--bfile JHS_b37_strand \
--recode vcf \
--keep-allele-order \
--out JHS_b37_strand.bas
```

```
awk '/^ *#/ { print; }' JHS_b37_strand.bas.vcf > header_JHS.txt

for chr in {1..22};
do
touch chr${chr}_bas.vcf
cat header_JHS.txt >  chr${chr}_bas.vcf
awk -v i=$chr '$1==i' JHS_b37_strand.bas.vcf >> chr${chr}_bas.vcf
echo 'chr'
echo $chr
echo 'done'
done
```

*compress/index*
```
for chr in {1..22};
do
bgzip -c chr${chr}_bas.vcf > chr${chr}_bas.vcf.gz &&
tabix -p vcf chr${chr}_bas.vcf.gz
done

bgzip -c JHS_b37_strand_prune.bas.vcf > JHS_b37_strand_prune.bas.vcf.gz
