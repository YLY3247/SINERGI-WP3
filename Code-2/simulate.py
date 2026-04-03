import os
import csv
import time  # Added for timing
import random
import numpy as np
from datetime import datetime

from tree import generate_random_tree_bottom_up
from param_generator import param_generate
from discretizer import bias_discretize
from dp_solver import DPAlgorithm

# ==========================================
# Configuration
# ==========================================
NUM_SEEDS = 10
RHO = 0.2
TREE_DEPTH = 3
OUTDEGREE_RANGE = (2, 10)
TOTAL_LEAVES = 15
DATA_DIR = "./data"

# Ensure data directory exists
if not os.path.exists(DATA_DIR):
    os.makedirs(DATA_DIR)

# ==========================================
# Helper: Save Tree Structure to CSV
# ==========================================
def save_tree_to_csv(mlnl, NODE, filename):
    """Saves tree structure to a CSV file for easy parsing."""
    filepath = os.path.join(DATA_DIR, filename)
    with open(filepath, 'w', newline='') as f:
        writer = csv.writer(f)
        # Header
        writer.writerow(['NodeTag', 'ParentTag', 'IsLeaf', 'Utility_a'])
        
        # BFS traversal
        queue = [mlnl.root]
        while queue:
            node = queue.pop(0)
            is_leaf = len(node.children) == 0
            utility = node.data.get('a', 0) if is_leaf else 0
            
            # Determine parent tag logic
            if node.tag == "root":
                parent_tag = "root"
            elif ',' in node.tag:
                parent_tag = node.tag.rsplit(',', 1)[0]
            else:
                parent_tag = "root"
            
            writer.writerow([node.tag, parent_tag, int(is_leaf), utility])
            
            for child in node.children:
                queue.append(child)
    return filepath

# ==========================================
# 1. Generate Tree Structure
# ==========================================
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
tree_filename = f"tree_{timestamp}.csv"
result_filename = f"results_{timestamp}.csv"

print(f"Generating Tree Structure...")
mlnl, NODE = generate_random_tree_bottom_up(
    depth=TREE_DEPTH, 
    outdegree_range=OUTDEGREE_RANGE, 
    total_leaves=TOTAL_LEAVES
)

# Save structure
tree_path = save_tree_to_csv(mlnl, NODE, tree_filename)
print(f"Tree saved: {tree_path}")

# ==========================================
# 2. Simulation Loop
# ==========================================
print(f"Running {NUM_SEEDS} simulations...")

# Prepare seeds
seeds = [random.randint(1000, 9999) for _ in range(NUM_SEEDS)]
results_data = []

for i, seed in enumerate(seeds):
    # 1. Generate Parameters
    MU, GAMMA_raw, OMEGA_raw = param_generate(mlnl, NODE, rand_seed=seed)
    
    # 2. Solve Raw (Continuous)
    t_start = time.time()
    solver_raw = DPAlgorithm(mlnl, NODE, MU, GAMMA_raw, OMEGA_raw)
    j_raw = solver_raw.run()
    t_raw = time.time() - t_start
    
    # 3. Discretize
    GAMMA_disc, OMEGA_disc = bias_discretize(GAMMA_raw, OMEGA_raw, MU['root'], rho=RHO)
    
    # 4. Solve Discrete
    t_start = time.time()
    solver_disc = DPAlgorithm(mlnl, NODE, MU, GAMMA_disc, OMEGA_disc)
    j_disc = solver_disc.run()
    t_disc = time.time() - t_start
    
    # 5. Calculate Error
    rel_error = abs(j_raw - j_disc) / abs(j_raw) if j_raw != 0 else 0
    results_data.append({
        'seed': seed,
        'j_raw': j_raw,
        'j_disc': j_disc,
        'rel_error': rel_error,
        'time_raw': t_raw,
        'time_disc': t_disc
    })
    
    # Detailed Progress Output
    # Format: [1/10] Seed: 1234 | Raw: 0.12s | Disc: 0.15s | Error: 0.05%
    print(f"[{i+1}/{NUM_SEEDS}] Seed: {seed} | "
          f"Raw: {t_raw:.3f}s | Disc: {t_disc:.3f}s | "
          f"Error: {rel_error:.4f}")

# ==========================================
# 3. Save Results & Statistics
# ==========================================

# Save to CSV (including timing data)
results_path = os.path.join(DATA_DIR, result_filename)
with open(results_path, 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['seed', 'j_raw', 'j_disc', 'rel_error', 'time_raw', 'time_disc'])
    writer.writeheader()
    writer.writerows(results_data)

# Calculate Stats
errors = [r['rel_error'] for r in results_data]
mean_mae = np.mean(errors)
std_mae = np.std(errors)

print("-" * 30)
print(f"Results saved: {results_path}")
print(f"Mean Rel. Error: {mean_mae:.4f}")
print(f"Std Rel. Error:  {std_mae:.4f}")