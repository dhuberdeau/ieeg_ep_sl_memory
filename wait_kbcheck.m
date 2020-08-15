function [sec, key] = wait_kbcheck(wait_time)

% Wait wait_time seconds and log the first key pressed (if any) in that
% time.

str = GetSecs;
key = nan;
sec = nan;
press = 0;
while (GetSecs - str) <= wait_time
    if ~press
        [press, press_time, keys] = KbCheck(0);
        WaitSecs(.05);
        if sum(keys) >= 1
            key_ = find(keys);
            key = key_(1);
            sec = press_time;
        end
    end
end