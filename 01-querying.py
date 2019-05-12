# Gathering information about COP reports available from the UN Global Compact website
from query_utils import *

import requests
import re
from bs4 import BeautifulSoup

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
