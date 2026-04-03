import pygraphviz as pgv

class Node:
    def __init__(self, parent=None, children=None, data=None, tag=None):
        """
        Node data structure
        :param parent:  Parent node
        :param children: Child nodes, list structure
        :param data: Data field
        """
        if children is None:
            children = []
        self.tag = tag
        self.parent = parent
        self.data = data
        self.children = children
    
    def __str__(self):
        return self.tag

class Tree:
    def __init__(self, rootdata):
        self.root = Node(data=rootdata, tag='root')

    def insert(self, parent_node, children_node):
        if children_node in parent_node.children:
            print(f"warning: Node {children_node.data} is already a child of {parent_node.data}")
            return
        children_node.parent = parent_node
        parent_node.children.append(children_node)

    def search(self, node, data):
        """
        Search for a node with value 'data' starting from 'node' as root
        :param node: Root node
        :param data: Data/Tag to search for
        :return: Node object or None
        """
        if node.data == data:
            return node
        elif len(node.children) == 0:
            return None
        else:
            for child in node.children:
                res = self.search(child, data)
                if res is not None:
                    return res
            return None

    def get_leavesByDataRoute(self, data_list):
        """
        Find all leaves under the path provided by the data list
        :param data_list: Path data list, [child node data, ...]
        :return: Set of leaf data under this path
        """
        leaves = set()
        node = self.root
        for data in data_list:
            node = self.search(node, data)

        for child in node.children:
            if len(child.children) > 0:
                leaves.add(child.data)

        return leaves

    def show(self, save_path='./figure/test.pdf'):
        """
        Display the tree structure
        :return:
        """
        nest_format = '\<{:s}\>'
        node_shape = 'point'
        node_style = 'dashed'
        node_color = 'blue'
        dg = pgv.AGraph(directed=True, rankdir='TB')

        def print_node(node):
            if len(node.children) > 0:
                for child in node.children:
                    # dg.add_node(child.tag, label=nest_format.format(child.data), shape=node_shape, \
                    #         style=node_style, color=node_color, fontname="Sans", fontsize='10')
                    dg.add_node(child.tag, shape=node_shape, \
                            style=node_style, color=node_color, fontname="Sans", fontsize='10')
                    dg.add_edge(node.tag, child.tag, arrowsize='0.2') # Can only use string type for parameters
                    print_node(child)

        # dg.add_node(self.root.tag, label=self.root.data, shape=node_shape, style=node_style, color=node_color)
        dg.add_node(self.root.tag, shape=node_shape, style=node_style, color=node_color)
        print_node(self.root)

        dg.draw(save_path, prog='dot')
        if save_path is not None:
            dg.render(save_path)

    # ==========================================
    # generate random tree structure
    # ==========================================
import math
import random

def generate_random_tree_bottom_up(depth=3, outdegree_range=(5, 10), total_leaves=50):
    """
    Generates a random tree using a constraint-based bottom-up strategy.
    This version calculates valid ranges for each level first to ensure 100% success rate.
    """
    min_out, max_out = outdegree_range
    
    # ==========================================
    # Phase 1: Constraint-Based Structure Planning
    # Calculate exact node counts for each level (Bottom -> Top)
    # ==========================================
    
    # 1. Initialize the structure list with leaves
    # structure[i] represents the number of nodes at level i (0 is leaves)
    structure = [total_leaves]
    
    current_nodes = total_leaves
    
    # 2. Work backwards from leaves to root to determine valid ranges
    # We need to determine counts for level 1, 2, ..., depth
    for level in range(1, depth + 1):
        parents_min = math.ceil(current_nodes / max_out)
        parents_max = current_nodes // min_out if min_out > 0 else current_nodes
        
        # Check for impossible constraints
        if parents_min > parents_max:
            raise ValueError(f"Impossible constraints at level {level}. "
                             f"Cannot fit {current_nodes} children with outdegree {outdegree_range}.")
        
        # 3. Apply Root Constraint
        # If this is the final level (Root), the count MUST be 1
        if level == depth:
            target_count = 1
            # Verify if 1 is a valid number of children for the root
            if not (parents_min <= target_count <= parents_max):
                 raise ValueError(f"Impossible constraints for Root. "
                                  f"Root requires [{parents_min}, {parents_max}] children, but needs exactly 1.")
        else:
            # 4. Random Selection within Valid Range
            # This is the key improvement: we pick randomly from the *valid* range
            target_count = random.randint(parents_min, parents_max)
            
        structure.append(target_count)
        current_nodes = target_count

    # ==========================================
    # Phase 2: Tree Construction (Top-Down)
    # Build actual Node objects based on the planned structure
    # ==========================================
    
    tree = Tree('root')
    root = tree.root
    node_dict = {'root': root}
    
    # Reverse structure for top-down construction: [Root_Count, ..., Leaf_Count]
    # e.g., [1, 7, 50]
    levels_top_down = structure[::-1]
    
    current_level_nodes = [root]
    
    for level_idx in range(1, len(levels_top_down)):
        next_level_nodes = []
        parents = current_level_nodes
        
        total_children_needed = levels_top_down[level_idx]
        num_parents = len(parents)
        
        # Distribute children to parents satisfying min/max constraints
        # 1. Assign min_out to everyone first
        children_counts = [min_out] * num_parents
        remaining_children = total_children_needed - (num_parents * min_out)
        
        # 2. Distribute the remainder randomly
        # Create a list of parent indices and shuffle to randomize distribution
        parent_indices = list(range(num_parents))
        random.shuffle(parent_indices)
        
        idx_ptr = 0
        while remaining_children > 0:
            p_idx = parent_indices[idx_ptr % num_parents]
            if children_counts[p_idx] < max_out:
                children_counts[p_idx] += 1
                remaining_children -= 1
            idx_ptr += 1

        # 3. Instantiate Nodes
        for i, parent in enumerate(parents):
            count = children_counts[i]
            for j in range(count):
                # Generate Tag
                if parent.tag == 'root':
                    child_tag = str(j + 1)
                else:
                    child_tag = f"{parent.tag},{j + 1}"
                
                child_node = Node(tag=child_tag, data={})
                node_dict[child_tag] = child_node
                tree.insert(parent, child_node)
                next_level_nodes.append(child_node)
        
        current_level_nodes = next_level_nodes

    return tree, node_dict

# # Example Usage
# if __name__ == "__main__":
#     try:
#         # Generate: Depth 3, Outdegree 1-3, 9 Leaves
#         t, nodes = generate_random_tree_bottom_up(depth=3, outdegree_range=(1, 3), total_leaves=9)
#         print("Tree generated successfully!")
#         print(f"Total nodes: {len(nodes)}")
#         t.show()
#     except ValueError as e:
#         print(e)