## load packages -----------------
library(readtext)
library(quanteda)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(rworldmap)
library(RColorBrewer)
library(haven)
library(readxl)

## load data ---------------------
ungd_files <- readtext("../TXT/*", 
                       docvarsfrom = "filenames", 
                       dvsep="_", 
                       docvarnames = c("Country", "Session", "Year"))


ungd_files$doc_id <- str_replace(ungd_files$doc_id , ".txt", "") %>%
  str_replace(. , "_\\d{2}", "")

save(ungd_files, file = "../data/ungd_files.RData")

## Creating corpus object -------
ungd_corpus <- corpus(ungd_files, text_field = "text") 


## Corpus summary ----------------
corp_summary <- summarise(group_by(summary(ungd_corpus, n = 10181),Year),
                          total_speeches=n(),total_sentences=sum(Sentences),total_words=sum(Tokens))

readr::write_csv(corp_summary, "../output/corp_summary.csv")

#Pre-processing -----------------

#Tokenization and basic pre-processing
tok <- tokens(ungd_corpus, what = "word",
              remove_punct = TRUE,
              remove_symbols = TRUE,
              remove_numbers = TRUE,
              remove_url = TRUE,
              split_hyphens = FALSE,
              verbose = TRUE)

tok <- tokens_tolower(tok)
tok.r <- tokens_select(tok, stopwords("english"), selection = "remove", padding = FALSE)

save(tok.r, file = "../data/tok.r.Rdata")
