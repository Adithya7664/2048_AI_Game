from sb3_contrib import MaskablePPO
from environment import Env2048
import numpy as np

model = MaskablePPO.load("2048_ppo_masked")
env = Env2048()

tiles = []
scores = []

for _ in range(100):
    obs, _ = env.reset()
    done = False
    steps = 0
    while not done and steps < 5000:
        masks = env.action_masks()
        action, _ = model.predict(obs, action_masks=masks, deterministic=True)
        obs, reward, done, _, _ = env.step(action)
        steps += 1
    tiles.append(env.game.highest_tile())
    scores.append(env.game.score)

tiles = np.array(tiles)
print(f"Best tile:    {tiles.max()}")
print(f"Avg tile:     {tiles.mean():.0f}")
print(f"512+ games:   {(tiles >= 512).sum()}/100")
print(f"1024+ games:  {(tiles >= 1024).sum()}/100")
print(f"Avg score:    {np.mean(scores):.0f}")
print(f"Tile distribution: {dict(zip(*np.unique(tiles, return_counts=True)))}")
