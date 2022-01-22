## load helpers ------------------
source("helpers.R")

## load packages -----------------
library(rvest)
library(tidyverse)
library(pdftools)
library(magrittr)

# load data
load("../data/csr_table.Rdata")

csr_english <- csr_table %>% dplyr::filter(English != 0)  %>% dplyr::rowwise() %>%
  dplyr::mutate(Pdf_url = pdf_urls(Link),
                Id = stringr::str_extract(Link, stringr::regex("\\d+")))

# file names
csr_english <- csr_english %>% 
  dplyr::mutate(file_name = paste0(Year,"_" , Code,"_" , str_extract_all(Link,stringr::regex("\\d+")),".pdf"))

save(csr_english,  file = "../data/csr_english.Rdata")

# download pdfs -----------------
folder <- "../pdf/"
dir.create(folder)
scrape_year <- c(2004:2020)

for (i in 1:length(scrape_year)) {
  download_pdfs(scrape_year = scrape_year[i], data_to_scrape = csr_english)
}

# download txts --------
folder <- "../txt/"
dir.create(folder)
scrape_year <- c(2004:2020)

for (i in 1:length(scrape_year)) {
  pdf_to_txt(scrape_year = scrape_year[i], data_to_scrape = csr_english)
}