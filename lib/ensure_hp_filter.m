function ensure_hp_filter()
% ENSURE_HP_FILTER  Make Dynare's one_sided_hp_filter available.
%   The one-sided HP filter (lambda = 1600) of the data (lib/load_nksam_data.m,
%   scripts/app_A_data_moments.m) and of the simulated data
%   (lib/dynare_scenario.m) is Dynare's one_sided_hp_filter. If only Dynare's
%   matlab/ root is on the path and the function sits in a subfolder, this
%   runs dynare_config (which adds Dynare's subfolders) once.
if ~isempty(which('one_sided_hp_filter')); return; end
if isempty(which('dynare_config'))
    error('ensure_hp_filter:dynare', ['Dynare is not on the MATLAB path ' ...
        '(needed for one_sided_hp_filter). Add Dynare''s matlab/ folder, e.g. ' ...
        'addpath(''/Applications/Dynare/7.2/matlab'').']);
end
evalc('dynare_config');
if isempty(which('one_sided_hp_filter'))
    error('ensure_hp_filter:missing', 'one_sided_hp_filter not found in this Dynare installation.');
end
end
