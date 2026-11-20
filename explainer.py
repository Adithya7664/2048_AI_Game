from analyzer import analyze
import numpy as np

TEMPLATES = {
    'invalid_move': "Can't move {dir} - no tiles would slide or merge.",

    'breaks_corner': "Avoid {dir} - it moves your {max_tile} away from the corner, breaking your anchor.",

    'corner_shifted': "Moving {dir} keeps {max_tile} in a corner but shifts it to the opposite side - risky if the board isn't symmetric.",

    'corner_rule': "Moving {dir} keeps your {max_tile} locked in the corner.",

    'chain_preserved': "Moving {dir} maintains your tile chain - high tiles stay ordered along the edge.",

    'merges': "Moving {dir} creates {count} merge(s), gaining {points} points.",

    'board_crowded': "Board is getting full ({empty} cells left) - prioritise moves that open space.",

    'chain_and_merges': "Moving {dir} both preserves your chain and merges tiles - strong move.",

    'no_highlights': "Moving {dir} is valid but doesn't merge tiles or improve position.",
}

PRIORITY = [
    'invalid_move',
    'breaks_corner',
    'corner_shifted',
    'chain_and_merges',
    'merges',
    'chain_preserved',
    'corner_rule',
    'board_crowded',
    'no_highlights',
]

def explain(board, direction, agent_scores = None):
    tags = analyze(board, direction)
    max_tile = int(np.max(board))
    empty = int(np.sum(board == 0))

    # extract merge count and points from tag like 'merges_16'
    merge_tag = next((t for t in tags if t.startswith('merges_')), None)
    merge_points = int(merge_tag.split('_')[1]) if merge_tag else 0
    merge_count = 1 if merge_points > 0 else 0
    
     # combine chain + merges into a stronger tag if both present
    if 'chain_and_merges' in tags and 'corner_shifted' in tags:
        tags.remove('chain_and_merges')  # let corner_shifted win

    # pick highest priority tag
    chosen = 'no_highlights'
    for key in PRIORITY:
        if key in tags:
            chosen = key
            break
        
    template = TEMPLATES[chosen]
    explanation = template.format(
        dir=direction,
        max_tile=max_tile,
        empty=empty,
        count=merge_count,
        points=merge_points,
    )
    
    result = {
        'direction': direction,
        'explanation': explanation,
        'tags': tags,
        'agent_scores': agent_scores,
    }
    
    return result

def suggest(board, policy):
    """policy: NumpyPolicy (policy_numpy.py). Returns the explanation for the best move."""
    directions = ['left', 'up', 'right', 'down']
    obs = board.copy().astype(float)
    obs[obs > 0] = np.log2(obs[obs > 0])
    obs = obs.flatten().astype('float32')

    from analyzer import _board_after_move
    masks = np.array([_board_after_move(board, d)[1] for d in directions])

    best_dir = directions[policy.predict(obs, masks)]
    probs = policy.probs(obs, masks)
    scores = {d: round(float(probs[i]), 3) for i, d in enumerate(directions)}
    return explain(board, best_dir, agent_scores=scores)
