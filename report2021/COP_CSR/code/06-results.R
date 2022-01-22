## load helpers ------------------
source("helpers.R")

## load packages -----------------
library(readtext)
library(quanteda)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(scales)
library(rworldmap)
library(RColorBrewer)
library(haven)
library(readxl)
library(tm)

## load data ---------------------

load("../data/total_counts.RData")
load("../data/tallied_texts.RData")

##########################################

# extract counts and proportions for plotting

# count data frame
agg_reference_df <- dplyr::left_join(
  total_counts %>% 
    dplyr::filter(Year >= 2011) %>%
    dplyr::group_by(Year) %>%
    dplyr::summarize(climate_references = sum(climate_count, na.rm = T),
                     health_references = sum(health_count, na.rm = T),
                     intersection_references = sum(intersection_count, na.rm = T)
    ) %>%
    tidyr::pivot_longer(cols = -c("Year"),
                        names_to = "Type", values_to = "Count"),
  total_counts %>% 
    dplyr::filter(Year >= 2011) %>%
    dplyr::group_by(Year) %>%
    dplyr::summarize(climate_references = mean(climate_count, na.rm = T),
                     health_references = mean(health_count, na.rm = T),
                     intersection_references = mean(intersection_count, na.rm = T)
    ) %>%
    tidyr::pivot_longer(cols = -c("Year"),
                        names_to = "Type", values_to = "Avg")) %>%
  dplyr::mutate(Key = factor(dplyr::case_when(Type == "climate_references" ~ "Climate",
                                              Type == "intersection_references" ~ "Intersection",
                                              Type == "health_references" ~ "Health"), 
                             levels = c("Intersection", "Climate", "Health")),
                Year = lubridate::ymd(Year, truncated = 2L))


reference_df <- dplyr::left_join(
  total_counts %>% 
    dplyr::filter(Year >= 2011) %>%
    dplyr::group_by(Sector, Year) %>%
    dplyr::summarize(climate_references = sum(climate_count, na.rm = T),
                     health_references = sum(health_count, na.rm = T),
                     intersection_references = sum(intersection_count, na.rm = T)
    ) %>%
    tidyr::pivot_longer(cols = -c("Sector", "Year"),
                        names_to = "Type", values_to = "Count"),
  total_counts %>% 
    dplyr::filter(Year >= 2011) %>%
    dplyr::group_by(Sector, Year) %>%
    dplyr::summarize(climate_references = mean(climate_count, na.rm = T),
                     health_references = mean(health_count, na.rm = T),
                     intersection_references = mean(intersection_count, na.rm = T)
    ) %>%
    tidyr::pivot_longer(cols = -c("Sector", "Year"),
                        names_to = "Type", values_to = "Avg")) %>%
  dplyr::mutate(Key = factor(dplyr::case_when(Type == "climate_references" ~ "Climate",
                                              Type == "intersection_references" ~ "Intersection",
                                              Type == "health_references" ~ "Health"), 
                             levels = c("Intersection", "Climate", "Health")),
                Year = lubridate::ymd(Year, truncated = 2L))

# composite df
agg_plot_df <- total_texts %>% dplyr::filter(Year >= 2011)  %>%
  tidyr::pivot_longer(cols = -c("Sector", "Year", "total_texts"),
                      names_to = "text", values_to = "value") %>%
  dplyr::group_by(Year, text) %>%
  dplyr::summarise(total_texts = sum(total_texts, na.rm = T),
                   value = sum(value, na.rm = T)) %>%
  dplyr::mutate(value = tidyr::replace_na(value, 0),
                Prop = value/total_texts,
                Key = factor(dplyr::case_when(text == "climate_texts" ~ "Climate",
                                              text == "intersection_texts" ~ "Intersection",
                                              text == "health_texts" ~ "Health"), 
                             levels = c("Intersection", "Climate", "Health")),
                Year = lubridate::ymd(Year, truncated = 2L))

# health sector df
plot_df <- total_texts %>% dplyr::filter(Year >= 2011)  %>%
  tidyr::pivot_longer(cols = -c("Sector", "Year", "total_texts"),
                      names_to = "text", values_to = "value") %>%
  dplyr::mutate(value = tidyr::replace_na(value, 0),
                Prop = value/total_texts,
                Key = factor(dplyr::case_when(text == "climate_texts" ~ "Climate",
                                              text == "intersection_texts" ~ "Intersection",
                                              text == "health_texts" ~ "Health"), 
                             levels = c("Intersection", "Climate", "Health")),
                Year = lubridate::ymd(Year, truncated = 2L))




###########################################################
###########################################################

