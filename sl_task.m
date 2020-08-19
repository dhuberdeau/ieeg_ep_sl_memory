function  sl_task(varargin)
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);

DAQ_ATTACHED = 1;

addpath(genpath(pwd))

sub_name_ = 'test01';
uniqueness_code = now*10000000000;
sub_name = [sub_name_, '_', num2str(uniqueness_code)];

screen_dims = [1920, 1080];
screen_dim1 = screen_dims(1);
screen_dim2 = screen_dims(2);

%% Intialise digital IO
interSample = .01;
if DAQ_ATTACHED
    [jo, jh] = initiate_labjack;
    send_trigger_to_initiated_lj(jo, jh, 0);
end

KbQueueCreate()
KbQueueStart()

%% setup images:
im_dwell_time = .6;
iti_time = 1;

symbol_file_names = {...
    'afasa1.jpg', 'afasa2.jpg', 'afasa3.jpg', 'afasa4.jpg'...
    'afasa5.jpg', 'afasa6.jpg', 'afasa7.jpg', 'afasa8.jpg'...
    'afasa9.jpg', 'afasa10.jpg', 'afasa11.jpg', 'afasa12.jpg'...
    '1.jpg', '2.jpg', '3.jpg', '4.jpg'...
    '5.jpg', '6.jpg', '7.jpg', '8.jpg'...
    '9.jpg', '10.jpg', '11.jpg', '12.jpg'};
% 
N_TARG = 8;
N_REPS = 5;
sym_index = 1:length(symbol_file_names);

% load target_index, target_pairs, and image_sequence
load('test_01_SL_params.mat');

% target_index_temp = sym_index(randperm(length(sym_index)));
% target_index = target_index_temp(1:N_TARG);
% foil_index = setdiff(sym_index, target_index);
% 
% %% setup experiment:
quit_command = 0;
% 
% % generate sequence through Markov Chain:
% pair_p = .25;
% target_pairs = [1, 3, 5, 7; 2, 4, 6, 8];
% 
% P = (1/(length(symbol_file_names) - 1))*ones(length(symbol_file_names));
% for i_targ = 1:size(target_pairs,2)
%     P(target_index(target_pairs(1,i_targ)), target_index(target_pairs(2,i_targ))) = .9;
%     P(target_index(target_pairs(1,i_targ)), setdiff(1:size(P,2), target_index(target_pairs(2,i_targ)))) = .1/(length(symbol_file_names)-2);
% end
% for i_c = 1:size(P, 2)
%     for i_r = 1:size(P,1)
%         if i_r == i_c
%             P(i_r, i_c) = 0;
%         end
%     end
% end
% 
% mc = mcmix(24, 'Fix', P);
% image_sequence = simulate(mc, floor(N_REPS*N_TARG/pair_p));

%% open screen
screens=Screen('Screens');
screenNumber=max(screens);
% rect_ = Screen('Rect', 1);
[win, rect] = Screen('OpenWindow', screenNumber, []);%, rect_); %[0 0 1600 900]);
o = Screen('TextSize', win, 24);

%% load images:
sym_texture_list = cell(1,length(symbol_file_names));
for i_symb = 1:length(symbol_file_names)
    temp_im = imread(symbol_file_names{i_symb});
    sym_texture_list{i_symb} = Screen('MakeTexture', win, temp_im);
end

%% start counter
if DAQ_ATTACHED
    send_trigger_to_initiated_lj(jo, jh, 255);
    pause(.1);
    send_trigger_to_initiated_lj(jo, jh, 0);
end

%% Display instructions.
Screen('DrawText', win,...
    'Please pay close attention to all images. Press the 0 key when you see "0"',...
    round(screen_dim1/2)-500, round(screen_dim2/2) - 100);
Screen('DrawText', win,...
    'To begin, press the G key.',...
    round(screen_dim1/2)-175, round(screen_dim2/2));
Screen('Flip', win);

str = GetSecs; [sec,~,~]=KbWait(0,0);

