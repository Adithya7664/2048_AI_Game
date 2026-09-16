from sb3_contrib import MaskablePPO
from sb3_contrib.common.maskable.utils import get_action_masks
from stable_baselines3.common.env_util import make_vec_env
from environment import Env2048

# vectorized env runs multiple games in parallel-speeds up training
env = make_vec_env(Env2048, n_envs=4)

model = MaskablePPO(
    "MlpPolicy", 
    env, 
    verbose=1, 
    learning_rate=3e-4, 
    n_steps=2048, 
    batch_size=64, 
    n_epochs=10
)

print("Training started...")
model.learn(total_timesteps=1_000_000)
model.save("2048_ppo_masked")
print("Model saved.")