function summary = run_all(varargin)
% RUN_ALL  Master script: reproduces every model-based figure, table and
%   number of "When Buying Takes Time" from the scripts
%   in scripts/ (paper results) and, optionally, diagnostics/.
%
%   QUICK START: type  run_all  (USER OPTIONS: run_all_options.m)
%   Options can also be given per call (they override the block):
%     run_all('scripts', {'main_s5_irfs', 'online_VI_robustness'})  scripts by name
%     run_all('groups', {'main', 'online'})   main | appendix | online | diagnostics | all
%     run_all('cache', 'fresh')               'auto' | 'fresh' | 'reuse'
%     run_all('seed', 1)                      random seed of all simulations
%     run_all('copy_to_paper', true)
%     run_all('cleanup_dynare', false)
%     run_all('stop_on_error', true)
%     run_all('close_figures', false)         keep all figure windows open
%     run_all('list', true)                   list the scripts and exit
%     run_all('compare_only', true)           run nothing: compare the existing results
%                                             with the paper (add 'copy_to_paper', true
%                                             to copy the differing files)
%     summary = run_all(...)                  status per script
%   Selection precedence: 'scripts' > 'groups' > RUN switches.
%
%   CODEBASE
%     run_all.m (this entry point), run_all_options.m (USER OPTIONS),
%     get_params.m (calibration), README.md; the code is lib/run_all_engine.m
%     scripts/      one script per paper result, named after its place in the
%                   paper: main_s<section>_*, app_<appendix>_*, online_<appendix>_*
%     diagnostics/  checks not in the paper (diag_*)
%     lib/          shared functions and setup scripts;  model/  Dynare model
%     data/         data.mat (inputs of all scripts), raw/ (sources);  cache/  regenerable caches
%     results/      figures/ (*.eps, *.png), tables/ (*.tex, tab_*.txt, *.csv),
%                   txt/ (numbers quoted in the text, reports, logs),
%                   mat/ (intermediate results), logs/ (run_all logs)
%
%   PER SCRIPT: the MATLAB path is reset to the path at call time plus the
%   codebase (removes the subfolders `dynare` adds, so Dynare functions
%   never shadow codebase functions and no MATLAB restart is needed); the
%   script runs in the BASE workspace (scripts start with `clear all`); its
%   console output is logged to results/logs/<timestamp>/; every expected
%   output must exist and be written during the run (OK / OUTPUT MISSING /
%   OUTPUT NOT UPDATED); Dynare's build output is deleted afterwards
%   (lib/cleanup_dynare_output.m).
%
%   CACHES (option 'cache'): lib/check_cache_signature.m deletes all caches
%   in cache/ whenever get_params values, the model, the data or any file in
%   lib/ or scripts/ changed ('auto', default). 'fresh' deletes them before
%   running (final replication run); 'reuse' keeps them (figure tweaks only).
%
%   SEED (option 'seed'): set before EVERY Dynare simulation
%   (lib/dynare_scenario.m), so simulated moments do not depend on run order.
%
%   PAPER: every figure (.eps) and table (.tex) is compared in content with
%   the copy in ../1_nksam_paper/eps_figures and ../1_nksam_paper/tables
%   (export metadata such as %%CreationDate ignored); differences are listed
%   in the summary. With copy_to_paper = true the differing files are copied
%   there. Skipped if the paper folder does not exist.
%
%   REQUIREMENTS: MATLAB R2020a+ with the Optimization Toolbox; Dynare 7.2
%   with its matlab/ folder on the MATLAB path (also provides
%   one_sided_hp_filter, used for data and simulated moments).
%   Full run: about 19 minutes (Apple M-series laptop).
%
%   THIS FILE is the entry point and never needs editing: it clears all loaded
%   functions and re-reads the path before every call, so edits to
%   run_all_options.m, lib/run_all_engine.m and any script, lib/ or model file,
%   also when made outside the MATLAB editor (sync, scripts), take effect
%   without a `clear`.
clear functions; rehash;   %#ok<CLFUNC>
p0 = path;  restore_path = onCleanup(@() path(p0));   % leave the MATLAB path as it was
addpath(fullfile(fileparts(mfilename('fullpath')), 'lib'));
summary = run_all_engine(varargin{:});
end
