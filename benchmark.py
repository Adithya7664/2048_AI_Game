"""Benchmark the trained Maskable PPO agent against a random-valid-move baseline.

Usage: python benchmark.py [num_games]   (default 100)
"""
import collections
import os
import random
import sys

import numpy as np
from sb3_contrib import MaskablePPO

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from environment import Env2048  # noqa: E402

N = int(sys.argv[1]) if len(sys.argv) > 1 else 100
model = MaskablePPO.load(os.path.join(HERE, "2048_ppo_masked"))


def play(policy, seed):
    env = Env2048()
    obs, _ = env.reset(seed=seed)
    np.random.seed(seed)
    random.seed(seed)
    done, steps = False, 0
    while not done and steps < 5000:
        masks = env.action_masks()
        obs, _, done, _, _ = env.step(policy(obs, masks))
        steps += 1
    return env.game.highest_tile(), env.game.score


def agent(obs, masks):
    action, _ = model.predict(obs, action_masks=masks, deterministic=True)
    return int(action)


rng = np.random.default_rng(0)


def random_valid(obs, masks):
    return int(rng.choice(np.flatnonzero(masks)))


for name, policy in [("MaskablePPO agent", agent), ("random valid moves", random_valid)]:
    results = [play(policy, s) for s in range(N)]
    tiles = np.array([r[0] for r in results])
    scores = np.array([r[1] for r in results])
    print(f"{name}: games={N} avg_max_tile={tiles.mean():.0f} best={tiles.max()} "
          f">=512: {(tiles >= 512).mean():.0%} >=1024: {(tiles >= 1024).mean():.0%} "
          f">=2048: {(tiles >= 2048).mean():.0%} avg_score={scores.mean():.0f}")
    print("  tile distribution:", dict(sorted(collections.Counter(tiles.tolist()).items())))
