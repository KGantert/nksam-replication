function [RUN, OPT] = run_all_options()
% RUN_ALL_OPTIONS  User options of run_all: which scripts run (RUN.<script>)
%   and the defaults of the other options (OPT.*). Edit here; options given
%   per call, e.g. run_all('cache', 'fresh'), override these defaults.
%   run_all re-reads this file before every call, so no `clear` is needed.

% ======================= USER OPTIONS =======================================
% Which scripts to run (used when no 'scripts'/'groups' argument is given)
RUN.main_s3_s4_slopes        = true;   % Sec. 3-4 slope figures; Sec. 2 calibration numbers; App. C cutoffs; OA V.2
RUN.main_s5_irfs             = true;   % Sec. 5 phase diagram and IRFs                         [Dynare]
RUN.main_s5_slope_summary    = true;   % Sec. 5 tab:slope_summary                              [Dynare]
RUN.app_A_data_moments       = true;   % App. A capacity utilization moments (data)
RUN.app_A_calibration        = true;   % App. A Table A.1: full-model implied parameters        [Dynare]
RUN.app_A_build_data         = false;  % App. A: rebuild data/data.mat from data/raw/ (data.mat is shipped)
RUN.online_IV_equivalence    = true;   % OA IV  equivalence classes table
RUN.online_V1_steady_states  = true;   % OA V.1 steady-state figures
RUN.online_V3_efficiency_irfs= true;   % OA V.3 matching-efficiency IRFs                       [Dynare]
RUN.online_V4_emp_checks     = true;   % OA V.4 tab:emp_checks                                 [Dynare]
RUN.online_VI_robustness     = true;   % OA VI (and Sec. 6) robustness figures and tables      [Dynare]
RUN.online_VI_fixed_kapP     = true;   % OA VI  check 5: Phillips-curve slopes, fixed kappa_P
RUN.online_VI_rigidity_grid  = true;   % OA VI  price vs wage rigidity grid (lambda_P x lambda_W)  [Dynare]
RUN.diag_kapP_switch         = false;  % diagnostic: kappa_P calibration modes are inverses
RUN.diag_quality_search      = false;  % diagnostic: gamma_P range of check 2                  [Dynare]
RUN.diag_data_gaps           = false;  % diagnostic: model-implied gaps vs. US data
RUN.diag_slope_paths         = false;  % diagnostic: aggregate slopes horizon by horizon, moment-based beta [Dynare]
RUN.diag_shock_persistence   = false;  % diagnostic: IRFs with more persistent shocks (rho_A = 0.95, rho_Z = 0.9, others 0.8) [Dynare]
RUN.diag_phase_diagram_capital = false; % diagnostic: phase diagram with capital and utilization (fixed/variable), no analytical thresholds [Dynare]
% Other options
OPT.cache          = 'auto';   % 'auto' | 'fresh' | 'reuse'
OPT.seed           = 1;        % random seed of all simulations
OPT.copy_to_paper  = false;    % copy differing figures/tables into ../1_nksam_paper/
OPT.cleanup_dynare = true;     % delete Dynare's build output after each Dynare script
OPT.stop_on_error  = false;
OPT.close_figures  = true;     % false: keep all MATLAB figure windows open (before each script and at the end)
% ============================================================================
