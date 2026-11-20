import numpy as np
from explainer import explain, suggest
from policy_numpy import NumpyPolicy

board = np.array([
    [512,   0,   0,   0],
    [256,   0,   0,   0],
    [  8,   8,   0,   0],
    [  4,   2,   0,   0],
])

print("=== Per-direction explanations ===")
for d in ['left', 'up', 'right', 'down']:
    result = explain(board, d)
    print(f"{d:6}: {result['explanation']}")

print("\n=== Agent suggestion ===")
model = NumpyPolicy("policy_weights.npz")
result = suggest(board, model)
print(f"Best move : {result['direction']}")
print(f"Explanation: {result['explanation']}")
print(f"Confidence : {result['agent_scores']}")
