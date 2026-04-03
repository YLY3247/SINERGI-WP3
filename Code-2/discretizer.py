import numpy as np

def bias_discretize(beta, omega, mu_root, rho=0.2):
    """
    Discretizes beta and omega into scale intervals defined by mu_0 and rho.
    
    Args:
        beta (list): List of original position bias values (GAMMA).
        omega (list): List of weights (OMEGA).
        mu_root (float): The MU value of the root node.
        rho (float): The growth rate parameter.
        
    Returns:
        tuple: (gamma_discrete, omega_discrete)
    """
    if not beta:
        return [], []

    b1 = min(beta)
    # Calculate the ratio based on root MU
    ratio = np.power(1 + rho, 1 / mu_root)
    
    i = 0 # Interval index
    j = 0 # Beta index
    g = [] # Effective interval left endpoints
    o = {} # Map: endpoint -> aggregated weight
    
    while j < len(beta):
        # Check if current beta falls into the current interval i
        if beta[j] < b1 * np.power(ratio, i + 1):
            k = b1 * np.power(ratio, i)
            
            if k not in o.keys():
                o[k] = omega[j]
                g.append(k)
            else:
                o[k] += omega[j]
            j += 1
        else:
            # Move to the next interval
            i += 1
            
    return g, [o[k] for k in g]