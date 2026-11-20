from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from policy_numpy import NumpyPolicy
from explainer import explain, suggest
import numpy as np

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
model = NumpyPolicy("policy_weights.npz")

class BoardRequest(BaseModel):
    board: list[list[int]]
    
@app.post("/suggest")
def suggest_move(req: BoardRequest):
    board = np.array(req.board)
    result = suggest(board, model)
    return result

@app.post("/explain")
def explain_all(req: BoardRequest):
    board = np.array(req.board)
    directions = ['left', 'up', 'right', 'down']
    return {d: explain(board, d) for d in directions}

@app.get("/")
def root():
    return {"service": "2048 AI API", "endpoints": ["POST /suggest", "POST /explain", "GET /health"]}

@app.get("/health")
def health():
    return {"status": "ok"}