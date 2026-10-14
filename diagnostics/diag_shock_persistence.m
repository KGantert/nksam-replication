% diag_shock_persistence.m -- robustness check (not in the paper): persistence of the shock processes
% -------------------------------------------------------------------------
% QUESTION
%   Do the IRFs of the benchmark and of the NK-SaM model, and the comparison between them,
%   depend on the persistence of the shocks? The baseline AR(1) coefficients (get_params.m,
%   shock.rho*) are 0.90 for technology (eA) and 0.50 for monetary policy (eM), search effort
%   (eD), epsilon-cost-push (eP) and matching efficiency (eT); the discount-rate shock (eZ) is
%   0.80. This script re-solves both models with
%       rho_A = 0.95 (technology),   rho_Z = 0.90 (discount rate),
%       rho = 0.80 for all other shocks (eM, eD, eP, eT)
%   (USER OPTIONS below) and plots the four curves per variable.
%
% DESIGN (as scripts/online_VI_robustness.m, but a separate script, not one of its 11 checks)
%   - Same baselines: benchmark (goods market SaM switched off) and NK-SaM, same configurations
%     as in the robustness script, so the baseline curves are the baseline curves of Online VI.
%     The baseline solutions are read from cache/robust_baseline.mat when it is valid (same
%     signature as in the robustness script); otherwise they are computed and stored there.
%   - Changed persistence in BOTH models (benchmark and NK-SaM). Only the AR(1) coefficients
%     change: shock standard deviations, the steady state and every other parameter are
%     unchanged (the script checks that the steady states are identical to the baselines').
%   - Figure (lib/plot_robust_grid.m, same layout as fig:robust_*): rows = 8 variables,
%     columns = 4 shocks (monetary policy, search effort, technology, epsilon-cost-push);
%     grey = benchmark, orange = NK-SaM; solid = baseline persistence, dashed = higher
%     persistence. All lines are divided by the BASELINE NK-SaM impact real-GDP response of
%     the column's shock, so a line above/below the solid orange line on impact means a
%     larger/smaller impact response than at baseline persistence. IRF horizon: 12 quarters.
%   - Numbers: impact, peak and cumulative responses, NK-SaM/benchmark ratios, omega_shock and
%     the Barro-Grossman quadrant of each shock (definitions as in lib/robust_write_summary.m).
%
% PRODUCES (diagnostic, not in the paper)
%   results/figures/fig_robust_persistence.eps
%   results/txt/diag_shock_persistence.txt
%   cache/robust_persistence.mat   (cache of the two high-persistence solutions)
%
% Run on its own (diagnostics/diag_shock_persistence.m) or with
% run_all('scripts', {'diag_shock_persistence'}). Two Dynare solves if the baseline cache is
% valid (about a minute), a full baseline otherwise.
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));

% ======================= USER OPTIONS =====================================
rho_tech  = 0.95;   % persistence of the technology shock (eA); baseline 0.90
rho_disc  = 0.90;   % persistence of the discount-rate shock (eZ); baseline 0.80
rho_other = 0.80;   % persistence of all other shocks (eM, eD, eP, eT); baseline 0.50
% ==========================================================================

cache_dir = nksam_path('cache');
fprintf('diag_shock_persistence.m -- %s\n', datestr(now));
dynare_opts.keep_sim = false;   % moments are not needed; saves memory

% ---- plot configuration (identical to scripts/online_VI_robustness.m) ------------
g.shocks        = ["eM", "eD", "eA", "eP"];
g.shock_titles  = ["Monetary Policy", "Search Effort", "Technology", "\epsilon-Cost-Push"];
g.no_bench_shock = 'eD';                 % benchmark has no search-effort shock
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

% ---- baseline models (identical to scripts/online_VI_robustness.m) ----------------
nk_cfg = base_cfg;
nk_cfg.parSAM.gamQ = 1e-4;
nk_cfg.parSAM.subQ = ranges.subQ_high;
nk_cfg.target.cuss = 1;
nk_cfg.target.dnss = 1e-4;
sam_cfg = base_cfg;

gp  = struct('par', par, 'parHW', parHW, 'parSAM', parSAM, 'shock', shock, ...
             'target', target, 'ranges', ranges, 'irfperiod', dynare_opts.irfperiod);
sig = struct('gp', gp, 'nk_cfg', nk_cfg, 'sam_cfg', sam_cfg);   % = signature of the robustness script

fprintf('\n== Baseline (benchmark, NK-SaM; shared cache with online_VI_robustness) ==\n');
base = robust_cached(fullfile(cache_dir, 'robust_baseline.mat'), sig, false, ...
    @() struct('nk',  robust_solve(nk_cfg,  dynare_opts), ...
               'sam', robust_solve(sam_cfg, dynare_opts), ...
               'iso', robust_iso_stats(sam_cfg, dynare_opts)));

