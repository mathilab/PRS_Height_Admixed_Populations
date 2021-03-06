#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("At least one argument must be supplied (a name for this run).n", call.=FALSE)
}
#Load packages #########################
library("optparse")
library(data.table)
library(dplyr)
library(asbio)
########################################
#calculate PRS function
home<-"/home/bbita"
dir<-"height_prediction/strat_prs/scripts"
source(paste0(home, "/", dir,'/PRS_calc.R'))
#partial R2 function
source(paste0(home, "/", dir,'/Rsq_R2.R'))
########################################
#####################################################################################################
#### First part: calculate recombination rates for PRS SNPs and divide them into quantiles ##########
#####################################################################################################
## Read in betas and recombination maps
rate.dist<-as.numeric(args[1])
w_map<-args[2]
PRS<-vector('list', 22)
afr<-fread('/project/mathilab/bbita/gwas_admix/new_height/pennBB_afr_betas_100000_0.0005.txt') #need to fix this path
lapply(1:22, function(chr) fread(paste0('zcat /project/mathilab/data/maps/hm2/hm2/genetic_map_GRCh37_chr', chr,'.txt.gz'))[,CHR:=gsub("chr","",Chromosome)][, Chromosome:=NULL])-> rec #need to fix this path
for(chr in 1:22){colnames(rec[[chr]])<-c('POS', 'RATE_cM_Mb', 'MAP_cM', 'CHR')}
lapply(1:22, function(chr) fread(paste0('zcat /project/mathilab/data/maps_b37/maps_chr.', chr, '.gz')))-> maps #need to fix this path
for(chr in 1:22){colnames(maps[[chr]])[1]<-"POS"}
lapply(1:22, function(chr) setkey(rec[[chr]],POS))
lapply(1:22, function(chr) setkey(maps[[chr]],POS))
lapply(1:22, function(chr) maps[[chr]][rec[[chr]], nomatch=0])-> map
lapply(1:22, function(chr) map[[chr]][,POS2:=POS])
remove(maps)
cat('loading done\n')
chrs<-vector('list',22)
for (chr in 1:22){
        cat('starting chr', chr, '\n')
        a<-seq(from=map[[chr]]$POS[1]-(rate.dist/2), to=map[[chr]]$POS[nrow(map[[chr]])], by=rate.dist)
        b<-c(a[-1],a[length(a)]+rate.dist)
        if(w_map=="AA"){
                AA.rate <- approxfun(map[[chr]]$POS, map[[chr]]$AA_Map, rule=2)
                e<-data.table(POS=a, POS2=b, Win=paste0(a,"|",b))
                setkey(e, POS, POS2)
                setkey(map[[chr]], POS, POS2)
                f<-foverlaps(map[[chr]], e)
                f[, diff:=AA.rate(f$POS2)-AA.rate(f$POS)]
                chrs[[chr]]<-f
                } else if (w_map=="CEU"){
                CEU.rate<-approxfun(map[[chr]]$POS, map[[chr]]$CEU_LD, rule=2)
                e<-data.table(POS=a, POS2=b, Win=paste0(a,"|",b))
                setkey(e, POS, POS2)
                setkey(map[[chr]], POS, POS2)
                f<-foverlaps(map[[chr]], e)
                f[, diff:=CEU.rate(f$POS2)-CEU.rate(f$POS)]
                chrs[[chr]]<-f
                }
}
do.call(rbind, chrs)-> f #combine into one data.table with all chromosomes
f[,Quantile:=cut(diff, breaks=quantile(diff), na.rm=T, include.lowest=T)]
afr[, POS1:=POS-(rate.dist/2)][,POS2:=POS+(rate.dist/2)]

#Stratify genome into 4 quantiles of recombination rate
if(w_map=="CEU"){
        afr[, diff:=CEU.rate(POS2)-CEU.rate(POS1), by=CHR]
        } else if (w_map=="AA"){
         afr[, diff:=AA.rate(POS2)-AA.rate(POS1), by=CHR]
}

#Split PRS SNPs according to these quantiles
lev<-quantile(f$diff)
q1<-afr[diff>=lev[1] & diff<lev[2]]
q2<-afr[diff>=lev[2] & diff<lev[3]]
q3<-afr[diff>=lev[3] & diff<lev[4]]
q4<-afr[diff>=lev[4]]
cat('checkpoint\n')
#calculate PRS for each of these quantiles
hei<-lapply(1:22, function(chr) readRDS('/project/mathilab/bbita/gwas_admix//new_height/pennBB_afr/hei_phys_100000_0.0005_v2.Rds')[[chr]]) #need to fix this path
hei<-do.call(rbind, hei)
hei[MarkerName %in% q1$MarkerName]-> hei_q1
hei[MarkerName %in% q2$MarkerName]-> hei_q2
hei[MarkerName %in% q3$MarkerName]-> hei_q3
hei[MarkerName %in% q4$MarkerName]-> hei_q4
prs<-vector('list', 4)
names(prs)<-c("q1","q2","q3", "q4")
prs[['q1']]<-PolScore(hei2=hei_q1)
cat('q1 done\n')
prs[['q2']]<-PolScore(hei2=hei_q2)
cat('q2 done\n')
prs[['q3']]<-PolScore(hei2=hei_q3)
cat('q3 done\n')
prs[['q4']]<-PolScore(hei2=hei_q4)
cat('q4 done\n')
PRS<-prs
remove(prs)
saveRDS(PRS,file=paste0("../output/prs_pennBB_afr_", rate.dist, "_", w_map, ".Rds")) #store results.
obj<-c(nrow(hei_q1), nrow(hei_q2), nrow(hei_q3), nrow(hei_q4))
saveRDS(obj, file=paste0("../output/Nr_SNPs_pennBB_afr_", rate.dist, "_", w_map, ".Rds")) #store results.

