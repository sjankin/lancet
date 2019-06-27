import re
import shutil
import os
import pandas as pd

# set focus year and language here
focus_year = "2018"
focus_language = "en"

language_ref = { 'en' : { 'name' : 'English', 'min_coocurrence' : 10},
                 'de' : { 'name' : 'German', 'min_coocurrence' : 2},
                 'es' : { 'name' : 'Spanish', 'min_coocurrence' : 2},
                 'fr' : { 'name' : 'French', 'min_coocurrence' : 2},
                 'pt' : { 'name' : 'Portuguese', 'min_coocurrence' : 2},
               }

# set folder for where text files are stored
txts_folder = "/Users/yuantinglee/Documents/SM_Projects/lancet/data/cops/txts/"

# --------------------------------------------
# Selecting COP reports that match required criteria
# (up to focus_year, written in focus_language)
# reports_index_csv_filename = "../data/cops/reports_index_" + focus_year + ".csv"
reports_index_csv_filename = "../data/cops/reports_index.csv"


df_pdfs = pd.read_csv(reports_index_csv_filename, sep='\t', encoding='utf-8', index_col=0, dtype={'year': object})
pdfs = df_pdfs.to_dict(orient='index')

selected_sectors = {}
selected_countries = {}
selected_years = {}
selected_countries_years = {}
selected_sectors_years = {}

selected_pdfs = {}

for pdf in pdfs.keys():
    language = pdfs[pdf]["language"]
    year = pdfs[pdf]["year"]
    country = pdfs[pdf]["country"]
    sector = pdfs[pdf]["sector"]

    if language == language_ref[focus_language]['name'] and int(year) <= int(focus_year):
        selected_pdfs[pdf] = pdfs[pdf]

        selected_sectors[sector] = selected_sectors.get(sector,0) + 1
        selected_countries[country] = selected_countries.get(country,0) + 1
        selected_years[year] = selected_years.get(year,0) + 1
        if country in selected_countries_years.keys():
            selected_countries_years[country][year] = selected_countries_years[country].get(year,0) + 1
        else:
            selected_countries_years[country] = {year : 1}

        if sector in selected_sectors_years.keys():
            selected_sectors_years[sector][year] = selected_sectors_years[sector].get(year,0) + 1
        else:
            selected_sectors_years[sector] = {year : 1}

# rename files so that doc var ids are in the file name
# country, year, sector
# need to join spaces in sector by a unique separator

# define regex
FILEMATCH = re.compile('/original/(.*)')

os.chdir(txts_folder)

for pdf in selected_pdfs.keys():
    filename = FILEMATCH.search(pdf).group(1) + ".txt"
    if os.path.isfile(os.path.join(txts_folder, filename)):
        sector = selected_pdfs[pdf]["sector"].replace(" ", "")
        newname = selected_pdfs[pdf]["country"] + "-SEP-" + selected_pdfs[pdf]["year"] + "-SEP-" + sector + "-SEP-" + filename
        try:
            shutil.move(filename, newname)
        except OSError:
            print("Error renaming: %s" % filename)
        print(".", end='')
