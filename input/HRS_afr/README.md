
*copy files to my local directory*
```
cp /project/mathilab/data/HRS/data/HRS_AFR* .
cp /project/mathilab/data/HRS/admixture/HRS_AFR_b37_strand_prune_include.2.Q . ##order comes from file below
cp /project/mathilab/data/HRS/data/HRS_EUR_b37_strand_include.fam .  #the order of samples
```
*convert to vcf format*

```
plink --allow-extra-chr --allow-no-sex --autosome \
--bfile HRS_AFR_b37_strand_include \
--recode vcf \
--keep-allele-order \
--out HRS_AFR_b37_strand_include.bas
```

```
awk '/^ *#/ { print; }' HRS_EUR_b37_strand_include.bas.vcf > header_HRS_eur.txt

for chr in {1..22};
do
touch chr${chr}_bas.vcf
cat header.txt >  chr${chr}_bas.vcf
awk -v i=$chr '$1==i' HRS_EUR_b37_strand_include.bas.vcf >> chr${chr}_bas.vcf
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

bgzip -c HRS_EUR_b37_strand_include.bas.vcf > HRS_EUR_b37_strand_include.bas.vcf.gz