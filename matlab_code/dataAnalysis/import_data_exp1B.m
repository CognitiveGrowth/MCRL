%% Import data from text file.
% Script for importing data from the following text file:
%
%    /Users/Falk/Dropbox/PhD/Metacognitive RL/MCRL/experiments/data/human/1B.1/trials.csv
%
% To extend the code to different selected data or a different text file,
% generate a function instead of a script.

% Auto-generated by MATLAB on 2017/07/12 18:07:42

%% Initialize variables.
if strcmp(getenv('USER'), 'priyamdas')
    filename = 'C:\Users\piichan\Documents\Berkeley\CoCoSci Lab\mcrl\MCRL\experiments\data\human\1B.1\trials.csv';
else
    filename = '/Users/Falk/Dropbox/PhD/Metacognitive RL/MCRL/experiments/data/human/1B.1/trials.csv';
end
delimiter = ',';
startRow = 2;

%% Format string for each line of text:
%   column1: double (%f)
%	column2: double (%f)
%   column3: double (%f)
%	column4: text (%q)
%   column5: text (%q)
%	column6: double (%f)
%   column7: double (%f)
%	column8: text (%q)
%   column9: double (%f)
%	column10: double (%f)
%   column11: text (%q)
%	column12: text (%q)
%   column13: text (%q)
%	column14: text (%q)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%f%f%f%q%q%f%f%q%f%f%q%q%q%q%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Allocate imported array to column variable names
index = dataArray{:, 1};
pid = dataArray{:, 2};
info_cost = dataArray{:, 3};
PR_type = dataArray{:, 4};
message = dataArray{:, 5};
trial_index = dataArray{:, 6};
trial_i = dataArray{:, 7};
delays = dataArray{:, 8};
score = dataArray{:, 9};
n_click = dataArray{:, 10};
clicks = dataArray{:, 11};
click_times = dataArray{:, 12};
path1 = dataArray{:, 13};
action_times = dataArray{:, 14};


%% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans;

%% get clicks before 1st, 2nd, and 3rd moves
for i = 1:length(index)
    cur_clicks = str2num(clicks{i});
    cur_click_times = str2num(click_times{i});
    cur_path = str2num(path1{i});
    cur_action_times = str2num(action_times{i});
    for j = 1:length(cur_action_times)
        idx = cur_click_times < cur_action_times(j);
        eval(['clicks',num2str(j),'{i}=cur_clicks(idx);'])
    end
end

%%
nr_trials = 16;
s = 0;
for i = unique(pid)'
    s = s + 1;
    idx = pid == i;
    data(s).info_cost = info_cost(idx);
    data(s).info_cost1 = data(s).info_cost(1);
    data(s).PR_type = PR_type(idx);
    data(s).PR_type1 = data(s).PR_type{1};
    data(s).message = message(idx);
    data(s).trial_index = trial_index(idx);
    data(s).trialID = trial_i(idx);
    data(s).delays = delays(idx);
    data(s).score = score(idx);
    data(s).n_click = n_click(idx);
    data(s).clicks = clicks(idx);
    data(s).click_times = click_times(idx);
    cur_path = path1(idx);
    for j = 1:length(cur_path)
        data(s).path1{j} = str2num(cur_path{j});
    end
    data(s).action_times = action_times(idx);
    data(s).clicks1 = clicks1(idx);
    data(s).clicks2 = clicks2(idx);
    data(s).clicks3 = clicks3(idx);
    
    for j = 1:nr_trials
        data(s).click_locations_before_first_move{data(s).trialID(j)+1} = data(s).clicks1{j};
        data(s).click_locations{data(s).trialID(j)+1} = data(s).clicks{j};
    end
end
