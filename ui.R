## Loading Libraries
library(shiny)
library(bslib)
library(networkD3)
library(DT)
library(shinycssloaders)
library(shinydashboard)

## UI
addResourcePath("images", "images")
ui <- fluidPage(theme = bs_theme(bootswatch = "sandstone"),
  br(),
  fluidRow(
    column(width = 3,tags$a(target = "_blank", href="https://thankarb.com/", tags$img(src = "images/AF_lockup_navy.png", height="80px")),align="left"),
    column(width = 6,h2("Delegate Network Visualization Based on Voting Patterns")),
    column(width = 3,tags$a(target = "_blank", href="https://app.dework.xyz/datagrants-thankar", tags$img(src = "images/odcarb.png", height="100px")),align="right"),
  ),
  tabsetPanel(
    tabPanel("Delegate Networks Clusters",
      br(),
      sidebarLayout(
        sidebarPanel(width=3,
          p(" Delegate is recognized as having a minimum of 1 Arb voting power, coupled with a prerequisite of having at least 2 addresses delegating to them."),
          p("From a pool of 153 Snapshot Proposals and 28 tally proposals, we've carefully curated 96 proposals characterized by diverse voting patterns. This selection criterion ensures that no proposal garners more than 80% of votes for a single answer."),
          p("The set of responses to the aforementioned 96 proposals is referred to as the 'Delegate DNA' vector."),
          p("The Similarity Score, an essential metric, is computed as the ratio of shared voting instances between two delegates to the total number of proposals they've jointly engaged with. This calculation is based on the aforementioned 'Delegate DNA' vector."),
          hr(),
          sliderInput("score_cutoff", label = "Delegate Similarity Score Threshold", min = .5, max = 1, value = .95,step=.05),
          br(),
          sliderInput("min_comprop", label = "Minimum Shared Voted Proposals", min = 10, max = 90, value = 80,step=5)
        ),
        mainPanel(width=9,
          withSpinner(forceNetworkOutput("coll_network",height="700px"))
        )
      )
    ),
    tabPanel("Delegate DNA Data Download",
      br(),
      fluidPage(
          downloadButton("downloadData", "Download"),
          withSpinner(dataTableOutput("coll_data"))
          
      )
    ),
  )
)