%% run encoding phase of experiment:
stimulus_list = nan(1, length(image_sequence));
key_strokes = nan(2, length(image_sequence));
for i_time = 1:length(image_sequence)
    
    if quit_command == 1
        break
    end
    
    this_ind = image_sequence(i_time);
    if this_ind == 0
        Screen('DrawText', win,...
        '0',...
        round(screen_dim1/2), round(screen_dim2/2));
        trigger_value = this_ind;
    else
        Screen('DrawTexture', win, sym_texture_list{this_ind});
        trigger_value = this_ind;
    end
    stimulus_list(i_time) = trigger_value;

    if DAQ_ATTACHED
        send_trigger_to_initiated_lj(jo, jh, trigger_value);
    end
    Screen('Flip', win);
    if DAQ_ATTACHED 
        send_trigger_to_initiated_lj(jo, jh, 0);
    end

    response_made = 0;
    temp_key = nan;
    str = GetSecs;
    while (GetSecs - str) < im_dwell_time
        [key_press, key_seconds, key_code, ~] = KbCheck;
        pause(.01);
        if key_press == 1
            key_hit = KbName(key_code);
            if isequal(key_hit, 'q')
                % quit command sent
                quit_command = 1;
                break
            end
            if response_made == 0
                temp_key = key_hit;
                temp_sec = key_seconds;
                response_made = 1;
            end
        end
    end
    
    if quit_command == 1
        break
    end
    
    Screen('Flip', win);
    
    % pause between images:
    [temp_sec2, temp_key2] = wait_kbcheck(iti_time);
    
    if ~isnan(temp_key)
        key_strokes(1, i_time) = temp_key(1);
        key_strokes(2, i_time) = temp_sec - str;
    elseif ~isnan(temp_key2)
        key_strokes(1, i_time) = temp_key2(1);
        key_strokes(2, i_time) = temp_sec2 - str;
    end

    save([sub_name, '_temp'], 'image_sequence', 'stimulus_list', 'key_strokes', 'target_index', 'target_pairs');
    
end

save([sub_name, '_encode'], 'image_sequence', 'stimulus_list', 'key_strokes', 'target_index', 'target_pairs');
%% run recall phase of experiment:
% switch of experiment trigger
if DAQ_ATTACHED
    send_trigger_to_initiated_lj(jo, jh, 255);
    pause(.1);
    send_trigger_to_initiated_lj(jo, jh, 0);
end

N_ALTS = 5;

option_locs_x = linspace(382, 1920 - 382, N_ALTS);
option_locs_y = (screen_dims(2)/2 + 200)*ones(1,5);
pair0_loc = screen_dims/2 - [0, 200];
window_size = [-50 -50 50 50];

sym_index_exPair0 = setdiff(sym_index, target_index(target_pairs(1,:)));
sym_index_exPair1 = setdiff(sym_index, target_index(target_pairs(2,:)));
sym_index_exPair = setdiff(sym_index, target_index);
pair_index = 1:N_ALTS;

sym_index_rand = sym_index(randperm(length(sym_index)));

response_YN = cell(1, length(sym_index_rand));
response_conf = cell(1, length(sym_index_rand));
response_answer = nan(1, length(sym_index_rand));
symbol_index_options = nan(N_ALTS, length(sym_index_rand));
for i_im = 1:length(sym_index)
    % ITI
    pause(1)
    
    % show image:
    if ismember(sym_index_rand(i_im), target_index(target_pairs(1,:)))
        % one of pair0. show image, and then show pair1 and 4 other
        % non-pair0
        Screen('DrawTexture', win, sym_texture_list{sym_index_rand(i_im)}, [],...
        [pair0_loc, pair0_loc] + window_size);
    
        pair_index_rand = pair_index(randperm(length(pair_index)));  
        temp_targ_index_paired = target_index(target_pairs(2,find(target_index(target_pairs(1,:)) == sym_index_rand(i_im))));
        Screen('DrawTexture', win, ...
            sym_texture_list{temp_targ_index_paired}, [],...
             [option_locs_x(pair_index_rand(1)), option_locs_y(pair_index_rand(1)), option_locs_x(pair_index_rand(1)), option_locs_y(pair_index_rand(1))] +window_size);
         response_answer(i_im) = pair_index_rand(1);
         symbol_index_options(pair_index_rand(1), i_im) = temp_targ_index_paired;
         
         sym_index_exPair0_rand = sym_index_exPair0(randperm(length(sym_index_exPair0)));
         for i_sy = setdiff(pair_index_rand, pair_index_rand(1))
             Screen('DrawTexture', win, sym_texture_list{sym_index_exPair0_rand(i_sy)}, [],...
                [option_locs_x(i_sy), option_locs_y(i_sy), option_locs_x(i_sy), option_locs_y(i_sy)] +window_size);
            
            symbol_index_options(i_sy, i_im) = sym_index_exPair0_rand(i_sy);
         end
         
         Screen('DrawText', win,...
            'Which symbol most likely follows the above symbol?',...
            round(screen_dim1/2) - 200, round(screen_dim2/2));
        
        for i_sy = 1:N_ALTS
            Screen('DrawText', win,...
            num2str(i_sy),...
            option_locs_x(i_sy), option_locs_y(i_sy) + 60);
        end
    elseif ismember(sym_index_rand(i_im), target_index(target_pairs(2,:)))
        % one of pair1. Show image, then show 5 other non-pair0 or pair1.
        Screen('DrawTexture', win, sym_texture_list{sym_index_rand(i_im)}, [],...
        [pair0_loc, pair0_loc] + window_size);
         
         sym_index_exPair_rand = sym_index_exPair(randperm(length(sym_index_exPair)));
         for i_sy = 1:length(pair_index)
             Screen('DrawTexture', win, sym_texture_list{sym_index_exPair_rand(i_sy)}, [],...
                [option_locs_x(i_sy), option_locs_y(i_sy), option_locs_x(i_sy), option_locs_y(i_sy)] +window_size);
            symbol_index_options(i_sy, i_im) = sym_index_exPair_rand(i_sy);
         end
         Screen('DrawText', win,...
            'Which symbol most likely follows the above symbol?',...
            round(screen_dim1/2) - 200, round(screen_dim2/2));
        
        for i_sy = 1:N_ALTS
            Screen('DrawText', win,...
            num2str(i_sy),...
            option_locs_x(i_sy), option_locs_y(i_sy) + 60);
        end
    else
        % not a member of a pair.. show whatever.
        Screen('DrawTexture', win, sym_texture_list{sym_index_rand(i_im)}, [],...
        [pair0_loc, pair0_loc] + window_size);
    
        sym_index_rand2_ = setdiff(sym_index, sym_index_rand(i_im));
        sym_index_rand2 = sym_index_rand2_(randperm(length(sym_index_rand2_)));
