import numpy as np
import random

class Game2048:
    def __init__(self):
        self.board = np.zeros((4, 4), dtype=int)
        self.score=0
        self.spawn_tile()
        self.spawn_tile()
        
    def spawn_tile(self):
        empty = list(zip(*np.where(self.board==0)))
        if empty:
            r, c = random.choice(empty)
            self.board[r][c] = 4 if random.random() < 0.1 else 2
            
    def move(self, direction):
        rotations = {'left': 0, 'up': 1, 'right': 2, 'down': 3}
        n = rotations[direction]
        board = np.rot90(self.board, n).copy()
        # print(f"  after rotating {n} times:")
        # print(board)
        board, score_gained, moved = self._collapse_left(board)
        # print(f"  after collapse:")
        # print(board)
        rotated_back = np.rot90(board, -n % 4).copy()
        # print(f"  after rotating back:")
        # print(rotated_back)
        self.board = rotated_back
        self.score += score_gained
        return moved
    
    def _collapse_left(self, board):
        new_board = np.zeros_like(board)
        score_gained = 0
        moved = False
        for r in range(4):
            row = board[r][board[r]!=0]
            merged = []
            i=0
            while i < len(row):
                if i + 1 < len(row) and row[i] == row[i + 1]:
                    merged.append(row[i] * 2)
                    score_gained += row[i] * 2
                    i += 2
                else:
                    merged.append(row[i])
                    i += 1
            new_board[r, :len(merged)] = merged
            #print(f"  row {r} merged: {merged}  new_board[r]: {new_board[r]}")
            if not np.array_equal(board[r], new_board[r]):
                moved = True
        #print(f"  moved: {moved}")
        return new_board, score_gained, moved
    
    def is_game_over(self):
        if np.any(self.board == 0):
            return False
        for r in range(4):
            for c in range(4):
                if c + 1 < 4 and self.board[r][c] == self.board[r][c+1]:
                    return False
                if r + 1 < 4 and self.board[r][c] == self.board[r+1][c]:
                    return False
        return True
    
    def highest_tile(self):
        return np.max(self.board)
        
            
    