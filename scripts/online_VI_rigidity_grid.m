% online_VI_rigidity_grid.m -- Online Appendix VI: price vs. wage rigidity grid (behind robustness checks 6, 7 and the literature combinations)
% -------------------------------------------------------------------------
% PRODUCES (proposed sec:robust_rigidity in chapters/online_appendix/ap_robustness.tex):
%   results/figures/fig_robust_rigidity.eps   comovement omega_shock and NK-SaM/benchmark ratios
%                                             over the (lambda_P, lambda_W) grid
%   results/txt/rigidity_grid_summary.txt     all numbers, kappa_P, kappa_W per grid point
%   results/mat/rigidity_grid.mat
%
% DESIGN
%   - Both Phillips-curve TARGETS are varied jointly in BOTH models; kappa_P and
%     kappa_W are re-solved by nk_time_steadystate.m exactly as at the baseline:
%       lambda_P = target.nkpc_slope   labor-share NKPC slope        -> kappa_P
%       lambda_W = -target.nkwpc_slope wage-PC slope, per pp of u, q -> kappa_W
%   - Grid, two layers (2026-10-06, per Konstantin):
%     Layer 1, sampling uncertainty: baseline estimates and the bounds of their 95% CI
%       (get_params: ranges.nkpc_ci, ranges.nkwpc_ci); IRF figures: robustness checks 6, 7.
%     Layer 2, other literature estimates (this grid and the literature combinations only, no IRF figures):
%       lambda_P in {0.051  Gali-Gertler (1999) Table 4, 1980Q1-1997Q4 (baseline),
%                    0.0392, 0.0628  its 95% CI,
%                    0.014  Kuttner-Robinson (2010) 1984-2007}
%       lambda_W in {0.30   steeper than any estimate (breakpoint; 2026-10-06: 0.599 dropped,
%                           it is no estimate),
%                    0.1793, 0.1107  95% CI of Gali-Gambetti (2019) 1986Q1-2007Q2,
%                    0.145  its point estimate (-0.58/4, baseline),
%                    0.0725 Gali-Gambetti 1964Q1-2007Q2 (-0.29/4)}
%                    (2026-10-06: 0.0275 (2007Q3-2017Q4) dropped, outside the calibration period)
%     = 20 points (x 2 models). Wage stickiness on (labor_ext = 1) throughout;
%     flexible wages (kappa_W = 0, omega = 0) are robustness check 7.
%   - Statistics per grid point (all from the IRFs, as main_s5_slope_summary.m):
%       omega_shock = sum_t u~_t Y~_t / sum_t Y~_t^2   (ue_gap in pp, gdp_gap in %)
%         NK-SaM: eM, eD, eA, eP, eT;  benchmark: eM, eA, eP
%       NK-SaM / benchmark: impact real GDP, impact inflation, cumulative real GDP
%         (eM, eA, eP; same as Panels B-C of tab:robust_full)
%   - Thresholds omega*_q, omega*_Xi come from the static channel slopes
%     (reduced-form model) and do NOT depend on kappa_P or kappa_W, so they
%     are drawn once (checked below: computed at every lambda_P anyway).
%   - Caching per grid point through lib/robust_cached.m (same signature logic).
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));

% ======================= USER OPTIONS =====================================
lamP = [target.nkpc_slope, ranges.nkpc_ci, 0.014];               % first entry = baseline
lamW = [0.30, -ranges.nkwpc_ci(2), -target.nkwpc_slope, ...
        -ranges.nkwpc_ci(1), 0.29/4];                                % steep -> flat
iWb  = 3;                                                            % baseline lambda_W
lamW_ci = sort(-ranges.nkwpc_ci);                                    % 95% CI band in the figure
force_rerun = false;
% ==========================================================================

cache_dir = nksam_path('cache');
log_file  = nksam_path('txt', 'rigidity_grid_log.txt');
if exist(log_file, 'file'), delete(log_file); end
diary(log_file); diary on;
fprintf('online_VI_rigidity_grid.m -- %s\n', datestr(now));

