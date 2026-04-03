import numpy as np
from copy import deepcopy
import collections

class DPAlgorithm:
    def __init__(self, mlnl, NODE, MU, GAMMA, OMEGA):
        """
        Initialize the DP Solver.
        
        Args:
            mlnl: The tree object.
            NODE: Dictionary of nodes.
            MU: Dictionary of MU parameters.
            GAMMA: List of discretized position bias values.
            OMEGA: List of discretized weight values.
        """
        self.mlnl = mlnl
        self.NODE = NODE
        self.MU = MU
        self.GAMMA = GAMMA
        self.OMEGA = OMEGA
        
        # Memoization Tables (Global variables in original script)
        self.S = {}       # Stores assortment-position solutions
        self.J_KEY = {}   # Stores the optimal omega split for a given state
        self.J_VALUE = {} # Stores the optimal value J
        
        # Generate nest_list (BFS traversal excluding root)
        self.nest_list = self._generate_nest_list()

    def _generate_nest_list(self):
        """Generates the list of node tags for DP iteration (BFS, no root)."""
        nest_list = []
        queue = collections.deque([self.mlnl.root])
        while queue:
            current_node = queue.popleft()
            if current_node.tag != 'root':
                nest_list.append(current_node.tag)
            for child in current_node.children:
                queue.append(child)
        return nest_list

    # --- Helper Functions ---

    def _pow_set(self, s):
        '''Returns the power set of a list s.'''
        l = len(s)
        tmp = [[j for j in range(s[i]+1)] for i in range(l)]
        
        r = []
        for i in range(l):
            t = tmp[i]
            if len(r) == 0:
                r = [[j] for j in t]
            else:
                newr = []
                for j in t:
                    for k in r:
                        m = deepcopy(k)
                        m.extend([j])
                        newr.append(m)
                r = deepcopy(newr)
        return r

    def _diff_set(self, a, b):
        '''Returns element-wise difference a - b.'''
        return [a[i]-b[i] for i in range(len(a))]

    # --- Core DP Functions ---

    def exp_mu_z(self, p, s):
        '''
        Computes h'_{i_1,...,i_l}(S).
        p: node tag (string)
        s: assortment-position solution (dict)
        '''
        pos = p.split(',')
        if len(pos) == 3: # Leaf node (assuming depth 3)
            if p in s.keys():
                # Ensure index is within bounds
                pos_idx = s[p]
                if pos_idx < len(self.GAMMA):
                    return np.power(self.NODE[p].data['a'] * self.GAMMA[pos_idx], self.MU['root'])
                else:
                    return 0
            else:
                return 0
        else:
            # Internal node
            tmp = 0
            for child in self.NODE[p].children:
                # Recursive call
                child_val = self.exp_mu_z(child.tag, s)
                # Power transformation
                tmp += np.power(child_val, self.MU[p]/self.MU['root'])
            return np.power(tmp, self.MU['root'] / self.MU[p])

    def compute_s(self, p, omega):
        '''
        Computes S_{i_1,...,i_l}(\omega).
        '''
        o = str(omega)
        if (p, o) in self.S:
            return self.S[p, o]
        
        if sum(omega) == 0:
            self.S[p, o] = {}
            return self.S[p, o]
        
        s = {}
        pos = p.split(',')
        
        if len(pos) == 3: # Leaf node
            i = len(omega)
            for j in omega[::-1]:
                i -= 1
                if j != 0:
                    s[p] = i
                    break
        else:
            # Internal node: Reconstruct S from children's optimal splits
            om = [0] * len(omega)
            ds = omega[:] # Copy
            
            for child in self.NODE[p].children:
                ds = self._diff_set(ds, om)
                key = (child.tag, str(ds))
                
                # Compute J if not exists
                if key not in self.J_KEY:
                    self.compute_j(child.tag, ds)
                
                om = self.J_KEY[key]
                # Merge child's solution into current solution
                child_s = self.S[child.tag, str(om)]
                s = {**s, **child_s}

        self.S[p, o] = s
        return self.S[p, o]

    def compute_j(self, p, omega):
        '''
        Computes J_{i_1,...,i_l}(\omega) and stores optimal split in J_KEY.
        '''
        if p not in self.NODE:
            return 0
        
        o = str(omega)
        if (p, o) in self.J_VALUE:
            return self.J_VALUE[p, o]

        p_s = self._pow_set(omega)
        p_sibling = p[:-1] + str(int(p[-1]) + 1)
        
        max_value = -1
        max_key = None
        
        for ps in p_s:
            # 1. Compute S for current subset ps
            self.compute_s(p, ps)
            
            # 2. Compute remaining capacity
            remaining_omega = self._diff_set(omega, ps)
            
            # 3. Calculate Value: Current Utility + Future Value (Sibling)
            current_utility = self.exp_mu_z(p, self.S[p, str(ps)])
            future_value = self.compute_j(p_sibling, remaining_omega)
            
            v = current_utility + future_value
            
            if v > max_value:
                max_key = ps
                max_value = v
        
        self.J_KEY[p, o] = max_key
        self.J_VALUE[p, o] = max_value

        return max_value

    def compute_s_root(self):
        '''Computes the final solution for the root.'''
        s = {}
        om = [0] * len(self.OMEGA)
        ds = self.OMEGA[:]
        
        for child in self.mlnl.root.children:
            ds = self._diff_set(ds, om)
            key = (child.tag, str(ds))
            
            if key not in self.J_KEY:
                self.compute_j(child.tag, ds)
            
            om = self.J_KEY[key]
            child_s = self.S[child.tag, str(om)]
            s = {**s, **child_s}
            
        return s

    def run(self):
        """
        Executes the full DP algorithm:
        1. Iterates through nest_list in reverse.
        2. Computes J for all subsets of OMEGA.
        3. Returns the optimal value for the root.
        """
        # 1. Fill the DP tables bottom-up
        for i in reversed(self.nest_list):
            # Generate all subsets of OMEGA
            all_subsets = self._pow_set(self.OMEGA)
            for ps in all_subsets:
                self.compute_j(i, ps)
        
        # 2. Return the final result
        return self.J_VALUE['1', str(self.OMEGA)]