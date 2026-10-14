% app_A_data_moments.m -- Appendix A: capacity utilization moments in the data
% -------------------------------------------------------------------------
% PRODUCES
%   results/txt/data_moments.txt   corr(cu, Y) and sd(cu)/sd(Y), 1984Q1-2019Q4,
%                                  quoted in the Introduction, Appendix A,
%                                  Online Appendix V.4 (sec:emp_checks_add) and
%                                  Section 6 / Online Appendix VI (tab:robust_full)
%
% Data (data/data.mat):
%   cu_obs  - service-adjusted capacity utilization (Gantert, 2025 measure:
%             FRED TCU combined with EU service-sector utilization, see
%             Appendix A), cyclical component, 1967Q1-2023Q4
%   GDPC1   - FRED real GDP, 1947Q1-2025Q2
%   TCU     - FRED capacity utilization (industry), for the raw mean
% Real GDP: log x 100, one-sided HP filter (lambda = 1600, Dynare's
% one_sided_hp_filter, as for the simulated data and lib/load_nksam_data.m),
% filtered from 1967Q1 (start of the capacity utilization series).
% Previous result (local recursive one-sided HP filter, 2026-09-29):
%   corr = 0.40, sd ratio = 1.51, sd(cu) = 1.96%, sd(Y) = 1.29%.
% -------------------------------------------------------------------------
clear; clc;
addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));
ensure_hp_filter();   % Dynare's one_sided_hp_filter
raw = load(nksam_path('data', 'data.mat'));

nobs   = numel(raw.GDPC1);                  % 1947Q1 = 1
i_cu0  = 81;                                % 1967Q1
cu     = NaN(nobs, 1);
cu(i_cu0:i_cu0+numel(raw.cu_obs)-1) = raw.cu_obs(:) .* 100;

y      = NaN(nobs, 1);
[~, y(i_cu0:end)] = one_sided_hp_filter(log(raw.GDPC1(i_cu0:end)) .* 100, 1600);

i0 = 149;   % 1984Q1
i1 = 292;   % 2019Q4
c  = cu(i0:i1);  g = y(i0:i1);
R  = corrcoef(c, g);

L = {'Capacity utilization vs. real GDP, 1984Q1-2019Q4 (app_A_data_moments.m)', ...
     sprintf('  corr(cu, Y)    = %.2f', R(1,2)), ...
     sprintf('  sd(cu) / sd(Y) = %.2f', std(c) / std(g)), ...
     sprintf('  sd(cu)         = %.2f %%', std(c)), ...
     sprintf('  sd(Y)          = %.2f %%', std(g)), ...
     sprintf('  mean(TCU raw)  = %.1f %% (industry only; service-adjusted mean: 86%%, Appendix A)', mean(raw.TCU(i0:i1)))};
fprintf('%s\n', L{:});
fid = fopen(nksam_path('txt', 'data_moments.txt'), 'w');
if fid == -1; error('app_A_data_moments: cannot write data_moments.txt'); end
fprintf(fid, '%s\n', L{:});
fclose(fid);
