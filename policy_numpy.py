"""NumPy-only inference for the trained Maskable PPO policy.

The deployed API only needs the actor (policy) half of the network, which is
two tanh hidden layers (16 -> 64 -> 64) and a 4-way output layer. Weights were
exported from 2048_ppo_masked.zip into policy_weights.npz (see export_weights.py),
so the API runs without PyTorch or stable-baselines3.
"""
import numpy as np


class NumpyPolicy:
    def __init__(self, path="policy_weights.npz"):
        w = np.load(path)
        self.w0, self.b0 = w["mlp_extractor.policy_net.0.weight"], w["mlp_extractor.policy_net.0.bias"]
        self.w1, self.b1 = w["mlp_extractor.policy_net.2.weight"], w["mlp_extractor.policy_net.2.bias"]
        self.wa, self.ba = w["action_net.weight"], w["action_net.bias"]

    def logits(self, obs):
        x = np.asarray(obs, dtype=np.float32).reshape(-1)
        x = np.tanh(self.w0 @ x + self.b0)
        x = np.tanh(self.w1 @ x + self.b1)
        return self.wa @ x + self.ba

    def probs(self, obs, mask):
        """Softmax over valid moves only (invalid moves get probability 0)."""
        z = self.logits(obs).astype(np.float64)
        z = np.where(np.asarray(mask, dtype=bool), z, -np.inf)
        z = z - z.max()
        e = np.exp(z)
        return e / e.sum()

    def predict(self, obs, mask):
        """Deterministic action: highest-probability valid move."""
        return int(np.argmax(self.probs(obs, mask)))
