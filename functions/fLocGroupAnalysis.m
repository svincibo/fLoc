function fLocGroupAnalysis(sessions, clip, contrasts)
% Automated group analysis of fMRI data from fLoc localizer experiment 
% using vistasoft functions (https://github.com/vistalab/vistasoft). If
% there is an error, the code terminates the analysis of that session but
% then continues on to the next session.
% 
% INPUTS
% 1) sessions: names of sessions in ~/fLoc/data/ to analyze (cell array)
% 2) clip: number of TRs to clip from the beginning of each run (int)
% 3) contrasts (optional): custom user-defined contrasts (struct)
%      contrasts(N).active  -- active condition numbers for Nth contrast
%      contrasts(N).control -- control condition numbers for Nth contrast
%
% OUTPUTS
% 
% Parameter maps:
% By default the code generates the following voxel-wise parameters maps: 
% Beta values, Model residual error, proportion of variance explained, and
% GLM contrasts (t-values). All parameter maps are saved as .mat files in 
% ~/fLoc/data/*/GLMs/ and can be viewed by calling 'mrVista' in a fully 
% processed session directory, setting the "Data Type" to GLMs, and then 
% loading a parameter map from the file menu. 
% 
% Logfiles:
% The group analysis code generates two logfiles in each session directory:
%   fLocAnalysis_log.txt -- logs high-level progress of analysis
%   vistasoft_log.txt    -- logs all vistasoft screen output
% 
% AS 7/2018


%% Check and validate inputs and path to vistasoft

% check for missing or empty inputs
if nargin < 1 || isempty(sessions)
    error('Missing "sessions" argument: specify session directories in ~/fLoc/data/.');
end
if nargin < 2 || isempty(clip)
    error('Missing "clip" argument: specify how many TRs to clip from beginning of each run.')
elseif length(clip) == 1
    clip = repmat(clip, 1, length(sessions));
elseif length(clip) ~= length(sessions)
    error('Length of clip argument is inconsistent with number of sessions.');
end
if nargin < 3 || isempty(contrasts)
    contrasts = [];
end

% check for vistasoft function in your path
if isempty(which('mrVista'))
    vista_path = 'https://github.com/vistalab/vistasoft';
    error(['Add vistasoft to your matlab path: ' vista_path]);
end

% analyze each session quietly and capature vistasoft output in logfile
start_dir = pwd; err_vec = zeros(1, length(sessions));
for ss = 1:length(sessions)
    try
        fprintf('\nStarting analysis of session %s. \n', sessions{ss});
        [T, err_vec(ss)] = evalc('fLocAnalysis(sessions{ss}, clip(ss), contrasts)');
        fid = fopen('vistasoft_log.txt', 'w+'); fprintf(fid, '%s', T); fclose(fid);
    catch
        err_vec(ss) = 1;
    end
    if err_vec(ss) == 1
        fprintf('Error in analysis of session %s. See fLocAnalysis_log.txt for more information. \n\n', sessions{ss});
    else
        fprintf('Completed analysis of session %s. \n\n', sessions{ss});
    end
    clear global; % this is critical to prevent mixing of session parameters
end
cd(start_dir);
fprintf('\nAnalysis finished without error in %i of %i sessions. \n', ...
    sum(~err_vec), length(err_vec));
if sum(err_vec == 1) > 0
    sprintf('See fLocAnalyis_log.txt to debug errors in the analysis of %s. ', ...
        strjoin(sessions(err_vec), ', '));
end

end