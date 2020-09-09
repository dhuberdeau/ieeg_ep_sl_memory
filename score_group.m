data_file_list = {...
    'test03_7380317414967477sl_final.mat',...
    'test04_7380317480803010sl_final.mat',...
    'test05_7380317551346991sl_final.mat',...
    'test06_7380317584213889sl_final.mat',...
    'test07_7380317624756944sl_final.mat',...
    'test08_7380317696399769sl_final.mat',...
    'test09_7380317733553587sl_final.mat',...
    'test10_7380317772410763sl_final.mat',...
    'test11_7380317809683102sl_final.mat',...
    'test12_7380317839986922sl_final.mat',...
    'test13_7380317867532176sl_final.mat',...
    'test14_7380317916489467sl_final.mat',...
    'test15_7380318670939930sl_final.mat',...
    };

score_list = nan(1, length(data_file_list));
for i_sub = 1:length(data_file_list)
    score_list(i_sub) = score_results(data_file_list{i_sub});
end

avg_score = mean(score_list);
sd_score = std(score_list);

%% plot:
figure;
errorbar(1, avg_score, sd_score/sqrt(length(data_file_list)));
hold on
bar(1, avg_score);
plot([0, 2], [.5 .5], 'k--');
ylim([.45 1])

% plot individuals:
plot(.975 + .05*rand(1, length(score_list)), score_list, 'k.', 'MarkerSize', 12)


%% plot patients:
patient_list = {'AW001_7380317265915162sl_final.mat',...
    'DR_7380435250276736sl_final.mat'};

score_list_pt = nan(1, length(patient_list));
for i_sub = 1:length(patient_list)
    score_list_pt(i_sub) = score_results(patient_list{i_sub});
end

avg_score = mean(score_list_pt);
sd_score = std(score_list_pt);

% plot(1, avg_score, 'c.', 'MarkerSize', 18)
plot(ones(1, length(score_list_pt)) + .07*rand(1, length(score_list_pt)),...
    score_list_pt, 'c.', 'MarkerSize', 18)