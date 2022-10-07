import os
import pandas as pd
import numpy as np
import re, string, timeit
import nltk
import sys
from nltk.corpus import stopwords
from multiprocessing import Pool
from tqdm import tqdm
import time
import re
from nltk import NLTKWordTokenizer
from torch.utils.data import Dataset, DataLoader
import json

tokenizer = nltk.data.load(os.getcwd()+'/punkt/english.pickle')
with open("stopwords.txt", "r") as fp:
    stopwords = json.load(fp)
    
compoundlist = ["air pollution", "mental disorder", "mental disorders", "climate change", "changing climate", "climate emergency", 
          "climate crisis", "climate decay", "global warming", "green house", "extreme weather", "global environmental change", 
          "climate variability",  "low carbon", "renewable energy", "carbon emission", "carbon emissions", "carbon dioxide", 
          "co2 emission", "co2 emissions", "climate pollutant", "climate pollutants", "carbon neutral", "carbon neutrality", 
          "climate neutrality", "climate action", "net zero", "covid 19", "corona virus", "sars cov 2"]

health_dict =["malaria", "diarrhoea", "infection", "disease", "diseases", "sars", "measles", "pneumonia", "epidemic", 
                "epidemics", "pandemic", "pandemics", "epidemiology", "healthcare", "health", "mortality", "morbidity", 
                "nutrition", "illness", "illnesses", "ncd", "ncds", "air_pollution", "nutrition", "malnutrition", 
                "malnourishment", "mental_disorder", "mental_disorders", "stunting"]

_treebank_word_tokenizer = NLTKWordTokenizer()
def word_tokenize(text):
    sentences = tokenizer.tokenize(text)
    return [
        token for sent in sentences for token in _treebank_word_tokenizer.tokenize(sent)
    ]

def text_process(text):
    #quanteda::tokens(df[start:min(c(start+chunk-1, length(df))), ], what = "word",
     #                     remove_punct = TRUE,
      #                    remove_symbols = TRUE,
       #                   remove_numbers = TRUE,
        #                  remove_twitter = TRUE,
         #                 remove_url = TRUE,
          #                split_hyphen = FALSE,
           #               verbose = TRUE)
    # remove url
    text = re.sub(r'https?://\S+', '', text, flags=re.MULTILINE)
    text = re.sub(r'www.\S+', '', text, flags=re.MULTILINE)
    # remove numbers
    text = re.sub(r'[2-8, 0]+', ' ', text)

    # remove punct
    remove = string.punctuation
    remove = remove.replace("-", "")
    table = str.maketrans("","", remove)
    text = text.lower().translate(table)
    text = word_tokenize(text)
    text = [word for word in text if not word in stopwords]
    return text

class KWIC():
    def __init__(self, search_list, corpus, id_, compound_list = None,):
        self.search_list = search_list
        self.compound_list = compound_list
        self.corpus = corpus
        self.id = id_

    def list_join(self,):
        expression_list = []
        # prepare the text for all analysis
        tokensjoin = ' '.join(self.corpus)
        for expression in self.compound_list:
            if expression in tokensjoin:
                expression_list.append('_'.join(expression.split()))
                tokensjoin =  re.sub(expression, ' ' +'_'.join(expression.split()) + ' ', tokensjoin, flags=re.IGNORECASE)
        self.tokensjoin = tokensjoin.split()
        #self.expression_list = expression_list
        #return expression_list

    def indices(self, element):
        # for kwic indexing key words
        # element: key word to search
        result = []
        offset = -1
        while True:
            try:
                offset = self.tokensjoin.index(element, offset+1)
            except ValueError:
                return result
            result.append(offset)
        return  result
    
    def concordance(self, window, key_word):
        dct = {'key_word': [],'left':[], 'right':[],'left_check':[], 'right_check':[], 'token_index': [], 'Id': []} 
        self.index = self.indices(key_word)
        for token_index in self.index:
            dct['key_word'].append(key_word)
            dct['token_index'].append(token_index)
            dct['left'].append(" ".join(self.tokensjoin[max(0, token_index-window-1):(token_index-1)]))
            dct['right'].append(" ".join(self.tokensjoin[max(0, token_index+1):min((token_index+window+1), len(self.tokensjoin))]))
            dct['Id'].append(int(self.id))
            dct['left_check'].append(" ".join(self.tokensjoin[max(0, token_index-2-1):(token_index-1)]))
            dct['right_check'].append(" ".join(self.tokensjoin[max(0, token_index+1):min((token_index+2+1), len(self.tokensjoin))]))   
        return pd.DataFrame(dct)
    
    def kwic_search(self, window):
        if self.compound_list:
            self.list_join()
        else:
            self.tokensjoin = self.corpus
        keywords = self.search_list
        dct = pd.DataFrame({'key_word': [],'left':[], 'right':[],'left_check':[], 'right_check':[],  'token_index': [], 'Id': []}) 
        if len(keywords) > 0: 
            for k in keywords:
                df = self.concordance(window = window, key_word = k)
                dct = dct.append(df)
        else:
            print('no keywords foound!') 
        return dct, self.tokensjoin
        
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
