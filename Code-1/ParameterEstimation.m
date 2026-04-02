clear all
clc;
global mu_true;
global eta_true;  
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
global mu_not_buy;
global V_0;

for set_exp = 1:1:4 
    if set_exp == 1 
        Num_level_1 = 3; %The degree of root node:D1
        Num_level_2 = 4; %The degree of first-level nodes:D2
        Num_level_3 = 5; %The degree of second-level nodes:D3
    elseif set_exp == 2 
        Num_level_1 = 3; 
        Num_level_2 = 4; 
        Num_level_3 = 10; 
    elseif set_exp == 3 
        Num_level_1 = 4; 
        Num_level_2 = 5; 
        Num_level_3 = 5; 
    elseif set_exp == 4 
        Num_level_1 = 2; 
        Num_level_2 = 3; 
        Num_level_3 = 10; 
    end
    %The structure of the MLNL model:
    N_leaf = Num_level_1*Num_level_2*Num_level_3; %number of products
    Non_leaf = Num_level_1 + Num_level_1*Num_level_2+1; %number of internal nodes
    Leaf = zeros(N_leaf,5); %leaf node (ID, utility, parent ID, r_j, nest_ID)
    Node = zeros(Non_leaf,5); %non-leaf node (ID, eta, degree, parent ID, nest_ID)
    Second_node = Num_level_1*Num_level_2; %The number of nodes at the second level
    Node_num = N_leaf + Non_leaf- 1; %The number of nodes
    root = N_leaf+ Non_leaf; %ID of root node
    height = 3; %The number of levels  
    H_num = [N_leaf, Second_node, Num_level_1];
    nest_num = Num_level_1;
    mu_not_buy = 10; %Phi_0
    mu_max = 2; %mu_max
    eta_min = 0.5;
    U_min = 20; %The lower bound of phi
    U_max = 30; %The upper bound of phi
    L2_error_data = [];
    estimate_parameters = [];
    N_exp = 20; %20 independent tests 
    data = zeros(N_leaf + Non_leaf, 5); %Store the tree structure

    % Generate the random variables of revenue
    a = 0.2;
    b = 0.8;
    n = Num_level_3;

    for i = 1:1:Second_node
        random_numbers = a + (b-a) * rand(1, n);
        data(n*(i-1)+1:i*n, 4)= sort(random_numbers, 'descend');
    end
    data(1:root, 1) = 1:root;
    %Generate the random variables of preference weight and eta
    data(1:N_leaf, 2) = rand(1, N_leaf)*(U_max-U_min)+U_min; %phi
    data(N_leaf+1:N_leaf+Non_leaf-1, 2) = rand(1, Non_leaf-1)*0.5 + 0.5; %eta:0.5-1
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

    V_0 = mu_not_buy;
    mu_true = zeros(1, N_leaf);
    eta_true = zeros(1, Non_leaf);

    for i = 1:1:N_leaf
        Leaf(i,1)=data(i,1);
        Leaf(i,2)=data(i,2);
        Leaf(i,3)=data(i,3);
        Leaf(i,4)=data(i,4);
        Leaf(i,5)=data(i,5);
        mu_true(i) = Leaf(i,2);
    end
    for i = 1:1:Non_leaf
        Node(i,1)=data(i+N_leaf,1);
        Node(i,2)=data(i+N_leaf,2);
        Node(i,3)=data(i+N_leaf,3);
        Node(i,4)=data(i+N_leaf,4);
        Node(i,5)=data(i+N_leaf,5);
        eta_true(i) = data(i+N_leaf,2);
    end
    true_values = [mu_true, eta_true];
    true = true_values(1:Node_num);
    %Construct S_0 to estimate the parameters
    num_item = Num_level_2*Num_level_3; % The number of products in the first-level nest
    S1 = 1:N_leaf;
    S2 = [];
    for i = 1:1:Num_level_2
        S = [];
        for j = 1:1:nest_num
            items = (j-1)*num_item + (i-1)*Num_level_3 + 1: (j-1)*num_item + i*Num_level_3;
            S = [S, items];
        end
        S2 = [S2; S];   
    end
    Exp_ass = {S1};
    rows_2 = size(S2, 1);
    for i = 1:1:rows_2
        Exp_ass{end+1} = S2(i,:);
    end
    S3 = [];
    for i = 1:1:Num_level_2
        S = [];
        for j = 1:1:nest_num
            S = [S, (j-1)*num_item+(i-1)*Num_level_3+1];
        end
        S3 = [S3; S];
    end
    estimate_data = {};
    rows = size(S3, 1);
    for i = 1:1:rows
        Exp_ass{end+1} = S3(i,:);
    end
    Set = {}; %store the subsets provided by the nests,Set{1,1}:The first subset provided by Nest1，Set{2,1}:The first subset provided by Nest2
    for i = 1:1:nest_num
        Set{i, 1} = num_item*(i-1)+1:num_item*i;
        for j = 1:1:Num_level_2
            Set{i, 1+j} = (i-1)*num_item+(j-1)*Num_level_3+1:(i-1)*num_item+j*Num_level_3;
        end
        for j = 1:1:Num_level_3
            Set{i, 1+Num_level_2+j} = (i-1)*num_item+(j-1)*Num_level_3+1;
        end    
    end
    for i = N_leaf+Second_node+1:1:Node_num
        estimate_data{i, 1} = S1; %required assortment S
        estimate_data{i, 2} = 1; %assortment ID
        estimate_data{i, 3} = 2;  %required assortment S'
        estimate_data{i, 4} = N_leaf + 1 + Num_level_2*(Node(i-N_leaf,5)-1); %children ID
    end
    for i = N_leaf+1:1:N_leaf+Second_node  
        mod_x = mod(i-N_leaf, Num_level_2);
        if mod_x == 0
            mod_x = Num_level_2;
        end
        estimate_data{i, 1} = Exp_ass{1+mod_x}; 
        estimate_data{i, 2} = 1+mod_x;
        estimate_data{i, 3} = 1+rows_2+mod_x;  
        estimate_data{i, 4} = num_item*(Node(i-N_leaf,5)-1)+(mod_x-1)*Num_level_3+1; 
    end

    %conduct experiments for N_exp times
    for n_exp = 1:1:N_exp
        n_exp
        n_ass = length(Exp_ass);
        N_bar = {}; 
        epoch = 1; 
        n_sum = zeros(n_ass, Node_num); %store cumulative click counts
        estimate_res = []; %store estimates
        LE_ass = zeros(1, n_ass); %store T(S,l)
        N_cycle = 1000;  %The number of cycles
        record_num = N_cycle/500; %calculate the error evey 500 cycles
        L2_error_res = zeros(1, record_num); %store L2-norm error
        estimate_hat = zeros(1, N_leaf+Non_leaf);
        cycle = 1;
        record = 1;

        while cycle <= N_cycle 
            idx_ass = mod(epoch, n_ass); 
            if idx_ass == 0 
                idx_ass = n_ass;      
            end
            LE_ass(idx_ass) = LE_ass(idx_ass) + 1;
            S = Exp_ass{1,idx_ass}; 
            S_a = transpose(S);
            n_epoch = zeros(1, Node_num); %n_hat during each epoch
            [c, pro] = choice_model(S_a);  %observe the customer choice
            while 1
                [c, pro] = choice_model(S_a);           
                is_pick = zeros(1, Node_num);
                if c == 0 
                    epoch = epoch + 1;           
                    break;
                else
                is_pick(c) = 1;
                is_pick(Leaf(c,3)) = 1;
                for j = N_leaf+1:1:Node_num
                    if is_pick(j) == 1 && Node(j-N_leaf,4) <= Node_num
                        is_pick(Node(j-N_leaf,4)) = 1;
                    end
                end
                n_epoch = n_epoch + is_pick; 
                end
            end
            n_sum(idx_ass,:) = n_sum(idx_ass,:) + n_epoch; 
            L_E1 = LE_ass(idx_ass); %T(S,l)
            n_bar = n_sum(idx_ass,:) /L_E1; %n_bar
            for n_nest = 1:1:nest_num
                N_bar{n_nest, idx_ass} = n_bar;
            end

            %parameter estimation
            if idx_ass == n_ass 
                %compute the estimates every 500 cycles
                if mod(cycle, 500) == 1
                    for j = Node_num:-1:N_leaf+1
                        nest_id = Node(j-N_leaf,5);
                        S_ID = estimate_data{j, 2};
                        S1_ID = estimate_data{j, 3};
                        ch_ID = estimate_data{j, 4};
                        n_1 = N_bar{nest_id, S_ID}; 
                        n_ch = N_bar{nest_id, S1_ID};

                        G_prod(j) = log(n_1(j)/n_ch(j))/log(n_1(j)/n_1(ch_ID));
                        if N_leaf+Second_node < j 
                            x1 = eta_min; 
                            x2 = 1; 
                            if x1 <= G_prod(j) && G_prod(j) <= x2
                                estimate_hat(j) = G_prod(j);
                            else
                                [~, idx] = min([abs(G_prod(j) - x1), abs(G_prod(j) - x2)]);
                                x_array = [x1, x2];
                                closest_value = x_array(idx);
                                G_prod(j) = closest_value;
                                estimate_hat(j) = G_prod(j);
                            end
                        else
                            mu_pa = G_prod(Node(j-N_leaf,4)); %1/mu of parent node
                            x1 = mu_pa*eta_min;
                            x2 = mu_pa;
                            if x1 <= G_prod(j) && G_prod(j) <= x2
                                estimate_hat(j) = G_prod(j)/G_prod(Node(j-N_leaf,4));
                            else
                                [~, idx] = min([abs(G_prod(j) - x1), abs(G_prod(j) - x2)]);
                                x_array = [x1, x2];
                                closest_value = x_array(idx);
                                G_prod(j) = closest_value;
                                estimate_hat(j) = G_prod(j)/G_prod(Node(j-N_leaf,4));
                            end
                        end

                        if N_leaf < j && j <= N_leaf + Second_node 
                            ind = G_prod(j)^(-1);

                            estimate_hat(ch_ID) = (mu_not_buy*n_ch(ch_ID))^(ind);
                            if U_min > estimate_hat(ch_ID) || U_max < estimate_hat(ch_ID)
                                [~, idx] = min([abs(estimate_hat(ch_ID) - U_min), abs(estimate_hat(ch_ID) - U_max)]);
                                x_array = [U_min, U_max];
                                closest_value = x_array(idx);
                                estimate_hat(ch_ID) = closest_value;
                            end

                            for idx_ch = ch_ID+1:1:ch_ID+Num_level_3-1
                                if n_1(ch_ID) == 0
                                    estimate_hat(idx_ch) = U_min;
                                else
                                    estimate_hat(idx_ch) = n_1(idx_ch)/n_1(ch_ID)*estimate_hat(ch_ID);

                                %estimate_hat(idx_ch) = max(U_min, min(n_1(idx_ch)/n_1(ch_ID)*estimate_hat(ch_ID), U_max));
                                    if estimate_hat(idx_ch) < U_min || estimate_hat(idx_ch) > U_max
                                        [~, idx] = min([abs(estimate_hat(idx_ch) - U_min), abs(estimate_hat(idx_ch) - U_max)]);
                                        x_array = [U_min, U_max];
                                        closest_value = x_array(idx);
                                        estimate_hat(idx_ch) =closest_value;
                                    end
                                end
                            end   
                            %estimate_hat(ch_ID) = max(U_min, min((mu_not_buy*n_ch(ch_ID))^(ind), U_max));
                        end     
                    end
                    % Compute relative L2-error     
                    L2_error = norm(estimate_hat - true_values, 2);  % L2-error
                    true_norm = norm(true_values, 2);  % L2-norm of true parameters
                    normalized_L2_error = L2_error/ true_norm;  % Relative L2-error
                    L2_error_res(cycle) = normalized_L2_error;
                    record = record + 1;
                end
                cycle = cycle + 1;
            end
        end
        %Log_likelihood_true = probability_compute(S_data, c_data, true);
        %LL_true(n_exp) = Log_likelihood_true;
        L2_error_data = [L2_error_data; L2_error_res];
        estimate_parameters = [estimate_parameters; estimate_hat];
    end
    L2_error_ave = mean(L2_error_data, 1); %average L2-norm error
    estimate_ave = mean(estimate_parameters, 1);
    
    %record the result
    x = 1:500:500*(length(L2_error_ave)-1)+1;
    filename = sprintf('L2_error_%d_%d_%d.xlsx',Num_level_1,Num_level_2,Num_level_3);
    writematrix([x; L2_error_ave]', filename);
end


function [c_t, pro] = choice_model(S)  
    %simulate the customer choice based on the MLNL model
    %Input: assortment S
    %Output: c_t:the product that customers choose (c_t = 0 means DNB); pro:choice probability vector of products in S and DNB
    global N_leaf;
    global Second_node;
    global Non_leaf;
    global Leaf;
    global Node;
    global mu_not_buy;
    global mu_true;
    global eta_true;
    global H_num;
    global height;
    global root;
    u_nest = zeros(1, N_leaf +Non_leaf+1);
    pro_nest = zeros(1, N_leaf+Non_leaf+1); 
    [len, m] = size(S); 
    Level_2 = (H_num(1)+1: H_num(1)+H_num(2)); 
    U_l2 = zeros(1, H_num(2));
    U_l2_pro = zeros(1, H_num(2)); 
    pro = ones(1, len+1); 
    
    for i = 1:1:len 
        pa = Leaf(S(i), 3);
        id = find(Level_2 == pa);
        if U_l2(id)==0
            utility = mu_true(S(i));
            for j = i+1:1:len
                if (Leaf(S(j),3)==pa)
                    utility = utility + mu_true(S(j));
                end
            end
        end
        
        eta_id = eta_true(pa-N_leaf);
        U_l2_pro(id) = utility;
        U_l2(id) = utility^eta_id;
        u_nest(pa) = utility^eta_id;  
        pro_nest(S(i)) = mu_true(S(i))/utility; 
    end
    
    for i = 3:1:height+1 
        id_1 = sum(H_num(1:i-2))+1;
        id_2 = sum(H_num(1:i-1));
        if i <= height
            id_3 = sum(H_num(1:i));
        else
            id_3 = id_2;
        end
        for j = id_1:1:id_2  
            pa = Node(j-N_leaf,4); 
            u_nest(pa) = u_nest(pa) + u_nest(j);  
        end
        for j = id_1:1:id_2  
            pa = Node(j-N_leaf,4); 
            if u_nest(j)>0 && i <height + 1
                pro_nest(j) = u_nest(j)/u_nest(pa);
            elseif u_nest(j)>0 && i ==height + 1
                pro_nest(j) = u_nest(j)/(u_nest(pa)+mu_not_buy); 
                pro(1) = mu_not_buy/(u_nest(pa)+mu_not_buy);
            end
        end
       
        for k = id_2+1:1:id_3
            u_nest(k)=u_nest(k)^eta_true(k-N_leaf);  
        end
    end
    for i = 1:1:len 
        pa = Leaf(S(i),3);
        pro(i+1) = pro_nest(S(i));
        while true
            if pa < root
                pro(i+1) = pro(i+1)*pro_nest(pa);
                pa = Node(pa-N_leaf,4);
            elseif pa == root
                break
            end
        end
    end
    S_0 = [0;S];  
    c_t=randsrc(1,1,[S_0';pro]);  
end
