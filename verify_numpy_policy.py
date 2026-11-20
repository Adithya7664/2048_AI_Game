"""Check that the NumPy policy used by the API matches the original SB3 model.
Needs the training requirements and the ORIGINAL explainer saved as explainer_old.py
(git show <commit before the NumPy change>:explainer.py > explainer_old.py)."""
import numpy as np, random, json
from sb3_contrib import MaskablePPO
import explainer_old as old, explainer as new
from policy_numpy import NumpyPolicy
from analyzer import _board_after_move
from game import Game2048

model = MaskablePPO.load("2048_ppo_masked", device="cpu")
pol = NumpyPolicy("policy_weights.npz")
dirs = ['left','up','right','down']

boards = []
rng = random.Random(0)
for g in range(60):
    game = Game2048()
    steps = 0
    while not game.is_game_over() and steps < 400:
        boards.append(game.board.copy())
        # play with the real agent half the time, random otherwise -> diverse boards
        masks = np.array([_board_after_move(game.board, d)[1] for d in dirs])
        if rng.random() < 0.5:
            obs = game.board.astype(float); obs[obs>0]=np.log2(obs[obs>0])
            a = int(model.predict(obs.flatten().astype('float32'), action_masks=masks, deterministic=True)[0])
        else:
            a = rng.choice([i for i in range(4) if masks[i]])
        if game.move(dirs[a]): game.spawn_tile()
        steps += 1
print("boards:", len(boards))

act_mismatch = out_mismatch = 0; maxdiff = 0.0
for b in boards:
    r_old = old.suggest(b, model)
    r_new = new.suggest(b, pol)
    # compare agent_scores and full result
    so, sn = r_old.get('agent_scores'), r_new.get('agent_scores')
    maxdiff = max(maxdiff, max(abs(so[k]-sn[k]) for k in so))
    if json.dumps(r_old, sort_keys=True, default=str) != json.dumps(r_new, sort_keys=True, default=str):
        out_mismatch += 1
        if out_mismatch <= 3: print("MISMATCH", so, sn, r_old.get('direction'), r_new.get('direction'))
print("boards compared:", len(boards))
print("full-output mismatches:", out_mismatch)
print("max |score diff| (3-dp rounded):", maxdiff)
