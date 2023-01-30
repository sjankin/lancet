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
  Sys.sleep(sample(1:5, 1))
  read_html(x) %>% html_nodes(.,  xpath = "/html/body/main/section/div/section/dl/dd[4]/ul/li/a") %>% 
    rvest::html_attr("href") %>% stringr::str_replace_all(" ", "%20") %>% .[1] %>%
    paste0("https:", .)
}

download_pdfs <- function(scrape_year, data_to_scrape) {
  dir.create(paste0(folder,scrape_year))
  csr <- data_to_scrape %>% dplyr::filter(Year == scrape_year)
  for (i in 1:length(csr$Pdf_url)) {
    if (!file.exists(paste0(folder, "/", scrape_year, "/", csr$file_name[i]))) {
      try(download.file(csr$Pdf_url[i], destfile = paste0(folder, "/",scrape_year, "/", csr$file_name[i]))) # , method = "libcurl" might be needed on windows machine
      Sys.sleep(runif(1, 0, 1))
    }
  }}

pdf_to_txt <- function(scrape_year, data_to_scrape) {
  dir.create(paste0(folder,scrape_year))
  csr <- data_to_scrape %>% dplyr::filter(Year == scrape_year) %>% dplyr::mutate(file_name_txt = stringr::str_replace_all(file_name, "pdf", "txt"))
  for (i in 1:length(csr$Pdf_url)) {
    if (!file.exists(paste0(folder, "/", scrape_year, "/", csr$file_name_txt[i]))) {
    try(text_file <- pdftools::pdf_text(pdf = paste0("pdf/", scrape_year, "/", csr$file_name[i])) %>%
        paste(sep = " ") %>%
        stringr::str_replace_all(fixed("\n"), " ") %>%
        stringr::str_replace_all(fixed("\r"), " ") %>%
        stringr::str_replace_all(fixed("\t"), " ") %>%
        stringr::str_replace_all(fixed("\""), " ") %>%
        paste(sep = " ", collapse = " ") %>%
        stringr::str_squish() %>%
        stringr::str_replace_all("- ", ""))
      try(writeLines(text_file, paste0(folder, "/", scrape_year, "/", csr$file_name_txt[i])))
      rm(text_file)
    }
  }}

create_table_from_txt <- function(scrape_year, folder = "../txt/") {
  readtext::readtext(paste0(folder, scrape_year ,"/*.txt"), 
                     docvarsfrom = "filenames", 
                     docvarnames = c("Year", "Code", "Id"),
                     dvsep = "_")
}


