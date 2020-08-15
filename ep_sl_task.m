function  oddball_task(varargin)
Screen('Preference', 'SkipSyncTests', 1);
% kq = zeros(1, 256);
% kq(81) = 1;
% KbQueueCreate(0, kq);
% KbQueueStart();

addpath(genpath(pwd))

sub_name_ = 'OB_P012';
uniqueness_code = now*10000000000;
sub_name = [sub_name_, num2str(uniqueness_code)];

screen_dims = [1980, 1020];
screen_dim1 = screen_dims(1);
screen_dim2 = screen_dims(2);

%% Intialise digital IO
interSample = .01;
[jo, jh] = initiate_labjack;
send_trigger_to_initiated_lj(jo, jh, 0);
% daqDevice = daqhwinfo('nidaq');
% daqDevName = daqDevice.InstalledBoardIds{1};
% dio = digitalio('nidaq',daqDevName); % create digital IO object
% addline(dio,0:7,0,'out'); % add 8 bit output to port 0
% putvalue(dio,0); % send 0 to wipe out code

KbQueueCreate()
KbQueueStart()
%% open screen
screens=Screen('Screens');
screenNumber=min(screens);
[win, rect] = Screen('OpenWindow', screenNumber, []); %[0 0 1600 900]);
o = Screen('TextSize', win, 24);

%% setup images:
face_texture_list = cell(1, 20);
face_index = 1:20;
face_trigger = 5:24;
sym_texture_list = cell(1,4);
sym_index = 1:4;
sym_trigger = 1:4;

im_dwell_time = .3;
iti_time = .4;

% for i_face = 1:length(face_texture_list)
%     temp_im = imread(['WM-Faces', filesep, 'WM-Faces', filesep, ...
%         'whiteMale', num2str(i_face), '.jpg']);
%     face_texture_list{i_face} = Screen('MakeTexture', win, temp_im);
% end
% symbol_file_names = {'afasa5.jpg', 'afasa6.jpg', 'afasa7.jpg', 'afasa8.jpg'};
% for i_symb = 1:length(sym_texture_list)
%     temp_im = imread(symbol_file_names{i_symb});
%     sym_texture_list{i_symb} = Screen('MakeTexture', win, temp_im);
% end

im_comm = imread('common_symbol.png');
txt_comm = Screen('MakeTexture', win, im_comm);
im_abrt = imread('aberant_symbol.png');
txt_abrt = Screen('MakeTexture', win, im_abrt);

quit_command = 0;

%% start counter
% putvalue(dio, 101);%beginning of experiment flag
send_trigger_to_initiated_lj(jo, jh, 101);
pause(.1);
send_trigger_to_initiated_lj(jo, jh, 0);
% putvalue(dio, 0);

Screen('DrawText', win, 'BEGINNING...', round(screen_dim1/2), round(screen_dim2/2));
Screen('Flip', win);
pause(.5);

%% Display instructions.
Screen('DrawText', win,...
    'Press J if you see X-symbols, and K if you see O-symbols',...
    round(screen_dim1/2)-500, round(screen_dim2/2) - 100);
Screen('DrawText', win,...
    'To begin, press the G key.',...
    round(screen_dim1/2)-175, round(screen_dim2/2));
Screen('Flip', win);
% Screen('DrawText', win,...
%     'Press J if you see a face, and K if you see a symbol',...
%     round(screen_dim1/2)-500, round(screen_dim2/2) - 100);
% Screen('DrawText', win,...
%     'To begin, press any key.',...
%     round(screen_dim1/2)-175, round(screen_dim2/2));
% Screen('Flip', win);

str = GetSecs; [sec,~,~]=KbWait(0,0);

% deviant_stimulus_list = [ones(1, 10), zeros(1, 40)]; 
% deviant_stimulus_list = deviant_stimulus_list(randperm(length(deviant_stimulus_list)));

deviant_stimulus_list = nan(16, 10);
blocks_with_double_ = [ones(1, ceil(size(deviant_stimulus_list,1)/2)), ...
    zeros(1, floor(size(deviant_stimulus_list,1)/2))];
