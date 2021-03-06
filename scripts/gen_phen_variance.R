#!/usr/bin/env Rscript
############################
library(data.table)
library(dplyr)
##read in a pruned set of SNPs and retain CHR and POS and write it into a file
library(data.table)
library(dplyr)
library(rjson)
library(optparse)
library(httr)
library(jsonlite)
library(TeachingDemos)
txtStart(paste0("logs/gen_phen_variants.txt"))
#dtsets<-vector("list", 6)
dtsets<-vector("list", 4)

#names(dtsets)<-c("WHI","JHS", "ukb_afr", "HRS_afr", "ukb_eur", "HRS_eur")

names(dtsets)<-c("ukb_afr", "HRS_afr", "ukb_eur", "HRS_eur")

for(I in names(dtsets)){
	readRDS(paste0('~/height_prediction/gwas/', I, '/output/hei_phys_100000_0.0005_v2.Rds'))-> betas
	betas<-lapply(betas, function(X) X[,.(CHR,POS, MarkerName, REF, ALT, Allele1, Allele2, b, SE, p, N)])
	betas<-do.call(rbind, betas)
	colnames(betas)[3]<-"SNP"
	res2<-vector("list",22)
	for(CR in 22:1){
		betas[,.(CHR,POS)][order(CHR,POS)]-> fwr
		fwr[CHR==CR][order(CHR,POS)]-> tp
		fwrite(tp, file=paste0("~/height_prediction/tmp/tmp",CR,"_", I, ".txt"), sep="\t", col.names=F)
		if (I=="ukb_afr"){
			com<-paste0('bcftools view -H -T ~/height_prediction/tmp/tmp', CR, '_', I, '.txt ~/height_prediction/input/',I, '/chr', CR,'_bas_afr.vcf.gz > ~/height_prediction/tmp/res_chr',CR, "_", I, '.txt')	
		} else if (I=='ukb_eur'){
			com<-paste0('bcftools view -H -T ~/height_prediction/tmp/tmp', CR, '_', I, '.txt ~/height_prediction/input/',I, '/chr', CR,'_bas_eur.vcf.gz > ~/height_prediction/tmp/res_chr',CR, "_", I, '.txt') 
		} else {
			com<-paste0('bcftools view -H -T ~/height_prediction/tmp/tmp', CR, '_', I, '.txt ~/height_prediction/input/',I, '/chr', CR,'_bas.vcf.gz > ~/height_prediction/tmp/res_chr',CR, "_", I, '.txt')
		} 
		system(com);cat('sleep\n')
		Sys.sleep(10)
		system(paste0("cat ~/height_prediction/input/", I, "/header_", I, ".txt > ~/height_prediction/tmp/temp2_chr", CR,"_",I, ".txt"))
		system(paste0("cat ~/height_prediction/tmp/res_chr",CR,"_", I,".txt >> ~/height_prediction/tmp/temp2_chr", CR, "_",I,".txt"))
		if(I=='ukb_eur'){
		comm<-paste0("plink --vcf ~/height_prediction/tmp/temp2_chr", CR,"_",I, ".txt --double-id --freq --out ~/height_prediction/tmp/out_chr", CR, "_", I)
                } else {
		comm<-paste0("plink --vcf ~/height_prediction/tmp/temp2_chr", CR,"_",I, ".txt --double-id --keep ~/height_prediction/gwas/",I, "/output/IDs_after_filter.txt ", "--freq --out ~/height_prediction/tmp/out_chr", CR, "_", I) ## calculate allele frequency and then heterozygosity : p*q
		}
		system(comm)
		Sys.sleep(10)
		res<-fread(paste0('~/height_prediction/tmp/out_chr',CR,"_",I, '.frq'), header=T)
		res[,pq:=MAF*(1-MAF)]
		res1<-fread(paste0('~/height_prediction/tmp/res_chr', CR,"_",I, ".txt" ))[,1:3]
		colnames(res1)<-c("CHR", "POS", "SNP")
		setkey(res1, CHR, SNP);setkey(res,CHR, SNP)
		res1[res]-> res2[[CR]]
		cat(I, " ", CR, " done\n")
		}
	do.call(rbind, res2)-> res3
	setkey(betas, CHR, POS, SNP)
	setkey(res3, CHR, POS, SNP)
	betas[res3]-> dtsets[[I]]
	dtsets[[I]][, value:=(b^2)*pq] 
	saveRDS(dtsets[[I]], file=paste0("~/height_prediction/output/tmp_dtsets_",I,".Rds"))
	system("rm ~/height_prediction/tmp/*") #clear everything
	cat(I, " done\n")
}
lapply(1:6, function(X) dtsets[[X]][, value2:=2*value])
saveRDS(dtsets, file="~/height_prediction/output/dtsets.Rds")

