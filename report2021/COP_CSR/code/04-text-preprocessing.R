## load helpers ------------------
source("helpers.R")

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
library(tm)

## load data ---------------------
load("../data/csr_text_df.Rdata")
ungc_df <- csr_text_df %>% dplyr::filter(!is.na(text) & text != "")

##########################################

## Summary statistics

## 1. creating corpus objects (by sector) ----
ungc_corpus <- quanteda::corpus(ungc_df, text_field = "text")

## 2. summary
corp_summary <- summarise(group_by(summary(ungc_corpus)),
                          total_speeches=sum(Types),total_sentences=sum(Sentences),total_words=sum(Tokens))
corp_summary

#readr::write_csv(corp_summary, "../data/corp_summary.csv")

## 2. pre-processing ----

# tokenization and basic pre-processing
tok <- quanteda::tokens(ungc_corpus, what = "word",
                        remove_punct = TRUE,
                        remove_symbols = TRUE,
                        remove_numbers = TRUE,
                        remove_twitter = TRUE,
                        remove_url = TRUE,
                        split_hyphen = FALSE,
                        verbose = TRUE)

# lowecasing and removing stopwords
tok <- quanteda::tokens_tolower(tok)
tok.r <- quanteda::tokens_select(tok, stopwords("english"), selection = "remove", padding = FALSE)

#save(tok, file = "../data/tok.RData")
save(tok.r, file = "../data/tok-r.RData")