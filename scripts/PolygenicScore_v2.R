############################################
# A function to calculate polygenic scores##
############################################
#NOTE: WHI data and ubnphased genotypes
home="~/height_prediction/"
PolScore2<- function(panel='sib_betas', panel2='WHI', tag='phys_100000_0.0005', CHR=22){
	#readRDS(paste0(home, panel, "/", panel2,  '/output/hei_', tag, '_v2.Rds'))-> hei
        hei[[CHR]]-> hei2	
	if(panel=='sib_betas' & tag %in% c("LD_250000_0.01_0.5","LD_100000_0.01_0.5", "LD_50000_0.01_0.5")){
        	samps<-colnames(hei2)[9:(ncol(hei2)-6)]
		hei2[ALT==A1]-> temp1
        	hei2[REF==A1]-> temp2
		} else if (panel=='sib_betas'){
		samps<-colnames(hei2)[9:(ncol(hei2)-7)]
                hei2[ALT==Allele1]-> temp1
                hei2[REF==Allele1]-> temp2 #im ignoring the other two rows for now
                } else if (panel=='gwas'){
	        samps<-colnames(hei2)[9:(ncol(hei2)-7)] 
        	hei2[ALT==Allele1]-> temp1
        	hei2[REF==Allele1]-> temp2 #im ignoring the other two rows for now
		}
        vector('list', length(samps))-> temp_list
        names(temp_list)<-samps
	cat('Number of samples is', length(samps), '\n')
        if(nrow(temp1)>0 & nrow(temp2)>0){
		matrix(nrow=nrow(temp1)+nrow(temp2), ncol=length(samps))-> my_matrix
        	colnames(my_matrix)<-samps
        	rownames(my_matrix)<-c(temp1[,MarkerName],temp2[,MarkerName])
        	b1<-temp1[,b]
       		b2<-temp2[,b]
		counter<-0
        	for(i  in samps){
			my_matrix[which(temp1[,i, with=F]=="0/0"),i]<-0
			my_matrix[which(temp1[,i, with=F]=="1/1"),i]<-2
			my_matrix[which(temp1[,i, with=F]=="1/0"),i]<-1
			my_matrix[which(temp1[,i, with=F]=="0/1"),i]<-1

			my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="0/0"),i]<-2
			my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="1/1"),i]<-0
			my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="1/0"),i]<-1
			my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="0/1"),i]<-1
			counter<-counter+1
			cat(counter,'\r')
                }
		 apply(my_matrix*c(b1,b2), 2, sum, na.rm=T)-> res
		cat('Finished first for loop\n')
       		} else if (nrow(temp1)>0){
                matrix(nrow=nrow(temp1), ncol=length(samps))-> my_matrix
                colnames(my_matrix)<-samps
                rownames(my_matrix)<-temp1[,MarkerName]
                b1<-temp1[,b]
                counter<-0
		for(i in samps){
		        my_matrix[which(temp1[,i, with=F]=="0/0"),i]<-0
                        my_matrix[which(temp1[,i, with=F]=="1/1"),i]<-2
                        my_matrix[which(temp1[,i, with=F]=="1/0"),i]<-1
                        my_matrix[which(temp1[,i, with=F]=="0/1"),i]<-1
                }
		 apply(my_matrix*b1, 2, sum, na.rm=T)-> res
	cat('Finished second  for loop\n')
        } else if (nrow(temp2)>0){
	        matrix(nrow=nrow(temp2), ncol=length(samps))-> my_matrix
                colnames(my_matrix)<-samps
                rownames(my_matrix)<-temp2[,MarkerName]
                b2<-temp2[,b]
                for(i in samps){
        	
                        my_matrix[which(temp2[,i, with=F]=="0/0"),i]<-2
                        my_matrix[which(temp2[,i, with=F]=="1/1"),i]<-0
                        my_matrix[which(temp2[,i, with=F]=="1/0"),i]<-1
                        my_matrix[which(temp2[,i, with=F]=="0/1"),i]<-1        
	}
	 apply(my_matrix*b2, 2, sum, na.rm=T)-> res
        }
	cat('Finished third  for loop\n')
