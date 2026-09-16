from environment import Env2048

env = Env2048()
obs, _ = env.reset()
directions = ['left', 'up', 'right', 'down']
games_played = 0
best = 0

for _ in range(50000):
    action = env.action_space.sample()
    obs, reward, done, _, _ = env.step(action)
    if done:
        games_played += 1
        tile = env.game.highest_tile()
        if tile > best:
            best = tile
        print(f"Game {games_played} over | Score: {env.game.score} | Best tile: {tile}")
        obs, _ = env.reset()

print(f"\nBest tile across all games: {best}")