blocks_with_double = blocks_with_double_(randperm(length(blocks_with_double_)));
block_half_seed = [1 0 0];
for i_block = 1:size(deviant_stimulus_list,1)
    block_first_half = [0 block_half_seed(randperm(length(block_half_seed))), 0];
    block_second_half = [0 block_half_seed(randperm(length(block_half_seed))), 0];
    block_zero_half = zeros(1,5);
    if blocks_with_double(i_block) == 1
        %this is a block with two odd-balls
        deviant_stimulus_list(i_block, :) = [block_first_half, block_second_half];
    else
        %this is a block with only one odd-balls
        deviant_stimulus_list(i_block, :) = [block_first_half, block_zero_half];
    end
end
deviant_stimulus_list = reshape(deviant_stimulus_list', numel(deviant_stimulus_list), 1);
deviant_stimulus_list = [zeros(10,1); deviant_stimulus_list]; %seed with 10 faces.
stimulus_list = nan(1, length(deviant_stimulus_list));
key_strokes = nan(2, length(deviant_stimulus_list));
for i_time = 1:length(deviant_stimulus_list)
%     pause(.5); %pause to wait for next image
str = GetSecs;
    while (GetSecs - str) < .5
        [key_press, ~, key_code, ~] = KbCheck;
        pause(.01);
        if key_press == 1
            key_hit = KbName(key_code);
            if isequal(key_hit, 'd') || isequal(key_hit, 'q')
                % quit command sent
                quit_command = 1;
                break
            end
        end
    end
    
    if quit_command == 1
            break
    end
    
    if deviant_stimulus_list(i_time) > 0
        %PsychPortAudio('FillBuffer', pahandle, oddball_data2);
        this_ind = sym_index(randperm(length(sym_index)));
%         Screen('DrawTexture', win, sym_texture_list{this_ind(1)});
        Screen('DrawTexture', win, txt_abrt);
        trigger_value = sym_trigger(this_ind(1));
    else
        %PsychPortAudio('FillBuffer', pahandle, sound_data2);
        this_ind = face_index(randperm(length(face_index)));
%         Screen('DrawTexture', win, face_texture_list{this_ind(1)});
        Screen('DrawTexture', win, txt_comm);
        trigger_value = face_trigger(this_ind(1));
    end
    stimulus_list(i_time) = trigger_value;
    
%     putvalue(dio, trigger_value);
    send_trigger_to_initiated_lj(jo, jh, trigger_value);
    %startTime = PsychPortAudio('Start', pahandle);
    Screen('Flip', win);
    send_trigger_to_initiated_lj(jo, jh, 0);
%     putvalue(dio, 0); %flip to show image
    
%     pause(.3) %pause to maintain image on screen for .3s seconds:
%     str = GetSecs;
%     [temp_sec, temp_key] = wait_kbcheck(.3);
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
    [temp_sec2, temp_key2] = wait_kbcheck(.4);
    
    if ~isnan(temp_key)
        key_strokes(1, i_time) = temp_key;
        key_strokes(2, i_time) = temp_sec - str;
    elseif ~isnan(temp_key2)
        key_strokes(1, i_time) = temp_key2;
        key_strokes(2, i_time) = temp_sec2 - str;
    end
        
    
%     Screen('DrawText', win, num2str(10 - i_time), round(screen_dim1/2),round(screen_dim2/2));
    %Screen('Flip', win);
    save(['oddball_', sub_name, '_temp'], 'deviant_stimulus_list', 'stimulus_list', 'key_strokes');
    
%    [pressed, firstPress, ~, ~] = KbQueueCheck;
%    if sum(pressed) > 0
%        % q was pressed
%        sca
%    end
%     ch_av = CharAvail;
%     while ch_av
%         temp_ch = GetChar;
%         if isequal(temp_ch, 'q')
%             sca;
%         end
%         ch_av = CharAvail;
%     end
end

% putvalue(dio, 102); % end of experiment trigger
send_trigger_to_initiated_lj(jo, jh, 102);
pause(.1);
send_trigger_to_initiated_lj(jo, jh, 0);
% putvalue(dio, 0);

save(['oddball_', sub_name], 'deviant_stimulus_list', 'stimulus_list', 'key_strokes');
% save(['oddball_', sub_name, '_KB'], 'key_strokes');
sca
