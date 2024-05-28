from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import logging
import pickle

from models.seq2seq_model import Seq2SeqModel

# Logging yapılandırması
logging.basicConfig(level=logging.INFO)
app = FastAPI()

# CORS middleware ekleme
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

seq2seq = Seq2SeqModel()
model_path = os.path.join('/home/enoca2/Desktop/OMUChatbot/models/seq2seq_model.keras')
seq2seq.load_model(model_path)

class RequestBody(BaseModel):
    question: str

@app.post("/predict/")
async def predict(request_body: RequestBody):
    question = request_body.question
    logging.info(f"Question: {question}")
    response = seq2seq.generate_response(question)
    logging.info(f"Response: {response}")
    return {"response": response}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
