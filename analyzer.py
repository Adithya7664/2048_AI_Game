import numpy as np

def get_empty_cells(board):
    return int(np.sum(board == 0))

def highest_tile(board):
    return int(np.max(board))

def highest_tile_in_corner(board):
    corners = [board[0][0], board[0][3], board[3][0], board[3][3]]
    return highest_tile(board) in corners

def merges_available(board, direction):
    from game import Game2048
    import copy
    temp = Game2048.__new__(Game2048)
    temp.board = board.copy()
    temp.score = 0
    old_score = temp.score
    moved = temp.move(direction)
    return (temp.score - old_score) // 2 if moved else 0

def breaks_corner(board, direction):
    from game import Game2048
    import copy
    if not highest_tile_in_corner(board):
        return False
    max_val = highest_tile(board)
    temp = Game2048.__new__(Game2048)
    temp.board = board.copy()
    temp.score = 0
    moved = temp.move(direction)
    if not moved:
        return False
    corners = [temp.board[0][0], temp.board[0][3], temp.board[3][0], temp.board[3][3]]
    return max_val not in corners

def _board_after_move(board, direction):
    from game import Game2048
    temp = Game2048.__new__(Game2048)
    temp.board = board.copy()
    temp.score = 0
    moved = temp.move(direction)
    return temp.board, moved

def chain_along_edge(board):
    max_val = highest_tile(board)
    for r in range(4):
        row = board[r]
        if row[0] == max_val and all(row[i] >= row[i+1] for i in range(3)):
            return True
    for c in range(4):
        col = board[:, c]
        if col[0] == max_val and all(col[i] >= col[i+1] for i in range(3)):
            return True
    return False

def analyze(board, direction):
    tags = []
    new_board, moved = _board_after_move(board, direction)

    if not moved:
        tags.append('invalid_move')
        return tags

    if highest_tile_in_corner(board):
        tags.append('corner_rule')

    # check chain AFTER the move
    if chain_along_edge(new_board):
        tags.append('chain_preserved')

    merges = merges_available(board, direction)
    if merges > 0:
        tags.append(f'merges_{merges}')

    if breaks_corner(board, direction):
        tags.append('breaks_corner')

    if get_empty_cells(board) <= 3:
        tags.append('board_crowded')
        
    #check if corner changed(risky even if it is stil a corner)

    return tags

if __name__ == '__main__':
    import numpy as np
    test_board = np.array([
        [512,   0,   0,   0],
        [256,   0,   0,   0],
        [  8,   8,   0,   0],
        [  4,   2,   0,   0],
    ])
    directions = ['left', 'up', 'right', 'down']
    for d in directions:
        tags = analyze(test_board, d)
        print(f"{d:6}: {tags}")