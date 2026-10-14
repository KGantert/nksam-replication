% compute_default_scenarios.m  (lib) -- script
% -------------------------------------------------------------------------
% The four scenarios of the Section 5 IRF figures and phase diagram
% (scripts/main_s5_irfs.m) and of Online Appendix V.3
% (scripts/online_V3_efficiency_irfs.m). Cached in cache/default_scenarios.mat
% (deleted by lib/check_cache_signature.m when calibration/model/code change).
%
% REQUIRES: lib/setup_dynare.m run in this workspace (base_cfg, ranges, dynare_opts).
% PROVIDES: res_1 (1x4 struct array: (1) Benchmark, (2) Matching
%   Complements, (3) Cobb-Douglas (Gamma_Q ~ 0), (4) CES (Gamma_Q = subQ_mid)),
%   default_scenario_legend, default_scenario_styles.
% -------------------------------------------------------------------------
cache_dir  = nksam_path('cache');
cache_file = nksam_path('cache', 'default_scenarios.mat');

if exist(cache_file, 'file')
    load(cache_file, 'res_1');
else
    s = base_cfg; s.target.cuss  = 1; s.target.dnss = 1e-4; s.parSAM.gamQ = 1e-4; s.parSAM.subQ = ranges.subQ_high; scen{1} = s;
    s = base_cfg;                         s.parSAM.subQ = ranges.subQ_low;  scen{2} = s;
    s = base_cfg;                         s.parSAM.subQ = ranges.subQ_high; scen{3} = s;
    s = base_cfg;                         s.parSAM.subQ = ranges.subQ_mid;  scen{4} = s;

    res_1 = arrayfun(@(k) dynare_scenario(scen{k}, dynare_opts), 1:4);

    if ~exist(cache_dir, 'dir'); mkdir(cache_dir); end
    save(cache_file, 'res_1');
    clearvars s scen;
end

default_scenario_legend = {"", "Benchmark", "Perfect Complements (\Gamma_Q \rightarrow -\infty)", ...
                            "Cobb-Douglas (\Gamma_Q \approx 0)", ...
                            sprintf("CES (\\Gamma_Q = %g)", ranges.subQ_mid)};   % 2026-09-23: aligned with paper text (was "Full Model (CB)")
default_scenario_styles = [astyle(col_gray, 1), ...
                            lstyle(col_blue,   'x', '-'), ...
                            lstyle(col_orange, 'v', '-'), ...
                            lstyle(col_yellow, 'o', '-')];
