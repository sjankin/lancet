## load helpers ------------------
source("helpers.R")

## load packages -----------------
library(rvest)
library(tidyverse)
library(pdftools)
library(magrittr)

## parse HTML --------------------
iso_codes <- readxl::read_xlsx("../data/iso_codes.xlsx")

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
n_pages <- 1:ceiling(n_entries/5000)

# urls holding tables
urls_to_parse <- paste0("https://www.unglobalcompact.org/participation/report/cop/create-and-submit/active?page=", n_pages,"&per_page=5000") 

# extraction of table information
csr_cop_submissions <- lapply(urls_to_parse, submission_table) %>% dplyr::bind_rows() 

# fixing of country names for iso code matching
csr_cop_submissions <- csr_cop_submissions %>% dplyr::mutate(Country = case_when(Country == "Bosnia-Herze..." ~ "Bosnia and Herzegovina",
                                                            Country == "Central Afri..." ~ "Central African Republic",
                                                            Country == "Congo, Democ..." ~ "Congo, the Democratic Republic of the",
                                                            Country == "Dominican Re..." ~ "Dominican Republic",
                                                            Country == "Iran, Islami..." ~ "Iran, Islamic Republic of",
                                                            Country == "Korea, Repub..." ~ "Korea, Republic of",
                                                            Country == "Kosovo as pe..." ~ "Kosovo",
                                                            Country == "Moldova, Rep..." ~ "Moldova, Republic of",
                                                            Country == "Palestine, S..." ~ "Palestine, State of",
                                                            Country == "Papua New Gu..." ~ "Papua New Guinea",
                                                            Country == "Russian Fede..." ~ "Russian Federation",
                                                            Country == "Sao Tome And..." ~ "Sao Tome and Principe",
                                                            Country == "Syrian Arab ..." ~ "Syrian Arab Republic",
                                                            Country == "Tanzania, Un..." ~ "Tanzania, United Republic of",
                                                            Country == "Trinidad And..." ~ "Trinidad and Tobago",
                                                            Country == "United Arab ..." ~ "United Arab Emirates",
                                                            Country == "United State..." ~ "United States",
                                                            T ~ Country
                                                            ))


# iso code matching - exclusion of 2020+
csr_table <- left_join(csr_cop_submissions, iso_codes, by = c("Country")) %>%
  dplyr::filter(Year != "2021")

# english and number of document availability (time-consuming//load csr_table.Rdata)
#csr_table <- csr_table %>% dplyr::rowwise() %>%
#  dplyr::mutate(English = submit_language(Link))

# save table -----
#save(csr_table, file = "../data/csr_table.Rdata")

