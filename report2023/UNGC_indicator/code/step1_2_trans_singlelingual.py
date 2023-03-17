import os
import nltk
import torch
import pandas as pd
import numpy as np
from torch.utils.data import Dataset, DataLoader
from tqdm import tqdm
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
from nltk import tokenize

folder = "nonEnglish_2023/"
os.environ['TORCH_HOME'] = os.getcwd()+'/cache'
lang = 'sv'
model_name = 'Helsinki-NLP/opus-mt-' + lang + '-en'
tokenizer = AutoTokenizer.from_pretrained(model_name, cache_dir=os.getcwd()+'/cache')
model = AutoModelForSeq2SeqLM.from_pretrained(model_name, cache_dir=os.getcwd()+'/cache')

df_name = "global_" + lang+'_sent.csv'

df = pd.read_csv(folder + df_name)
#df = df.iloc[-int(0.3*len(df)):].reset_index()
#df.to_csv(folder + "30per_es_backup.csv")
print(lang, df_name, df.shape, model_name)

test = False 
if test == True:
    df = df.iloc[:100]

device = 'cuda:0'
batch = 80
print(device)
model= torch.nn.DataParallel(model)
model.to(device)
model.eval()

class Datapre(Dataset):
    def __init__(self, dataframe, tokenizer, max_len):
        self.tokenizer = tokenizer
        self.df = dataframe
        self.text = self.df.text
        self.max_len = max_len
        self.label = dataframe.Id.tolist()
        # check same length
        if (len(self.label) != len(self.text)):
            print('length does not match!')
    
    def __len__(self):
        return len(self.text)

    def __getitem__(self, index):
        text = str(self.text[index])
        text = " ".join(text.split())
        label = self.label[index]
        
        inputs = self.tokenizer.encode_plus(
            text,
            max_length=self.max_len,
            pad_to_max_length=True,
        )
        ids = inputs['input_ids']
        mask = inputs['attention_mask']
        return  {
            'input_ids': torch.tensor(ids, dtype=torch.long).to(device),
            'attention_mask': torch.tensor(mask, dtype=torch.long).to(device),
        }, label
    

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