dynare_opts.keep_sim = false;

sh_sam   = {'eM', 'eD', 'eA', 'eP', 'eT'};
sh_bench = {'eM', 'eA', 'eP'};
sh_lab   = containers.Map({'eM','eD','eA','eP','eT'}, ...
           {'Monetary Policy', 'Search Effort', 'Technology', '\epsilon-Cost-Push', 'Matching Eff.'});

% ---- baseline configs (as online_VI_robustness.m) --------------------------
nk_cfg = base_cfg;
nk_cfg.parSAM.gamQ = 1e-4;
nk_cfg.parSAM.subQ = ranges.subQ_high;
nk_cfg.target.cuss = 1;
nk_cfg.target.dnss = 1e-4;
sam_cfg = base_cfg;

assert(abs(lamP(1) - target.nkpc_slope) < 1e-12 && abs(lamW(iWb) + target.nkwpc_slope) < 1e-12, ...
       'online_VI_rigidity_grid: grid does not contain the baseline targets.');

gp = struct('par', par, 'parHW', parHW, 'parSAM', parSAM, 'shock', shock, ...
            'target', target, 'irfperiod', dynare_opts.irfperiod);

% ---- thresholds (reduced form; independent of kappa_P, kappa_W) -------------
par0 = get_params('slopes'); dat = load_nksam_data();
flags0 = struct('ghh', 0, 'hw_select', 1, 'hp_select', 0, 'mp_select', 1, ...
                'stst_target', 1, 'kapP_select', 0);
thr = NaN(numel(lamP), 2);
for i = 1:numel(lamP)
    pp = par0; pp.slopeLS = lamP(i);
    [o, ~] = compute_wedges(build_p(pp, dat, flags0));
    thr(i, :) = real([-o.CU_t/o.CU_ue, -o.PE_t/o.PE_ue]);    % [omega*_q, omega*_Xi]
end
fprintf('thresholds omega*_q, omega*_Xi by lambda_P:\n'); disp(thr);
if max(abs(thr - thr(1, :)), [], 'all') > 1e-8
    warning('online_VI_rigidity_grid: thresholds vary with lambda_P (unexpected).');
end
om_q = thr(1, 1); om_X = thr(1, 2);

% ---- grid --------------------------------------------------------------------
nP = numel(lamP); nW = numel(lamW);
omega = struct(); ratio = struct(); kap = NaN(nP, nW, 4);   % kapP/kapW, SaM and bench
for s = sh_sam,   omega.sam.(s{1})   = NaN(nP, nW); end
for s = sh_bench, omega.bench.(s{1}) = NaN(nP, nW);
                  ratio.Y.(s{1}) = NaN(nP, nW); ratio.pi.(s{1}) = NaN(nP, nW);
                  ratio.Ycum.(s{1}) = NaN(nP, nW); end
omf = @(r, sh) sum(r.irfs.(sh).ue_gap .* r.irfs.(sh).gdp_gap) / sum(r.irfs.(sh).gdp_gap.^2);

