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

n_pages <- 1:ceiling(n_entries/5000)

urls_to_parse <- paste0("https://www.unglobalcompact.org/participation/report/cop/create-and-submit/active?page=", n_pages,"&per_page=5000")


parser_links <- function(x) {
  read_html(x) %>% html_nodes(.,  xpath = "//*[@id='paged_results']/div/table/tbody/tr[*]/td[*]/a") %>%
    rvest::html_attr("href") %>% unlist(use.names = F, recursive = T)
}


submission_table <- function(x) {
  read_html(x) %>% html_node("table") %>% html_table() %>%
    dplyr::mutate(Link = paste0("https://www.unglobalcompact.org",parser_links(x))) 
}

submit_date <- function(x) {
  read_html(x) %>% html_nodes(.,  xpath = "/html/body/main/section/div/section/dl/dd[2]/ul/li") %>%
    rvest::html_text() %>% stringr::str_extract(stringr::regex("\\d{4}/\\d{2}/\\d{2}"))
}

submit_language <- function(x) {
  read_html(x) %>% html_nodes(.,  xpath = "/html/body/main/section/div/section/dl/dd[4]/ul/li/text()") %>%
    rvest::html_text() %>% stringr::str_detect("English") %>% sum()
}

pdf_urls <- function(x) {
  read_html(x) %>% html_nodes(.,  xpath = "/html/body/main/section/div/section/dl/dd[4]/ul/li/a") %>% 
    rvest::html_attr("href") %>% stringr::str_replace_all(" ", "%20") %>% .[1] %>%
    paste0("https:", .)
}

csr_cop_submissions <- lapply(urls_to_parse, submission_table) %>% dplyr::bind_rows()

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


csr_table <- left_join(csr_cop_submissions, iso_codes, by = c("Country")) %>%
  dplyr::filter(Year != "2021")

csr_table <- csr_table %>% dplyr::rowwise() %>%
  dplyr::mutate(English = submit_language(Link))

#-----
save(csr_table, file = "../data/csr_table.Rdata")


