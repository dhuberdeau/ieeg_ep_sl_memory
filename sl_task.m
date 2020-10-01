function  sl_task(varargin)
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);

DAQ_ATTACHED = 0;

addpath(genpath(pwd))

if nargin > 0
    sub_name_ = varargin{1};
else
    sub_name_ = 'test';
end

uniqueness_code = now*10000000000;
sub_name = [sub_name_, '_', num2str(uniqueness_code)];

screen_dims = [1920, 1080];
screen_dim1 = screen_dims(1);
screen_dim2 = screen_dims(2);

% load target_index, target_pairs, and image_sequence
% load('XX_SL_params.mat');
generate_parameters_sl(sub_name);
load([sub_name, '_SL_params.mat'])

%% Intialise digital IO
interSample = .01;
if DAQ_ATTACHED
    [jo, jh] = initiate_labjack;
    send_trigger_to_initiated_lj(jo, jh, 0);
end

KbQueueCreate()
KbQueueStart()

%% setup images:
im_dwell_time = .4;
iti_time = .8;

symbol_file_names = {...
    'afasa1.jpg', 'afasa2.jpg', 'afasa3.jpg', 'afasa4.jpg'...
    'afasa5.jpg', 'afasa6.jpg', 'afasa7.jpg', 'afasa8.jpg'...
    'afasa9.jpg', 'afasa10.jpg', 'afasa11.jpg', 'afasa12.jpg'...
    '1.jpg', '2.jpg', '3.jpg', '4.jpg'...
    '5.jpg', '6.jpg', '7.jpg', '8.jpg'...
    '9.jpg', '10.jpg', '11.jpg', '12.jpg'};
% 

sym_index = 1:length(symbol_file_names);

quit_command = 0;

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
    
    this_ind = target_list(image_sequence(i_time));
    if this_ind == 0
        Screen('DrawText', win,...
        '0',...
        round(screen_dim1/2), round(screen_dim2/2));
        trigger_value = this_ind;
    else
        Screen('DrawTexture', win, sym_texture_list{this_ind});
        trigger_value = this_ind;
    end
    stimulus_list(i_time) = this_ind;

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

    save([sub_name, '_temp'], 'image_sequence', 'stimulus_list', 'key_strokes', 'target_list');
    
end

save([sub_name, '_encode'], 'image_sequence', 'stimulus_list', 'key_strokes', 'target_list');

%% run item test phase:

item_sym_index_rand = sym_index(randperm(length(sym_index)));
item_response_YN = cell(1, length(item_sym_index_rand));
item_response_conf = cell(1, length(item_sym_index_rand));
for i_im = 1:length(sym_index)
    % ITI
    pause(1)
    
    % show image:
    Screen('DrawTexture', win, sym_texture_list{item_sym_index_rand(i_im)});
    Screen('DrawText', win,...
        'Have you seen this symbol?',...
        round(screen_dim1/2)-75, round(screen_dim2/2)-100);
    
    if DAQ_ATTACHED
        send_trigger_to_initiated_lj(jo, jh, item_sym_index_rand(i_im));
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
            item_response_YN{i_im} = key_hit;
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
         '1 - did not see, 2 - may not have seen, 3 - may have seen, 4 - did see',...
         round(screen_dim1/2)-175, round(screen_dim2/2));
    
    if DAQ_ATTACHED
        send_trigger_to_initiated_lj(jo, jh, item_sym_index_rand(i_im));
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
            item_response_conf{i_im} = key_hit;
            if isequal(key_hit, 'q')
                % quit command sent
                quit_command = 1;
                break
            end
        end
    end
    Screen('Flip', win);
    save([sub_name, 'response_temp'], 'image_sequence', 'stimulus_list', 'key_strokes', 'item_response_YN', 'item_response_conf', 'item_sym_index_rand');
%     pause
end

%% run pair-detection phase of experiment: 
% for each item pair, show the first item in the pair along with the paired
% item plus 1 random item (among those used in other pairs).
if DAQ_ATTACHED
    send_trigger_to_initiated_lj(jo, jh, 255);
    pause(.1);
    send_trigger_to_initiated_lj(jo, jh, 0);
end

N_TEST_REPS = 1;
N_ALTS = 2;

option_locs_x = linspace(682, 1920 - 682, N_ALTS);
option_locs_y = (screen_dims(2)/2 + 200)*ones(1,N_ALTS);
pair0_loc = screen_dims/2 - [0, 200];
window_size = [-50 -50 50 50];

% randomize the order of presentation:
target_presentation_order_temp = repmat(1:size(target_pairs,2), 1, N_TEST_REPS);
target_presentation_order = target_presentation_order_temp(randperm(length(target_presentation_order_temp)));

