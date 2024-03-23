## Load Libraries
library(lubridate)
library(reshape2)
library(parallel)

## Load Data
snap_props <- readRDS("ArbSnapshotData/Proposals.RDS")
tally_props <- readRDS("ArbTallyData/Proposals.RDS")
snap_votes <- readRDS("ArbSnapshotData/Votes.RDS")
tally_votes <- readRDS("ArbTallyData/Votes.RDS")
all_voters <- unique(c(snap_votes$voter,tally_votes$voter))
del_data <- readRDS("ArbTallyData/delegatesdf.RDS")
del_list <- del_data$Address[del_data$delegatorsCount>1 & del_data$votesCount>10^18]


######################################################
## Snapshot
######################################################
snap_props_sel <- snap_props[(sapply(strsplit(snap_props$choices,"<\\|\\|>"),length)==3) & grepl("abstain",tolower(snap_props$choices)),-8]
voter_prop_mat_sn <- matrix(NA,nrow=length(all_voters),ncol=nrow(snap_props_sel))
for(idx in 1:nrow(snap_props_sel))
{
	cvotes <- snap_votes[snap_votes$prop_id == snap_props_sel$id[idx],]
	cvotes$choice <- ifelse(cvotes$choice==2,-1,cvotes$choice)
	cvotes$choice <- ifelse(cvotes$choice==3,0,cvotes$choice)
	cvotes$choice <- as.numeric(cvotes$choice)
	voter_prop_mat_sn[,idx] <- cvotes$choice[match(all_voters,cvotes$voter)]
}
######################################################
######################################################


######################################################
## Tally
######################################################
voter_prop_mat_tal <- matrix(NA,nrow=length(all_voters),ncol=nrow(tally_props))
for(idx in 1:nrow(tally_props))
{
	cvotes <- tally_votes[tally_votes$id == tally_props$id[idx],]
	cvotes$support <- ifelse(cvotes$support=="FOR",1,cvotes$support)
	cvotes$support <- ifelse(cvotes$support=="AGAINST",-1,cvotes$support)
	cvotes$support <- ifelse(cvotes$support=="ABSTAIN",0,cvotes$support)
	cvotes$support <- as.numeric(cvotes$support)
	voter_prop_mat_tal[,idx] <- cvotes$support[match(all_voters,cvotes$voter)]
}
######################################################
######################################################


######################################################
## Similarity Score Calculation
######################################################
voter_prop_mat <- cbind(voter_prop_mat_sn,voter_prop_mat_tal)
# voter_prop_mat_selidx <- which(apply(voter_prop_mat,1,function(x) sum(!is.na(x)))>10)
voter_prop_mat_selidx <- which(all_voters %in% del_list)
sel_voters <- all_voters[voter_prop_mat_selidx]
voter_prop_mat_sel <- voter_prop_mat[voter_prop_mat_selidx,]
voter_prop_mat_sel <- voter_prop_mat_sel[,!apply(voter_prop_mat_sel,2,function(x) any((table(x)/sum(table(x)))>.8))]
voter_prop_mat_l <- as.list(data.frame(t(voter_prop_mat_sel)))
get_score <- function(x,xidx,y,yidx)
{
	z <- as.vector(na.omit(x==y))
	lenz <- length(z)
	sumz <- sum(z)
	if(lenz>0) return(data.frame(voterA=xidx,voterB=yidx,Score=sumz/lenz,NumCommonVotedProposals=lenz))
}
get_score_df_s <- function(avec,avecidx,bvecset)
{
	do.call(rbind,mapply(get_score,bvecset,1:length(bvecset),MoreArgs=list(y=avec,yidx=avecidx),SIMPLIFY=FALSE,USE.NAMES=FALSE))
}
voter_score_dfl <- mcmapply(get_score_df_s,voter_prop_mat_l,1:length(voter_prop_mat_l),MoreArgs=list(bvecset=voter_prop_mat_l),SIMPLIFY=FALSE,USE.NAMES=FALSE,mc.cores=16)
voter_score_df <- do.call(rbind,voter_score_dfl)
voter_score_df <- voter_score_df[voter_score_df$voterA!=voter_score_df$voterB,]
voter_score_df$voterA <- sel_voters[voter_score_df$voterA]
voter_score_df$voterB <- sel_voters[voter_score_df$voterB]
A_match <- del_data$Name[match(voter_score_df$voterA,del_data$Address)]
voter_score_df$voterAName <- ifelse(A_match=="",voter_score_df$voterA,A_match)
B_match <- del_data$Name[match(voter_score_df$voterB,del_data$Address)]
voter_score_df$voterBName <- ifelse(B_match=="",voter_score_df$voterB,B_match)
saveRDS(voter_score_df,"data/voter_score_df.RDS")
######################################################
######################################################