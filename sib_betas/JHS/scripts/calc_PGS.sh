#!/bin/bash

#using sib betas and gwas p=values
for i in 1000000 500000 100000 75000 50000 25000 10000 5000;
do
echo 'Window size is '
echo $i
for j in 0.00000005 0.0000005 0.000005 0.00005 0.0005;
do
echo $j
#bsub -o /project/mathilab/bbita/gwas_admix/sib_gwas/JHS/logphys_${i}_${j} -e /project/mathilab/bbita/gwas_admix/sib_gwas/JHS/logphys_${i}_${j} -M 15240 Rscript --vanilla /project/mathilab/bbita/gwas_admix/sib_gwas/JHS/run_PRS.R LD_prun phys_${i}_${j}
Rscript --vanilla run_PRS.R LD_prun phys_${i}_${j}
echo $j
echo 'done'
done
echo $i
echo 'done'
done

for i in 1 0.5 0.3 0.25 0.2 0.15 0.1;
do
echo 'Window size is '
echo $i
for j in 0.00000005 0.0000005 0.000005 0.00005 0.0005;
do
echo $j
#bsub -o /project/mathilab/bbita/gwas_admix/sib_gwas/JHS/logphys_${i}_${j} -e /project/mathilab/bbita/gwas_admix/sib_gwas/JHS/logphys_${i}_${j} -M 10240 Rscript --vanilla /project/mathilab/bbita/gwas_admix/sib_gwas/JHS/run_PRS.R LD_prun genet_${i}_${j}
Rscript --vanilla run_PRS.R LD_prun genet_${i}_${j}
echo $j
echo 'done'
done
echo $i
echo 'done'
done


for i in 250000 100000 50000;
do
echo 'Window size is '
echo $i
#bsub -M 30240 -o /project/mathilab/bbita/gwas_admix/sib_gwas/JHS/logphys_LD_${i} -e /project/mathilab/bbita/gwas_admix/sib_gwas/JHS/logphys_LD_${i} Rscript --vanilla /project/mathilab/bbita/gwas_admix/sib_gwas/JHS/run_PRS.R LD_prun LD_${i}_0.01_0.5 
Rscript --vanilla run_PRS.R LD_prun LD_${i}_0.01_0.5
echo $i
echo 'done'
done


bsub -M 10240 Rscript --vanilla run_PRS.R LD_prun LD_block_0_0_AFR

bsub -M 10240 Rscript --vanilla run_PRS.R LD_prun LD_block_0_0_EUR


