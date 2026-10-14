function [relstd_TIME, corr_TIME] = run_shock_isolation_sweep(cfg, dynare_opts, cache_tag)
% RUN_SHOCK_ISOLATION_SWEEP  Full relstd/corr arrays from isolating each of
%   the 6 canonical shocks in turn.
%
%   [relstd_TIME, corr_TIME] = RUN_SHOCK_ISOLATION_SWEEP(cfg, dynare_opts, cache_tag)
%
%   cfg          - scenario configuration struct, as passed to
%                  dynare_scenario (e.g. base_cfg, or base_cfg with the
%                  SaM/home-production overrides for a "benchmark" variant)
%   dynare_opts  - simulation options struct (must include var_sim_select)
%   cache_tag    - string identifying this cfg variant, e.g. "benchmark"
%                  or "saam". Used only for the cache filename below.
%
%   Returns the full [n_vars x n_vars x 6] relstd_TIME/corr_TIME arrays
%   (one n_vars x n_vars relstd/corr matrix per shock, in the canonical
%   order rhoA/rhoZ/rhoM/rhoP/rhoT/rhoD), from which any caller can select
%   whichever reference-variable column and shock-column subset it needs
%   (lib/default_statistics.m uses the gdp_obs-relative column for
%   tab:emp_checks; diagnostics/diag_slope_paths.m the gdp_gap-relative
%   column for the gap moments).
%
% CACHING: cache/shock_sweep_<cache_tag>.mat. The "benchmark" and "saam"
% configurations of online_V4_emp_checks.m and diag_slope_paths.m are
% identical (goods market SaM off via parSAM.gamQ = 1e-4, parSAM.subQ =
% ranges.subQ_high, target.cuss = 1, target.dnss = 1e-4; home production
% ON), so whichever runs second reuses the first's sweep. Caches are
% deleted by lib/check_cache_signature.m whenever calibration, model or
% code change.
% -------------------------------------------------------------------------

all_rho = ["rhoA", "rhoZ", "rhoM", "rhoP", "rhoT", "rhoD"];
all_std = ["stdA", "stdZ", "stdM", "stdP", "stdT", "stdD"];
n_shock = numel(all_rho);
n_vars  = numel(dynare_opts.var_sim_select);

cache_dir     = nksam_path('cache');
cache_file    = nksam_path('cache', sprintf('shock_sweep_%s.mat', cache_tag));

if exist(cache_file, 'file')
    load(cache_file, 'relstd_TIME', 'corr_TIME');
    fprintf('run_shock_isolation_sweep: reusing cached "%s" sweep (delete %s to force a re-run).\n', ...
        cache_tag, cache_file);
    return;
end

relstd_TIME = zeros(n_vars, n_vars, n_shock);
corr_TIME   = zeros(n_vars, n_vars, n_shock);

for tt = 1:n_shock
    scfg = cfg;
    if ~isfield(scfg, 'shock')
        scfg.shock = struct();
    end
    for ss = 1:n_shock
        if ss ~= tt
            scfg.shock.(all_rho(ss)) = 0;
            scfg.shock.(all_std(ss)) = 1e-5;
        end
    end
    res = dynare_scenario(scfg, dynare_opts);
    relstd_TIME(:,:,tt) = res.relstd;
    corr_TIME(:,:,tt)   = res.corr;
end

if ~exist(cache_dir, 'dir'); mkdir(cache_dir); end
save(cache_file, 'relstd_TIME', 'corr_TIME');

end
