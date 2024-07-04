from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pickle
import numpy as np
from keras.utils import pad_sequences
import re

app = FastAPI()

origins = [
    "http://localhost",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
    "http://127.0.0.1",
    "http://localhost:33457",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class Question(BaseModel):
    text: str

with open('/home/enoca2/Desktop/OMUChatbot/api/model/models_and_data.pkl', 'rb') as f:
    enc_model, dec_model, dense, MAX_LEN, vocab, inv_vocab = pickle.load(f)

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
        sample_word = inv_vocab[sample_word_index]

        if sample_word == '<EOS>':
            break

        if sample_word != '<PAD>':
            decoded_translation += ' ' + sample_word

        empty_target_seq = np.zeros((1, 1))
        empty_target_seq[0, 0] = sample_word_index
        stat = [h, c]

        if len(decoded_translation.split()) > MAX_LEN:
            break

    return decoded_translation.strip().title()

@app.post("/ask/")
async def ask_question(question: Question):
    answer = predict(question.text)
    return {"question": question.text, "answer": answer}

@app.get("/test-cors/")
async def test_cors():
    return {"message": "CORS is working!"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
