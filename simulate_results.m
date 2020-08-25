group_means = [1.5, .6, .5]; %assumed d-prime values with severe impairment in AD and mtle groups
group_sd = [.5 .5 .5];

N = 60;
group_data = nan(N,3);
for i_sim = 1:1000
    group_data(:,1) = group_means(1) + group_sd(1)*randn(N,1);
    group_data(:,2) = group_means(2) + group_sd(2)*randn(N,1);
    group_data(:,3) = group_means(3) + group_sd(3)*randn(N,1);
end

% use g-power with group means and sd as specified.

%% for stat learning:

group_means = [1.0, .6, .5];
group_sd = [.5 .5 .5];

N = 60;
group_data_sl = nan(N,3);
for i_sim = 1:1000
    group_data_sl(:,1) = group_means(1) + group_sd(1)*randn(N,1);
    group_data_sl(:,2) = group_means(2) + group_sd(2)*randn(N,1);
    group_data_sl(:,3) = group_means(3) + group_sd(3)*randn(N,1);
end