#!/usr/bin/env Rscript

############################
old <- Sys.time()
#args<-c('phys_100000_0.0005', 21)
## Load libraries
source('~/height_prediction/strat_prs/scripts/Rsq_R2.R')
library(optparse)
library(data.table)
library(dplyr)
library(readr)
library(tidyr)
library(parallel)
library(reshape2)
library(asbio)
library(ggplot2)
#options(scipen=999)
source('~/height_prediction/scripts/mclapply2.R')
##Load other PRSs

readRDS("~/height_prediction/imputed/output/all_prs.Rds")-> res_all
names(res_all)<-c("PLINK", "PLINK_TSTAT_1")
data.table(SUBJID=names(res_all[[1]][[1]]), PRS_afr=(unlist(res_all[[1]][[1]])+unlist(res_all[[2]][[1]])+unlist(res_all[[3]][[1]])+unlist(res_all[[4]][[1]])+unlist(res_all[[5]][[1]])+unlist(res_all[[6]][[1]])+unlist(res_all[[7]][[1]])+unlist(res_all[[8]][[1]])+unlist(res_all[[9]][[1]])+unlist(res_all[[10]][[1]])+unlist(res_all[[11]][[1]])+unlist(res_all[[12]][[1]])+unlist(res_all[[13]][[1]])+unlist(res_all[[14]][[1]])+unlist(res_all[[15]][[1]])+unlist(res_all[[16]][[1]])+unlist(res_all[[17]][[1]])+ unlist(res_all[[18]][[1]])+unlist(res_all[[19]][[1]])+unlist(res_all[[20]][[1]])+unlist(res_all[[21]][[1]])+unlist(res_all[[22]][[1]])),PRS_EUR=unlist(readRDS('~/height_prediction/gwas/WHI/output/PGS_WHI_phys_100000_0.0005.Rds')))-> a

a[, PRS_afr:=scale(PRS_plink)]