#Make a list
PRS2<-vector('list', length(PRS[['q1']]))
names(PRS2)<-names(PRS[['q1']])
for(J in names(PRS2)){
        PRS2[[J]]<-data.table(q1=PRS[['q1']][[J]],q2=PRS[['q2']][[J]],q3=PRS[['q3']][[J]], q4=PRS[['q4']][[J]])
        cat(J, '\r')
}
do.call(rbind,PRS2)-> PRS2 #combine into one data.table
rownames(PRS2)<-names(PRS[[1]])
saveRDS(PRS2, file=paste0('../output/PRS2_pennBB_afr_',rate.dist,"_", w_map, '.Rds'))  #store results.

#########################################################
#### Second part: calculate partial R2 for PRS. #########
#########################################################

#read in phenotype data
setDT(readRDS('/project/pmbb_mathi_lab/phenotypes/cov_afr_nophi_170815.RDS'))-> Pheno_pennBB_afr #need to fix this path
fread('/project/mathilab/bbita/gwas_admix/height/pennBB/afr/Final_AFR_Height_Weight_BMI.txt')-> Pheno2_pennBB_afr #need to fix this path

#fix some columns and set keys for merging data tables
Pheno_pennBB_afr[,GENO_ID:=paste0(GENO_ID, "_", GENO_ID)]
Pheno2_pennBB_afr[,GENO_ID:=paste0(GENO_ID, "_", GENO_ID)]
setkey(Pheno_pennBB_afr, GENO_ID)
setkey(Pheno2_pennBB_afr, GENO_ID)
Pheno_pennBB_afr[Pheno2_pennBB_afr, nomatch=0]-> Pheno3_pennBB_afr

#add ancestry
anc_pennBB_afr<-cbind(fread('/project/mathilab/bbita/gwas_admix/height/pennBB/afr/PRUNED.2.Q'), fread('/project/mathilab/bbita/gwas_admix/height/pennBB/afr/PRUNED.fam')[,V2]) #need to fix this path
colnames(anc_pennBB_afr)<-c("EUR_ANC","AFR_ANC","GENO_ID")
anc_pennBB_afr[,GENO_ID:=paste0(GENO_ID, "_", GENO_ID)]
setkey(anc_pennBB_afr, GENO_ID)

#Make a list to store results
PGS2_pennBB_afr<-vector('list', 4)
names(PGS2_pennBB_afr)<-c("q1","q2","q3","q4")

for (I in names(PGS2_pennBB_afr)){
        data.table(GENO_ID=rownames(PRS2), PGS=PRS2[,get(I)])-> PGS2_pennBB_afr[[I]]
        setkey(PGS2_pennBB_afr[[I]], GENO_ID)
        PGS2_pennBB_afr[[I]][Pheno3_pennBB_afr, nomatch=0]-> PGS2_pennBB_afr[[I]]
        PGS2_pennBB_afr[[I]][anc_pennBB_afr, nomatch=0]-> PGS2_pennBB_afr[[I]]
        PGS2_pennBB_afr[[I]][,HEIGHTX:=Height*2.54] #convert to cm
        PGS2_pennBB_afr[[I]][,WEIGHTX:=Weight*0.45359237] #convert to kg
	PGS2_pennBB_afr[[I]][AFR_ANC>=0.05]-> PGS2_pennBB_afr[[I]] #filter out individuals that have no African ancestry
        PGS2_pennBB_afr[[I]][-which(is.na(PGS2_pennBB_afr[[I]][,HEIGHTX])),]-> PGS2_pennBB_afr[[I]]
}

#run linear models
lapply(PGS2_pennBB_afr, function(X) lm(HEIGHTX~sex,X))-> lm0_pennBB_afr
lapply(PGS2_pennBB_afr, function(X) lm(HEIGHTX~PGS, X))-> lm1_pennBB_afr
lapply(PGS2_pennBB_afr, function(X) lm(HEIGHTX~age, X))-> lm2_pennBB_afr
lapply(PGS2_pennBB_afr, function(X) lm(HEIGHTX~age2, X))-> lm3_pennBB_afr
lapply(PGS2_pennBB_afr, function(X) lm(HEIGHTX~EUR_ANC, X))-> lm4_pennBB_afr
lapply(PGS2_pennBB_afr, function(X) lm(HEIGHTX~sex+age, X))-> lm5_pennBB_afr
lapply(PGS2_pennBB_afr, function(X) lm(HEIGHTX~sex+age+age2, X))-> lm6_pennBB_afr
lapply(PGS2_pennBB_afr, function(X) lm(HEIGHTX~sex+age+age2+EUR_ANC, X))-> lm7_pennBB_afr
lapply(PGS2_pennBB_afr, function(X) lm(HEIGHTX~sex+age+age2+EUR_ANC+PGS,X))-> lm8_pennBB_afr

#Get partial R2, i.e, the proportion of variation in height explained by the PRS
partial_r2_pennBB_afr<-lapply(1:length(PGS2_pennBB_afr), function(X) partial.R2(lm7_pennBB_afr[[X]], lm8_pennBB_afr[[X]])) 
names(partial_r2_pennBB_afr)<- names(PGS2_pennBB_afr)


saveRDS(partial_r2_pennBB_afr,file=paste0('../output/part_R2_pennBB_afr_', rate.dist, "_", w_map, '.Rds')) #store results
