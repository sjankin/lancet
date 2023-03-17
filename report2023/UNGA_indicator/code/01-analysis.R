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
load("../data/tok.r.Rdata")
#load("../data/country_lists.Rdata")
summary_df <- readr::read_csv("../output/corp_summary.csv") 

country_groupings <- readxl::read_excel("../data/Country Names and groupings - 2023 Report.xlsx")

##########################################


## 1. setting up agreed dictionaries ----

# creating compound tokens from the key terms (phrases) in our dictionaries

mylist <- list(c("air", "pollution"), c("mental", "disorder"), c("mental", "disorders"), c("climate","change"), c("changing","climate"), c("climate","emergency"), 
               c("climate","crisis"), c("climate","decay"), c("global","warming"), c("green","house"), c("extreme","weather"), c("global", "environmental", "change"), 
               c("climate","variability"),  c("low","carbon"), c("renewable","energy"), c("carbon","emission"), c("carbon","emissions"), c("carbon","dioxide"), 
               c("co2","emission"), c("co2","emissions"), c("climate","pollutant"), c("climate","pollutants"), c("carbon","neutral"), c("carbon","neutrality"), 
               c("climate","neutrality"), c("climate","action"), c("net","zero")) 

tok.compound <- quanteda::tokens_compound(tok.r, mylist, valuetype = "fixed", concatenator = "_")


# creating the dictionary of climate change terms

climate_dict <- dictionary(list(climate =  c("climate_change", "changing_climate", "climate_emergency", "climate_crisis", "climate_decay", "global_warming",
                                             "green_house", "temperature", "extreme_weather", "global_environmental_change", "climate_variability", "greenhouse", 
                                             "greenhouse-gas", "low_carbon", "ghge", "ghges", "renewable_energy", "carbon_emission", "carbon_emissions", 
                                             "carbon_dioxide", "carbon-dioxide", "co2_emission", "co2_emissions", "climate_pollutant", "climate_pollutants", 
                                             "decarbonization", "decarbonisation", "carbon_neutral", "carbon-neutral", "carbon_neutrality", "climate_neutrality", 
                                             "climate_action", "net-zero", "net_zero")))
# creating the dictionary of health terms

health_dict <- dictionary(list(health = c("malaria", "diarrhoea", "infection", "disease", "diseases", "sars", "measles", "pneumonia", "epidemic", "epidemics", 
                                          "pandemic", "pandemics", "epidemiology", "healthcare", "health", "mortality", "morbidity", "nutrition", "illness", 
                                          "illnesses", "ncd", "ncds", "air_pollution", "nutrition", "malnutrition", "malnourishment", "mental_disorder", 
                                          "mental_disorders", "stunting")))

# combined dictionary

combined_dict <- dictionary(list(
  climate =  c("climate_change", "changing_climate", "climate_emergency", "climate_crisis", "climate_decay", "global_warming", "green_house", "temperature", 
               "extreme_weather", "global_environmental_change", "climate_variability", "greenhouse", "greenhouse-gas", "low_carbon", "ghge", "ghges", "renewable_energy",
               "carbon_emission", "carbon_emissions", "carbon_dioxide", "carbon-dioxide", "co2_emission", "co2_emissions", "climate_pollutant", "climate_pollutants", 
               "decarbonization", "decarbonisation", "carbon_neutral", "carbon-neutral", "carbon_neutrality", "climate_neutrality", "climate_action", "net-zero", "net_zero"), 
  health = c("malaria", "diarrhoea", "infection", "disease", "diseases", "sars", "measles", "pneumonia", "epidemic", "epidemics", "pandemic", "pandemics", "epidemiology",
             "healthcare", "health", "mortality", "morbidity", "nutrition", "illness", "illnesses", "ncd", "ncds", "air_pollution", "nutrition", "malnutrition", 
             "malnourishment", "mental_disorder", "mental_disorders", "stunting")))

# covid dictionary

covid_dict <- dictionary(list(covid = c("covid-19", "covid19", "covid 19", "corona", "coronavirus", "sars-cov-2")))

# gender dictionary

gender_dict <- dictionary(list(gender = c("gender", "male", "female", "man", "men", "woman", "women", "sex")))



## 2. Keyword-in-context search (KWIC) ----

# health dictionary
tok.hea <- kwic(tok.compound, health_dict, window = 25, valuetype = "fixed")

# climate change dictionary
tok.cc <- kwic(tok.compound, climate_dict, window = 25, valuetype = "fixed")

# intersection
corpus_health <- quanteda::corpus(tok.hea, split_context = FALSE, extract_keyword = TRUE)
tok.climate.kwic <- kwic(corpus_health, climate_dict, window = 25, valuetype = "fixed")

# save .csv
readr::write_csv(tok.hea, "../output/health_kwic_25_fixed.csv")
readr::write_csv(tok.cc, "../output/climate_kwic_25_fixed.csv")
readr::write_csv(tok.climate.kwic, "../output/intersection_kwic_25_fixed.csv")


# view keywords
df_health_keywords <- data.frame(tok.hea$keyword) %>%
  dplyr::select(keyword=tok.hea.keyword) %>%
  dplyr::group_by(keyword) %>%
  dplyr::tally(name="count") %>%
  dplyr::arrange(-count)

df_climate_keywords <- data.frame(tok.cc$keyword) %>%
  dplyr::select(keyword=tok.cc.keyword) %>%
  dplyr::group_by(keyword) %>%
  dplyr::tally(name="count") %>%
  dplyr::arrange(-count)

df_intersection_keywords <- data.frame(tok.climate.kwic$keyword) %>%
  dplyr::select(keyword=tok.climate.kwic.keyword) %>%
  dplyr::group_by(keyword) %>%
  dplyr::tally(name="count") %>%
  dplyr::arrange(-count)

