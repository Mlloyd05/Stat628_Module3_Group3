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

coffee_shops <- read_csv("Shiny_Data/best_filtered_smaller_data.csv")
PA_shops <- coffee_shops[coffee_shops$state == "PA",]



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