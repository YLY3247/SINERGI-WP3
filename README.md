# SINERGI-WP3
This repository contains the necessary code for SINERGI-WP3, including "Dynamic Assortment Optimization Under the Multi-level Nested Logit Model" (Code-1) and "Nested Logit Simulation" (Code-2).

# Core Components in Code-1:
It consists of three main processing modules:

**ParameterEstimation.m** - Contains the code for the parameter estimation method  (Algorithm 1) in the paper. The performance is evaluated by L2-norm error and the output results of each case are saved as .xlsx files.

**DynamicAssortment.m** - Contains the code for the dynamic assortment policy (Algorithm 2) in the paper. The input is an .xlsx file, and the output regret is saved as an .xlsx file.

**TreeGeneration.m** - Contains the code for generating the MLNL model. The input is  the tree structure $(D_1,D_2,D_3)$ and the lower and upper bounds of the preference weight parameter $(\underline{U},\overline{U})$. The generated MLNL model is saved as an .xlsx file. 

##

## Reproduction Workflow

To reproduce the results, follow this sequential process:

1. **Performance of Parameter Estimation**: Run ParameterEstimation.m to obtain the L2-norm error results in four cases.

2. **Performance of the Dynamic Assortment Algorithm**:  Firstly, please run TreeGeneration.m to generate the MLNL models with different values of $(D_1,D_2,D_3)$. Then, run CompareTest.m to compare the results of our algorithm with the baseline. The regret are saved as .xlsx files, and results are saved in "res_table.xlsx" file.

3. **Robustness of the Dynamic Assortment Algorithm**:  Run RobustTest.m to obtain the regret of our algorithm under different cases. The results are saved as .xlsx files, and each file contains the results with different $(\underline{U},\overline{U})$.

## 
# Nested Logit Simulation

This project is a dynamic programming solver and simulation environment based on tree structures (Nested Logit Model). The main workflow includes randomly generating tree structures, generating model parameters, discretizing the parameters, and using a dynamic programming algorithm to solve for the optimal value $J$.

## Project Structure

```
simulation/
├── data/                     # [Dir] Stores generated tree structures (CSV) and simulation result logs
├── __pycache__/              # [Dir] Python compiled cache files
├── tree.py                   # [Core] Tree structure definition and random generation (bottom-up)
├── param_generator.py        # [Core] Model parameter (mu, gamma, omega) generator
├── discretizer.py            # [Core] Parameter discretization tool
├── dp_solver.py              # [Core] Dynamic Programming Solver (DP Algorithm)
├── simulate.py               # [Main] Batch simulation entry: Generate Tree -> Multi-run Solving -> Error Statistics
├── test_on_saved_log.py      # [Tool] Load saved tree files and run a single simulation (for debugging/reproduction)
└── run_simulate.bat          # [Script] Windows batch file to run simulate.py with one click
```

## Quick Start

### 1. Run Batch Simulation

Generates a random tree and tests the error before and after discretization over 10 different random seeds.

- **For Windows:**
Double-click `run_simulate.bat` or run in the terminal:

```
run_simulate.bat
```

- **Universal Command:**

```
python simulate.py
```

### 2. Test on a Specific Case

If you want to debug or reproduce results for a specific tree structure already saved in the `data/` directory:

```
python test_on_saved_log.py
```

*The script will list available data files for you to choose from.*

## Core Logic Overview

1. **Generate Tree (**`tree.py`**)**: Uses `generate_random_tree_bottom_up` to create a nested structure satisfying depth and leaf node constraints.
2. **Generate Parameters (**`param_generator.py`**)**: Generates random utility and substitution parameters for each node.
3. **Solve (**`dp_solver.py`**)**: Uses dynamic programming to calculate the optimal objective value $J$.
4. **Discretize (**`discretizer.py`**)**: Performs **discretization** on the parameters (e.g., bias discretization) to simulate scenarios with limited precision or simplified models.
5. **Compare (**`simulate.py`**)**: Compares the solving results of the original continuous parameters against the discretized parameters and calculates the relative mean absolute error.
