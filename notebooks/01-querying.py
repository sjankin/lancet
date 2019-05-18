# Gathering information about COP reports available from the UN Global Compact website
from query_utils import *

import requests
import re
from bs4 import BeautifulSoup
import pandas as pd

# set focus year here
focus_year = "2018"

# --------------------------------------------
gc_url = "https://www.unglobalcompact.org/participation/report/cop/create-and-submit/active?page=1&per_page=10"
gc_base_url = "https://www.unglobalcompact.org"

gc_home = requests.get(gc_url)

soup = BeautifulSoup(gc_home.content, 'lxml')

header = soup.h2.string

total_num_cops = re.search(r'(?<=: )[0-9]+', header)[0]
print("Total number of COPs available: %s" % total_num_cops)

full_gc_url = "https://www.unglobalcompact.org/participation/report/cop/create-and-submit/active?page=1&per_page=" + total_num_cops

print("Getting full list of reports ...")
gc_full_list = requests.get(full_gc_url)

gc_full_list_soup = BeautifulSoup(gc_full_list.content, 'lxml')

participants = gc_full_list_soup.tbody.find_all("tr")
pdfs = {}

num_pdfs = 0
num_nonpdfs = 0
num_noreport = 0
num_error = 0

langregex = re.compile(r'(?<=\()[^\)\(]+(?=\)$)')

print("Getting details of each report ...")
for participant in participants:
    cells = participant.find_all('td')
    sector = cells[1].get_text(strip=True)
    country = cells[2].get_text(strip=True)
    year = cells[3].get_text(strip=True)

    participant_entry_url = gc_base_url + cells[0].a.get('href')
    if year == focus_year:
        try:
            participant_profile = requests.get(participant_entry_url)
            participant_profile_soup = BeautifulSoup(participant_profile.content, 'lxml')

            (participant_sdgs_3, participant_sdgs_13) = check_sdgs_3_13(participant_profile_soup)

            main_body = participant_profile_soup.find("section", class_='main-content-body')
            list_items = main_body.find_all("li")
            found_report = False

            for li in list_items:
                if li.a:
                    link = li.a.get('href')
                    if "/ungc-production/attachments/" in link:
                        if ".pdf" in link:
                            num_pdfs += 1
                            language = langregex.search(li.get_text(strip=True))[0]
                            pdfs[link] = { "sector" : sector, "country" : country, "year" : year, "language" : language, "sdgs3" : participant_sdgs_3, "sdgs13" : participant_sdgs_13}
                            print(".", end='')
                        else:
                            num_nonpdfs += 1
                            found_report = True
            if not found_report:
                num_noreport += 1

        except requests.exceptions.SSLError:
            num_error += 1
            print(participant_entry_url)
            pass

        except ConnectionError:
            num_error += 1
            print(participant_entry_url)
            pass

print(" done.")
print("PDFs: %d, non-PDFs: %d, no-report: %d, error: %d" % (num_pdfs, num_nonpdfs, num_noreport, num_error))

reports_index_csv_filename = "../data/cops/reports_index_" + focus_year + ".csv"

df_pdfs = pd.DataFrame.from_dict(pdfs, orient='index')
df_pdfs.to_csv(reports_index_csv_filename, sep='\t', encoding='utf-8')