for i = 1:nP
    for j = 1:nW
        ovr = {'target', 'nkpc_slope', lamP(i); 'target', 'nkwpc_slope', -lamW(j)};
        tag = sprintf('rigid_P%04d_W%04d', round(1e4*lamP(i)), round(1e4*lamW(j)));
        fprintf('\n== lambda_P = %.3f, lambda_W = %.4f ==\n', lamP(i), lamW(j));
        cs = robust_apply_ovr(sam_cfg, ovr);
        cn = robust_apply_ovr(nk_cfg,  ovr);
        sig = struct('gp', gp, 'sam', cs, 'nk', cn);
        try
            out = robust_cached(fullfile(cache_dir, [tag '.mat']), sig, force_rerun, ...
                  @() struct('sam', robust_solve(cs, dynare_opts), 'nk', robust_solve(cn, dynare_opts)));
        catch ME
            fprintf(2, '  *** grid point FAILED: %s\n', ME.message); continue;
        end
        kap(i, j, :) = [out.sam.par.kapP, out.sam.par.kapW, out.nk.par.kapP, out.nk.par.kapW];
        for s = sh_sam,   omega.sam.(s{1})(i, j)   = omf(out.sam, s{1}); end
        for s = sh_bench
            sh = s{1};
            omega.bench.(sh)(i, j) = omf(out.nk, sh);
            ratio.Y.(sh)(i, j)    = out.sam.irfs.(sh).gdp_obs(1) / out.nk.irfs.(sh).gdp_obs(1);
            ratio.pi.(sh)(i, j)   = out.sam.irfs.(sh).piC(1)     / out.nk.irfs.(sh).piC(1);
            ratio.Ycum.(sh)(i, j) = sum(out.sam.irfs.(sh).gdp_obs) / sum(out.nk.irfs.(sh).gdp_obs);
        end
    end
end

% ---- figure: x = lambda_W, one line per lambda_P ----------------------------
% Row 1: omega_shock (NK-SaM solid, benchmark grey) with omega*_q, omega*_Xi, Okun.
% Row 2: NK-SaM / benchmark impact real GDP.  Row 3: impact inflation.
cols = {col_orange, [0 0.45 0.74], [0 0.45 0.74], [0.47 0.67 0.19]};
lsP  = {'-', '--', '-.', ':'};
shF  = {'eM', 'eD', 'eA', 'eP'};
fig = figure('Name', 'Price vs wage rigidity', 'Color', 'w', 'Units', 'centimeters', 'Position', [0 0 16 13]);
tl = tiledlayout(fig, 3, numel(shF), 'TileSpacing', 'compact', 'Padding', 'compact');
for r = 1:3
    for c = 1:numel(shF)
        sh = shF{c}; ax = nexttile(tl); hold(ax, 'on'); box(ax, 'on');
        if r > 1 && ~isfield(ratio.Y, sh)              % no benchmark search-effort shock
            axis(ax, 'off');
            text(ax, 0.5, 0.5, 'No benchmark counterpart', 'Units', 'normalized', ...
                 'HorizontalAlignment', 'center', 'FontSize', 7, 'Color', [0.4 0.4 0.4]);
            continue;
        end
        set(ax, 'XScale', 'log');
        for i = 1:nP
            lab = sprintf('$NKPC_{Slope}=%.3f$', lamP(i));
            switch r
                case 1
                    plot(ax, lamW, omega.sam.(sh)(i, :), lsP{i}, 'Color', cols{i}, 'LineWidth', 1.1, ...
                         'Marker', 'o', 'MarkerSize', 3, 'DisplayName', lab);
                    if isfield(omega.bench, sh)
                        hb = plot(ax, lamW, omega.bench.(sh)(i, :), lsP{i}, 'Color', [0.55 0.55 0.55], ...
                             'LineWidth', 0.8, 'HandleVisibility', 'off');
                        if c == 1 && i == 1
                            set(hb, 'HandleVisibility', 'on', 'DisplayName', 'Benchmark');
                        end
                    end
                case 2
                    if isfield(ratio.Y, sh), plot(ax, lamW, ratio.Y.(sh)(i, :), lsP{i}, 'Color', cols{i}, ...
                         'LineWidth', 1.1, 'Marker', 'o', 'MarkerSize', 3, 'HandleVisibility', 'off'); end
                case 3
                    if isfield(ratio.pi, sh), plot(ax, lamW, ratio.pi.(sh)(i, :), lsP{i}, 'Color', cols{i}, ...
                         'LineWidth', 1.1, 'Marker', 'o', 'MarkerSize', 3, 'HandleVisibility', 'off'); end
            end
        end
        if r == 1
            hv = 'off'; if c == 1, hv = 'on'; end        % threshold lines in the legend once
            yline(ax, om_q, ':k', 'HandleVisibility', hv, 'DisplayName', sprintf('Diagonal boundary, $\\omega_q^\\ast=%.2f$', om_q));
            yline(ax, om_X, '--k', 'HandleVisibility', hv, 'DisplayName', sprintf('Price-elasticity threshold, $\\omega_\\Xi^\\ast=%.2f$', om_X));
            yline(ax, -0.45, ':', 'Color', [0.6 0.6 0.6], 'HandleVisibility', hv, 'DisplayName', 'Okun locus, $\omega=-0.45$');
            title(ax, sh_lab(sh), 'Interpreter', 'tex', 'FontWeight', 'normal');
        else
            yline(ax, 1, ':', 'Color', [0.6 0.6 0.6], 'HandleVisibility', 'off');
        end
        xline(ax, lamW(iWb), ':', 'Color', [0.6 0.6 0.6], 'HandleVisibility', 'off');    % baseline
        yl = ylim(ax);                                                                    % 95% CI band
        hp = patch(ax, lamW_ci([1 2 2 1]), yl([1 1 2 2]), [0.85 0.85 0.85], 'EdgeColor', 'none', ...
                   'FaceAlpha', 0.4, 'HandleVisibility', 'off');
        uistack(hp, 'bottom'); ylim(ax, yl);
        if c == 1
            ylabs = {'$\omega_{shock}$', 'Impact $Y$: NK-SaM/bench.', 'Impact $\pi$: NK-SaM/bench.'};
            ylabel(ax, ylabs{r}, 'Interpreter', 'latex');
        end
        if r == 3, xlabel(ax, '$-NKWPC_{Slope}$ (per pp of $u$, quarterly)', 'Interpreter', 'latex'); end
        set(ax, 'XDir', 'reverse', 'FontSize', 7, ...    % left -> right: flatter wage curve, higher kappa_W
                'XTick', [0.07 0.1 0.15 0.3], 'XTickLabel', {'0.07', '0.1', '0.15', '0.3'}, ...
                'XLim', [0.065 0.33]);
    end
