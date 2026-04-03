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
global mu_UCB;
global eta_UCB;
global num_assortment;
global mu_not_buy;
global V_0;
global T;
global Num_level_1;
global Num_level_2;
global Num_level_3;
global eta_min;
global mu_max;
global U_min;
global U_max;
global c_explore_time;

Res_table = zeros(28, 6);
T_exp = [1e3, 5e3, 1e4, 5e4, 1e5, 5e5, 1e6]; % set the selling horizon
for i_set = 1:1:27
    %i_set
    N_exp = 100; % The number of independent tests
    T_idx = mod(i_set, 7);
    if T_idx == 0
        T_idx = 7;
    end
    T = T_exp(T_idx); %Selling horizon
    if i_set < 8
        Num_level_1 = 2; 
        Num_level_2 = 3; 
        Num_level_3 = 10; 
        data = readmatrix('Data/data_2_3_10.xlsx');
    elseif i_set < 15
        Num_level_1 = 3; %D1
        Num_level_2 = 4; %D2
        Num_level_3 = 5; %D3
        data = readmatrix('Data/data_3_4_5.xlsx');
   elseif i_set < 22
        Num_level_1 = 3; 
        Num_level_2 = 4; 
        Num_level_3 = 10; 
        data = readmatrix('Data/data_3_4_10.xlsx');
    else
        Num_level_1 = 4; 
        Num_level_2 = 5; 
        Num_level_3 = 5; 
        data = readmatrix('Data/data_4_5_5.xlsx');
    end
    U_min = 25;
    U_max = 30;
    N_leaf = Num_level_1*Num_level_2*Num_level_3; %number of product
    Non_leaf = Num_level_1 + Num_level_1*Num_level_2+1; %number of nonleaf node
    Leaf = zeros(N_leaf,5); %leaf node (ID, utility, parent ID, r_j, nest_ID)
    Node = zeros(Non_leaf,5); %non-leaf node (ID, eta, degree, parent ID, nest_ID)
    Second_node = Num_level_1*Num_level_2; 
    Node_num = N_leaf + Non_leaf- 1; 
    root = N_leaf+ Non_leaf; 
    height = 3;
    H_num = [N_leaf, Second_node, Num_level_1];
    nest_num = Num_level_1;
    mu_not_buy = 10;
    mu_max = 2;
    eta_min = 0.5;
    V_0 = mu_not_buy;
    mu_true = zeros(1, N_leaf);
    eta_true = zeros(1, Non_leaf);

    %The structure of the MLNL model
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
    regret_data_our = zeros(N_exp, T);
    regret_data_exp = zeros(N_exp, T);
    regret_data_exp_ave = zeros(N_exp, T);
    regret_data_ave = zeros(N_exp, T);
    num_opt_baseline = 0; 

    for n_exp = 1:1:N_exp  
        %n_exp
        %baseline
        [regret_exp, regret_ave_exp] = exp_exp();
        regret_data_exp(n_exp,:) = regret_exp(1:T);
        %ourmethod
        [regret_res, regret_ave] = dynamic_assortment();
        regret_data_our(n_exp,:) = regret_res(1:T);
    end

    true_values = [mu_true, eta_true];
    true = true_values(1:Node_num);

    regret_mean = mean(regret_data_our, 1); %regret of our method
    regret_exp_mean = mean(regret_data_exp, 1); %regret of the baseline
    time = 1:T;
    result_our = [time; regret_mean];
    result_exp = [time; regret_exp_mean];
    
    %Calculate the corresponding evaluation metrics
    ave_this_work = regret_mean(T);
    ave_baseline = regret_exp_mean(T);

    reg_this_work = regret_data_our(:, end);  
    reg_exp = regret_data_exp(:, end);  
    
    %medium
    med_this_work = median(reg_this_work);
    med_baseline = median(reg_exp);

    %maximum
    max_this_work = max(reg_this_work);
    max_baseline = max(reg_exp);
    
    improve_max = (max_baseline-max_this_work)/max_baseline;
    improve_med = (med_baseline-med_this_work)/med_baseline;
    Res_table(i_set, 1) = med_baseline;
    Res_table(i_set, 2) = max_baseline;
    Res_table(i_set, 3) = med_this_work;
    Res_table(i_set, 4) = max_this_work;
    Res_table(i_set, 5) = improve_med;
    Res_table(i_set, 6) = improve_max;
    
    [len, len2] = size(regret_mean);
    output_reg = [time; regret_mean; regret_exp_mean];
    if T == 1e6
        [len, len2] = size(regret_mean);
        x = 1:1:len2;
        figure;
        plot(x,regret_mean,'r');
        hold on;% 表示在这幅图上继续作图
        %hold off;% 表示当前图形绘制完毕
        xlabel('x');
        ylabel('cumulative regret');
        legend('this work');
        grid on;
        filename = sprintf('regret_result_%d_%d_%d_%d.xlsx', T, Num_level_1, Num_level_2, Num_level_3);
        writematrix(output_reg', filename);
    end
end
%writematrix(Res_table, 'res_table.xlsx'); 

function [regret_res, regret_ave] = dynamic_assortment(~)
    %Our method: dynamic assortment algorithm
    %Output:regret_res: the regret vector; regret_ave: the average regret vector
    global mu_true;
    global eta_true;  
    global N_leaf;
    global Second_node;
    global Non_leaf;
    global Leaf;
    global Node;
    global root;
    global H_num;
    global nest_num;
    global Node_num;
    global mu_not_buy;
    global M;
    global T;
    global Num_level_1;
    global Num_level_2;
    global Num_level_3;
    global eta_min;
    global mu_max;
    global U_min;
    global U_max;
    global mu_not_buy;
    global c_explore_time;
    
    %Construct S_0 to estimate the parameters
    num_item = Num_level_2*Num_level_3;
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
    Set = {};
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
        estimate_data{i, 1} = S1;
        estimate_data{i, 2} = 1;
        estimate_data{i, 3} = 2;
        estimate_data{i, 4} = N_leaf + 1 + Num_level_2*(Node(i-N_leaf,5)-1);
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
    n_ass = length(Exp_ass);
    N_bar = {};
    epoch = 1;
    n_sum = zeros(n_ass, Node_num);
    estimate_res = [];
    LE_ass = zeros(1, n_ass);
    estimate_hat = zeros(1, N_leaf+Non_leaf);
    cycle = 1;
    stage = 1; %1:first step; 2:second step;
    t = 1;
    n_0 = 1;
    alpha = 0.01;
    
    regret_res = zeros(1, T); %regret
    regret_ave = zeros(1, T); %average regret
    [S_star, Max_r_opt] = findopt(mu_true,eta_true); %static assortment optimization
    n_stage1 = 1;
    while t <= T
        if stage == 1 %enter the first step
            idx_ass = mod(epoch, n_ass);
            if idx_ass == 0
                idx_ass = n_ass;
            end
            LE_ass(idx_ass) = LE_ass(idx_ass) + 1;
            S = Exp_ass{1,idx_ass};
            S_a = transpose(S);
            n_epoch = zeros(1, Node_num);
            [c, pro] = choice_model(S_a);
            r_act = sum(pro(2:end)*Leaf(S_a,4));
            regret = Max_r_opt - r_act;
            while 1
                [c, pro] = choice_model(S_a);
                if t == 1
                    regret_res(1) = regret;
                else
                    regret_res(t) = regret_res(t-1) + regret;
                end
                regret_ave(t) = regret_res(t)/t;
                t = t + 1;
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
            L_E1 = LE_ass(idx_ass);
            n_bar = n_sum(idx_ass,:) /L_E1;
            for n_nest = 1:1:nest_num
                N_bar{n_nest, idx_ass} = n_bar;
            end
            D_N = (Num_level_2+Num_level_2*Num_level_3)*Non_leaf*N_leaf^2;
            %parameter estimation
            if idx_ass == n_ass
                n_stage1 = n_stage1 + 1;
                if n_stage1 >= n_0
                    for j = Node_num:-1:N_leaf+1
                        nest_id = Node(j-N_leaf,5);
                        S_ID = estimate_data{j, 2};
                        S1_ID = estimate_data{j, 3};
                        ch_ID = estimate_data{j, 4};
                        n_1 = N_bar{nest_id, S_ID}; %e.g. {1,2,3}
                        n_ch = N_bar{nest_id, S1_ID};%e.g. {1}

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
                            mu_pa = G_prod(Node(j-N_leaf,4));
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
                                    if estimate_hat(idx_ch) < U_min || estimate_hat(idx_ch) > U_max
                                        [~, idx] = min([abs(estimate_hat(idx_ch) - U_min), abs(estimate_hat(idx_ch) - U_max)]);
                                        x_array = [U_min, U_max];
                                        closest_value = x_array(idx);
                                        estimate_hat(idx_ch) =closest_value;
                                    end
                                end
                            end
                        end
                    end
                    stage = 2;
                end
            end
        elseif stage == 2
            %disp("exploitation");
            %disp(cycle);
            mu_hat = estimate_hat(1:N_leaf);
            eta_hat = estimate_hat(N_leaf+1:length(estimate_hat));
            eta_hat = [eta_hat, 0];
            [S_l, Max_r] = findopt(mu_hat, eta_hat);
            s = M(root);
            A_root = cell2mat(s(1));
            M_0 = Num_level_2 + 1;
            T_duration = M_0*N_leaf^2*cycle;
            if cycle == 1
                A = A_root;
                [m, n] = size(A);
                R_sum = zeros(1, n); %total revenue of assortments
                R_average = zeros(1, n); %average revenue of assortments
                R_UCB = ones(1, n);
                R_UCB(n) = 0;
                R_average(n) = 0;
                R_sum(n) = 0;
                T_offer = zeros(1, n); %N(S,t):the number of times assortment S has been offered up to t
            else
                [m, n] = size(A);
                [m_prime, ~] = size(A_root);
                A_cell = arrayfun(@(i) sort(A(i,A(i,:)~=0)), 1:m, 'UniformOutput', false);
                new_rows = [];
                for i = 1:m_prime
                    assortment_new = sort(A_root(i, A_root(i,:) ~= 0));
                    is_exist = false;
                    for j = 1:m
                        if isequal(assortment_new, A_cell{j})
                            is_exist = true;
                            break;
                        end
                    end
                    if ~is_exist
                        new_rows = [new_rows; A_root(i,:)];
                        R_average = [R_average, 0];
                        R_sum = [R_sum, 0];
                        R_UCB = [R_UCB, 0];
                        T_offer = [T_offer, 0];
                    end
                end
                if ~isempty(new_rows)
                    A = [A; new_rows];
                end
            end                 
            alpha = 0.006;
            t_end = min(T, t + alpha*T_duration);
            for t = t:1:t_end
                [max_value, index] = max(R_UCB);
                S = A(index, A(index, :) ~= 0);
                S_a = transpose(S);
                [c, pro] = choice_model(S_a);
                if c == 0
                    R_sum(index) = R_sum(index);
                else
                    R_sum(index) = R_sum(index) + Leaf(c, 4);
                end
                T_offer(index) = T_offer(index) + 1;
                r_act = sum(pro(2:end)*Leaf(S_a,4));
                regret_res(t) = regret_res(t-1)+Max_r_opt - r_act;
                regret_ave(t) = regret_res(t)/t;
                R_average(index) = R_sum(index)/T_offer(index);
                R_UCB(index) = min(1, R_average(index) + 0.1*sqrt(2*log(T)/T_offer(index)));
            end
            cycle = cycle + 1;
            stage = 1;
        end
    end
end


function [regret_exp, regret_ave_exp] = exp_exp(~)
    %baseline: explore then exploit method
    %Output:regret_exp: the regret vector; regret_ave_exp: the average regret vector
    global T;
    global mu_true;
    global eta_true;
    global Num_level_1;
    global Num_level_2;
    global Num_level_3;
    global N_leaf;
    global Non_leaf;
    global nest_num;
    global Second_node;
    global Node_num;
    global Node;
    global Leaf;
    global eta_min;
    global mu_max;
    global U_min;
    global U_max;
    global mu_not_buy;
    global c_explore_time;
    
    [S_star, Max_r_opt] = findopt(mu_true,eta_true); %static optimal assortment
    t = 1;
    regret_exp = zeros(1, T); 
    regret_ave_exp = zeros(1, T); 
    %construct S_0 to estimate the parameters
    num_item = Num_level_2*Num_level_3; 
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
    Set = {}; 
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
        estimate_data{i, 1} = S1; 
        estimate_data{i, 2} = 1; 
        estimate_data{i, 3} = 2;  
        estimate_data{i, 4} = N_leaf + 1 + Num_level_2*(Node(i-N_leaf,5)-1); 
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

    T_exp = [1e3, 5e3, 1e4, 5e4, 1e5, 5e5, 1e6]; 
    c0 = find(T_exp == T, 1);  % 只返回第一个匹配的索引
    n_ass = length(Exp_ass);
    N_bar = {}; 
    epoch = 1; 
    n_sum = zeros(n_ass, Node_num); 
    LE_ass = zeros(1, n_ass); 
    estimate_hat = zeros(1, N_leaf+Non_leaf);
        
    if T == 1e6
        T0 = 0.15*T^(1/2);
    else
        T0 = 20*T^(1/2); 
    end
    cycle = 1;
    while t<= T0
    %for cycle = 1:1:L0  
        for idx_ass = 1:1:n_ass
            LE_ass(idx_ass) = LE_ass(idx_ass) + 1; 
            S = Exp_ass{1,idx_ass}; 
            S_a = transpose(S);
            n_epoch = zeros(1, Node_num); 
            [c, pro] = choice_model(S_a);  
            r_act = sum(pro(2:end)*Leaf(S_a,4)); 
            regret = Max_r_opt - r_act;  
            while 1
                [c, pro] = choice_model(S_a);               
                is_pick = zeros(1, Node_num);
                if t == 1
                    regret_exp(1) = regret;
                else
                    regret_exp(t) = regret_exp(t-1) + regret;
                end
                regret_ave_exp(t) = regret_exp(t)/t;
                t = t + 1;
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
            L_E1 = LE_ass(idx_ass); 
            n_bar = n_sum(idx_ass,:) /L_E1; 
            for n_nest = 1:1:nest_num
                N_bar{n_nest, idx_ass} = n_bar;
            end
        end
    end
    %parameter estimation
    for j = Node_num:-1:N_leaf+1
            nest_id = Node(j-N_leaf,5);
            S_ID = estimate_data{j, 2};
            S1_ID = estimate_data{j, 3};
            ch_ID = estimate_data{j, 4};
            n_1 = N_bar{nest_id, S_ID}; %e.g. {1,2,3}
            n_ch = N_bar{nest_id, S1_ID};%e.g. {1}
        
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
                mu_pa = G_prod(Node(j-N_leaf,4)); 
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
                        if estimate_hat(idx_ch) < U_min || estimate_hat(idx_ch) > U_max
                            [~, idx] = min([abs(estimate_hat(idx_ch) - U_min), abs(estimate_hat(idx_ch) - U_max)]);
                            x_array = [U_min, U_max];
                            closest_value = x_array(idx);
                            estimate_hat(idx_ch) =closest_value;
                        end
                    end
                end   
            end     
    end

    [S_a, ~] = findopt(estimate_hat(1:N_leaf),estimate_hat(N_leaf+1:N_leaf+Non_leaf)); %static optimal assortment 
    [c, pro] = choice_model(S_a);  %观察顾客选择
    r_act = sum(pro(2:end)*Leaf(S_a,4)); %计算收益
    regret = Max_r_opt - r_act;  
    while t <= T
        regret_exp(t) = regret_exp(t-1)+regret;
        regret_ave_exp(t) = regret_exp(t)/t;
        t = t + 1;
    end
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


function [Max_S, Max_r] = findopt(mu, eta)
    %static assortment optimization
    %Input:parameters of the MLNL model
    %Output:Max_S:optimal assortment; Max_r: revenue of Max_S;
    global N_leaf;
    global Second_node;
    global Non_leaf;
    global Leaf;
    global Node;
    global M;
    global mu_not_buy;
    global root;
    M = containers.Map('KeyType','int64','ValueType','any'); %M(ID)={S,V,V*R,u};

    temp_mu = zeros(1, N_leaf);
    temp_eta = zeros(1, Non_leaf);
    for item = 1:1:N_leaf
            temp_mu(item) = Leaf(item,2);
            Leaf(item,2)=mu(item);  
    end
    for item = 1:1:Non_leaf
            temp_eta(item)=Node(item,2);
            Node(item,2)=eta(item);  
    end
    for i = 1:1:Second_node  
        A = {}; 
        child = [];
        for j = 1:1:N_leaf 
            if Leaf(j, 3)==Node(i,1)
                child=[child, j]; 
            end
        end
        S=combi(child, Node(i,3)); 
        A{1} = S;
        V = [];
        V_R=[];
        u = [];
        for k = 1:1:Node(i,3)+1
            v=value(Leaf, S(k,:),Node(i,2)); 
            V=[V,v];
            v_r = cal_vr(Leaf,S(k,:),v); 
            V_R=[V_R, v_r*v];
        end
        A{2}= V;
        A{3} = V_R; %store V*R
        u = Interval(V,V_R);
        %compute the intersection point
        A{4} = u;
        M(Node(i,1)) = A;
    end
    for i=Second_node+1:1:Non_leaf  
        global root;
        if Node(i,3) >0
            child = [];
            for j = 1:1:Non_leaf 
                if Node(j, 4)==Node(i,1)
                    child=[child, Node(j,1)]; 
                end
            end
            U = containers.Map('KeyType','int64','ValueType','any');
            %Is_comp = containers.Map('KeyType','int64','ValueType','any');
            index = ones(Node(i,3)); 
            len = zeros(Node(i,3));  
            for j = 1:1:Node(i,3)
                num = child(j);
                s = M(num);
                U(j) = s{4};  
                [m, length]=size(s{4});
                len(j) = length;
            end
            S=[];
            V_vector = []; 
            V_R_vector =[]; 
            while true
                flag = 1; 
                for k = 1:1:Node(i,3)
                    if index(k)<len(k)+1
                        flag = 0;
                        break;
                    end
                end
                if flag==1
                    break
                end
                C = [];
                for k = 1:1:Node(i,3)
                    inter = U(k);
                    visit = index(k);
                    if index(k)<=len(k)
                        C = [C, inter(visit)];
                    else
                        C=[C,100000];  %use a large constant (100000) to represent that the comparison has been completed
                    end
                end
                [min_x, pos] = min(C); 
                s_comb = [];
                v_value = 0; 
                if Node(i,1)==root
                    v_value = mu_not_buy;  
                end
                v_r_value = 0; 
                for k = 1:1:Node(i,3)
                    s=M(child(k));
                    s_matrix = s{1};
                    v1=s{2};
                    r1=s{3};
                    index;
                    k;
                    index(k);
                    v1;
                    v_value = v_value + v1(index(k));
                    v_r_value = v_r_value + r1(index(k));
                    s_comb = [s_comb, s_matrix(index(k),:)];
                end 
                s_comb(find(s_comb==0))=[];
                [m,len_s]=size(s_comb);
                s_comb=[s_comb , zeros(1,N_leaf-len_s)];
                S = [S;s_comb]; 
                v_new = v_value^Node(i,2);
                V_vector = [V_vector, v_new];
                V_R_vector = [V_R_vector, v_r_value/v_value*v_new];
                index(pos)=index(pos)+1; 
            end
            S=[S;zeros(1,N_leaf)]; 
            V_vector = [V_vector, 0];
            V_R_vector = [V_R_vector, 0];
            ID = Node(i,1);
            A = {}; 
            A{1}=S;
            A{2}=V_vector;
            A{3}=V_R_vector;
            u = Interval(V_vector, V_R_vector);
            A{4}=u;
            M(ID) = A;
        end
    end
    s = M(root);
    s1 = s{1};
    s3 = s{3};
    [B, I] = sort(s{3}, 2, 'descend'); 
    ite = 1;
     Max_s = I(ite);
     Max_S = s1(Max_s,:);
     Max_S = nonzeros(Max_S); 
     Max_r = B(ite);

    for item = 1:1:N_leaf
            Leaf(item,2)=temp_mu(item);  
    end
    for item = 1:1:Non_leaf
            Node(item,2)=temp_eta(item);  
    end
end

function S=combi(child, n)    
    %output the collction of subsets
    S = []; 
    for i = 1:1:n+1
        n_pick = n+1-i;
        pick = [];
        for j = 1:1:n_pick
            pick = [pick, child(j)];        
        end
       pick=[pick , zeros(1,n-length(pick))];
       S = [S;pick]; 
    end
end

function v = value(Leaf, child, eta) 
    %compute the preference weight of the nest at level d-1
    global N_leaf;
    p = length(child);
    if p > 0
        sum = 0;
        for i=1:1:p
            ch = child(i);
            c = ch(1,1);
            if c > 0 && c <= N_leaf
               sum = sum + Leaf(c,2);  
            end
        end       
        v = sum^eta;
    end
end

function v_r = cal_vr(Leaf, child, v) 
    %compute the preference weight*revenue of the nest at level d-1
    global N_leaf;
    p= length(child);
    if p >0
        sum = 0;
        sum_2 = 0;
        for i=1:1:p
            ch = child(i);
            c = ch(1,1);
            if c > 0 && c <= N_leaf
               sum = sum + Leaf(c,4)*Leaf(c,2);  
               sum_2 = sum_2 + Leaf(c,2); 
            end
        end       
        if sum_2 == 0
            v_r = 0;
        else
            v_r = sum/sum_2;
        end       
    end
end

function u = Interval(V, V_R)  
    %compute the intersection point
    u = [];
    p=length(V);
    i = 1;
    while true    
        if V(i)==0 || i >= p
            break
        end
        u_in = (V_R(i)-V_R(i+1))/(V(i)-V(i+1));
        u = [u, u_in];
        i = i+1;
    end
end
