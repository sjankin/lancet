import os
import nltk
import torch
import pandas as pd
import numpy as np
from torch.utils.data import Dataset, DataLoader
from tqdm import tqdm
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM

folder = "nonEnglish_2023/"
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
df_inter = pd.read_csv("resuslt_inter_pt_tmp.csv")
df = df.iloc[len(df_inter):].reset_index()
print((lang_1, lang_2), df_name, df.shape, (model_name_1, model_name_2))

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
    

test = False 
if test == True:
    df = df.iloc[:50]
    
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

listoftransids = df_inter.Id.tolist()
listoftext = df_inter.text.tolist() 
with torch.no_grad():
    for encoded, Ids in tqdm(loader_):
        listoftransids.extend(Ids.numpy())
        translated = model_1.module.generate(**encoded).to(device)
        translated_texts = tokenizer_1.batch_decode(translated, skip_special_tokens=True)
        listoftext.extend(translated_texts)
        if len(listoftransids) % 10000 == 0:
            print('Partly finished ',len(listoftransids))
            pd.DataFrame({'Id': listoftransids, 'text':listoftext}).to_csv(folder + 'resuslt_inter_' + lang_1 + '_tmp.csv', index= False)
pd.DataFrame({'Id': listoftransids, 'text':listoftext}).to_csv(folder + 'resuslt_inter_' + lang_1 + '.csv', index= False)            
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
            pd.DataFrame({'Id': listoftransids, 'text':listoftext}).to_csv(folder + 'resuslt_' + lang_2 + '_tmp.csv', index= False)
            
pd.DataFrame({'Id': listoftransids, 'text':listoftext}).to_csv(folder + 'resuslt_' + lang_1 + '.csv', index= False)
