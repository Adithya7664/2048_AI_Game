from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sb3_contrib import MaskablePPO
from explainer import explain, suggest
import numpy as np

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
model = MaskablePPO.load("2048_ppo_masked")

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

@app.get("/health")
def health():
    return {"status": "ok"}