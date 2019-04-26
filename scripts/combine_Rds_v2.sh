#!/bin/sh

hom='/home/bbita/height_prediction'
MY=$hom/$1/$2
echo $MY



touch $M/scripts/run_this.sh
echo '#!/bin/sh' > $MY/scripts/run_this.sh
for j in 0.00000005 0.0000005 0.000005 0.00005 0.0005;
do
for k in 1000000 500000 100000 75000 50000 25000 10000 5000;
do
echo "Rscript --vanilla $hom/scripts/combine_Rds.R phys_${k}_${j} $1 $2" >> $MY/scripts/run_this.sh
done
for l in 1 0.5  0.3 0.25 0.2 0.15 0.1;
do
echo "Rscript --vanilla $hom/scripts/combine_Rds.R genet_${l}_${j} $1 $2" >> $MY/scripts/run_this.sh
done
done

#these three work differently. See run_PRS.R
for k in 250000 100000 50000;
do
echo "Rscript --vanilla $hom/scripts/combine_Rds.R LD_${k}_0.01_0.5 $1 $2" >> $MY/scripts/run_this.sh
done



echo "Rscript --vanilla $hom/scripts/combine_Rds.R LD_block_0_0_AFR $1 $2" >> $MY/scripts/run_this.sh
echo "Rscript --vanilla $hom/scripts/combine_Rds.R LD_block_0_0_EUR $1 $2" >> $MY/scripts/run_this.sh

chmod 777 $MY/scripts/run_this.sh

bash $MY/scripts/run_this.sh
