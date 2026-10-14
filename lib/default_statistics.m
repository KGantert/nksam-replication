% default_statistics.m  (lib) -- second-moment tables for one model variant
% Script (runs in the caller's workspace), called by scripts/online_V4_emp_checks.m.
%
% Needs in the workspace (from lib/setup_dynare.m and the caller):
%   stat_benchmark  - 1 = benchmark NK (no goods market SaM), 0 = NK-SaM
%   homeprod        - 1 = with home production, 0 = without
%   dynare_opts, base_cfg, ranges
%
% Output (correlations / relative standard deviations with real GDP, each
% shock simulated in isolation, one-sided HP filter):
%   relstdtab, corrtab - 5 shocks: TFP, Policy, Cost-Push, Search, Matching Eff.

% =========================================================================
% 1. BUILD BASE CFG FOR THIS TABLE VARIANT
% =========================================================================
cfg = base_cfg;

% No-SaM overrides: shut off goods-market search-and-matching
if stat_benchmark == 1
    cfg.parSAM.gamQ  = 1e-4;
    cfg.parSAM.subQ  = ranges.subQ_high;
    cfg.target.cuss  = 1;
    cfg.target.dnss  = 1e-4;
end

% No-HP overrides: shut off home production
% DESIGN INVARIANT: home production is ON in the benchmark whenever it is ON
% in the NK-SaM model; `homeprod` must never be conditioned on stat_benchmark.
if homeprod == 0
    cfg.parHW.gamH       = 0.02;
    cfg.parHW.subH       = 1e-4;
    cfg.target.hnss      = 1e-4;
    cfg.target.chgdpss   = 1e-4;
end

% =========================================================================
% 2. SHOCK-ISOLATION SWEEP (lib/run_shock_isolation_sweep.m, cached per
%    variant and shared with diagnostics/diag_slope_paths.m)
% =========================================================================
var_sim_select = dynare_opts.var_sim_select;
n_vars         = numel(var_sim_select);

if stat_benchmark == 1
    cache_tag = 'benchmark';
else
    cache_tag = 'saam';
end
[relstd_TIME, corr_TIME] = run_shock_isolation_sweep(cfg, dynare_opts, cache_tag);

% =========================================================================
% 4. OUTPUT TABLES: TFP(1), Monetary Policy(3), Cost-Push(4), Search(6),
%    Matching Eff.(5) -- column order [1,3,4,6,5] (tab:emp_checks)
% =========================================================================
relstd_TAB = squeeze(relstd_TIME(:,1,:));
corr_TAB   = squeeze(corr_TIME(:,1,:));

relstdtab = array2table(round(relstd_TAB(:,[1,3,4,6,5]),2), ...
    'VariableNames', ["TFP", "Policy", "Cost-Push", "Search", "Matching Eff."], ...
    'RowNames', var_sim_select)

corrtab = array2table(round(corr_TAB(:,[1,3,4,6,5]),2), ...
    'VariableNames', ["TFP", "Policy", "Cost-Push", "Search", "Matching Eff."], ...
    'RowNames', var_sim_select)
