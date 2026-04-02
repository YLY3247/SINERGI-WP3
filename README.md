# SINERGI-WP3
This repository contains the necessary code for SINERGI-WP3, including "Dynamic Assortment Optimization Under the Multi-level Nested Logit Model" (Code-1) and "xxxxx".

# Core Components in Code-1:
It consists of three main processing modules:

**ParameterEstimation.m** - Contains the code for the parameter estimation method  (Algorithm 1) in the paper. The performance is evaluated by L2-norm error and the output results of each case are saved as .xlsx files.

**DynamicAssortment.m** - Contains the code for the dynamic assortment policy (Algorithm 2) in the paper. The input is an .xlsx file, and the output regret is saved as an .xlsx file.

**TreeGeneration.m** - Contains the code for generating the MLNL model. The input is  the tree structure $(D_1,D_2,D_3)$ and the lower and upper bounds of the preference weight parameter $(\underline{U},\overline{U})$. The generated MLNL model is saved as an .xlsx file. 

## 
