% diag_phase_diagram_capital.m -- diagnostic (not in the paper): Barro-Grossman phase diagram with capital
% -------------------------------------------------------------------------
% QUESTION
%   Does Figure 3 (sec:phase_diagram) change when the model has a capital stock and variable
%   capital utilization (robustness check 11, Online Appendix VI)? Do the shocks keep their
%   diagonal (comoving vs. diverging), and how do the thresholds move?
%
% DESIGN
%   - No model change: capital is a set of parameter overrides on model/nk_time.dyn, taken
%     verbatim from lib/robust_define_checks.m (check 11, "capK" + delF2 = delH2 = ...).
%   - Cobb-Douglas NK-SaM scenario as in Figure 3 (scenario 3 of lib/compute_default_scenarios.m,
%     parSAM.subQ = ranges.subQ_high), all five shocks, same plot settings as main_s5_irfs.m
%     (impact normalization, monetary policy at half the common norm).
%   - Variants (USER OPTIONS): 1 = no capital (the Figure 3 baseline, re-plotted without the
%     analytical threshold, for comparison); 2 = capital, fixed utilization (delU = 1e3);
%     3 = capital, variable utilization (delU = 0.3).
%
% WHAT IS DIFFERENT FROM FIGURE 3 (read before using in the paper)
%   - The analytical thresholds beta*_q and beta*_Xi, and with them the red threshold ray and
%     the amplification cones, are NOT drawn: they come from the reduced-form slopes
%     (compute_wedges), which do not nest capital (as in tab:robust_regimes).
%   - The reference lines (Okun locus, zero contours) use ThY, Thu recovered from the model's own
%     IRFs by plot_phase_diagram via identity (*). With capital, (*) need not hold exactly:
%     check the printed R^2 and the "does not hold exactly" warning. If R^2 < 1, the zero
%     contours in panels (b)-(d) are approximations and the caption must say so; the
%     trajectories and the regime classification (signs of x_gap and ue_gap) are unaffected.
%
% PRODUCES (diagnostic)
%   results/figures/fig_phase_diagram_capital_<tag>.eps   tag = nocap | fixed | variable
%   results/txt/diag_phase_diagram_capital.txt            ThY, Thu, R^2, beta*_q = -ThY/Thu, regimes
%   cache/phase_diagram_capital.mat                       cache of the two capital solutions
% Run on its own or with run_all('scripts', {'diag_phase_diagram_capital'}). Two Dynare solves.
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_dynare.m'));

% ======================= USER OPTIONS =====================================
variants_to_run = [1 2 3];   % 1 no capital, 2 capital + fixed utilization, 3 capital + variable utilization
delU_fixed      = 1e3;       % as in lib/robust_define_checks.m
delU_variable   = 0.3;       % as in lib/robust_define_checks.m
% ==========================================================================

fprintf('diag_phase_diagram_capital.m -- %s\n', datestr(now));

% Capital overrides of robustness check 11 (copied from lib/robust_define_checks.m; keep in sync)
capK = {'switches', 'ls_target', 1; ...
        'par',      'delF1',     0.025; ...
        'par',      'kapF',      4; ...
        'parHW',    'alpH',      0.33; ...
        'parHW',    'delH1',     0.025; ...
        'parHW',    'kapH',      4};

tags   = {'nocap', 'fixed', 'variable'};
labels = {'No capital (baseline)', 'Capital, fixed utilization', 'Capital, variable utilization'};
ovr    = {{}, ...
          [capK; {'par', 'delF2', delU_fixed;    'parHW', 'delH2', delU_fixed}], ...
          [capK; {'par', 'delF2', delU_variable; 'parHW', 'delH2', delU_variable}]};

% ---- solve (Cobb-Douglas NK-SaM scenario of Figure 3, plus capital overrides) ----------
cache_file = nksam_path('cache', 'phase_diagram_capital.mat');
res = cell(1, 3);
if exist(cache_file, 'file')
    S = load(cache_file, 'res_cap');
    res(2:3) = S.res_cap;
else
    for k = 2:3
        s = base_cfg; s.parSAM.subQ = ranges.subQ_high;       % scenario 3 of compute_default_scenarios.m
        s = robust_apply_ovr(s, ovr{k});
        fprintf('  solving: %s\n', labels{k});
        res{k} = dynare_scenario(s, dynare_opts);
    end
    res_cap = res(2:3); %#ok<NASGU>
    if ~exist(nksam_path('cache'), 'dir'); mkdir(nksam_path('cache')); end
    save(cache_file, 'res_cap');
end
if any(variants_to_run == 1)
    compute_default_scenarios;           % res_1: Figure 3 baseline (cached)
    res{1} = res_1(3);
end

% ---- plot configuration (as main_s5_irfs.m, without the analytical threshold) ----------
pcfg_pd = struct();
pcfg_pd.scenario     = 1;               % each call gets one solved scenario
pcfg_pd.shocks       = ["eA",        "eM",              "eD",            "eT",                 "eP"];
pcfg_pd.shock_labels = ["Technology","Monetary Policy",  "Search Effort", "Matching Efficiency","$\epsilon$-Cost-Push"];
pcfg_pd.colors       = [col_blue; col_orange; col_yellow; col_purple; col_green];
pcfg_pd.legend_cols  = 3;
pcfg_pd.okun_elast   = -2.23;
pcfg_pd.norm_impact  = true;
pcfg_pd.extra_scale  = [1, 0.5, 1, 1, 1];
pcfg_pd.mark_impact  = true;
pcfg_pd.xi_beta      = NaN;             % no analytical threshold with capital
pcfg_pd.shade_amp    = false;

fid = fopen(nksam_path('txt', 'diag_phase_diagram_capital.txt'), 'w');
fprintf(fid, 'Phase diagram with capital (diag_phase_diagram_capital.m, %s), Cobb-Douglas NK-SaM\n', datestr(now)); %#ok<TNOW1,DATST>
fprintf(fid, 'Regimes: gap-space quadrant of (x_gap, ue_gap) per quarter, from plot_phase_diagram (classify_regime).\n');
for k = variants_to_run
    pcfg_pd.fig_name   = ['Phase Diagram, ' labels{k}];
    pcfg_pd.fig_prefix = nksam_path('figures', ['fig_phase_diagram_capital_' tags{k}]);
    info = plot_phase_diagram(res{k}, pcfg_pd);
    fprintf(fid, '\n==== %s ====\n', labels{k});
    fprintf(fid, 'identity (*): ThY = %.4f, Thu = %.4f, R^2 = %.8f, beta*_q = -ThY/Thu = %.3f\n', ...
            info.ThY, info.Thu, info.R2, -info.ThY / info.Thu);
    for sh = fieldnames(info.regimes_gap)'
        r = info.regimes_gap.(sh{1});
        fprintf(fid, '  %-4s gap regimes: %s\n', sh{1}, strjoin(r(:)', ' | '));
    end
    if ~isempty(info.regime_switch)
        fprintf(fid, '  classified differently in levels and gaps: %s\n', char(strjoin(string(info.regime_switch), ', ')));
    end
end
fclose(fid);

clearvars pcfg_pd info fid r sh S s;
cleanup_dynare_output();
