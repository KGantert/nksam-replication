% app_A_build_data.m -- Appendix A: builds data/data.mat from the raw data in data/raw/
% -------------------------------------------------------------------------
% data/data.mat is shipped with the package; this script documents and
% reproduces it (RUN.app_A_build_data = false by default in run_all_options.m).
% Before overwriting data.mat it compares the rebuilt series with the
% existing file and reports the largest absolute difference.
%
% INPUTS (data/raw/)
%   GDP, GDPC1, GDPPOT, NROU, TCU, UNRATE, CPIAUCSL .xlsx
%       FRED downloads (sheet "Quarterly", quarterly aggregates as delivered
%       by FRED), files created 2025-08-05
%   labor_wedge.xls
%       labor wedges of Karabarbounis (2014, RED), sheet "Labor Wedge
%       Quarterly", 1964-2011, tax-unadjusted; four measures that differ in
%       the data for hours worked per person (wedge_OR, wedge_CPU,
%       wedge_CES/CPS, wedge_CES/PRO)
%   cu_obs.csv
%       service-adjusted capacity utilization, cyclical component,
%       1967Q1-2023Q4 (FRED TCU combined with EU service-sector capacity
%       utilization from the European Commission's Business and Consumer
%       Surveys, mapped to the US through its standard deviation and
%       correlation with industry utilization; Appendix A)
% OUTPUT
%   data/data.mat: one column per series on the quarterly grid of GDP
%   (1947Q1-2025Q2, 314 quarters, NaN outside each series' sample), plus
%   observation_date and cu_obs (228 quarters from 1967Q1).
% -------------------------------------------------------------------------
clear; clc;
addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));
rawdir = fullfile(nksam_path('data'), 'raw');

% ---- FRED series on the GDP date grid ------------------------------------
fred = {'GDP', 'GDPC1', 'GDPPOT', 'UNRATE', 'NROU', 'TCU', 'CPIAUCSL'};
T    = readtable(fullfile(rawdir, 'GDP.xlsx'), 'Sheet', 'Quarterly');
data = struct();
data.observation_date = T.observation_date;
grid = data.observation_date;
for k = 1:numel(fred)
    Tk = readtable(fullfile(rawdir, [fred{k} '.xlsx']), 'Sheet', 'Quarterly');
    data.(fred{k}) = align(grid, Tk.observation_date, Tk.(fred{k}));
end

% ---- Labor wedges, Karabarbounis (2014) ----------------------------------
W  = readtable(fullfile(rawdir, 'labor_wedge.xls'), 'Sheet', 'Labor Wedge Quarterly', ...
               'VariableNamingRule', 'preserve');
wd = datetime(W.year, 3 * (W.quarter - 1) + 1, 1);
wedges = {'wedge_OR', 'wedge_CPU', 'wedge_CES/CPS', 'wedge_CES/PRO'};
for k = 1:numel(wedges)
    data.(strrep(wedges{k}, '/', '_')) = align(grid, wd, W.(wedges{k}));
end

% ---- Service-adjusted capacity utilization --------------------------------
C = readtable(fullfile(rawdir, 'cu_obs.csv'));
data.cu_obs = C.cu_obs;

% ---- Compare with the shipped data.mat, then save -------------------------
out = nksam_path('data', 'data.mat');
if isfile(out)
    old = load(out);
    f   = setdiff(fieldnames(data), {'observation_date'});
    dev = 0;
    for k = 1:numel(f)
        if ~isfield(old, f{k}) || numel(old.(f{k})) ~= numel(data.(f{k}))
            fprintf('  %s: missing or different length in the existing data.mat\n', f{k});
            dev = Inf;
            continue;
        end
        a = old.(f{k})(:); b = data.(f{k})(:);
        if ~isequal(isnan(a), isnan(b)); dev = Inf; end
        dev = max([dev; abs(a(~isnan(a)) - b(~isnan(a)))]);
    end
    fprintf('app_A_build_data: largest absolute difference to the existing data.mat: %g\n', dev);
end
save(out, '-struct', 'data');
fprintf('app_A_build_data: wrote %s\n', out);

% -------------------------------------------------------------------------
function y = align(grid, d, x)
% Values x observed at dates d, placed on the date grid (NaN elsewhere).
y = NaN(numel(grid), 1);
[tf, loc] = ismember(dateshift(d, 'start', 'day'), dateshift(grid, 'start', 'day'));
y(loc(tf)) = x(tf);
end
