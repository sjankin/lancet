## load helpers ------------------
source("code/helpers.R")

## load packages -----------------
library(rvest)
library(tidyverse)
library(pdftools)
library(magrittr)
setwd("~/Documents/GitHub/lancet/report2021/COP_CSR/")

## parse HTML --------------------
iso_codes <- read.csv(file = "data/iso_code.csv") 
colnames(iso_codes) <- c("Country", "alpha.2", "code", "country.code" , "iso_3166.2",
                         "region" ,  "sub.region" , "intermediate.region" , "region.code",
                         "sub.region.code" , "intermediate.region.code")                
#("../data/iso_3.csv")

# parse with read_html
parsed_doc <- read_html("https://www.unglobalcompact.org/participation/report/cop/create-and-submit/active?page=1&per_page=10") # usually the first step in R when scraping web pages
parsed_doc

# number of active COPs
n_entries <- rvest::html_nodes(parsed_doc, xpath = "/html/body/main/section/div/header/h2") %>% 
  rvest::html_text("") %>%
  stringr::str_extract_all("\\d+") %>%
  as.numeric

paste0("Total number of GC Active COPs received: ", n_entries)

## extract information ------------------

# number of entries to calculate pages
n_pages <- 1:ceiling(n_entries/250)

# urls holding tables
urls_to_parse <- paste0("https://www.unglobalcompact.org/participation/report/cop/create-and-submit/active?page=", n_pages,"&per_page=250") 

# extraction of table information
csr_cop_submissions <- lapply(urls_to_parse, submission_table) %>% dplyr::bind_rows() 

# fixing of country names for iso code matching
csr_cop_submissions <- csr_cop_submissions %>% dplyr::mutate(Country = case_when(Country == "Bosnia-Herze..." ~ "Bosnia and Herzegovina",
                                                            Country == "Central Afri..." ~ "Central African Republic",
                                                            Country == "Congo, Democ..." ~ "Congo. Democratic Republic of the",
                                                            Country == "Dominican Re..." ~ "Dominican Republic",
                                                            Country == "Iran, Islami..." ~ "Iran. Islamic Republic of",
                                                            Country == "Korea, Repub..." ~ "Korea. Republic of",
                                                            Country == "Kosovo as pe..." ~ "Kosovo",
                                                            Country == "Moldova, Rep..." ~ "Moldova. Republic of",
                                                            Country == "Palestine, S..." ~ "Palestine. State of",
                                                            Country == "Papua New Gu..." ~ "Papua New Guinea",
                                                            Country == "Russian Fede..." ~ "Russian Federation",
                                                            Country == "Sao Tome And..." ~ "Sao Tome and Principe",
                                                            Country == "Syrian Arab ..." ~ "Syrian Arab Republic",
                                                            Country == "Tanzania, Un..." ~ "Tanzania. United Republic of",
                                                            Country == "Trinidad And..." ~ "Trinidad and Tobago",
                                                            Country == "United Arab ..." ~ "United Arab Emirates",
                                                            Country == "United State..." ~ "United States",
                                                            T ~ Country
                                                            ))

#iso_codes <- iso_codes %>% dplyr::mutate(Country = case_when(Country == "Congo. the Democratic Republic of the" ~ "Congo, the Democratic Republic of the", 
 #                                                            Country == "Iran. Islamic Republic of" ~ "Iran, Islamic Republic of",
  #                                                           Country == "Korea. Republic of" ~ "Korea, Republic of",
   #                                                          Country == "Moldova. Republic of" ~ "Moldova, Republic of",
    #                                                         Country == "Palestine. State of" ~ "Palestine, State of",
     #                                                        Country == "Tanzania. United Republic of" ~ "Tanzania, United Republic of",
      #                                                       T ~ Country
       #                                                      ))

# iso code matching - exclusion of 2020+
csr_table <- left_join(csr_cop_submissions, iso_codes[c('Country', 'code')], by = c("Country")) %>%
  dplyr::filter(Year != "2022")

# english and number of document availability (time-consuming//load csr_table.Rdata)
#csr_table <- csr_table %>% dplyr::rowwise() %>%
 # dplyr::mutate(English = submit_language(Link))

csr_table_all = csr_table[FALSE, ]
chunk = 300
total_dim = dim(csr_table)[1]

for (start in seq(dim(csr_table_all)[1]+1, total_dim, by=chunk)){
  
  if (dim(csr_table_all)[1] == 0){
    csr_table_all <-  csr_table[start:min(c(start+chunk-1, total_dim)), ] %>% dplyr::rowwise() %>%
      dplyr::mutate(English = submit_language(Link))
  } else {
    df <- csr_table[start:min(c(start+chunk-1, total_dim)), ] %>% dplyr::rowwise() %>%
      dplyr::mutate(English = submit_language(Link))
    csr_table_all <- rbind(csr_table_all, df)
  }
  save(csr_table_all, file = "data/csr_table_tmp.Rdata")
}  
# Format: 'Express', docs from USA not identified as English 
csr_table = as.data.frame(csr_table_all)

# save table -----
save(csr_table, file = "data/csr_table.Rdata")

