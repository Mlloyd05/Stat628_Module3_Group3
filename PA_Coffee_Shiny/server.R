library(shiny)
library(tidyverse)
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
library(stringr)
library(bipartite)
library(tidytext)
library(DT)


PA_shops <- read_csv("Shiny_Data/PA_Yelp_Coffee_Data.csv")
top_words <- as.data.frame(read_csv("Shiny_Data/top_words.csv"))





server <- function(input, output) { 
  #Selection Handling
  output$address <- renderUI({
    selectInput("Address", "Address:", choices = unique(PA_shops[PA_shops$name_business_or_review == input$Shop,]$address))
  })
  outputOptions(output, "address", suspendWhenHidden = FALSE)
  
  
  #Default holders
  current_lat <- reactiveVal(0)
  current_long <- reactiveVal(0)
  
  #Map Handling
  observeEvent(input$Address,{
    current_lat <-PA_shops[PA_shops$address == input$Address,]$latitude[1]
    current_long <-PA_shops[PA_shops$address == input$Address,]$longitude[1]
    #Philadelphia Lng and Lat defaults: lng = -75.1624776, lat = 39.9562897
    output$mymap <- renderLeaflet({
      m <- leaflet() %>%
        addTiles() %>%
        addMarkers(lng = current_long, lat = current_lat) %>%
        setView(lng = current_long, lat = current_lat, zoom = 50)
      m
    })
  })
  
  
  
  #Review Tab Handling
  observeEvent(input$Address,
               {
                 current_store_positives <-PA_shops[(PA_shops$address == input$Address) & (PA_shops$name_business_or_review == input$Shop)
                                                    & (PA_shops$Sent_resp == 1),]$text
                 current_store_negatives <-PA_shops[(PA_shops$address == input$Address) & (PA_shops$name_business_or_review == input$Shop)
                                                    & (PA_shops$Sent_resp == -1),]$text
                 if(length(current_store_positives) == 0){
                   current_store_positives <- "No Positive Reviews Available"
                 }
                 if(length(current_store_negatives) == 0){
                   current_store_negatives <- "No Negative Reviews Available"
                 }
                 positive_docs <- Corpus(VectorSource(current_store_positives))
                 negative_docs <- Corpus(VectorSource(current_store_negatives))
                 
                 #Cleaning positive docs
                 positive_docs <- positive_docs %>%
                   tm_map(removeNumbers) %>%
                   tm_map(removePunctuation) %>%
                   tm_map(stripWhitespace)
                 positive_docs <- tm_map(positive_docs, content_transformer(tolower))
                 positive_docs <- tm_map(positive_docs, removeWords, stopwords("english"))
                 
                 #Cleaning negative docs
                 negative_docs <- negative_docs %>%
                   tm_map(removeNumbers) %>%
                   tm_map(removePunctuation) %>%
                   tm_map(stripWhitespace)
                 negative_docs <- tm_map(negative_docs, content_transformer(tolower))
                 negative_docs <- tm_map(negative_docs, removeWords, stopwords("english"))
                 
                 positive_dtm <- TermDocumentMatrix(positive_docs) 
                 negative_dtm <- TermDocumentMatrix(negative_docs)
                 rm(positive_docs,negative_docs)
                 positive_matrix <- as.matrix(positive_dtm)
                 negative_matrix <- as.matrix(negative_dtm)
                 rm(positive_dtm,negative_dtm)
                 positive_words <- sort(rowSums(positive_matrix),decreasing=TRUE)
                 negative_words <- sort(rowSums(negative_matrix),decreasing=TRUE)
                 rm(positive_matrix,negative_matrix)
                 positive_df <- data.frame(word = names(positive_words),freq=positive_words)
                 negative_df <- data.frame(word = names(negative_words),freq=negative_words)
                 rm(positive_words,negative_words)
                 
                 #filter out stop words 
                 positive_df <- positive_df %>% 
                   filter(!(word %in% stopwords(source = "smart")))
                 
                 negative_df <- negative_df %>% 
                   filter(!(word %in% stopwords(source = "smart")))
                 
                 #Add additional filtering down to keywords
                 extra_removal_words <- c("starbucks", "ive", "didnt", "dont", "one", "can", "get", "just", "also", "know", "great", "good", "love", "make", "like", "place", "really", "even", "always", "best", "well", "coffee", "tea", "latte", "cappucino", "cappuccino", "bad", "poor", "get", "best", "just", "friendly", "nice", "back", "pretty", "super", "clean", "location", "day", "work", "perfect", "city", "town","neighborhood", "philly", "open", "horrible", "terrible", "disappointed", "woman", "extremely", "order", "amazing", "ordered", "recommend", "enjoy", "awesome", "excellent", "times", "short", "coming", "worse", "hate")
                 
                 positive_df <- positive_df %>% 
                   filter(!(word %in% extra_removal_words))
                 
                 negative_df <- negative_df %>% 
                   filter(!(word %in% extra_removal_words))
                 
                 top_words <- as.data.frame(read_csv("Shiny_Data/top_words.csv"))
                 
                 top_words$positive_dummy <- apply(top_words, 1, function(x) grepl(paste0("\\b",x[1],"\\b"),positive_df, fixed = FALSE, ignore.case = FALSE))[1,]
                 
                 top_words$negative_dummy <- apply(top_words, 1, function(x) grepl(paste0("\\b",x[2],"\\b"),negative_df, fixed = FALSE, ignore.case = FALSE))[1,]
                 
                 top_words$"Positive Frequency" <- apply(top_words, 1, function(x) if(x[3] == TRUE){positive_df[positive_df$word == x[1],]$freq} else{0}) 
                 
                 top_words$"Negative Frequency" <- apply(top_words, 1, function(x) if(x[4] == TRUE){negative_df[negative_df$word == x[2],]$freq} else{0})
                 
                 rm(positive_df, negative_df)
                 
                 #for(i in 1:15){
                 #  if(length(top_words$"Positive Frequency"[i]) == 0)
                 #    {top_words$"Positive Frequency"[i] = 0}
                 ##  if(length(top_words$"Negative Frequency"[i]) == 0)
                 #    {top_words$"Negative Frequency"[i] = 0}
                 #}
                 
                 
                 
                 col_order <- c("Positives", "Positive Frequency", "Negatives", "Negative Frequency", "positive_dummy", "negative_dummy")
                 top_words <- top_words[, col_order]
                 
                 output$word_list <- renderDataTable(datatable(top_words, options = list( columnDefs = list(list(targets = c(5,6), visible = FALSE)))) %>% formatStyle('Positives', 'positive_dummy', backgroundColor = styleEqual(TRUE, "turquoise")) %>% formatStyle('Negatives', 'negative_dummy', backgroundColor = styleEqual(TRUE, "orange")))
                 
                 #output$positives <-renderText(positive_df[1:5,1])
                 #output$negatives <-renderText(negative_df[1:5,1])
               })
  
  #Ratings Graph handling
  observeEvent(input$Address,
               {
                 review_spread <- as.data.frame(table(PA_shops[(PA_shops$address == input$Address) & (PA_shops$name_business_or_review == input$Shop),]$stars_review))
                 output$review_plot <- renderPlot(ggplot(review_spread, aes(x = Var1, y = Freq, fill = Freq)) + geom_bar(stat= "identity") +
                                                    labs(x = "Review Stars", y = "Count") + theme(plot.title = element_text(hjust = 0.5)) + labs(title = "Review Score Across Ratings") + scale_fill_continuous(type = "gradient"))
               })
  
  observeEvent(input$Address,
               {
                 current_shops <- PA_shops[(PA_shops$address == input$Address) & (PA_shops$name_business_or_review == input$Shop),]
                 
                 output$sentiment_plot <- renderPlot(ggplot(current_shops) +
                                                       geom_point(aes(current_shops$stars_review, current_shops$Sent_QDAP)) +
                                                       labs(x = "Business Rating",
                                                            y = "Review Sentiment Score") + theme(plot.title = element_text(hjust = 0.5)) + labs(title = "Review Sentiment Spread Across Ratings"))
                 
               })
  
  
  
  #output$positive_list <- renderTable(top_positive_words$word, colnames = FALSE) %>%
  #  formatStyle(backgroundColor = 'red')
  
  
  #output$negative_list <- renderTable(top_negative_words$word, colnames = FALSE)
  
  
}