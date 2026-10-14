% online_VI_robustness.m -- Online Appendix VI (sec:robust) and Section 6: robustness checks
% -------------------------------------------------------------------------
% PRODUCES (chapters/online_appendix/ap_robustness.tex, summarized in chapters/robustness.tex):
%   results/figures/fig_robust_<tag>.eps     one IRF figure per check, fig:robust_<tag>,
%                                            tag = calib, qs, iq, longterm (part A), kapP, kapPci, kapW (part B),
%                                            nohp, ghh, hours, capital (part C); kapcorner (literature
%                                            combinations of the two slopes): table rows only
%   results/tables/tab_robust_regimes.tex    rows of tab:robust_regimes (Table VI.2; \input by the paper from tables/)
%   results/tables/tab_robust_magnitudes.tex rows of tab:robust_magnitudes (Table VI.3) (2026-10-11 restructure)
%   results/txt/robustness_summary.txt       all numbers, steady states and parameters per check
%   results/txt/robustness_log.txt           console log
%   results/mat/robustness_summary.mat       table numbers per variant
% Check 5 (fixed kappa_P) has a second figure, fig:robust_kapP_pc: online_VI_fixed_kapP.m.
% The (NKPC_Slope, NKWPC_Slope) grid behind checks 6, 7 and the literature combinations: online_VI_rigidity_grid.m.
% Numbering (2026-10-09): three parts. A goods market SaM only (benchmark unchanged): 1-4;
% B Phillips-curve calibration: 5-7; C shared model structure (both models change): 8-11.
%
% DESIGN
%   - Eleven checks plus the literature combinations, each along ONE dimension of the
%     main model, with one or more variants, defined in lib/robust_define_checks.m
%     (array positions 1-11 = check numbers, position 12 = literature combinations):
%       Part A (goods market SaM only)
%         1 calibration: gamma_Q in {0.11, 0.32} x nu_D/nu_N in {0.5, 1, 1.5}
%         2 quality search: gamma_P = 0.1 and 0.16
%         3 firm-specific search convexity (I_Q = 1)
%         4 long-term trade relationships (delta_T), inventories (delta_I), both
%       Part B (Phillips-curve calibration)
%         5 kappa_P fixed at the benchmark value instead of targeting the slope
%         6 price rigidity: NKPC_Slope at the bounds of its 95% CI (ranges.nkpc_ci);
%           flexible prices (kappa_P = 0)
%         7 wage rigidity: NKWPC_Slope at the bounds of its 95% CI (ranges.nkwpc_ci);
%           flexible wages (kappa_W = 0)
%         -- adverse literature combinations of the two slopes (ranges.kap_corner;
%           table rows only, no figure; tabulated after check 7)
%       Part C (shared model structure)
%         8 no home production        9 GHH preferences
%        10 employment adjustment costs (kappa_N = ranges.phiN_act) at the baseline
%           kappa_W and at the bounds of its 95% CI
%        11 capital with fixed and with variable utilization
%   - Figure (lib/plot_robust_grid.m): rows = 8 variables, columns = 4 shocks
%     (monetary policy, search effort, technology, epsilon-cost-push); all
%     lines divided by the baseline NK-SaM impact real-GDP response. Grey =
%     benchmark, orange = NK-SaM; solid = baseline, dashed / dash-dotted /
%     dotted = variants.
%   - Table: lib/robust_write_summary.m. A failing check is reported and
%     skipped; the others still run.
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));

% ======================= USER OPTIONS =====================================
% checks_to_run: checks to solve (or load from a valid cache) and re-plot; all
% OTHER checks are only loaded from cache, so the table stays complete.
% [] = rebuild the table only. Caches (cache/robust_*.mat) are reused only if
% calibration, model and code are unchanged (lib/check_cache_signature.m and
% the per-check signature in lib/robust_cached.m).
checks_to_run = 1:12;  % array positions in lib/robust_define_checks.m (1-11 = checks, 12 = literature combinations); others are loaded from cache
% ==========================================================================

cache_dir = nksam_path('cache');
log_file  = nksam_path('txt', 'robustness_log.txt');
if exist(log_file, 'file'), delete(log_file); end
diary(log_file); diary on;
fprintf('online_VI_robustness.m -- %s\n', datestr(now));

dynare_opts.keep_sim = false;   % moments are enough; saves memory

