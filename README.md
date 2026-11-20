# 2048 AI: Maskable PPO agent and Flutter app

A 2048 game written in Flutter, backed by a reinforcement-learning agent (Maskable PPO) served through FastAPI. The agent can play the game for you ("Watch AI") and the in-game tutor explains why a move is good or bad.

## Results

Benchmark over 100 seeded games (`python benchmark.py 100`), deterministic policy, same seeds for both players:

| Player | Avg max tile | Games reaching 512 | Games reaching 1024 | Reaching 2048 | Avg score |
|---|---|---|---|---|---|
| Maskable PPO agent | 360 | 38% | 6% | 0% | 4,445 |
| Random valid moves | 108 | 0% | 0% | 0% | 1,140 |

The agent is clearly better than random play but does not reach 2048 in these runs. Tile distribution for the agent: 64 (3 games), 128 (14), 256 (45), 512 (32), 1024 (6).

## How it works

- **Environment** (`environment.py`): Gymnasium environment; observation is the 16 tiles as log2 values, 4 discrete actions, reward is the normalized score gain with penalties for invalid moves and for ending the game.
- **Agent** (`train.py`): `MaskablePPO` from sb3-contrib with action masking, so illegal moves are never sampled. 1M timesteps, 4 parallel environments, learning rate 3e-4, `n_steps` 2048, batch size 64, 10 epochs. Weights are in `2048_ppo_masked.zip`.
- **Tutor** (`analyzer.py`, `explainer.py`): rule-based board analysis (corner anchoring, merges available, edge chains) combined with the policy's move preferences to generate a short explanation for each direction.
- **API** (`api.py`, `policy_numpy.py`): FastAPI service. Inference is plain NumPy (the policy is two 64-unit tanh layers), so the deployed container needs no PyTorch and runs in well under 512 MB. The weights are exported from the SB3 model into `policy_weights.npz` by `export_weights.py`, and `verify_numpy_policy.py` checks that it picks the same move as the original model (7,437 boards, 0 differing moves; the only difference was one score rounded 0.530 vs 0.529). Endpoints:  `POST /suggest` (best move and explanation), `POST /explain` (explanation for all four directions) and `GET /health`. CORS is enabled so the web build can call it.
- **App** (`lib/`, `android/`, `web/`, ...): Flutter client with custom merge/slide animations, themes, swipe gestures, a "Watch AI" mode and an AI overlay.

## Run it

API with Docker:

```bash
docker build -t 2048-ai .
docker run -p 8000:8000 2048-ai   # listens on $PORT, default 8000
```

or without Docker: `pip install -r requirements.txt && uvicorn api:app --port 8000`. Training and evaluation need `pip install -r requirements-train.txt` instead.

App:

```bash
flutter pub get
flutter run --dart-define=API_BASE=http://127.0.0.1:8000
```

On a physical phone, use your computer's LAN address (or a deployed API URL) for `API_BASE`; `127.0.0.1` points at the phone itself. For an Android emulator use `http://10.0.2.2:8000`.

Web build (for GitHub Pages):

```bash
flutter build web --release --base-href /2048_AI_Game/ --dart-define=API_BASE=https://<your-api-url>
```

Reproduce the benchmark: `python benchmark.py 100`. Retrain: `python train.py`, then `python export_weights.py` to refresh the API weights.

## Repository layout

```
api.py, explainer.py, analyzer.py   FastAPI service and move explanations
policy_numpy.py, policy_weights.npz NumPy inference and exported weights
export_weights.py                   SB3 zip -> policy_weights.npz
environment.py, game.py             Gymnasium environment and game logic
train.py, evaluate.py, benchmark.py Training and evaluation
2048_ppo_masked.zip                 Trained agent
lib/, android/, ios/, web/, ...     Flutter client
Dockerfile                          API container
```
