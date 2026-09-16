import gymnasium as gym
import numpy as np
from gymnasium import spaces
from game import Game2048

class Env2048(gym.Env):
    def __init__(self):
        super().__init__()
        # agent sees 16 numbers (log2 of each tile, 0 stays 0)
        self.observation_space = spaces.Box(low=0, high=16, shape=(16,), dtype=np.float32)
        # 4 actions: 0=left, 1=up, 2=right, 3=down
        self.action_space = spaces.Discrete(4)
        self.game = None

    def reset(self, seed=None, options=None):
        super().reset(seed=seed)
        self.game = Game2048()
        return self._obs(), {}

    def step(self, action):
        directions = ['left', 'up', 'right', 'down']
        old_score = self.game.score
        moved = self.game.move(directions[action])

        if moved:
            self.game.spawn_tile()
            reward = (self.game.score - old_score) / 100.0  # normalize
        else:
            reward = -1.0  # stronger invalid move penalty

        done = self.game.is_game_over()
        if done:
            reward -= 5.0

        return self._obs(), reward, done, False, {}
    
    def action_masks(self):
        # tell the agent which moves are currently valid
        directions = ['left', 'up', 'right', 'down']
        masks = []
        for d in directions:
            import copy
            temp = copy.deepcopy(self.game)
            moved = temp.move(d)
            masks.append(moved)
        return np.array(masks)

    def _obs(self):
        # log2 transform — turns 2→1, 4→2, 512→9, keeps 0 as 0
        board = self.game.board.copy().astype(float)
        board[board > 0] = np.log2(board[board > 0])
        return board.flatten().astype(np.float32)
