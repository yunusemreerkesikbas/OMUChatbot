from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from pydantic import BaseModel
import pickle
from model.project_main import predict
from database import Database, User
from keras.models import load_model

BASE_DIR = Path(__file__).resolve().parent
SAVED_MODEL_PATH = BASE_DIR / "model" / "saved_models"

# FastAPI uygulamasını oluştur
app = FastAPI()

# CORS yapılandırması
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Tüm kökenlere izin ver
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class AskQuestion(BaseModel):
    text: str

# Pydantic modellerini tanımla
class Question(BaseModel):
    question: str
    answer: str

class User(BaseModel):
    email: str
    password: str

@app.post("/ask")
async def ask_question(question: AskQuestion):

    print(SAVED_MODEL_PATH)
    print("girmedi ************************************************************************")
    enc_model2 = load_model(SAVED_MODEL_PATH / 'enc_model.h5')
    dec_model2 = load_model(SAVED_MODEL_PATH / 'dec_model.h5')

    with open(SAVED_MODEL_PATH / 'storage.pkl', 'rb') as f:
        dense2, MAX_LEN2, vocab2, inv_vocab2 = pickle.load(f)

    answer = predict(question.text, enc_model2, dec_model2, dense2, MAX_LEN2, vocab2, inv_vocab2)
    return {"question": question.text, "answer": str(answer)}

@app.get("/test-cors/")
async def test_cors():
    return {"message": "CORS is working!"}

@app.post("/signup/")
async def signup(user: User):
    db = Database()
    if db.cursor is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    db.create_user_table()
    try:
        db.insert_user(user.email, user.password)
    except Exception as e:
        db.close()
        raise HTTPException(status_code=400, detail=str(e))
    db.close()
    return {"message": "User created successfully"}

@app.post("/login/")
async def login(user: User):
    db = Database()
    if db.cursor is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    db.create_user_table()
    user_exists = db.check_user(user.email, user.password)
    db.close()
    if user_exists:
        return {"message": "Login successful"}
    else:
        raise HTTPException(status_code=400, detail="Invalid email or password")

@app.get("/qa/")
async def get_qa():
    db = Database()
    if db.cursor is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    qa_data = db.fetch_data()
    db.close()
    return [{"id": qa[0], "question": qa[1], "answer": qa[2]} for qa in qa_data]

@app.post("/qa/")
async def add_qa(qa: Question):
    db = Database()
    if db.cursor is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        db.insert_data([(qa.question, qa.answer)])
    except Exception as e:
        db.close()
        raise HTTPException(status_code=400, detail=str(e))
    db.close()
    return {"message": "Q&A pair added successfully"}

@app.put("/qa/{qa_id}")
async def update_qa(qa_id: int, qa: Question):
    db = Database()
    if db.cursor is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        db.update_data(qa_id, qa.question, qa.answer)
    except Exception as e:
        db.close()
        raise HTTPException(status_code=400, detail=str(e))
    db.close()
    return {"message": "Q&A pair updated successfully"}

@app.delete("/qa/del/{qa_id}")
async def delete_qa(qa_id: int):
    db = Database()
    if db.cursor is None:
        raise HTTPException(status_code=500, detail="Database connection failed")
    try:
        db.delete_data(qa_id)
    except Exception as e:
        db.close()
        raise HTTPException(status_code=400, detail=str(e))
    db.close()
    return {"message": "Q&A pair deleted successfully"}

if __name__ == "__main__":
    pass
#     import uvicorn
#     uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
