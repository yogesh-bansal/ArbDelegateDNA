## Loading Libraries
library(shiny)
library(networkD3)
library(DT)
library(readr)

########################################################################
## Load All data
########################################################################
## One time
# voter_score_dfAll <- readRDS("data/voter_score_df.RDS")
# voter_score_dfAll <- voter_score_dfAll[(duplicated(apply(voter_score_dfAll[,1:2],1,function(x) paste0(sort(x),collapse="")))),]
# saveRDS(voter_score_dfAll,"data/voter_score_df.RDS")
del_data <- readRDS("data/delegatesdf.RDS")
voter_score_dfAll <- readRDS("data/voter_score_df.RDS")

########################################################################
## Server Code
########################################################################
function(input, output, session) {

	## Network Plot
    output$coll_network <- renderForceNetwork({
                                                voter_score_df <- voter_score_dfAll[voter_score_dfAll$Score>=input$score_cutoff & voter_score_dfAll$NumCommonVotedProposals>input$min_comprop,]
                                                if(nrow(voter_score_df)==0) return(NULL)
												## Prepare Nodes and Links
                                                all_voters <- unique(c(voter_score_df$voterA,voter_score_df$voterB))
												all_votersNames <- del_data$Name[match(all_voters,del_data$Address)]
												voter_nodes <- data.frame(
																			name=ifelse(all_votersNames=="",all_voters,all_votersNames),
																			group=c("0 to 10 Delegators","10 to 500 Delegators",">500 Delegators")[findInterval(del_data$delegatorsCount[match(all_voters,del_data$Address)],c(0,10,500))],
																			size=(as.numeric(del_data$votesCount[match(all_voters,del_data$Address)])/10^18)^.35
																)
												voter_links <- data.frame(
																			source = match(voter_score_df$voterAName,voter_nodes$name)-1,
																			target = match(voter_score_df$voterBName,voter_nodes$name)-1,
																			value=voter_score_df$Score
																)
												my_color <- 'd3.scaleOrdinal() .domain(["0 to 10 Delegators", "10 to 500 Delegators",">500 Delegators"]) .range(["#9DCCED","#12AAFF","#213147"])'
												forceNetwork(
													Links = voter_links,
													Nodes = voter_nodes,
													Source = "source", 
													Target = "target",
													Value = "value", 
													NodeID = "name",
													Nodesize = "size",
													Group = "group",
													legend=TRUE,
													colourScale=my_color,
													opacity = 1,
													fontSize = 12,
													opacityNoHover = 1,
													bounded=TRUE,
													zoom = FALSE
												)

                            })

    ## Data Table
    output$coll_data <- renderDataTable({
                                            outdata <- voter_score_dfAll[,c(5,6,4,3)]
                                            outdata$Score <- round(outdata$Score,2)
                                            names(outdata) <- c("DelegateA","DelegateB","CommonProposals","SimilarityScore")
                                            outdata <- outdata[order(-outdata$SimilarityScore,-outdata$CommonProposals),]
                                            datatable(
                                                        outdata,
                                                        escape = FALSE,
                                                        rownames=FALSE,
                                                        options = list(
                                                                        paging = TRUE,
                                                                        bInfo = FALSE,
                                                                        ordering=TRUE,
                                                                        searching=TRUE,
                                                                        autoWidth = TRUE,
                                                                        bLengthChange = FALSE,
                                                                        pageLength = 20
                                                                    )
                                                    )
                            })

    output$downloadData <- downloadHandler(
    filename = function() {
      # Use the selected dataset as the suggested file name
      "DelegateDNA.csv"
    },
    content = function(file) {
      # Write the dataset to the `file` that will be downloaded
      outdata <- voter_score_dfAll[,c(5,6,4,3)]
	  outdata$Score <- round(outdata$Score,2)
	  names(outdata) <- c("DelegateA","DelegateB","CommonProposals","SimilarityScore")
	  outdata <- outdata[order(-outdata$SimilarityScore,-outdata$CommonProposals),]
      write_csv(outdata, file)
    }
  )
}