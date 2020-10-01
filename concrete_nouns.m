fid = fopen('concrete_nouns_list.txt');
tline = fgetl(fid);
concrete_noun = cell(1,1);
i_line = 1;
while ischar(tline)
    tline = fgetl(fid);
    concrete_noun{i_line} = tline;
    i_line = i_line + 1;
end
fclose(fid);

noun_list = concrete_noun(1:(end-1));