df_health_keywords
df_climate_keywords
df_intersection_keywords

# extract counts

## health
health_dfm <- quanteda::dfm(corpus_health)
health <- convert(health_dfm, "tm")
health_df <- tidytext::tidy(health) %>% dplyr::rename(docid = document) %>% 
  dplyr::mutate(line = stringr::str_extract(docid, stringr::regex("\\.L\\d*")))


## climate
corpus_climate <- corpus(tok.cc, split_context = FALSE, extract_keyword = TRUE)
climate_dfm <- dfm(corpus_climate)
climate <- convert(climate_dfm, "tm")
climate_df <- tidytext::tidy(climate_dfm) %>% dplyr::rename(docid = document) %>% 
  dplyr::mutate(line = stringr::str_extract(docid, stringr::regex("\\.L\\d*")))


## intersection
corpus_intersection <- corpus(tok.climate.kwic, split_context = FALSE, extract_keyword = TRUE)
intersection_dfm <- dfm(corpus_intersection)
intersection <- convert(intersection_dfm, "tm")
intersection_df <- tidytext::tidy(intersection_dfm) %>% dplyr::rename(docid = document) %>% 
  dplyr::mutate(line = stringr::str_extract(docid, stringr::regex("\\.L\\d*")),
                year = stringr::str_extract(docid, stringr::regex("\\d{4}")),
                document_id = stringr::str_extract(docid, stringr::regex("^(.+?)_")),
                Code = stringr::str_remove_all(document_id, "_"))


intersection_covid <- 
  tibble::tibble(
    year = 2022,
    intersection_df %>% dplyr::filter(year == 2022) %>% dplyr::summarize(total_docs = dplyr::n_distinct(Code)),
    quanteda::dfm_lookup(intersection_dfm, dictionary = covid_dict, valuetype= "fixed") %>% convert(., "tm") %>%
      tidytext::tidy(.) %>% dplyr::summarize(hits = sum(count),
                                             documents = n_distinct(document),
                                             prop_doct = documents/total_docs))

gender_intersection_df <- quanteda::dfm_lookup(intersection_dfm, dictionary = gender_dict, valuetype= "fixed") %>% convert(., "tm") %>%
  tidytext::tidy(.) %>% dplyr::rename(docid = document) %>% 
  dplyr::mutate(line = stringr::str_extract(docid, stringr::regex("\\.L\\d*")),
                year = stringr::str_extract(docid, stringr::regex("\\d{4}")),
                document_id = stringr::str_extract(docid, stringr::regex("^(.+?)_")),
                Code = stringr::str_remove_all(document_id, "_"))

intersection_gender <- dplyr::left_join(
  intersection_df %>% group_by(year) %>% dplyr::summarize(total_docs = dplyr::n_distinct(Code)),
  gender_intersection_df %>% 
    group_by(year) %>% dplyr::summarize(hits = sum(count),documents = n_distinct(Code))) %>% 
  dplyr::mutate(prop_doct = round(documents/total_docs, 2)) %>%
  dplyr::mutate_all(~replace(., is.na(.), 0))


### counts

health_counts <- health_df %>% group_by(docid) %>% dplyr::summarise(words = n()) %>%
  dplyr::mutate(docid = stringr::str_remove(docid, stringr::regex("\\.L\\d*"))) %>%
  dplyr::group_by(docid) %>% dplyr::summarise(health_count = n())

climate_counts <- climate_df %>% group_by(docid) %>% dplyr::summarise(words = n()) %>%
  dplyr::mutate(docid = stringr::str_remove(docid, stringr::regex("\\.L\\d*"))) %>%
  group_by(docid) %>% dplyr::summarise(climate_count = n())

intersection_counts <- intersection_df %>% group_by(docid) %>% dplyr::summarise(words = n()) %>%
  dplyr::mutate(docid = stringr::str_remove(docid, stringr::regex("\\.L\\d*\\.L\\d*"))) %>%
  group_by(docid) %>% dplyr::summarise(intersection_count = n())

counts_df <- climate_counts %>% 
  full_join(health_counts, by = "docid") %>% 
  full_join(intersection_counts, by = "docid") %>%
  replace_na(list(health_count=0, climate_count=0, intersection_count=0))

# join to text info
total_counts <- counts_df %>% dplyr::mutate(year = stringr::str_extract(docid, stringr::regex("\\d{4}")),
                                            document_id = stringr::str_extract(docid, stringr::regex("^(.+?)_")),
                                            Code = stringr::str_remove_all(document_id, "_")) %>% 
  dplyr::select(-document_id) %>%
  left_join(., country_groupings, by = join_by(Code == ISO3))

total_counts <- arrange(total_counts, Code, year)

# Data preparation
climate_texts <- total_counts %>% filter(climate_count>0) %>% group_by(year) %>% tally(name = "climate_texts")
health_texts <- total_counts %>% filter(health_count>0) %>% group_by(year) %>% tally(name = "health_texts")
intersection_texts <- total_counts %>% filter(intersection_count>0) %>% group_by(year) %>% tally(name = "intersection_texts")

total_texts <- summary_df %>% dplyr::mutate(year = as.character(Year)) %>%
  dplyr::left_join(., climate_texts) %>%
  dplyr::left_join(., health_texts) %>%
  dplyr::left_join(., intersection_texts) %>%
  dplyr::mutate_all(~replace(., is.na(.), 0))

# save dfs for results
save(climate_texts, health_texts, intersection_texts, total_texts, file = "../data/tallied_texts.RData")
save(total_counts, file = "../data/total_counts.RData")
save(intersection_covid, intersection_gender, file = "../data/intersection_covid_gender.RData")
save(df_health_keywords, df_climate_keywords, df_intersection_keywords, file = "../data/keyword_tables.RData")
