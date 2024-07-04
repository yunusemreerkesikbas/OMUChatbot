from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pickle
import numpy as np
from keras.utils import pad_sequences
from model.project_main import predict
from keras.models import load_model

# FastAPI uygulamasını oluştur
app = FastAPI()

# Pydantic modelini tanımla
class Question(BaseModel):
    text: str

@app.post("/ask")
async def ask_question(question: Question):
    enc_model2 = load_model('enc_model.h5')
    dec_model2 = load_model('dec_model.h5')

    with open('storage.pkl', 'rb') as f:
        dense2, MAX_LEN2, vocab2, inv_vocab2 = pickle.load(f)

    answer = predict(question.text, enc_model2, dec_model2, dense2, MAX_LEN2, vocab2, inv_vocab2)

    return {"question": question.text, "answer": answer}

if __name__ == "__main__":
    # import uvicorn
    # uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
    pass
    

