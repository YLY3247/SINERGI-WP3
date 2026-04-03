import numpy as np
import random

def param_generate(mlnl, NODE, 
                   rand_seed=31, 
                   mu_range=(1.0, 5.0), 
                   utility_range=(1.0, 5.0), 
                   gamma_range=(1.0, 2.0), 
                   gamma_ratio=0.4):
    """
    Generates random parameters (MU, Utility, Gamma, Omega) for an EXISTING tree structure.
    
    Args:
        mlnl (Tree): The existing tree structure object.
        NODE (dict): The dictionary of nodes in the tree.
        rand_seed (int): Random seed for reproducibility.
        mu_range (tuple): (min, max) for MU scale parameters.
        utility_range (tuple): (min, max) for leaf utility 'a'.
        gamma_range (tuple): (min, max) for position bias.
        gamma_ratio (float): Ratio of gamma length to leaf count.
        
    Returns:
        tuple: (MU, GAMMA_raw, OMEGA_raw)
    """
    # --- 1. Set Seeds ---
    # We reset seeds here to ensure parameter generation is reproducible 
    # independent of the tree generation step.
    random.seed(rand_seed)
    np.random.seed(rand_seed)
    
    # --- 2. Generate Parameters ---
    mu_params, gamma_vals = _generate_parameters_internal(
        mlnl, NODE, utility_range, gamma_range, gamma_ratio, mu_range
    )
    
    # --- 3. Prepare Raw Omega ---
    # Omega is initialized as a vector of 1s with the same length as Gamma
    omega_raw = [1] * len(gamma_vals)
        
    return mu_params, gamma_vals, omega_raw

# ==========================================
# Internal Logic
# ==========================================

def _generate_parameters_internal(tree, node_dict, utility_range, gamma_range, gamma_ratio, mu_range):
    """
    Internal logic for assigning values to an existing tree.
    """
    mu_params = {}
    
    # --- A. Generate MU (Scale Parameters) ---
    # 1. Root MU is fixed at 1.0
    mu_params['root'] = 1.0
    
    # 2. BFS Traversal to assign MU to internal nodes
    # Queue stores: (node, min_allowed_mu, max_allowed_mu)
    queue = [(tree.root, mu_range[0], mu_range[1])]
    
    while queue:
        current_node, min_limit, max_limit = queue.pop(0)
        
        if current_node.tag == 'root':
            current_mu = mu_params['root']
        else:
            # Assign random MU within the calculated limits
            val = random.uniform(min_limit, max_limit)
            mu_params[current_node.tag] = val
            current_mu = val

        # Prepare constraints for children
        if current_node.children:
            # Child MU must be > Parent MU
            child_min = current_mu + 1e-9
            child_max = mu_range[1]
            
            # Only proceed if a valid range exists
            if child_min < child_max:
                for child in current_node.children:
                    queue.append((child, child_min, child_max))

    # --- B. Generate Utility 'a' (Leaf Nodes) ---
    for node_key, node in node_dict.items():
        if len(node.children) == 0:
            val = random.uniform(utility_range[0], utility_range[1])
            node.data['a'] = val

    # --- C. Generate GAMMA (Position Bias) ---
    # Count leaves dynamically from the provided node_dict
    num_leaves = len([n for n in node_dict.values() if len(n.children) == 0])
    
    # Calculate gamma length based on ratio
    gamma_length = max(1, int(num_leaves * gamma_ratio))
    
    gamma_vals = [random.uniform(gamma_range[0], gamma_range[1]) for _ in range(gamma_length)]
    gamma_vals.sort()

    return mu_params, gamma_vals