#acollect sample names for this population from 1000G data.
        return(res)
}

##

#1000 Genomes

PolScore_1000G<-function(POP='CEU', superpop=F, CHR=CR, my_dt=args[1]){
	if(superpop==F){
        	samps<- samples[pop==POP][,sample]
        } else if (superpop==T){
        	samps<- samples[super_pop==POP][,sample]
        }
	dt<-readRDS(paste0('~/height_prediction/gwas/ukb_eur/output/hei_', my_dt, '_1000g.Rds'))[[CHR]]
        dt2<-cbind(dt[,c(1:5)], dt[, samps, with=F], dt[, (ncol(dt)-7):ncol(dt),with=F])
        dt2[ALT==Allele1]-> temp1
        dt2[REF==Allele1]-> temp2 #im ignoring the other two rows for now
        vector('list', length(samps))-> temp_list
        names(temp_list)<-samps
        cat('Number of samples is', length(samps), '\n')
        if(nrow(temp1)>0 & nrow(temp2)>0){
                matrix(nrow=nrow(temp1)+nrow(temp2), ncol=length(samps))-> my_matrix
                colnames(my_matrix)<-samps
                rownames(my_matrix)<-c(temp1[,MarkerName],temp2[,MarkerName])
                b1<-temp1[,b]
                b2<-temp2[,b]
                counter<-0
                for(i  in samps){
                        my_matrix[which(temp1[,i, with=F]=="0|0"),i]<-0
                        my_matrix[which(temp1[,i, with=F]=="1|1"),i]<-2
                        my_matrix[which(temp1[,i, with=F]=="1|0"),i]<-1
                        my_matrix[which(temp1[,i, with=F]=="0|1"),i]<-1

                        my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="0|0"),i]<-2
                        my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="1|1"),i]<-0
                        my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="1|0"),i]<-1
                        my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="0|1"),i]<-1
                        counter<-counter+1
                        cat(counter,'\r')
                }
                 apply(my_matrix*c(b1,b2), 2, sum, na.rm=T)-> res
                cat('Finished first for loop\n')
                } else if (nrow(temp1)>0){
                matrix(nrow=nrow(temp1), ncol=length(samps))-> my_matrix
                colnames(my_matrix)<-samps
                rownames(my_matrix)<-temp1[,MarkerName]
                b1<-temp1[,b]
                counter<-0
                for(i in samps){
                        my_matrix[which(temp1[,i, with=F]=="0|0"),i]<-0
                        my_matrix[which(temp1[,i, with=F]=="1|1"),i]<-2
                        my_matrix[which(temp1[,i, with=F]=="1|0"),i]<-1
                        my_matrix[which(temp1[,i, with=F]=="0|1"),i]<-1
                }
                 apply(my_matrix*b1, 2, sum, na.rm=T)-> res
        cat('Finished second  for loop\n')
	        } else if (nrow(temp2)>0){
                matrix(nrow=nrow(temp2), ncol=length(samps))-> my_matrix
                colnames(my_matrix)<-samps
                rownames(my_matrix)<-temp2[,MarkerName]
                b2<-temp2[,b]
                for(i in samps){

                        my_matrix[which(temp2[,i, with=F]=="0|0"),i]<-2
                        my_matrix[which(temp2[,i, with=F]=="1|1"),i]<-0
                        my_matrix[which(temp2[,i, with=F]=="1|0"),i]<-1
                        my_matrix[which(temp2[,i, with=F]=="0|1"),i]<-1
        }
         apply(my_matrix*b2, 2, sum, na.rm=T)-> res
        }
        cat('Finished third  for loop\n')
#acollect sample names for this population from 1000G data.
        #return(res)

