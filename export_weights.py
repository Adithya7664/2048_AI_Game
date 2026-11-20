"""One-off: export the policy weights from the SB3 zip to policy_weights.npz.
Needs torch + sb3-contrib installed (training environment only)."""
import numpy as np
from sb3_contrib import MaskablePPO

model = MaskablePPO.load("2048_ppo_masked", device="cpu")
sd = {k: v.numpy() for k, v in model.policy.state_dict().items()}
keep = {k: v for k, v in sd.items() if k.startswith(("mlp_extractor.policy_net", "action_net"))}
np.savez("policy_weights.npz", **keep)
print("saved", list(keep))