# Summary of data
tibble::tibble(
count = length(total_counts$Participant),
unique = unique(total_counts$Participant) %>% length(),
total_health = total_counts %>% dplyr::filter(!is.na(health_count)) %>% dplyr::filter(health_count != 0) %>% nrow(),
total_climate = total_counts %>% dplyr::filter(!is.na(climate_count)) %>% dplyr::filter(climate_count != 0) %>% nrow(),
total_intersection = total_counts %>% dplyr::filter(!is.na(intersection_count)) %>% dplyr::filter(intersection_count != 0) %>% nrow(),
) %>%
  dplyr::mutate(prop_health = round(total_health/count,2),
                prop_climate = round(total_climate/count,2),
                prop_intersection = round(total_intersection/count,2)) %>%
  knitr::kable(col.names = c("Companies (N)", "Companies (Unique)", 
                             "Health, (N)" , "Climate, (N)", "Intersection, (N)", 
                             "Health, %" , "Climate, %", "Intersection, %"))

# 1. Composite 

## a. Main text - Proportion of companies, %
agg_plot_df %>% 
  ggplot(aes(x = Year, y = Prop, color = Key)) +
  geom_path(aes(linetype = Key)) +
  scale_linetype_manual(values = c("solid", "longdash", "twodash")) +
  ggplot2::annotate("text", x = as.Date("2013-05-31"), y = 0.85, label = "Health", color = "#619cff") +
  ggplot2::annotate("text", x = as.Date("2013-05-31"), y = 0.48, label = "Climate Change", color = "darkgreen") +
  ggplot2::annotate("text", x = as.Date("2012-12-31"), y = 0.1, label = "Intersection", color = "red") +
  scale_y_continuous(labels = scales::percent_format()) +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(y = "Proportion of companies, %") 

## b. Appendix - Total number of references
agg_reference_df %>%
  ggplot(aes(x = Year, y = Count, color = Key)) +
  geom_line(aes(linetype = Key))  +
  scale_linetype_manual(values = c("solid", "longdash", "twodash")) +
  ggplot2::annotate("text", x = as.Date("2011-05-31"), y = 31500, label = "Health", color = "#619cff") +
  ggplot2::annotate("text", x = as.Date("2013-05-31"), y = 25000, label = "Climate Change", color = "darkgreen") +
  ggplot2::annotate("text", x = as.Date("2016-12-31"), y = 4000, label = "Intersection", color = "red") +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(y = "Total number of references") 

## c. Appendix - Total number of references (Intersection)
agg_reference_df %>% 
  dplyr::filter(Key == "Intersection") %>%
  ggplot(aes(x = Year, y = Count, color = Key)) +
  geom_line() +
  ggplot2::annotate("text", x = as.Date("2013-12-31"), y = 1500, label = "Intersection", color = "red") +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(y = "Total number of references") 

## d. Appendix - Average number of references
agg_reference_df %>%
  ggplot(aes(x = Year, y = Avg, color = Key)) +
  geom_line(aes(linetype = Key)) +
  scale_linetype_manual(values = c("solid", "longdash", "twodash")) +
  ggplot2::annotate("text", x = as.Date("2011-05-31"), y = 29, label = "Health", color = "#619cff") +
  ggplot2::annotate("text", x = as.Date("2014-01-01"), y = 17, label = "Climate Change", color = "darkgreen") +
  ggplot2::annotate("text", x = as.Date("2016-12-31"), y = 3, label = "Intersection", color = "red") +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(y = "Average number of references") 

## e. Appendix - Total number of references by WHO region
total_counts %>% 
  dplyr::filter(Year >= 2011) %>%
  dplyr::group_by(Year, who_region) %>%
  dplyr::summarize(climate_references = sum(climate_count, na.rm = T),
                   health_references = sum(health_count, na.rm = T),
                   intersection_references = sum(intersection_count, na.rm = T)
  ) %>%
  tidyr::pivot_longer(cols = -c("Year", "who_region"),
                      names_to = "Type", values_to = "Count") %>%
  dplyr::mutate(Key = factor(dplyr::case_when(Type == "climate_references" ~ "Climate",
                                              Type == "intersection_references" ~ "Intersection",
                                              Type == "health_references" ~ "Health"), 
                             levels = c("Intersection", "Climate", "Health")),
                Year = lubridate::ymd(Year, truncated = 2L)) %>%
  dplyr::filter(Key == "Intersection") %>%
  ggplot(aes(x = Year, y = Count, color = who_region)) +
  geom_path() +
  theme_minimal() +
  labs(y = "Total number of references",
       color = "WHO Region") 


