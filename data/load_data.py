import os
import zipfile
import requests

# Veri setini indir
url = 'http://www.cs.cornell.edu/~cristian/data/cornell_movie_dialogs_corpus.zip'
r = requests.get(url, allow_redirects=True)
with open('cornell_movie_dialogs_corpus.zip', 'wb') as f:
    f.write(r.content)

# Zip dosyasını aç
with zipfile.ZipFile('cornell_movie_dialogs_corpus.zip', 'r') as zip_ref:
    zip_ref.extractall('cornell_movie_dialogs_corpus')

# Veri dosyasının yolu
dataset_path = os.path.join('cornell_movie_dialogs_corpus', 'cornell_movie_dialogs_corpus', 'movie_conversations.txt')
base_path = os.path.join('/home/enoca2/Desktop/OMUChatbot/data/cornell_movie_dialogs_corpus')
