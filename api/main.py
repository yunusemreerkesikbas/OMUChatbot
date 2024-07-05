from http.client import HTTPException


from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pickle
import numpy as np
from keras.utils import pad_sequences
import re
from models.database import Database, User
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

@app.get("/test-cors/")
async def test_cors():
    return {"message": "CORS is working!"}

db = Database()

@app.post("/signup/")
async def signup(user: User):
    db.create_user_table()
    try:
        db.insert_user(user.email, user.password)
    except HTTPException as e:
        db.close()
        raise e
    db.close()
    return {"message": "User created successfully"}

@app.post("/login/")
async def login(user: User):
    db.create_user_table()
    user_exists = db.check_user(user.email, user.password)
    db.close()
    if user_exists:
        return {"message": "Login successful"}
    else:
        raise HTTPException(status_code=400, detail="Invalid email or password")



if __name__ == "__main__":
    # import uvicorn
    # uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
    pass