#        for(i in samps){
#                sum(temp1[which(temp1[,i, with=F]=="0|0"),b]*0) + sum(temp1[which(temp1[,i,with=F]=="0|1"),b]*1) + sum(temp1[which(temp1[,i,with=F]=="1|0"),b]*1) + sum(temp1[which(temp1[,i,with=F]=="1|1"),b]*2)-> temp_list[[i]]
#                temp_list[[i]] + sum(temp2[which(temp2[,i, with=F]=="0|0"),b]*2) + sum(temp2[which(temp2[,i,with=F]=="0|1"),b]*1) + sum(temp2[which(temp2[,i,with=F]=="1|0"),b]*1) + sum(temp2[which(temp2[,i,with=F]=="1|1"),b]*0)-> temp_list[[i]]
#                }
        return(res)
}

PolScore_random<- function(panel='sib_betas', panel2='WHI', tag='phys_100000_0.0005', CHR=22){
        hei[[CHR]]-> hei2
        if(panel=='sib_betas'){
                samps<-colnames(hei2)[9:(ncol(hei2)-6)]
                } else if (panel=='gwas'){
                samps<-colnames(hei2)[9:(ncol(hei2)-8)]
        }
        hei2[ALT==Allele1]-> temp1
        hei2[REF==Allele1]-> temp2 #im ignoring the other two rows for now
        vector('list', length(samps))-> temp_list
        names(temp_list)<-samps
        cat('Number of samples is', length(samps), '\n')
        if(nrow(temp1)>0 & nrow(temp2)>0){
                matrix(nrow=nrow(temp1)+nrow(temp2), ncol=length(samps))-> my_matrix
                colnames(my_matrix)<-samps
                rownames(my_matrix)<-c(temp1[,MarkerName],temp2[,MarkerName])
                #b1<-temp1[,b]
                #b2<-temp2[,b]
                counter<-0
                for(i  in samps){
                        my_matrix[which(temp1[,i, with=F]=="0/0"),i]<-0
                        my_matrix[which(temp1[,i, with=F]=="1/1"),i]<-2
                        my_matrix[which(temp1[,i, with=F]=="1/0"),i]<-1
                        my_matrix[which(temp1[,i, with=F]=="0/1"),i]<-1

                        my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="0/0"),i]<-2
             		my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="1/1"),i]<-0
                        my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="1/0"),i]<-1
                        my_matrix[nrow(temp1)+which(temp2[,i, with=F]=="0/1"),i]<-1
                        counter<-counter+1
                        cat(counter,'\r')
                }
                apply(my_matrix, 2, sum, na.rm=T)-> res
                cat('Finished first for loop\n')
                } else if (nrow(temp1)>0){
                matrix(nrow=nrow(temp1), ncol=length(samps))-> my_matrix
                colnames(my_matrix)<-samps
                rownames(my_matrix)<-temp1[,MarkerName]
                b1<-temp1[,b]
                counter<-0
                for(i in samps){
                        my_matrix[which(temp1[,i, with=F]=="0/0"),i]<-0
                        my_matrix[which(temp1[,i, with=F]=="1/1"),i]<-2
                        my_matrix[which(temp1[,i, with=F]=="1/0"),i]<-1
                        my_matrix[which(temp1[,i, with=F]=="0/1"),i]<-1
                }
                 apply(my_matrix, 2, sum, na.rm=T)-> res
        cat('Finished second  for loop\n')
        } else if (nrow(temp2)>0){
               matrix(nrow=nrow(temp2), ncol=length(samps))-> my_matrix
                colnames(my_matrix)<-samps
                rownames(my_matrix)<-temp2[,MarkerName]
                #b2<-temp2[,b]
                for(i in samps){
                        my_matrix[which(temp2[,i, with=F]=="0/0"),i]<-2
                        my_matrix[which(temp2[,i, with=F]=="1/1"),i]<-0
                        my_matrix[which(temp2[,i, with=F]=="1/0"),i]<-1
                        my_matrix[which(temp2[,i, with=F]=="0/1"),i]<-1
        }
         apply(my_matrix, 2, sum, na.rm=T)-> res
        }
        cat('Finished third  for loop\n')
#acollect sample names for this population from 1000G data.
        return(res)
}

#*******
#* END *
#*******