% ---- plot configuration ----------------------------------------------------
g.shocks        = ["eM", "eD", "eA", "eP"];
g.shock_titles  = ["Monetary Policy", "Search Effort", "Technology", "\epsilon-Cost-Push"];
g.no_bench_shock = 'eD';                 % benchmark has no search-effort shock
g.dir_shocks    = ["eM", "eA", "eP"];    % direction reading (tab:robust_regimes)
g.vars          = ["gdp_obs", "gdp_gap", "ue_gap", "piC", "w_obs", "cu", "ped_obs", "lw_obs"];
g.var_titles    = ["Real GDP", "Output Gap", "Unempl. Gap", "Inflation", ...
                   "Real Wage", "Cap. Utilization", "Price Elasticity", "Labor Wedge"];
g.col_bench     = [0.45 0.45 0.45];
g.col_sam       = col_orange;
g.marker_size   = 3;
g.lw_base       = 1.2;
g.lw_ext        = 1.0;
g.fig_size      = [16 20.5];             % cm; included at \textwidth
g.font_size     = 7;

% ---- baseline models -------------------------------------------------------
% Benchmark: goods market SaM switched off exactly as in
% compute_default_scenarios.m / default_statistics.m. NK-SaM: base_cfg, as in
% default_statistics.m (tab:emp_checks), so the baseline row reproduces it.
nk_cfg = base_cfg;
nk_cfg.parSAM.gamQ = 1e-4;
nk_cfg.parSAM.subQ = ranges.subQ_high;
nk_cfg.target.cuss = 1;
nk_cfg.target.dnss = 1e-4;
sam_cfg = base_cfg;

gp  = struct('par', par, 'parHW', parHW, 'parSAM', parSAM, 'shock', shock, ...
             'target', target, 'ranges', ranges, 'irfperiod', dynare_opts.irfperiod);
sig = struct('gp', gp, 'nk_cfg', nk_cfg, 'sam_cfg', sam_cfg);

fprintf('\n== Baseline (benchmark, NK-SaM, NK-SaM search-effort-only) ==\n');
base = robust_cached(fullfile(cache_dir, 'robust_baseline.mat'), sig, false, ...
    @() struct('nk',  robust_solve(nk_cfg,  dynare_opts), ...
               'sam', robust_solve(sam_cfg, dynare_opts), ...
               'iso', robust_iso_stats(sam_cfg, dynare_opts)));

% ---- checks ----------------------------------------------------------------
checks = robust_define_checks(par, target, ranges);
nC     = numel(checks);
outs   = cell(1, nC);
run_ok = false(1, nC);
fac    = NaN(nC, numel(g.shocks));

for c = 1:nC
    chk   = checks(c);
    sig_c = struct('base', sig, 'chk', chk);
    cfile = fullfile(cache_dir, ['robust_' chk.tag '.mat']);
    if isnan(chk.num), cnum = '--'; else, cnum = sprintf('%d', chk.num); end
    fprintf('\n== %s. %s ==\n', cnum, chk.title);
    if ~ismember(c, checks_to_run)
        % not re-solved: load from cache (if valid) so the table stays complete
        outs{c}   = robust_cached(cfile, sig_c, false, []);
        run_ok(c) = ~isempty(outs{c});
        continue;
    end
    try
        outs{c}   = robust_cached(cfile, sig_c, false, ...
                                  @() robust_run_check(chk, nk_cfg, sam_cfg, dynare_opts));
        if ~(isfield(chk, 'no_figure') && isequal(chk.no_figure, true))
            fac(c, :) = plot_robust_grid(base, outs{c}, chk, g);
        end
        run_ok(c) = true;
    catch ME
        fprintf(2, '  *** %s FAILED: %s\n', chk.tag, ME.message);
        for kk = 1:numel(ME.stack)
            fprintf('      at %s (line %d)\n', ME.stack(kk).name, ME.stack(kk).line);
        end
    end
end

% ---- static channel slopes (reduced-form model) -----------------------------
fprintf('\n== Static channel slopes (reduced-form model) ==\n');
S = robust_static_slopes(checks);

% ---- table rows + summary --------------------------------------------------
fprintf('\n== Summary ==\n');
robust_write_summary(checks, base, outs, S, run_ok, g);
fprintf('normalization factors 1/Y_0 (rows = checks, cols = %s):\n', strjoin(g.shocks, ', '));
disp(fac);
fprintf('checks OK: %s | failed/not run: %s\n', ...
        mat2str(find(run_ok)), mat2str(setdiff(1:nC, find(run_ok))));

diary off;

% -- Delete Dynare's regenerable build output (option: lib/cleanup_dynare_output.m)
cleanup_dynare_output();