lapply(dtsets, function(X) sum(X$value, na.rm=T))

js<-'input/results_whi.json'
#
cat('Read in JSON file...\n')
json_data <-fromJSON(paste0(js))
#json_data('http://bioinfo.hpc.cam.ac.uk/cellbase/webservices/rest/v4/hsapiens/feature/variation/rs4540055/info?limit%3D-1%26skip%3D-1%26skipCount%3Dfalse%26count%3Dfalse%26Output%2520format%3Djson')
json_data()
setDT(json_data)
js_tidy<-json_data %>% group_by(id) %>% summarise(REF=refAllele, ALT=altAllele, Freq_Alt=altAlleleFreq, Study=study) %>% rename(ID=id) %>% as.data.table
#fread('/project/mathilab/data/WHI/data/1kg/1kg_affy6_all_CEU.afreq')-> ceu
fread('/project/mathilab/data/WHI/data/1kg/1kg_affy6_all_CEU.bim')[,V3:=NULL]-> ceu
#colnames(ceu_bim)<-c('CHR', 'MarkerName','POS','Al1', 'Al2')
colnames(ceu)[1]<-'CHR'
colnames(ceu)[2]<-'ID'
colnames(ceu)[3]<-'POS'
setkey(js_tidy, 'ID')
setkey(ceu, 'ID')
merge(ceu, js_tidy)-> js2
readRDS('~/height_prediction/output/tmp_dtsets_WHI.Rds')-> whi
whi[, value2:=2*value]
setkey(whi, CHR,POS)
setkey(js2, CHR, POS)
whi[js2, nomatch=0]-> final
na.omit(final)-> final
#final[,pq:=ALT_FREQS* (1-ALT_FREQS)]
final[,pq:=Freq_Alt* (1-Freq_Alt)]
final[, value3:=(b^2)*pq]
final[, value4:=2*value3]
fwrite(as.data.frame(final$ID), 'output/rsIDs_whi.txt' , quote=F, col.names=F, row.names=F) #save this for another analysis
nrow(whi)
nrow(js2)
nrow(final)
##

js<-'input/results_jhs.json'
#
cat('Read in JSON file...\n')
json_data <-fromJSON(paste0(js))
#json_data('http://bioinfo.hpc.cam.ac.uk/cellbase/webservices/rest/v4/hsapiens/feature/variation/rs4540055/info?limit%3D-1%26skip%3D-1%26skipCount%3Dfalse%26count%3Dfalse%26Output%2520format%3Djson')
json_data()
setDT(json_data)
js_tidy<-json_data %>% group_by(id) %>% summarise(REF=refAllele, ALT=altAllele, Freq_Alt=altAlleleFreq, Study=study) %>% rename(ID=id) %>% as.data.table
#fread('/project/mathilab/data/WHI/data/1kg/1kg_affy6_all_CEU.afreq')-> ceu
setkey(js_tidy, 'ID')
setkey(ceu, 'ID')
merge(ceu, js_tidy)-> js2
readRDS('~/height_prediction/output/tmp_dtsets_JHS.Rds')-> jhs
jhs[, value2:=2*value]
setkey(jhs, CHR,POS)
setkey(js2, CHR, POS)
jhs[js2, nomatch=0]-> final2
na.omit(final2)-> final2
#final[,pq:=ALT_FREQS* (1-ALT_FREQS)]
final2[,pq:=Freq_Alt* (1-Freq_Alt)]
final2[, value3:=(b^2)*pq]
final2[, value4:=2*value3]
fwrite(as.data.frame(final2$ID), 'output/rsIDs_jhs.txt' , quote=F, col.names=F, row.names=F) #save this for another analysis
nrow(jhs)
nrow(js2)
nrow(final2)
lapply(1:6, function(X) sum(dtsets[[X]]$value, na.rm=T))
unlist(lapply(1:2, function(X) sum(dtsets[[X]]$value2, na.rm=T)))/c(sum(final$value4, na.rm=T), sum(final2$value4))
txtStop()