% present true pair on left or right:
pair_index_temp = [ones(1,length(target_presentation_order)/2), 2*ones(1,length(target_presentation_order))];
pair_index_rand = pair_index_temp(randperm(length(pair_index_temp)));

response_answer = nan(1, length(target_presentation_order));
symbol_index_options = nan(N_ALTS, length(target_presentation_order));
response_YN = cell(1, length(target_presentation_order));
response_conf = cell(1, length(target_presentation_order));

for i_pair = 1:length(target_presentation_order)
    pause(.2);
    
     Screen('DrawTexture', win, sym_texture_list{target_list(target_pairs(1,target_presentation_order(i_pair)))}, [],...
        [pair0_loc, pair0_loc] + window_size);
    
    % draw the correct pair:
    Screen('DrawTexture', win, ...
        sym_texture_list{target_list(target_pairs(2, target_presentation_order(i_pair)))}, [],...
         [option_locs_x(pair_index_rand(i_pair)), option_locs_y(pair_index_rand(i_pair)), option_locs_x(pair_index_rand(i_pair)), option_locs_y(pair_index_rand(i_pair))] +window_size);
    response_answer(i_pair) = pair_index_rand(i_pair);
    symbol_index_options(pair_index_rand(i_pair), i_pair) = target_presentation_order(i_pair);
         
%          sym_index_exPair0_rand = sym_index_exPair0(randperm(length(sym_index_exPair0)));
    % draw a random incorrect pair:
    alt_symbol_options = setdiff(1:size(target_pairs,2), target_presentation_order(i_pair));
    alt_symbol_options_rand = alt_symbol_options(randperm(length(alt_symbol_options)));
    this_alt_symbol = alt_symbol_options_rand(1);
    Screen('DrawTexture', win, ...
        sym_texture_list{target_list(target_pairs(2, this_alt_symbol))}, [],...
        [option_locs_x(setdiff(1:2, pair_index_rand(i_pair))), option_locs_y(pair_index_rand(i_pair)), option_locs_x(setdiff(1:2, pair_index_rand(i_pair))), option_locs_y(pair_index_rand(i_pair))] + window_size);
    symbol_index_options(setdiff(1:2, pair_index_rand(i_pair)), i_pair) = this_alt_symbol;
     
    Screen('DrawText', win,...
            'Which symbol most likely follows the above symbol?',...
            round(screen_dim1/2) - 200, round(screen_dim2/2));
        
    Screen('DrawText', win,...
        '1',...
        option_locs_x(1), 50+option_locs_y(pair_index_rand(i_pair)));
    Screen('DrawText', win, ...
        '2',...
        option_locs_x(2), 50+option_locs_y(pair_index_rand(i_pair)));
    
    % register response:
    if DAQ_ATTACHED
        send_trigger_to_initiated_lj(jo, jh, target_presentation_order(i_pair));
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
            response_YN{i_pair} = key_hit;
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
%     Screen('DrawTexture', win, sym_texture_list{sym_index_rand(i_pair)});
    Screen('DrawText', win,...
        'How confident are you?',...
        round(screen_dim1/2)-75, round(screen_dim2/2)- 100);
     Screen('DrawText', win,...
         '1 - No confidence, 2 - Some, 3 - Moderate, 4 - Strong',...
         round(screen_dim1/2)-175, round(screen_dim2/2));
    
    if DAQ_ATTACHED
        send_trigger_to_initiated_lj(jo, jh, target_presentation_order(i_pair));
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
            response_conf{i_pair} = key_hit;
            if isequal(key_hit, 'q')
                % quit command sent
                quit_command = 1;
                break
            end
        end
    end
    Screen('Flip', win);
    save([sub_name, 'response_temp'], 'image_sequence', 'stimulus_list', 'key_strokes', 'response_YN', 'response_conf', 'target_list', 'target_pairs', 'symbol_index_options', 'response_answer', 'target_presentation_order');
end


%% Shut down experiment:
% end of experiment trigger
if DAQ_ATTACHED
    send_trigger_to_initiated_lj(jo, jh, 255);
    pause(.1);
    send_trigger_to_initiated_lj(jo, jh, 0);
end

save([sub_name, 'sl_final'], 'image_sequence', 'stimulus_list', 'key_strokes', 'response_YN', 'response_conf', 'target_list', 'target_pairs', 'symbol_index_options', 'response_answer', 'target_presentation_order',...
    'item_response_YN', 'item_response_conf', 'item_sym_index_rand');

sca