%         sym_index_rand2 = setdiff(sym_index_rand2_, sym_index_rand(i_im));
        for i_sy = 1:N_ALTS
            Screen('DrawTexture', win, sym_texture_list{sym_index_rand2(i_sy)}, [],...
                [option_locs_x(i_sy), option_locs_y(i_sy), option_locs_x(i_sy), option_locs_y(i_sy)] +window_size);
            symbol_index_options(i_sy, i_im) = sym_index_rand2(i_sy);
        end
        Screen('DrawText', win,...
            'Which symbol most likely follows the above symbol?',...
            round(screen_dim1/2) - 200, round(screen_dim2/2));
        
        for i_sy = 1:N_ALTS
            Screen('DrawText', win,...
            num2str(i_sy),...
            option_locs_x(i_sy), option_locs_y(i_sy) + 60);
        end
    end
    
    if DAQ_ATTACHED
        send_trigger_to_initiated_lj(jo, jh, sym_index_rand(i_im));
    end
    Screen('Flip', win);
    if DAQ_ATTACHED 
        send_trigger_to_initiated_lj(jo, jh, 0);
    end
    
    str = GetSecs;
    key_press = 0;
    while ~key_press
        [key_press, key_seconds, key_code, ~] = KbCheck;
        pause(.01);
        if key_press == 1
            key_hit = KbName(key_code);
            response_YN{i_im} = key_hit;
            if isequal(key_hit, 'q')
                % quit command sent
                quit_command = 1;
                break
            end
        end
    end
    Screen('Flip', win);
    
    pause(.2)
    
    % ask for response:
%     Screen('DrawTexture', win, sym_texture_list{sym_index_rand(i_im)});
    Screen('DrawText', win,...
        'How confident are you?',...
        round(screen_dim1/2)-75, round(screen_dim2/2)- 100);
     Screen('DrawText', win,...
         '1 - No confidence, 2 - Some, 3 - Moderate, 4 - Strong',...
         round(screen_dim1/2)-175, round(screen_dim2/2));
    
    if DAQ_ATTACHED
        send_trigger_to_initiated_lj(jo, jh, sym_index_rand(i_im));
    end
    Screen('Flip', win);
    if DAQ_ATTACHED 
        send_trigger_to_initiated_lj(jo, jh, 0);
    end
    
    str = GetSecs;
    key_press = 0;
    while ~key_press
        [key_press, key_seconds, key_code, ~] = KbCheck;
        pause(.01);
        if key_press == 1
            key_hit = KbName(key_code);
            response_conf{i_im} = key_hit;
            if isequal(key_hit, 'q')
                % quit command sent
                quit_command = 1;
                break
            end
        end
    end
    Screen('Flip', win);
    save([sub_name, 'response_temp'], 'image_sequence', 'stimulus_list', 'key_strokes', 'response_YN', 'response_conf', 'target_index', 'target_pairs', 'symbol_index_options', 'response_answer', 'sym_index_rand');
%     pause
end

%% Shut down experiment:
% end of experiment trigger
if DAQ_ATTACHED
    send_trigger_to_initiated_lj(jo, jh, 255);
    pause(.1);
    send_trigger_to_initiated_lj(jo, jh, 0);
end

save([sub_name, 'sl_final'], 'image_sequence', 'stimulus_list', 'key_strokes', 'response_YN', 'response_conf', 'target_index', 'target_pairs', 'symbol_index_options', 'response_answer', 'sym_index_rand');

sca
