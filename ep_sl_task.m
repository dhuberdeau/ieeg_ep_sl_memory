function  ep_sl_task(varargin)
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference','VisualDebugLevel', 0);

DAQ_ATTACHED = 0;

addpath(genpath(pwd))

sub_name_ = 'test00';
uniqueness_code = now*10000000000;
sub_name = [sub_name_, '_', num2str(uniqueness_code)];

screen_dims = [1980, 1020];
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
%% open screen
screens=Screen('Screens');
screenNumber=min(screens);
[win, rect] = Screen('OpenWindow', screenNumber, []); %[0 0 1600 900]);
o = Screen('TextSize', win, 24);

%% setup images:
im_dwell_time = 4;
iti_time = 2;

symbol_file_names = {...
    'afasa1.jpg', 'afasa2.jpg', 'afasa3.jpg', 'afasa4.jpg'...
    'afasa5.jpg', 'afasa6.jpg', 'afasa7.jpg', 'afasa8.jpg'...
    'afasa9.jpg', 'afasa10.jpg', 'afasa11.jpg', 'afasa12.jpg'...
    '1.jpg', '2.jpg', '3.jpg', '4.jpg'...
    '5.jpg', '6.jpg', '7.jpg', '8.jpg'...
    '9.jpg', '10.jpg', '11.jpg', '12.jpg'};

%load the noun_list:
concrete_nouns;
noun_list_rand = noun_list(randperm(length(noun_list)));

face_dir = 'C:\Users\ITS\Documents\MATLAB\ieeg_ep_sl_memory\stims_famous\faces';
place_dir = 'C:\Users\ITS\Documents\MATLAB\ieeg_ep_sl_memory\stims_famous\scenes';
face_dir_contents = dir(face_dir);
place_dir_contents = dir(place_dir);
face_file_names = cell(1, length(face_dir_contents) - 2);
place_file_names = cell(1, length(place_dir_contents) - 2);

for i_face = 3:length(face_dir_contents)
    face_file_names{i_face - 2} = face_dir_contents(i_face).name;
end

for i_place = 3:length(place_dir_contents)
    place_file_names{i_place - 2} = place_dir_contents(i_place).name;
end

face_file_names_rand = face_file_names(randperm(length(face_file_names)));

stimuli_file_names_ = cat(2, face_file_names_rand(1:31), place_file_names(1:31));
stimuli_file_names = stimuli_file_names_(randperm(length(stimuli_file_names_)));

sym_texture_list = cell(1,length(stimuli_file_names));
for i_symb = 1:length(stimuli_file_names)
    temp_im = imread(stimuli_file_names{i_symb});
    sym_texture_list{i_symb} = Screen('MakeTexture', win, temp_im);
end

N_TARG = 12;
N_REPS = 1;
sym_index = 1:length(sym_texture_list);
sym_trigger = 1:length(sym_texture_list);
target_index_temp = sym_index(randperm(length(sym_index)));
target_index = target_index_temp(1:N_TARG);
foil_index = setdiff(sym_index, target_index);

%% start counter

if DAQ_ATTACHED
    send_trigger_to_initiated_lj(jo, jh, 255);
    pause(.1);
    send_trigger_to_initiated_lj(jo, jh, 0);
end

Screen('DrawText', win, 'BEGINNING...', round(screen_dim1/2), round(screen_dim2/2));
Screen('Flip', win);
pause(.5);

%% Display instructions.
Screen('DrawText', win,...
    'Please memorize the word given along with each image. Press the 0 key when you see "0"',...
    round(screen_dim1/2)-500, round(screen_dim2/2) - 100);
Screen('DrawText', win,...
    'To begin, press the G key.',...
    round(screen_dim1/2)-175, round(screen_dim2/2));
Screen('Flip', win);

str = GetSecs; [sec,~,~]=KbWait(0,0);

%% setup experiment:
quit_command = 0;

image_sequence_ = [zeros(1, ceil(N_REPS*N_TARG*.1)), repmat(target_index, 1, N_REPS)];
image_sequence = image_sequence_(randperm(length(image_sequence_)));

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
        Screen('DrawTexture', win, sym_texture_list{this_ind},...
            [],...
            [round(screen_dim1/2) - 50, round(screen_dim2/2) + 50, round(screen_dim1/2) - 50, round(screen_dim2/2) + 50]);
        trigger_value = this_ind;
        
        Screen('DrawText', win, noun_list_rand{this_ind}, ...
            round(screen_dim1/2), round(screen_dim2/2)-75);
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

    save([sub_name, '_temp'], 'image_sequence', 'stimulus_list', 'key_strokes');
    
end


%% run recall phase of experiment:
% switch of experiment trigger
if DAQ_ATTACHED
    send_trigger_to_initiated_lj(jo, jh, 255);
    pause(.1);
    send_trigger_to_initiated_lj(jo, jh, 0);
end

sym_index_rand = sym_index(randperm(length(sym_index)));
response_YN = cell(1, length(sym_index_rand));
response_conf = cell(1, length(sym_index_rand));
for i_im = 1:length(sym_index)
    % ITI
    pause(1)
    
    % show image:
    Screen('DrawTexture', win, sym_texture_list{sym_index_rand(i_im)});
    Screen('DrawText', win,...
        'Have you seen this symbol?',...
        round(screen_dim1/2)-75, round(screen_dim2/2)-100);
    
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
         '1 - did not see, 2 - may not have seen, 3 - may have seen, 4 - did see',...
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
    save([sub_name, 'response_temp'], 'image_sequence', 'stimulus_list', 'key_strokes', 'response_YN', 'response_conf');
%     pause
end

%% Shut down experiment:
% end of experiment trigger
if DAQ_ATTACHED
    send_trigger_to_initiated_lj(jo, jh, 255);
    pause(.1);
    send_trigger_to_initiated_lj(jo, jh, 0);
end

save([sub_name, 'ep_sl'], 'image_sequence', 'stimulus_list', 'key_strokes', 'response_YN', 'response_conf', 'target_index');

sca
