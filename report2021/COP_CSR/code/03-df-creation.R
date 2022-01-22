## load helpers ------------------
source("helpers.R")

## load packages -----------------
library(rvest)
library(tidyverse)
library(pdftools)
library(magrittr)
library(quanteda)
library(readtext)

## load data ---------------------
load("../data/csr_english.Rdata")

## table from txts
scrape_year <- c(2004:2020)
folder <- "../txt/"

txt_list <- list()
for (i in 1:length(scrape_year)) {
  txt_list[[i]] <- create_table_from_txt(scrape_year[i])
  
}

# bind dfs from list
csr_text_df <- dplyr::bind_rows(txt_list) %>% dplyr::mutate(Id = as.character(Id)) %>% dplyr::left_join(csr_english, .)

save(csr_text_df, file = "../data/csr_text_df.Rdata")