clear all
clc;
global N_leaf;
global Second_node;
global Non_leaf;
global Leaf;
global Node;
global root;  
global height;
global H_num;
global nest_num;
global Node_num;

%Please input (D1, D2, D3);
Num_level_1 = 3; %D1
Num_level_2 = 4; %D2
Num_level_3 = 5; %D3
%Please input U_min and U_max;
U_min = 20;
U_max = 30;

N_leaf = Num_level_1*Num_level_2*Num_level_3; %number of products
Non_leaf = Num_level_1 + Num_level_1*Num_level_2+1; %number of nonleaf nodes
Leaf = zeros(N_leaf,5); %leaf node (ID, utility, parent ID, r_j, nest_ID)
Node = zeros(Non_leaf,5); %non-leaf node (ID, eta, degree, parent ID, nest_ID)
Second_node = Num_level_1*Num_level_2; %The number of nodes at the second level
Node_num = N_leaf + Non_leaf- 1; 
root = N_leaf+ Non_leaf; 
height = 3;
H_num = [N_leaf, Second_node, Num_level_1];
nest_num = Num_level_1;

data = zeros(N_leaf + Non_leaf, 5);

%generate the revenue random variables
a = 0.2;
b = 0.8;
n = Num_level_3;

for i = 1:1:Second_node
    random_numbers = a + (b-a) * rand(1, n);
    data(n*(i-1)+1:i*n, 4)= sort(random_numbers, 'descend');
end
data(1:root, 1) = 1:root;

data(1:N_leaf, 2) = rand(1, N_leaf)*(U_max-U_min)+U_min; 
data(N_leaf+1:N_leaf+Non_leaf-1, 2) = rand(1, Non_leaf-1)*0.5 + 0.5; 
for i = 1:1:N_leaf
    data(i, 5) = ceil(i/Second_node); %nest_ID
    data(i, 3) = N_leaf + ceil(i/Num_level_3); %parent
end
data(N_leaf+1:N_leaf+Second_node, 3) = Num_level_3; 
data(N_leaf+Second_node+1:N_leaf+Non_leaf-1, 3) = Num_level_2; 
data(root, 3) = Num_level_1; 

for i = 1:1:Second_node
    data(N_leaf + i, 5) = ceil(i/Num_level_2); %nest ID
    data(N_leaf + i, 4) = N_leaf+Second_node+ceil(i/Num_level_2); %parent
end
data(N_leaf+Second_node+1:N_leaf+Non_leaf-1, 5) = 1:Num_level_1; %nest ID
data(N_leaf+Second_node+1:N_leaf+Non_leaf-1, 4) = root; %parent

filename = sprintf('Data/data_%d_%d_%d.xlsx', Num_level_1, Num_level_2, Num_level_3);
writematrix(data, filename);

