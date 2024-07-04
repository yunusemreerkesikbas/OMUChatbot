from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pickle
import numpy as np
from keras.utils import pad_sequences
import re

# FastAPI uygulamasını oluştur
app = FastAPI()

# Pydantic modelini tanımla
class Question(BaseModel):
    text: str

# Verileri ve modelleri yükle
with open('/home/enoca2/Desktop/OMUChatbot/api/model/models_and_data.pkl', 'rb') as f:
    enc_model, dec_model, dense, MAX_LEN, vocab, inv_vocab = pickle.load(f)

# Stop words yükle
with open("/home/enoca2/Desktop/OMUChatbot/api/model/turkce-stop-words.txt", "r", encoding='utf-8') as file:
    turkish_stopwords = set(file.read().replace("\n", " ").split())

def veri_temizligi(text):
    metin = re.sub("[^a-zA-ZçÇğĞıİöÖşŞüÜ]", " ", text).lower()
    kelimeler = metin.split()
    kelimeler = [i for i in kelimeler if not i in turkish_stopwords]
    return kelimeler

def predict(prepro1):
    prepro1 = ' '.join(veri_temizligi(prepro1))
    prepro = [prepro1]

    txt = []
    for x in prepro:
        lst = []
        for y in x.split():
            try:
                lst.append(vocab[y])
            except:
                lst.append(vocab['<OUT>'])

        txt.append(lst)

    txt = pad_sequences(txt, MAX_LEN, padding='post', truncating="post")

    stat = enc_model.predict(txt)
    empty_target_seq = np.zeros((1, 1))
    empty_target_seq[0, 0] = vocab['<SOS>']

    stop_condition = False
    decoded_translation = ''

    while not stop_condition:
        dec_outputs, h, c = dec_model.predict([empty_target_seq] + stat)
        decoder_concat_input = dense(dec_outputs)

        sample_word_index = np.argmax(decoder_concat_input[0, -1, :])
        sample_word = inv_vocab[sample_word_index] + ' '

        if sample_word != '<EOS> ':
            decoded_translation += sample_word

        if sample_word == '<EOS>' or len(decoded_translation.split()) > MAX_LEN:
            stop_condition = True

        empty_target_seq = np.zeros((1, 1))
        empty_target_seq[0, 0] = sample_word_index
        stat = [h, c]

    return decoded_translation.title()

@app.post("/ask")
async def ask_question(question: Question):
    answer = predict(question.text)
    return {"question": question.text, "answer": answer}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
