% generate image sequence and targets in a separate file:
function generate_parameters_sl(sub_name)
symbol_file_names = {...
    'afasa1.jpg', 'afasa2.jpg', 'afasa3.jpg', 'afasa4.jpg'...
    'afasa5.jpg', 'afasa6.jpg', 'afasa7.jpg', 'afasa8.jpg'...
    'afasa9.jpg', 'afasa10.jpg', 'afasa11.jpg', 'afasa12.jpg'...
    '1.jpg', '2.jpg', '3.jpg', '4.jpg'...
    '5.jpg', '6.jpg', '7.jpg', '8.jpg'...
    '9.jpg', '10.jpg', '11.jpg', '12.jpg'};

N_TARG = 8;
N_REPS = 5;
sym_index = 1:length(symbol_file_names);
target_index_temp = sym_index(randperm(length(sym_index)));
target_index = target_index_temp(1:N_TARG);
foil_index = setdiff(sym_index, target_index);

%% setup experiment:
quit_command = 0;

% generate sequence through Markov Chain:
pair_p = .25;
target_pairs = [1, 3, 5, 7; 2, 4, 6, 8];

P = (1/(length(symbol_file_names) - 1))*ones(length(symbol_file_names));
for i_targ = 1:size(target_pairs,2)
    P(target_index(target_pairs(1,i_targ)), target_index(target_pairs(2,i_targ))) = .9;
    P(target_index(target_pairs(1,i_targ)), setdiff(1:size(P,2), target_index(target_pairs(2,i_targ)))) = .1/(length(symbol_file_names)-2);
end
for i_c = 1:size(P, 2)
    for i_r = 1:size(P,1)
        if i_r == i_c
            P(i_r, i_c) = 0;
        end
    end
end

mc = mcmix(24, 'Fix', P);
image_sequence = simulate(mc, floor(N_REPS*N_TARG/pair_p));

%% save

save([sub_name, '_SL_params'], 'target_index', 'target_pairs', 'image_sequence');