## f. Appendix - Number of references 2020 per sector
total_counts %>% 
  dplyr::filter(Year == 2020) %>%
  dplyr::group_by(Sector, Year) %>%
  dplyr::summarize(climate_references = sum(climate_count, na.rm = T),
                   health_references = sum(health_count, na.rm = T),
                   intersection_references = sum(intersection_count, na.rm = T)
  ) %>%
  dplyr::select(Sector, health_references, climate_references, intersection_references) %>%
  knitr::kable(col.names = c("Sector", "Health", "Climate", "Intersection"))

## g. Appendix - Proportion of references 2020 per sector
total_counts %>% 
  dplyr::filter(Year == 2020) %>%
  dplyr::group_by(Sector, Year) %>%
  dplyr::summarize(climate_references = mean(climate_count, na.rm = T),
                   health_references = mean(health_count, na.rm = T),
                   intersection_references = mean(intersection_count, na.rm = T)
  ) %>%
  dplyr::mutate_if(is.numeric,round,1) %>%
  dplyr::select(Sector, health_references, climate_references, intersection_references) %>%
  knitr::kable(col.names = c("Sector", "Health, %", "Climate, %", "Intersection, %"))


## h. Appendix - Proportion of companies 2020 per sector
plot_df %>%
  dplyr::filter(Year >= "2020-01-01") %>% 
  ggplot(., aes(x = Sector, y = Prop, fill = Key)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  theme(legend.position = "bottom") +
  labs(fill = "",
       y = "Proportion of companies, %",
       x = "\nSector")

## i. Appendix - Total number of regerences by SIDS, Tier 1 and Tier 2
total_counts %>% 
  dplyr::filter(Year >= 2011) %>%
  dplyr::group_by(Year, tier_region) %>%
  dplyr::summarize(climate_references = sum(climate_count, na.rm = T),
                   health_references = sum(health_count, na.rm = T),
                   intersection_references = sum(intersection_count, na.rm = T)
  ) %>%
  tidyr::pivot_longer(cols = -c("Year", "tier_region"),
                      names_to = "Type", values_to = "Count") %>%
  dplyr::mutate(Key = factor(dplyr::case_when(Type == "climate_references" ~ "Climate",
                                              Type == "intersection_references" ~ "Intersection",
                                              Type == "health_references" ~ "Health"), 
                             levels = c("Intersection", "Climate", "Health")),
                Year = lubridate::ymd(Year, truncated = 2L)) %>%
  dplyr::filter(Key == "Intersection" & !is.na(tier_region)) %>%
  ggplot(aes(x = Year, y = Count, color = tier_region)) +
  geom_path() +
  theme_minimal() +
  labs(y = "Total number of references",
       color = "") 

###########################################################
###########################################################

# 2. Health Care Sector 

## a. Main text - Proportion of companies, %
plot_df %>% 
  dplyr::filter(Sector == "Health Care Equipment & Ser...") %>%
  ggplot(aes(x = Year, y = Prop, color = Key)) +
  geom_line(aes(linetype = Key)) +
  scale_linetype_manual(values = c("solid", "longdash", "twodash")) +
  ggplot2::annotate("text", x = as.Date("2013-05-31"), y = 0.85, label = "Health", color = "#619cff") +
  ggplot2::annotate("text", x = as.Date("2013-05-31"), y = 0.48, label = "Climate Change", color = "darkgreen") +
  ggplot2::annotate("text", x = as.Date("2012-12-31"), y = 0.1, label = "Intersection", color = "red") +
  scale_y_continuous(labels = scales::percent_format()) +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(y = "Proportion of companies, %") 

## b. Appendix - Total number of references
reference_df %>% 
  dplyr::filter(Sector == "Health Care Equipment & Ser...") %>%
  ggplot(aes(x = Year, y = Count, color = Key)) +
  geom_line(aes(linetype = Key))  +
  scale_linetype_manual(values = c("solid", "longdash", "twodash")) +
  ggplot2::annotate("text", x = as.Date("2011-05-31"), y = 500, label = "Health", color = "#619cff") +
  ggplot2::annotate("text", x = as.Date("2013-05-31"), y = 250, label = "Climate Change", color = "darkgreen") +
  ggplot2::annotate("text", x = as.Date("2016-12-31"), y = 75, label = "Intersection", color = "red") +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(y = "Total number of references") 

## c. Appendix - Total number of references (Intersection)
reference_df %>% 
  dplyr::filter(Sector == "Health Care Equipment & Ser..." & Key == "Intersection") %>%
  ggplot(aes(x = Year, y = Count, color = Key)) +
  geom_line() +
  ggplot2::annotate("text", x = as.Date("2013-12-31"), y = 18, label = "Intersection", color = "red") +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(y = "Total number of references") 

## d. Appendix - Average number of references
reference_df %>% 
  dplyr::filter(Sector == "Health Care Equipment & Ser...") %>%
  ggplot(aes(x = Year, y = Avg, color = Key)) +
  geom_line(aes(linetype = Key)) +
  scale_linetype_manual(values = c("solid", "longdash", "twodash")) +
  ggplot2::annotate("text", x = as.Date("2011-05-31"), y = 32, label = "Health", color = "#619cff") +
  ggplot2::annotate("text", x = as.Date("2012-05-31"), y = 8, label = "Climate Change", color = "darkgreen") +
  ggplot2::annotate("text", x = as.Date("2016-12-31"), y = 3, label = "Intersection", color = "red") +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(y = "Average number of references") 

## e. Appendix - Total number of references by WHO region
total_counts %>% 
  dplyr::filter(Year >= 2011 & Sector == "Health Care Equipment & Ser...") %>%
  dplyr::group_by(Sector, Year, who_region) %>%
  dplyr::summarize(climate_references = sum(climate_count, na.rm = T),
                   health_references = sum(health_count, na.rm = T),
                   intersection_references = sum(intersection_count, na.rm = T)
  ) %>%
  tidyr::pivot_longer(cols = -c("Sector", "Year", "who_region"),
                      names_to = "Type", values_to = "Count") %>%
  dplyr::mutate(Key = factor(dplyr::case_when(Type == "climate_references" ~ "Climate",
                                              Type == "intersection_references" ~ "Intersection",
                                              Type == "health_references" ~ "Health"), 
                             levels = c("Intersection", "Climate", "Health")),
                Year = lubridate::ymd(Year, truncated = 2L)) %>%
  dplyr::filter(Key == "Intersection") %>%
  ggplot(aes(x = Year, y = Count, color = who_region)) +
  geom_path() +
  theme_minimal() +
  labs(y = "Total number of references",
       color = "WHO Region") 


## f. Appendix - Number of references 2020 per sector
total_counts %>% 
  dplyr::filter(Year == 2020) %>%
  dplyr::group_by(Sector, Year) %>%
  dplyr::summarize(climate_references = sum(climate_count, na.rm = T),
                   health_references = sum(health_count, na.rm = T),
                   intersection_references = sum(intersection_count, na.rm = T)
  ) %>%
  dplyr::select(Sector, health_references, climate_references, intersection_references) %>%
  knitr::kable(col.names = c("Sector", "Health", "Climate", "Intersection"))

## g. Appendix - Proportion of references 2020 per sector
total_counts %>% 
  dplyr::filter(Year == 2020) %>%
  dplyr::group_by(Sector, Year) %>%
  dplyr::summarize(climate_references = mean(climate_count, na.rm = T),
                   health_references = mean(health_count, na.rm = T),
                   intersection_references = mean(intersection_count, na.rm = T)
  ) %>%
  dplyr::mutate_if(is.numeric,round,1) %>%
  dplyr::select(Sector, health_references, climate_references, intersection_references) %>%
  knitr::kable(col.names = c("Sector", "Health, %", "Climate, %", "Intersection, %"))


## h. Appendix - Proportion of companies 2020 per sector
plot_df %>%
  dplyr::filter(Year >= "2020-01-01") %>% 
  ggplot(., aes(x = Sector, y = Prop, fill = Key)) +
  geom_bar(stat = "identity", position = "dodge") +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
  theme(legend.position = "bottom") +
  labs(fill = "",
       y = "Proportion of companies, %",
       x = "\nSector")
  
## i. Appendix - Total number of regerences by SIDS, Tier 1 and Tier 2
total_counts %>% 
  dplyr::filter(Year >= 2011 & Sector == "Health Care Equipment & Ser...") %>%
  dplyr::group_by(Sector, Year, tier_region) %>%
  dplyr::summarize(climate_references = sum(climate_count, na.rm = T),
                   health_references = sum(health_count, na.rm = T),
                   intersection_references = sum(intersection_count, na.rm = T)
  ) %>%
  tidyr::pivot_longer(cols = -c("Sector", "Year", "tier_region"),
                      names_to = "Type", values_to = "Count") %>%
  dplyr::mutate(Key = factor(dplyr::case_when(Type == "climate_references" ~ "Climate",
                                              Type == "intersection_references" ~ "Intersection",
                                              Type == "health_references" ~ "Health"), 
                             levels = c("Intersection", "Climate", "Health")),
                Year = lubridate::ymd(Year, truncated = 2L)) %>%
  dplyr::filter(Key == "Intersection" & !is.na(tier_region)) %>%
  ggplot(aes(x = Year, y = Count, color = tier_region)) +
  geom_path() +
  theme_minimal() +
  labs(y = "Total number of references",
       color = "") 