#read in the prss and add them
prs<-vector('list', 12)
names(prs)<-c("0", "0.1", "0.15", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8", "0.9","1")
for (A in names(prs)){
	prs[[A]]<-vector('list',22)
		for(chr in 1:22){
		prs[[A]][[chr]]<-readRDS(paste0('~/height_prediction/loc_anc_analysis/output/chr', chr,'_',A, '_prs.Rds'))
	}
}
samp_names<-names(prs[[1]][[1]])
dt<-data.table(SUBJID=samp_names, PRS_0=NA, PRS_0.1=NA, PRS_0.15=NA, PRS_0.2=NA, PRS_0.3=NA, PRS_0.4=NA, PRS_0.5=NA, PRS_0.6=NA, PRS_0.7=NA, PRS_0.8=NA, PRS_0.9=NA, PRS_1=NA)

prs2<-vector('list', 12)
names(prs2)<-c("0", "0.1", "0.15", "0.2", "0.3", "0.4", "0.5", "0.6", "0.7", "0.8","0.9", "1")
for (A in names(prs2)){
	prs2[[A]]<-vector('list', length(prs[[1]][[1]]))
	names(prs2[[A]])<-gsub("_A", "",samp_names)
}

for (A in names(prs2)){
	for (S in names(prs2[[A]])){
	prs2[[A]][[S]]<-sum(prs[[A]][[1]][[S]],prs[[A]][[2]][[S]],prs[[A]][[3]][[S]],prs[[A]][[4]][[S]],prs[[A]][[5]][[S]],prs[[A]][[6]][[S]], prs[[A]][[7]][[S]], prs[[A]][[8]][[S]], prs[[A]][[9]][[S]], prs[[A]][[10]][[S]],prs[[A]][[11]][[S]], prs[[A]][[12]][[S]], prs[[A]][[13]][[S]],prs[[A]][[14]][[S]], prs[[A]][[15]][[S]], prs[[A]][[16]][[S]], prs[[A]][[17]][[S]], prs[[A]][[18]][[S]], prs[[A]][[19]][[S]], prs[[A]][[20]][[S]], prs[[A]][[21]][[S]],prs[[A]][[22]][[S]], na.rm=T)
	}
}

dt[, PRS_0:=unlist(prs2[[1]])]
dt[, PRS_0.1:=unlist(prs2[[2]])]
dt[, PRS_0.15:=unlist(prs2[[3]])]
dt[, PRS_0.2:=unlist(prs2[[4]])]
dt[, PRS_0.3:=unlist(prs2[[5]])]
dt[, PRS_0.4:=unlist(prs2[[6]])]
dt[, PRS_0.5:=unlist(prs2[[7]])]
dt[, PRS_0.6:=unlist(prs2[[8]])]
dt[, PRS_0.7:=unlist(prs2[[9]])]
dt[, PRS_0.8:=unlist(prs2[[10]])]
dt[, PRS_0.9:=unlist(prs2[[11]])]
dt[, PRS_1:=unlist(prs2[[12]])]

merge(dt,a, by="SUBJID")-> dt
#phenotype
fread('~/height_prediction/input/WHI/WHI_phenotypes.txt')-> Pheno_WHI

Pheno_WHI[, SUBJID:=paste0("0_", as.character(Pheno_WHI[, SUBJID]))]
setkey(Pheno_WHI, SUBJID)
#add ancestry
ancestry<-do.call(rbind, lapply(1:22, function(X) fread(paste0('~/height_prediction/input/WHI/rfmix_anc_chr', X, '.txt'))))
anc_WHI<-ancestry %>% group_by(SUBJID) %>% summarise(AFR_ANC=mean(AFR_ANC), EUR_ANC=1-mean(AFR_ANC)) %>% as.data.table #mean across chromosomes for each individual
setkey(anc_WHI, SUBJID)
##

#PRS_EUR<-data.table(PRS_EUR=unlist(readRDS('~/height_prediction/gwas/WHI/output/PGS_WHI_phys_100000_0.0005.Rds')),SUBJID=names(unlist(readRDS('~/height_prediction/gwas/WHI/output/PGS_WHI_phys_100000_0.0005.Rds'))))
#a<-merge(dt, PRS_EUR, by="SUBJID")
setkey(dt, SUBJID)
setkey(Pheno_WHI, SUBJID)
dt[Pheno_WHI][anc_WHI]-> final
final[,c("SUBJID", "PRS_0","PRS_0.1","PRS_0.15","PRS_0.2","PRS_0.3","PRS_0.4","PRS_0.5","PRS_0.6","PRS_0.6","PRS_0.7", "PRS_0.8", "PRS_0.9","PRS_1","PRS_EUR", "SEX", "HEIGHTX", "EUR_ANC","AFR_ANC","AGE")]-> final2
final2[, PRS_0:=scale(PRS_0)]
final2[, PRS_0.1:=scale(PRS_0.1)]
final2[, PRS_0.15:=scale(PRS_0.15)]
final2[, PRS_0.2:=scale(PRS_0.2)]
final2[, PRS_0.3:=scale(PRS_0.3)]
final2[, PRS_0.4:=scale(PRS_0.4)]
final2[, PRS_0.5:=scale(PRS_0.5)]
final2[, PRS_0.6:=scale(PRS_0.6)]
final2[, PRS_0.7:=scale(PRS_0.7)]
final2[, PRS_0.8:=scale(PRS_0.8)]
final2[, PRS_0.9:=scale(PRS_0.9)]
final2[, PRS_1:=scale(PRS_1)]

final2[,AGE2:=AGE^2]

#
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_EUR, data=final2))*100 #4.1%
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_0, data=final2))*100
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_0.1, data=final2))*100 
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_0.2, data=final2))*100
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_0.3, data=final2))*100
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_0.4, data=final2))*100
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_0.5, data=final2))*100
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_0.6, data=final2))*100
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_0.7, data=final2))*100
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_0.8, data=final2))*100
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_0.9, data=final2))*100
partial.R2(lm(HEIGHTX~AGE+AGE2+EUR_ANC, data=final2), lm(HEIGHTX~AGE+AGE2+EUR_ANC+PRS_1, data=final2))*100
#

###################
####