end
lg = legend(nexttile(tl, 1), 'Interpreter', 'latex', 'NumColumns', 4);
lg.Layout.Tile = 'south';
save_fig(nksam_path('figures', 'fig_robust_rigidity.eps'), 16, 13);

% ---- summary ------------------------------------------------------------------
fid = fopen(nksam_path('txt', 'rigidity_grid_summary.txt'), 'w');
fprintf(fid, 'PRICE vs WAGE RIGIDITY GRID -- %s\n', datestr(now));
fprintf(fid, 'thresholds: omega*_q = %.3f, omega*_Xi = %.3f, Okun = -0.45\n\n', om_q, om_X);
for i = 1:nP
    for j = 1:nW
        fprintf(fid, 'lambda_P = %.3f, lambda_W = %.4f | kapP SaM %.1f bench %.1f | kapW SaM %.1f bench %.1f\n', ...
                lamP(i), lamW(j), kap(i,j,1), kap(i,j,3), kap(i,j,2), kap(i,j,4));
        fprintf(fid, '   omega NK-SaM:'); for s = sh_sam, fprintf(fid, ' %s %.3f', s{1}, omega.sam.(s{1})(i,j)); end
        fprintf(fid, '\n   omega bench: '); for s = sh_bench, fprintf(fid, ' %s %.3f', s{1}, omega.bench.(s{1})(i,j)); end
        fprintf(fid, '\n   NK-SaM/bench impact Y / impact pi / cum Y:');
        for s = sh_bench, fprintf(fid, '  %s %.3f / %.3f / %.3f', s{1}, ratio.Y.(s{1})(i,j), ratio.pi.(s{1})(i,j), ratio.Ycum.(s{1})(i,j)); end
        fprintf(fid, '\n');
    end
end
fclose(fid);
save(nksam_path('mat', 'rigidity_grid.mat'), 'lamP', 'lamW', 'kap', 'omega', 'ratio', 'om_q', 'om_X');

diary off;
cleanup_dynare_output();
