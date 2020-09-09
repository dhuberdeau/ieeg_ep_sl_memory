function score = score_results(subject_file)
% score the SL results for subject whose data is in subject_file

load(subject_file);

% the target indies used as pairs:
target_index = [1, 3, 5, 7, 9, 11; 2, 4, 6, 8, 10, 12];

% get target pairs as indicies of the actual images used:
target_pairs = target_list(target_index);

% get target numbers as indicies of the actual images used:
presented_targets = target_list(target_index(1, target_presentation_order));

% get pair option as indicies of the actual images used:
pair_options = [target_list(target_index(2, symbol_index_options(1,:)));...
    target_list(target_index(2, symbol_index_options(2,:)))];

%% get response as indicies of the options presented:
R1 = '1!';
R2 = '2@';
response_num = nan(1,size(response_YN,2));
for i_res = 1:length(response_YN)
    switch response_YN{i_res}
        case R1
            response_num(i_res) = 1;
        case R2
            response_num(i_res) = 2;
        otherwise
            response_num(i_res) = nan;
    end
end


%% score responses:

score_list = nan(1, length(response_num));

for i_res = 1:length(response_num)
    this_target = presented_targets(i_res);
    this_pair = target_pairs(2, find(target_pairs(1,:) == this_target));
    
    if ~isnan(response_num(i_res))
        score_list(i_res) = pair_options(response_num(i_res), i_res) == this_pair;
    else
        score_list(i_res) = 0;
    end
end

score = sum(score_list)/length(score_list);