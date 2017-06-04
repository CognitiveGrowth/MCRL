%% Import data from text file.
% Script for importing data from the following text file:
%
%    /Users/Falk/Dropbox/PhD/Metacognitive RL/MCRL/experiments/data/human/0.6/trials_matlab.csv
%
% To extend the code to different selected data or a different text file,
% generate a function instead of a script.

% Auto-generated by MATLAB on 2017/06/03 18:42:03

%% Initialize variables.
filename = '/Users/Falk/Dropbox/PhD/Metacognitive RL/MCRL/experiments/data/human/0.6/trials_matlab.csv';
delimiter = ',';
startRow = 2;

%% Format string for each line of text:
%   column1: double (%f)
%	column2: double (%f)
%   column3: double (%f)
%	column4: double (%f)
%   column5: double (%f)
%	column6: double (%f)
%   column7: double (%f)
%	column8: double (%f)
%   column9: double (%f)
%	column10: double (%f)
%   column11: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';

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
VarName1 = dataArray{:, 1};
pid = dataArray{:, 2};
info_cost = dataArray{:, 3};
PR_type = dataArray{:, 4};
message = dataArray{:, 5};
trial_index = dataArray{:, 6};
trial_i = dataArray{:, 7};
score = dataArray{:, 8};
relative_score = dataArray{:, 9};
n_click = dataArray{:, 10};
early_click = dataArray{:, 11};


%% Clear temporary variables
clearvars filename delimiter startRow formatSpec fileID dataArray ans;