import requests
import re
import PyPDF2
import shutil
import os
import pandas as pd

# set focus year and language here
focus_year = "2019"
focus_language = "en"

language_ref = { 'en' : { 'name' : 'English', 'min_coocurrence' : 10},
                 'de' : { 'name' : 'German', 'min_coocurrence' : 2},
                 'es' : { 'name' : 'Spanish', 'min_coocurrence' : 2},
                 'fr' : { 'name' : 'French', 'min_coocurrence' : 2},
                 'pt' : { 'name' : 'Portuguese', 'min_coocurrence' : 2},
               }

# set folder for PDFs here
pdfs_folder = "/Volumes/M/pdfs/"

# set folder for text here
txts_folder = "../data/cops/txts/" + focus_year + "/"

# set verbosity of code
verbosity = 0

# --------------------------------------------
# Selecting COP reports that match required criteria
# (up to focus_year, written in focus_language)

reports_index_csv_filename = "../data/cops/reports_index_" + focus_year + ".csv"

df_pdfs = pd.read_csv(reports_index_csv_filename, sep='\t', encoding='utf-8', index_col=0, dtype={'year': object})
pdfs = df_pdfs.to_dict(orient='index')

selected_sectors = {}
selected_countries = {}
selected_years = {}
selected_countries_years = {}

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

# --------------------------------------------
# Extracting text from the PDF file of each report

filenameregex = re.compile(r'(?<=/)[^$/]+(?=$)')

num_txt = 0
num_load_error = 0
num_exists = 0

try:
    os.stat(txts_folder)
except:
    os.mkdir(txts_folder)

for pdf in selected_pdfs.keys():
    filename = pdfs_folder + filenameregex.search(pdf)[0]
    filenametxt = txts_folder + filenameregex.search(pdf)[0] + ".txt"
    if not os.path.isfile(filenametxt):
        print("Loading %s" % (filename))
        try:
            pdfFileObj = open(filename, 'rb')
            txtFileObj = open(filenametxt, 'w')
            pdfReader = PyPDF2.PdfFileReader(pdfFileObj)
            num_pages = pdfReader.numPages
        except:
            print("Couldn't load %s" % (filename))
            num_load_error += 1
            continue

        print("Extracting text from %s" % (filename))
        for num_page in range(0,num_pages):
            try:
                pageObj = pdfReader.getPage(num_page)
                txtFileObj.write(pageObj.extractText())
            except:
                print("Couldn't extract txt %s, page %d" % (filename, num_page))
                continue
        pdfFileObj.close()
        txtFileObj.close()
        num_txt += 1

    else:
        print("Skipping %s, TXT already available in folder" % (filename))
        num_exists += 1

num_extract = num_txt - num_load_error
print("TXTs Extracted: %d, TXTs already existing: %d, Load Error: %d" % (num_extract, num_exists, num_load_error))
