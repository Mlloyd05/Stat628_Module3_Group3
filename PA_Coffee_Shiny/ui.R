library(shiny)
library(tidyverse)
library(lubridate)
library(tidygraph)
library(ggraph)
library(ggplot2)
library(utils)
library(SentimentAnalysis)
library(SnowballC)
library(wordcloud)
library(tm)
library(stopwords)
library(shinythemes)
library(leaflet)
library(tidytext)
library(jsonlite)
library(stringr)
library(bipartite)
library(tidytext)
library(topicmodels)
library(superheat)
library(ggrepel)
library(DT)

PA_shops <- read_csv("Shiny_Data/PA_Yelp_Coffee_Data.csv")
PA_shops$Sent_QDAP <- analyzeSentiment(PA_shops$text)$SentimentQDAP
PA_shops <- PA_shops[!is.na(PA_shops$Sent_QDAP),]
PA_shops$Sent_direct <- convertToDirection(PA_shops$Sent_QDAP)
PA_shops$Sent_resp <- 0
#PA_shops$Sent_resp[PA_shops$Sent_direct == "positive"] <- 1
#PA_shops$Sent_resp[PA_shops$Sent_direct == "negative"] <- -1
## Changing to handle adjusted scores 
PA_shops$Sent_resp[PA_shops$Sent_QDAP < quantile(PA_shops$Sent_QDAP)[3] - .05] <- -1
PA_shops$Sent_resp[PA_shops$Sent_QDAP > quantile(PA_shops$Sent_QDAP)[3] + .05] <- 1



### definition of app
ui <- 
  navbarPage("PA Coffee Shops", collapsible = TRUE, inverse = TRUE, theme = shinytheme("spacelab"),
             tabPanel("Store Selection",
                      sidebarLayout(sidebarPanel(selectInput("Shop", "Shop:", choices = sort(unique(PA_shops$name_business_or_review))), 
                                                 conditionalPanel("input.Shop!=''",
                                                                  uiOutput("address"))),
                                    mainPanel(
                                      tabsetPanel(
                                        tabPanel("Top Words",  
                                                 dataTableOutput("word_list")), 
                                        tabPanel("Location",leafletOutput("mymap")),
                                        tabPanel("Ratings", plotOutput("review_plot"), plotOutput("sentiment_plot"))
                                      )),
                      )
             ),
             
             tabPanel("About", p("UPDATE THIS FOR MODULE 3 INFORMATION")),
             
             tabPanel("Contact", p("This shiny app is maintained by Marwan Lloyd '23. For any questions, concerns, or feedback please reach out him at either of the below emails:"), tags$address("Marwan.Lloyd@Wisc.edu"), tags$address("Melloyd2@Wisc.edu"))
  )