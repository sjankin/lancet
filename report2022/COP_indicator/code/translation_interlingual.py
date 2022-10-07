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
lang_1 = 'pt'
lang_2 = 'gl'
model_name_1 = 'Helsinki-NLP/opus-mt-' + lang_1 + '-' +lang_2
model_name_2 = 'Helsinki-NLP/opus-mt-' + lang_2 + '-en'
tokenizer_1 = AutoTokenizer.from_pretrained(model_name_1, cache_dir=os.getcwd()+'/cache')
model_1 = AutoModelForSeq2SeqLM.from_pretrained(model_name_1, cache_dir=os.getcwd()+'/cache')

tokenizer_2 = AutoTokenizer.from_pretrained(model_name_2, cache_dir=os.getcwd()+'/cache')
model_2 = AutoModelForSeq2SeqLM.from_pretrained(model_name_2, cache_dir=os.getcwd()+'/cache')

df_name = "global_" + lang_1+'_sent.csv'

df = pd.read_csv(folder + df_name)
print((lang_1, lang_2), df_name, df.shape, (model_name_1, model_name_2))


test = False 
if test == True:
    df = df.iloc[:150]
    
# !!!!!!! important 
device = 'cuda:3'
batch = 80
print(device)
model_1= torch.nn.DataParallel(model_1)
model_1.to(device)
model_1.eval()

model_2= torch.nn.DataParallel(model_2)
model_2.to(device)
model_2.eval()

params = {'batch_size': batch,
          'shuffle': False,
          'num_workers': 0}

#prepare dataset
df_ = Datapre(df, tokenizer_1, max_len = 300)
loader_ = DataLoader(df_, **params)

listoftransids = []
listoftext = []
with torch.no_grad():
    for encoded, Ids in tqdm(loader_):
        listoftransids.extend(Ids.numpy())
        translated = model_1.module.generate(**encoded).to(device)
        translated_texts = tokenizer_1.batch_decode(translated, skip_special_tokens=True)
        listoftext.extend(translated_texts)
        if len(listoftransids) % 10000 == 0:
            print('Partly finished ',len(listoftransids))
            pd.DataFrame({'Id': listoftransids, 'text':listoftext}).to_csv('resuslt_inter_' + lang_1 + '_tmp.csv', index= False)

print('Intermediate Translation finished!!!')
df_inter = pd.DataFrame({'Id': listoftransids, 'text':listoftext})

df_inter_ = Datapre(df_inter, tokenizer_2, max_len = 300)
loader_2 = DataLoader(df_inter_, **params)

listoftransids = []
listoftext = []
with torch.no_grad():
    for encoded, Ids in tqdm(loader_2):
        listoftransids.extend(Ids.numpy())
        translated = model_2.module.generate(**encoded).to(device)
        translated_texts = tokenizer_2.batch_decode(translated, skip_special_tokens=True)
        listoftext.extend(translated_texts)
        if len(listoftransids) % 10000 == 0:
            print('Partly finished ',len(listoftransids))
            pd.DataFrame({'Id': listoftransids, 'text':listoftext}).to_csv('resuslt_' + lang_2 + '_tmp.csv', index= False)
            
pd.DataFrame({'Id': listoftransids, 'text':listoftext}).to_csv(folder + 'resuslt_' + lang_1 + '.csv', index= False)
