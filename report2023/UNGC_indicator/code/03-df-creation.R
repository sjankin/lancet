setwd("~/Documents/GitHub/lancet_1/report2023/COP_CSR/")
## load helpers ------------------
source("code/helpers.R")

## load packages -----------------
library(rvest)
library(tidyverse)
library(pdftools)
library(magrittr)
library(quanteda)
library(readtext)

## load data ---------------------
load("data/csr_english.Rdata")

## table from txts
scrape_year <- c(2004:2022)

create_table_from_txt <- function(scrape_year, folder ="txt/") {
  readtext::readtext(paste0(folder, scrape_year ,"/*.txt"), 
                              docvarsfrom = "filenames", 
                              docvarnames = c("Year", "code", "Id"),
                              dvsep = "_")
}

txt_list <- list()
for (i in 1:length(scrape_year)) {
  try(txt_list[[i]] <- create_table_from_txt(scrape_year[i], folder = "txt/"))
}

# bind dfs from list
csr_text_df <- dplyr::bind_rows(txt_list) %>% dplyr::mutate(Id = as.character(Id)) %>% dplyr::left_join(csr_english, .)
sum(is.na(csr_text_df$text))
save(csr_text_df, file = "data/csr_text_df_English.Rdata")