% ---- the change: persistence of all six AR(1) shock processes ---------------------
rho_new = struct('A', rho_tech, 'Z', rho_disc, 'M', rho_other, ...
                 'P', rho_other, 'T', rho_other, 'D', rho_other);
ids = fieldnames(rho_new);
assert(all(structfun(@(v) v >= 0 && v < 1, rho_new)), ...
       'diag_shock_persistence: persistence values must lie in [0, 1).');
ovr = cell(numel(ids), 3);                       % {struct, field, value} as in robust_apply_ovr
fprintf('\nPersistence (baseline -> check):\n');
for ii = 1:numel(ids)
    ovr(ii, :) = {'shock', ['rho' ids{ii}], rho_new.(ids{ii})};
    fprintf('  rho%s: %.2f -> %.2f\n', ids{ii}, shock.(['rho' ids{ii}]), rho_new.(ids{ii}));
end

% ---- check definition (fields used by lib/plot_robust_grid.m and lib/robust_cached.m) ----
SAM = 'NK-SaM model';
if isscalar(unique([shock.rhoM, shock.rhoD, shock.rhoP]))
    leg_base = sprintf('$\\rho_A=%.2f,\\ \\rho_{M,D,P}=%.2f$ (baseline)', shock.rhoA, shock.rhoM);
else
    leg_base = sprintf('$\\rho_A=%.2f$ (baseline)', shock.rhoA);
end
leg_var = sprintf('$\\rho_A=%.2f,\\ \\rho_{M,D,P}=%.2f$', rho_tech, rho_other);

chk = struct();
chk.tag           = 'persistence';
chk.title         = 'Persistence of the Shock Processes';
chk.bench_changes = true;                        % the change applies to both models
chk.base_leg      = leg_base;
chk.base_group    = SAM;
chk.base_order    = 1;
chk.ext           = struct('leg', leg_var, 'group', SAM, 'order', 2, 'col', [], ...
                           'ls', '--', 'marker', 'none', 'dyn_ovr', {ovr});

% ---- solve both models with the changed persistence (cached) ----------------------
fprintf('\n== %s ==\n', chk.title);
sig_c = struct('base', sig, 'chk', chk);
out = robust_cached(fullfile(cache_dir, 'robust_persistence.mat'), sig_c, false, ...
    @() struct('sam', {{robust_solve(robust_apply_ovr(sam_cfg, ovr), dynare_opts)}}, ...
               'nk',  {{robust_solve(robust_apply_ovr(nk_cfg,  ovr), dynare_opts)}}));

% ---- figure ------------------------------------------------------------------------
fac = plot_robust_grid(base, out, chk, g);
fprintf('normalization factors 1/Y_0 (%s): %s\n', strjoin(g.shocks, ', '), mat2str(fac, 4));

% ---- numbers -----------------------------------------------------------------------
shocks = cellstr(g.shocks);
nS     = numel(shocks);
mods   = {base.nk, out.nk{1}, base.sam, out.sam{1}};
mname  = {'Benchmark, baseline', 'Benchmark, higher rho', 'NK-SaM, baseline', 'NK-SaM, higher rho'};
is_nk  = [true, true, false, false];
imp    = @(r, sh, v) r.irfs.(sh).(v)(1);                 % impact response (period 1)
cum    = @(r, sh, v) sum(r.irfs.(sh).(v));               % summed over the IRF horizon
omg    = @(r, sh) sum(r.irfs.(sh).ue_gap .* r.irfs.(sh).gdp_gap) / sum(r.irfs.(sh).gdp_gap .^ 2);

% Barro-Grossman quadrant in which the IRF spends most of the horizon, periods weighted by
% |output gap| (as quads() in lib/robust_write_summary.m): UC underconsumption (cu<0, u<0),
% RI repressed inflation (cu>0, u<0), CU classical unemployment (cu>0, u>0), KU Keynesian
% unemployment (otherwise).
qlab = {'UC', 'RI', 'KU', 'CU'};
qd   = repmat({'--'}, numel(mods), nS);
for mi = 1:numel(mods)
    for si = 1:nS
        sh = shocks{si};
        if is_nk(mi) && strcmp(sh, g.no_bench_shock), continue; end
        ir = mods{mi}.irfs.(sh);
        cq = ir.cu_gap(:); cu_ = ir.ue_gap(:); cy = ir.gdp_gap(:);
        if max(abs(cu_)) < 1e-8, continue; end
        cw = abs(cy) / sum(abs(cy));
        ck = 3 * ones(size(cq));
        ck(cq < 0 & cu_ < 0) = 1; ck(cq > 0 & cu_ < 0) = 2; ck(cq > 0 & cu_ > 0) = 4;
        cs = arrayfun(@(j) sum(cw(ck == j)), 1:4);
        [cmax, cj] = max(cs);
        qd{mi, si} = sprintf('%s(%.0f%%)', qlab{cj}, 100 * cmax);
    end
