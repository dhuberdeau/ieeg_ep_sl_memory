% generate image sequence and targets in a separate file:
function generate_parameters_sl(sub_name)
symbol_file_names = {...
    'afasa1.jpg', 'afasa2.jpg', 'afasa3.jpg', 'afasa4.jpg'...
    'afasa5.jpg', 'afasa6.jpg', 'afasa7.jpg', 'afasa8.jpg'...
    'afasa9.jpg', 'afasa10.jpg', 'afasa11.jpg', 'afasa12.jpg'...
    '1.jpg', '2.jpg', '3.jpg', '4.jpg'...
    '5.jpg', '6.jpg', '7.jpg', '8.jpg'...
    '9.jpg', '10.jpg', '11.jpg', '12.jpg'};

N_TARG = 12;
N_REPS = 10;
sym_index = 1:length(symbol_file_names);
target_list_temp = sym_index(randperm(length(sym_index)));
target_list = target_list_temp(1:N_TARG);

% symbol_file_names_subset = symbol_file_names(target_index);
% target_index = 1:length(symbol_file_names_subset);
% foil_index = setdiff(sym_index, target_index);
target_list_index = 1:length(target_list);

%% setup experiment:

PAIR_TRANSITION_PROBABILITY = 1;

% generate sequence through Markov Chain:
pair_p = 1/(N_TARG/2);
target_pairs = [1, 3, 5, 7, 9, 11; 2, 4, 6, 8, 10, 12];

% assign transition probabilities between pairs:
P = zeros(length(target_list));
for i_targ = 1:size(target_pairs,2)
    %assign pair transition probabilities:
    P(target_list_index(target_pairs(1,i_targ)), target_list_index(target_pairs(2,i_targ))) = PAIR_TRANSITION_PROBABILITY;
    
    % assign transition probabilities to non-pairs:
    P(target_list_index(target_pairs(1,i_targ)), setdiff(1:size(P,2), target_list_index(target_pairs(2,i_targ)))) = (1 - PAIR_TRANSITION_PROBABILITY)/(size(P,2)-2); 
    
    % assign pair transitions between pairs:
    P(target_pairs(2,i_targ), setdiff(target_pairs(1,:), target_pairs(1,i_targ))) = 1/(size(target_pairs,2) - 1);
    P(target_pairs(2,i_targ), target_pairs(1,i_targ)) = 0; %don't transition back to first set of pair
end
for i_c = 1:size(P, 2)
    P(i_c, i_c) = 0;
end

mc = mcmix(length(target_list), 'Fix', P);
image_sequence = simulate(mc, floor(N_REPS*N_TARG));

%% save

save([sub_name, '_SL_params'], 'target_list', 'target_pairs', 'image_sequence');