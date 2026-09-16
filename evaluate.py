from sb3_contrib import MaskablePPO
from environment import Env2048
import numpy as np

model = MaskablePPO.load("2048_ppo_masked")
env = Env2048()

games = 0
best = 0

for _ in range(100):
    obs, _ = env.reset()
    done = False
    steps = 0
    while not done and steps < 5000:
        masks = env.action_masks()
        action, _ = model.predict(obs, action_masks=masks, deterministic=True)
        obs, reward, done, _, _ = env.step(action)
        steps += 1
    games += 1
    tile = env.game.highest_tile()
    if tile > best:
        best = tile
    print(f"Game {games} | Steps: {steps} | Score: {env.game.score} | Best tile: {tile}")

print(f"\nBest tile across 100 games: {best}")
