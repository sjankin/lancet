setwd("~/Documents/GitHub/lancet/report2021/COP_CSR/")
## load helpers ------------------
source("code/helpers.R")

## load packages -----------------
library(rvest)
library(tidyverse)
library(pdftools)
library(magrittr)

# load data
load("data/csr_table.Rdata")

country_eng <- c('ATG', 'AUS', 'BHS', 'BRB', 'BLZ', 'CAN', 'DMA', 'GRD', 'GUY', 'IRL', 'JAM', 'MLT', 'NZL',
                 'KNA', 'LCA', 'VCT', 'TTO', 'GBR', 'USA')

df_english <- csr_table %>% dplyr::filter((English > 0 )) #|(code %in% country_eng)) does not contain link info

csr_english_all = csr_table[FALSE, ]
chunk = 300
total_dim = dim(csr_table)[1]
#round = 0
for (start in seq(round*chunk + 1, total_dim, by=chunk)){
  
  if (dim(csr_english_all)[1] == 0){
    csr_english_all <-  csr_table[start:min(c(start+chunk-1, total_dim)), ] %>% dplyr::filter(English > 0)  %>% dplyr::rowwise() %>% 
      dplyr::mutate(Pdf_url = pdf_urls(Link),
                    Id = stringr::str_extract(Link, stringr::regex("\\d+")))
  } else {
    df <- csr_table[start:min(c(start+chunk-1, total_dim)), ] %>% dplyr::filter(English > 0)  %>% dplyr::rowwise() %>% 
      dplyr::mutate(Pdf_url = pdf_urls(Link),
                    Id = stringr::str_extract(Link, stringr::regex("\\d+")))
    csr_english_all <- rbind(csr_english_all, df)
  }
  round = round + 1
  if (round %% 20 == 0) {
    print(round)
  }
  save(csr_english_all, file = "data/csr_english_tmp.Rdata")
} 

csr_english = as.data.frame(csr_english_all)
# file names
csr_english <-  csr_english %>% 
  dplyr::mutate(file_name = paste0(Year,"_" , code,"_" , str_extract_all(Link,stringr::regex("\\d+")),".pdf"))

save(csr_english,  file = "data/csr_english.Rdata")


load("data/csr_english.Rdata")

# download pdfs -----------------
# tried multiprocessing error with connection occur too often due to frequent request
download_pdfs <- function(scrape_year, data_to_scrape) {
  dir.create(paste0(folder,scrape_year))
  csr <- data_to_scrape %>% dplyr::filter(Year == scrape_year)
  for (i in 1:length(csr$Pdf_url)) {
    fname = str_replace(csr$file_name[i], "pdf", "txt")
    if ((!file.exists(paste0('pdf', "/", scrape_year, "/", csr$file_name[i]))) &
        (!file.exists(paste0('txt', "/", scrape_year, "/", fname)))){
      try(download.file(csr$Pdf_url[i], destfile = paste0(folder, "/",scrape_year, "/", csr$file_name[i]))) # , method = "libcurl" might be needed on windows machine
      Sys.sleep(runif(1, 0, 1)*2)
    } else {
      print(paste0(fname, ' already exists.'))
    }
  }
}

folder <- "pdf/"
dir.create(folder)
scrape_year <- c(2004:2021)

for (i in 1:length(scrape_year)) {
  download_pdfs(scrape_year = scrape_year[i], data_to_scrape = csr_english)
}


# download txts --------
pdf_to_txt <- function(scrape_year, data_to_scrape) {
  dir.create(paste0(folder,scrape_year))
  csr <- data_to_scrape %>% dplyr::filter(Year == scrape_year) %>% dplyr::mutate(file_name_txt = stringr::str_replace_all(file_name, "pdf", "txt"))
  for (i in 1:length(csr$Pdf_url)) {
    if ((!file.exists(paste0('txt', "/", scrape_year, "/", csr$file_name_txt[i])))) {
      try(text_file <- pdftools::pdf_text(pdf = paste0("pdf/", scrape_year, "/", csr$file_name[i])) %>%
            paste(sep = " ") %>%
            stringr::str_replace_all(fixed("\n"), " ") %>%
            stringr::str_replace_all(fixed("\r"), " ") %>%
            stringr::str_replace_all(fixed("\t"), " ") %>%
            stringr::str_replace_all(fixed("\""), " ") %>%
            paste(sep = " ", collapse = " ") %>%
            stringr::str_squish() %>%
            stringr::str_replace_all("- ", ""))
      if (exists('text_file')){
        try(writeLines(text_file, paste0(folder, "/", scrape_year, "/", csr$file_name_txt[i])))
        rm(text_file)
      } else {
        print(paste0('FILE NOT CONVERTED! ', 'txt2021', "/", scrape_year, "/", csr$file_name_txt[i]))
        }
    }
  }}

folder <- "txt/"
dir.create(folder)
scrape_year <- c(2004:2021)
for (i in 1:length(scrape_year)) {
  pdf_to_txt(scrape_year = scrape_year[i], data_to_scrape = csr_english)
}
