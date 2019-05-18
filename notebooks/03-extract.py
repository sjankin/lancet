# Extracting text from the PDF file of each report
import PyPDF2
import shutil
import os
import pandas as pd

# set folder for text here
txts_folder = "../data/cops/txts/"

# set verbosity of code
verbosity = 0

# --------------------------------------------
reports_index_csv_filename = "../data/cops/reports_index_" + focus_year + ".csv"

df_pdfs = pd.read_csv(reports_index_csv_filename, sep='\t', encoding='utf-8', index_col=0, dtype={'year': object})
pdfs = df_pdfs.to_dict(orient='index')

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
