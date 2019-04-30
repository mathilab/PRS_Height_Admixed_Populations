####
*Select SNPs and prepare the data*
```
for D in JHS WHI pennBB_afr pennBB_eur ukb_afr ukb_eur;
do
Rscript --vanilla ~/height_prediction/scripts/make_vcf.R temp gwas $D
done
``