end

% steady states must not depend on the persistence of the shocks
ssf = fieldnames(base.sam.ss);
dss = 0;
for ii = 1:numel(ssf)
    dss = max([dss, abs(base.sam.ss.(ssf{ii}) - out.sam{1}.ss.(ssf{ii})), ...
                    abs(base.nk.ss.(ssf{ii})  - out.nk{1}.ss.(ssf{ii}))]);
end

fT = nksam_path('txt', 'diag_shock_persistence.txt');
ensure_dir(fT);
fid = fopen(fT, 'w');
if fid < 0, error('diag_shock_persistence: cannot open %s.', fT); end
fprintf(fid, 'SHOCK PERSISTENCE -- robustness check (not in the paper) -- %s\n\n', datestr(now));
fprintf(fid, 'AR(1) coefficients, baseline -> check (both models):\n');
for ii = 1:numel(ids)
    fprintf(fid, '  rho%s: %.2f -> %.2f\n', ids{ii}, shock.(['rho' ids{ii}]), rho_new.(ids{ii}));
end
fprintf(fid, '\nMax. abs. difference of the steady states (variables of robust_solve) to the baselines: %.2e\n', dss);
fprintf(fid, 'Normalization of the figure, 1/(baseline NK-SaM impact real GDP): %s\n', ...
        strjoin(arrayfun(@(s, f) sprintf('%s %.3f', shocks{s}, f), 1:nS, fac, 'UniformOutput', false), ', '));

fprintf(fid, '\nIRF statistics (percent / pp, 1 s.d. shocks, horizon %d quarters)\n', dynare_opts.irfperiod);
fprintf(fid, '  Y = real GDP, pi = inflation; peak = largest |Y| response (quarter); cum. = Y summed over the horizon;\n');
fprintf(fid, '  omega = sum(u~ Y~)/sum(Y~^2) with the unemployment gap (pp) and the output gap (%%); quadrant = Barro-Grossman quadrant.\n');
fprintf(fid, '%-6s %-24s %9s %9s %14s %9s %8s  %s\n', 'shock', 'model', 'Y impact', 'pi impact', 'Y peak (qtr)', 'Y cum.', 'omega', 'quadrant');
for si = 1:nS
    sh = shocks{si};
    for mi = 1:numel(mods)
        if is_nk(mi) && strcmp(sh, g.no_bench_shock), continue; end
        r = mods{mi};
        y = r.irfs.(sh).gdp_obs(:);
        [~, qk] = max(abs(y));
        fprintf(fid, '%-6s %-24s %9.4f %9.4f %9.4f (%2d) %9.4f %8.3f  %s\n', sh, mname{mi}, ...
                imp(r, sh, 'gdp_obs'), imp(r, sh, 'piC'), y(qk), qk, cum(r, sh, 'gdp_obs'), omg(r, sh), qd{mi, si});
    end
    fprintf(fid, '\n');
end

fprintf(fid, 'NK-SaM relative to the benchmark WITH THE SAME persistence (as tab:robust_regimes, columns iii-v)\n');
fprintf(fid, '%-6s %-22s %10s %10s %10s\n', 'shock', 'persistence', 'Y impact', 'pi impact', 'Y cum.');
for si = 1:nS
    sh = shocks{si};
    if strcmp(sh, g.no_bench_shock), continue; end     % no benchmark counterpart
    pairs = {base.sam, base.nk, 'baseline'; out.sam{1}, out.nk{1}, 'higher rho'};
    for pi_ = 1:2
        a = pairs{pi_, 1}; b = pairs{pi_, 2};
        fprintf(fid, '%-6s %-22s %10.3f %10.3f %10.3f\n', sh, pairs{pi_, 3}, ...
                imp(a, sh, 'gdp_obs') / imp(b, sh, 'gdp_obs'), ...
                imp(a, sh, 'piC')     / imp(b, sh, 'piC'), ...
                cum(a, sh, 'gdp_obs') / cum(b, sh, 'gdp_obs'));
    end
end

fprintf(fid, '\nNK-SaM with higher rho relative to baseline NK-SaM (impact responses, as tab:robust_magnitudes)\n');
fprintf(fid, '%-6s %10s %10s\n', 'shock', 'Y impact', 'pi impact');
for si = 1:nS
    sh = shocks{si};
    fprintf(fid, '%-6s %10.3f %10.3f\n', sh, imp(out.sam{1}, sh, 'gdp_obs') / imp(base.sam, sh, 'gdp_obs'), ...
            imp(out.sam{1}, sh, 'piC') / imp(base.sam, sh, 'piC'));
end
fclose(fid);
fprintf('  wrote %s\n\n%s', fT, fileread(fT));

% -- Delete Dynare's regenerable build output (option: lib/cleanup_dynare_output.m)
cleanup_dynare_output();
