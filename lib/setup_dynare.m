% setup_dynare.m  (lib) -- shared preamble of every script using the full
% nonlinear NK-SaM model in Dynare (Section 5, Online Appendix V-VI)
% -------------------------------------------------------------------------
% Run as the FIRST line of a script:
%   run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));
% Clears the workspace, puts the codebase on the path, checks the cache
% signature (lib/check_cache_signature.m), sets the simulation and figure
% settings, loads the calibration (get_params('dynare')) and runs the Dynare
% preprocessor once on model/nk_time.dyn. Each scenario is then solved by
% lib/dynare_scenario.m without re-running the preprocessor.
%
% PROVIDES: dynare_opts, base_cfg, base_plot_cfg, par, parHW, parSAM, shock,
%   target, ranges, homeprod, style helpers (lstyle, astyle, col_*),
%   shocks_std/shock_labels_std/shock_tags_std, repo_root, model_dir.
% Dynare writes its build output (model/nk_time/, model/+nk_time/, and
% nk_time/ in the current folder); lib/cleanup_dynare_output.m deletes it at
% the end of every Dynare script.
% -------------------------------------------------------------------------
clear all; clc;

this_file_dir = fileparts(mfilename('fullpath'));       % <codebase>/lib
repo_root     = fileparts(this_file_dir);               % <codebase>
model_dir     = fullfile(repo_root, 'model');

addpath(genpath(repo_root));
check_cache_signature(repo_root);   % deletes all caches if calibration/model/code changed

% =========================================================================
% 1. DYNARE / SIMULATION SETTINGS
% =========================================================================
dynare_opts.approxorder      = 1;
dynare_opts.irfperiod        = 12;
dynare_opts.simperiod        = 200000;
dynare_opts.replicnumber     = 5;
dynare_opts.simreplicnumber  = 5;
dynare_opts.dropnumber       = 20000;

dynare_opts.var_sim_select ...
    = ["gdp_obs", "gdp_gap", "ue_gap", "piC", "w_obs", "cu", ...
       "mc_obs", "ped_obs", "lw_obs", "d_obs", "ue"];
% NOTE: "ue" is APPENDED, never inserted -- see lib/default_statistics.m.

% =========================================================================
% 2. FIGURE SETTINGS
% =========================================================================
fig_width  = 21; fig_height = 9; fig_font = 7; fig_layout = [3 3];

var_select   = ["gdp_obs", "gdp_gap", "ue_gap", "piC", "w_obs", ...
                 "cu", "ped_obs", "lw_obs", "d_obs"];
title_select = ["Real GDP", "Output Gap", "Unemployment Gap", "Inflation", ...
                 "Real Wage", "Capacity Utilization", ...
                 "Price Elasticity", "Labor Wedge", "Search Effort"];
unit_select  = ["%-Dev.", "%-Dev.", "pp-Dev.", "pp-Dev.", "%-Dev.", ...
                 "pp-Dev.", "%-Dev.", "%-Dev.", "pp-Dev. (Mkt. Work)"];

shocks_std       = ["eA",  "eM",              "eD",           "eT",                   "eP"];
shock_labels_std = ["TFP", "Monetary Policy",  "Search Effort","Matching Efficiency", "ε-Cost-Push"];   % figure window names only
shock_tags_std   = ["tfp", "policy",           "search",       "efficiency",          "eis"];

% =========================================================================
% 3. DEFAULT SCENARIO CONFIGURATION
% =========================================================================
base_cfg = struct();
base_cfg.switches.ghh_pref     = 0;
base_cfg.switches.labor_ext    = 1;
base_cfg.switches.dAP          = 0;
base_cfg.switches.nkpc_target  = 1;
base_cfg.switches.markup_stst  = 1;
base_cfg.switches.ls_target    = 0;

homeprod = 0;   % 1 = with home production, 0 = without (read by default_statistics.m; set to 1 in online_V4_emp_checks.m)

base_plot_cfg.var_select   = var_select;
base_plot_cfg.title_select = title_select;
base_plot_cfg.unit_select  = unit_select;
base_plot_cfg.fig_size     = [fig_width fig_height];
base_plot_cfg.font_size    = fig_font;
base_plot_cfg.layout       = fig_layout;

% =========================================================================
% 4. CALIBRATION
% =========================================================================
[par, parHW, parSAM, shock, target, ranges] = get_params('dynare');

% =========================================================================
% 5. STYLE HELPERS
% =========================================================================
lstyle = @(c, mk, ls) struct('type','line', 'color',c, 'marker',mk, 'linestyle',ls, 'alpha',1);
astyle = @(c, a)      struct('type','area', 'color',c, 'marker','', 'linestyle','', 'alpha',a);

col_gray   = [0.70 0.70 0.70];
col_blue   = [0.00 0.45 0.74];
col_orange = [0.85 0.33 0.10];
col_yellow = [0.93 0.69 0.13];
col_purple = [0.49 0.18 0.56];
col_green  = [0.47 0.67 0.19];

% =========================================================================
% 6. ONE-TIME DYNARE PREPROCESSING
% =========================================================================
assignin('base', 'ghh_pref',    base_cfg.switches.ghh_pref);
assignin('base', 'labor_ext',   base_cfg.switches.labor_ext);
assignin('base', 'dAP',         base_cfg.switches.dAP);
assignin('base', 'nkpc_target', base_cfg.switches.nkpc_target);
assignin('base', 'markup_stst', base_cfg.switches.markup_stst);
assignin('base', 'ls_target',   base_cfg.switches.ls_target);

cd(model_dir);
eval(['dynare nk_time.dyn'                                          ...
    ' -Dreplic_number='       num2str(dynare_opts.replicnumber)     ...
    ' -Dsimul_replic_number=' num2str(dynare_opts.simreplicnumber)  ...
    ' -Ddrop_number='         num2str(dynare_opts.dropnumber)       ...
    ' -Dapprox_order='        num2str(dynare_opts.approxorder)      ...
    ' -Dirf_periods='         num2str(dynare_opts.irfperiod)        ...
    ' -Dsim_periods='         num2str(dynare_opts.simperiod)        ...
    ' noclearall;']);
cd(repo_root);
