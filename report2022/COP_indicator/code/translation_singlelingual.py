import os
import nltk
import torch
import pandas as pd
import numpy as np
from torch.utils.data import Dataset, DataLoader
from tqdm import tqdm
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
from nltk import tokenize

folder = "globalmulti/"
os.environ['TORCH_HOME'] = os.getcwd()+'/cache'
lang = 'mul'
model_name = 'Helsinki-NLP/opus-mt-' + lang + '-en'
tokenizer = AutoTokenizer.from_pretrained(model_name, cache_dir=os.getcwd()+'/cache')
model = AutoModelForSeq2SeqLM.from_pretrained(model_name, cache_dir=os.getcwd()+'/cache')

df_name = "global_"+lang+'_sent.csv'

df = pd.read_csv(folder + df_name)
print(lang, df_name, df.shape, model_name)

test = False 
if test == True:
    df = df.iloc[:150]

device = 'cuda:2'
batch = 80
print(device)
model= torch.nn.DataParallel(model)
model.to(device)
model.eval()

params = {'batch_size': batch,
          'shuffle': False,
          'num_workers': 0}

#prepare dataset
df_ = Datapre(df, tokenizer, max_len = 300)
loader_ = DataLoader(df_, **params)

listoftransids = []
listoftext = []
with torch.no_grad():
    for encoded, Ids in tqdm(loader_):
        listoftransids.extend(Ids.numpy())
        translated = model.module.generate(**encoded).to(device)
        translated_texts = tokenizer.batch_decode(translated, skip_special_tokens=True)
        listoftext.extend(translated_texts)
        if len(listoftransids) % 10000 == 0:
            print('finished ',len(listoftransids))
            pd.DataFrame({'Id': listoftransids, 'text':listoftext}).to_csv(folder + 'resuslt_' + lang + '_tmp.csv', index= False)

print('Translation finished!!!')
pd.DataFrame({'Id': listoftransids, 'text':listoftext}).to_csv(folder + 'resuslt_' + lang + '.csv', index= False)
