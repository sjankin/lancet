import PyPDF2
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

# set folder for PDF download here
pdfs_folder = "/Volumes/M/pdfs/"

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
# Downloading PDF file for each COP report that matches required criteria

filenameregex = re.compile(r'(?<=/)[^$/]+(?=$)')

num_saved = 0
num_error = 0
num_exists = 0

try:
    os.stat(pdfs_folder)
except:
    os.mkdir(pdfs_folder)

for pdf in selected_pdfs.keys():
    filename = pdfs_folder + filenameregex.search(pdf)[0]

    if not os.path.isfile(filename):
        if verbosity > 0:
            print("Saving %s" % (filename))
        file = requests.get(gc_base_url + pdf, stream=True)
        try:
            with open(filename, 'wb') as out_file:
                shutil.copyfileobj(file.raw, out_file)
            del file
            num_saved += 1
        except:
            print("Error: Could not save %s" % (filename))
            num_error += 1
            continue
    else:
        if verbosity > 0:
            print("Skipping %s, PDF already available in folder" % (filename))
            num_exists += 1

print("PDFs Saved: %d, PDFs already existing: %d, Error: %d" % (num_saved, num_exists, num_error))
