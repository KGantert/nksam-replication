function checks = robust_define_checks(par, target, ranges)
% ROBUST_DEFINE_CHECKS  The robustness checks of the online appendix (checks 1-11 + literature combinations)
%   (chapters/online_appendix/ap_robustness.tex, sec:robust).
%
%   checks = ROBUST_DEFINE_CHECKS(par, target, ranges)
%
%   Inputs are the Dynare-context calibration structs from
%   get_params('dynare') (in the workspace after lib/setup_dynare.m).
%
%   Each check changes the main model along ONE dimension, with one or
%   more variants. Fields of checks(c):
%     .tag            file tag -> results/figures/fig_robust_<tag>.eps
%     .title          figure window name
%     .bench_changes  true: every variant is also applied to the benchmark
%                     (benchmark shown with and without it); false: the
%                     variants act through goods market SaM only
%                     (benchmark shown once)
%     .base_leg       legend label of the baseline lines (LaTeX)
%     .base_group     legend group (column title) of the baseline NK-SaM
%                     line; the benchmark always forms its own group
%     .base_order     position of the baseline line within its group
%     .no_figure      (optional) true: no IRF figure, table rows only (literature combinations)
%     .num, .part, .table_order   check number (NaN: unnumbered), part A/B/C, order of the table rows
%     .ext(k)         variant k:
%        .leg         legend label within its group (LaTeX)
%        .group       legend group of the NK-SaM line (LaTeX column title)
%        .order       position within the group (legend sorted by it)
%        .col         NK-SaM line colour ([] = default orange)
%        .ls, .marker line style / marker (benchmark lines use the same)
%        .row         row label in tab:robust_full (LaTeX, '' = none)
%        .change      "Change" entry in tab:robust_full (LaTeX)
%        .dyn_ovr     n x 3 cell {struct, field, value} -> Dynare cfg
%        .slopes_ovr  n x 3 cell {'par'|'flags', field, value} -> reduced-
%                     form slope model; {} = same as baseline; NaN = not
%                     nested in the reduced-form model (empty table cell)
%
%   2026-09-24 (v2, per Konstantin): variants restored/added from the old
%   robustness figures -- gamma_Q = 0.11 and 0.32 lines (calibration),
%   employment adjustment costs kappa_N (sticky wages), gamma_P = 0.1 and 0.16
%   (quality search), contracts + inventories combined (long-term),
%   capital with fixed vs variable utilization (capital).
%   2026-10-06 (per Konstantin): checks 2 (kappa_P, 95% CI), 4 (kappa_W, 95% CI, flexible
%   wages), 5 (employment adjustment x kappa_W) and 6 (adverse literature combinations, table only)
%   added; the former check 3 (labor market) split into 4 and 5. Numbering: 1 calib, 2 kapPci,
%   3 kapP, 4 kapW, 5 hours, 6 kapcorner, 7 nohp, 8 ghh, 9 qs, 10 longterm, 11 capital, 12 iq.
%   2026-10-06 (later): shorter table labels (NKPC/NKWPC; check 6 as (NKPC, NKWPC) pair) so that
%   tab:robust_transmission / tab:robust_full fit the text width.
%   2026-10-09 (per Konstantin): checks reordered and renumbered into three parts: A goods market SaM only
%   (1 calib, 2 qs, 3 iq, 4 longterm), B Phillips-curve calibration (5 kapP, 6 kapPci, 7 kapW), C shared
%   model structure (8 nohp, 9 ghh, 10 hours, 11 capital). The adverse literature combinations (kapcorner)
%   are no longer a numbered check: array position 12, num = NaN, tabulated after check 7 (table_order 7.5).
%   Extra fields: .num (check number), .part ('A'|'B'|'C'), .table_order (row order in tab:robust_*).
%   Array positions 1-11 = check numbers. Caches are keyed by tag and unaffected.
%   2026-10-11: row labels of checks 3, 4, 8, 9, 10 abbreviated (Search conv., Trade rel., No home prod., GHH pref., Empl. adj.) so that
%   the merged tab:robust_full fits on one rotated page.
% -------------------------------------------------------------------------

col_blue   = [0.00 0.45 0.74];
SAM        = 'NK-SaM model';

% Flexible wages: wage markup that reproduces the steady-state
% unemployment target (Gali), as nk_time_steadystate.m does for
% labor_ext = 1, so only wage stickiness is switched off.
epsW_flex = ((1+target.uss)^par.nuN) / ((1+target.uss)^par.nuN - 1);

% Capital with FIXED utilization: utilization-cost curvature so high that
% e_F, e_H stay at their steady state of 1 (get_params' "off" placeholder
% for delF2 is 99; a larger value is used to make fixed utilization tight).
delU_fixed = 1e3;

c = 0;

% ---- 1. Calibration: gamma_Q x nu_D/nu_N ------------------------------------
% Colour = gamma_Q (orange: baseline 0.32, blue: 0.11), line style =
% nu_D/nu_N (dashed 0.5, solid 1, dash-dotted 1.5). The benchmark does not
% depend on either parameter.
c = c + 1;
checks(c).tag           = 'calib';
checks(c).num           = 1;
checks(c).part          = 'A';
checks(c).table_order   = 1;
checks(c).title         = 'Calibration Sensitivity';
checks(c).bench_changes = false;
checks(c).base_leg      = '$\nu_D/\nu_N=1$ (baseline)';
checks(c).base_group    = sprintf('NK-SaM, $\\gamma_Q=%g$ (baseline)', ranges.gamQ_high);
checks(c).base_order    = 2;
rat  = [ranges.nuDnuN_low, 1, ranges.nuDnuN_high];
lsr  = {'--', '-', '-.'};
gams = [ranges.gamQ_high, ranges.gamQ_low];
grp  = {checks(c).base_group, sprintf('NK-SaM, $\\gamma_Q=%g$', ranges.gamQ_low)};
cols = {[], col_blue};
e    = [];
first_row = true;
for gi = 1:2
    for ri = 1:3
        if gi == 1 && ri == 2, continue; end     % = baseline
        nuD = rat(ri) * par.nuN;
        if first_row, rowlab = '1. Calibration'; first_row = false; else, rowlab = ''; end
        e = [e, mk_ext(sprintf('$\\nu_D/\\nu_N=%g$', rat(ri)), grp{gi}, ri, cols{gi}, lsr{ri}, 'none', ...
                       rowlab, sprintf('$\\gamma_Q=%g$, $\\nu_D/\\nu_N=%g$', gams(gi), rat(ri)), ...
                       {'parSAM', 'gamQ', gams(gi); 'parSAM', 'nuD', nuD}, ...
                       {'par',    'gamQ', gams(gi); 'par',    'nuD', nuD})]; %#ok<AGROW>
    end
end
checks(c).ext = e;

% ---- 2. Quality search: gamma_P = 0.1, 0.16---------------------------------------
% NK-SaM only (the benchmark has almost no shopping time to split);
% variety-specific search convexity stays off (switches.dAP = 0).
c = c + 1;
checks(c).tag           = 'qs';
checks(c).num           = 2;
checks(c).part          = 'A';
checks(c).table_order   = 2;
checks(c).title         = 'Quality Search';
checks(c).bench_changes = false;
checks(c).base_leg      = '$\gamma_P=0$ (baseline)';
checks(c).base_group    = SAM;
checks(c).base_order    = 1;
gP  = [ranges.gamP_loop, ranges.gamP_high];
lsq = {'--', '-.'};
rl  = {'2. Quality search', ''};
e   = [];
for kk = 1:2
    e = [e, mk_ext(sprintf('$\\gamma_P=%g$', gP(kk)), SAM, kk+1, [], lsq{kk}, 'none', ...
                   rl{kk}, sprintf('$\\gamma_P=%g$', gP(kk)), ...
                   {'parHW', 'gamP', gP(kk)}, ...
                   {'flags', 'hp_select', 1; 'par', 'gamP', gP(kk)})]; %#ok<AGROW>
end
checks(c).ext = e;

% ---- 3. Firm-specific search convexity: I_Q = 1 (switches.dAP) ---------------------
% Added 2026-09-25. With firm-specific convexity a firm internalizes that attracting customers raises
% their marginal search cost (nk_time.dyn: dAP terms in vphi, mcT, mcY; nk_time_steadystate.m).
% MARKUP TARGET IS INFEASIBLE for I_Q = 1 at the baseline gamma_Q: at theta = 1 the steady state implies
%   mc = mc_T*(1-gamma_Q)*(1+nu_D)/(1-gamma_Q+nu_D),  mc_T = 1-(1+P_Q)/eps < 1,
% so mc <= 0.761 (markup >= 1.31) at gamma_Q = 0.32, nu_D = 2; a markup of 1.2 would need eps < 0.
% The variant therefore FIXES epsilon (switches.markup_stst = 0) at the value that delivers the baseline
% markup in the I_Q = 0 model (closed form at theta = 1, gamP = 0, delT = delI = 1); the markup then
% rises endogenously. gamma_Q = 0.32 stays at its baseline. All other targets are kept and kappa_P
% targets the same Phillips-curve slope (I_Q = 1: kappa_P = (eps-1)/(mc*slope), nk_time_steadystate.m).
% Baseline (I_Q = 0) and benchmark are drawn once; the variant acts through goods market SaM only.
c = c + 1;
checks(c).tag           = 'iq';
checks(c).num           = 3;
checks(c).part          = 'A';
checks(c).table_order   = 3;
checks(c).title         = 'Firm-Specific Search Convexity';
checks(c).bench_changes = false;
checks(c).base_leg      = '$I_Q=0$ (baseline)';
checks(c).base_group    = SAM;
checks(c).base_order    = 1;
gq     = ranges.gamQ_high;
mc0    = 1 / target.markup;
P0     = mc0 * gq / (1 - gq);            % search price of the I_Q = 0 baseline (theta = 1)
eps_iq = (1 + P0) / (1 - mc0);           % = 8.35 at gamma_Q = 0.32, markup 1.2
checks(c).ext = mk_ext('$I_Q=1$', SAM, 2, [], '--', 'none', ...
           '3. Search conv.', sprintf('$\\mathbb{I}_Q=1$, $\\epsilon=%.2f$', eps_iq), ...
           {'switches', 'markup_stst', 0; 'par', 'epss', eps_iq; 'switches', 'dAP', 1}, NaN);

% ---- 4. Long-term contracts and inventories, step by step -------------------------
c = c + 1;
checks(c).tag           = 'longterm';
checks(c).num           = 4;
checks(c).part          = 'A';
checks(c).table_order   = 4;
checks(c).title         = 'Long-Term Trade Relationships and Inventories';
checks(c).bench_changes = false;
checks(c).base_leg      = '$\delta_T=\delta_I=1$ (baseline)';
checks(c).base_group    = SAM;
checks(c).base_order    = 1;
dT = ranges.delT_loop; dI = ranges.delI_loop;
checks(c).ext = [ ...
    mk_ext(sprintf('Trade relationships, $\\delta_T=%g$', dT), SAM, 2, [], '--', 'none', ...
           '4. Trade rel.', sprintf('$\\delta_T=%g$', dT), ...
           {'parSAM', 'delT', dT}, NaN), ...
    mk_ext(sprintf('Inventories, $\\delta_I=%g$', dI), SAM, 3, [], '-.', 'none', ...
           '\phantom{4.} Inventories', sprintf('$\\delta_I=%g$', dI), ...
           {'parSAM', 'delI', dI}, NaN), ...
    mk_ext('Both', SAM, 4, [], ':', 'o', ...
           '\phantom{4.} Both', sprintf('$\\delta_T=%g$, $\\delta_I=%g$', dT, dI), ...
           {'parSAM', 'delT', dT; 'parSAM', 'delI', dI}, NaN)];

% ---- 5. Phillips-curve calibration: fixed kappa_P ---------------------------------------
% kappa_P fixed at the benchmark model's slope-targeted value,
% eps_benchmark / NKPC_Slope (= 6/0.051 = 117.6, App. A), in both models
% instead of re-targeting the labor-share Phillips-curve slope
% (2026-09-24, per Konstantin; value follows target.nkpc_slope). The benchmark is unchanged by
% construction; NK-SaM's implied labor-share slope rises. The reduced-form
% channel slopes do not depend on kappa_P (static ratios = 1).
kapP_b = par.epss / target.nkpc_slope;
c = c + 1;
checks(c).tag           = 'kapP';
checks(c).num           = 5;
checks(c).part          = 'B';
checks(c).table_order   = 5;
checks(c).title         = 'Phillips-Curve Calibration: Fixed kappa_P';
checks(c).bench_changes = false;
checks(c).base_leg      = '$\kappa_P$ targets the Phillips-curve slope (baseline)';
checks(c).base_group    = SAM;
checks(c).base_order    = 1;
checks(c).ext = mk_ext(sprintf('$\\kappa_P=%.1f$ (benchmark value)', kapP_b), SAM, 2, [], '--', 'none', ...
           '5. Fixed $\kappa_P$', sprintf('$\\kappa_P=%.1f$', kapP_b), ...
           {'switches', 'nkpc_target', 0; 'par', 'kapP', kapP_b}, ...
           {'flags', 'kapP_select', 1; 'par', 'kapP', kapP_b});

% ---- 6. Price rigidity: kappa_P at the 95% CI of the price Phillips-curve slope -------
% Added 2026-10-06 (per Konstantin). NKPC_Slope at the bounds of the 95% confidence interval of
% Gali-Gertler (1999), Table 4, 1980Q1-1997Q4 (0.051, se 0.006): ranges.nkpc_ci. kappa_P is
% re-targeted in BOTH models (benchmark recalibrated). Flatter slope = higher kappa_P.
% The reduced-form channel slopes do not depend on kappa_P (static ratios = 1, {}).
% 2026-10-09 (per Konstantin): flexible prices (kappa_P = 0) added as variant 3, mirroring flexible wages
% in check 7: nkpc_target = 0 stops nk_time_steadystate.m from computing kapP from the slope target, so
% par.kapP = 0 is used in BOTH models (bench_changes = true). The steady state is unchanged (markup target
% does not involve kapP); sticky wages stay on. Static slopes unaffected ({}).
lamP_ci = ranges.nkpc_ci;                       % [low, high] slope
c = c + 1;
checks(c).tag           = 'kapPci';
checks(c).num           = 6;
checks(c).part          = 'B';
checks(c).table_order   = 6;
checks(c).title         = 'Price Rigidity: 95% Interval of the Phillips-Curve Slope';
checks(c).bench_changes = true;
checks(c).base_leg      = sprintf('$NKPC_{Slope}=%.3f$ (baseline)', target.nkpc_slope);
checks(c).base_group    = SAM;
checks(c).base_order    = 2;
checks(c).ext = [ ...
    mk_ext(sprintf('$NKPC_{Slope}=%.3f$ (high $\\kappa_P$)', lamP_ci(1)), SAM, 1, [], '--', 'none', ...
           '6. Price rigidity', sprintf('$NKPC=%.3f$', lamP_ci(1)), ...
           {'target', 'nkpc_slope', lamP_ci(1)}, {}), ...
    mk_ext(sprintf('$NKPC_{Slope}=%.3f$ (low $\\kappa_P$)', lamP_ci(2)), SAM, 3, [], '-.', 'none', ...
           '', sprintf('$NKPC=%.3f$', lamP_ci(2)), ...
           {'target', 'nkpc_slope', lamP_ci(2)}, {}), ...
    mk_ext('Flexible prices, $\kappa_P=0$', SAM, 4, [], ':', 'o', ...
           '', 'Flexible prices', ...
           {'switches', 'nkpc_target', 0; 'par', 'kapP', 0}, {})];

% ---- 7. Wage rigidity: kappa_W at the 95% CI of the wage Phillips-curve slope; flexible wages
% Added 2026-10-06 (per Konstantin); absorbs the flexible-wage variant of the former check 3.
% NKWPC_Slope at the bounds of the 95% confidence interval of Gali-Gambetti (2019), Table 1A,
% 1986Q1-2007Q2 (-0.58/4, se 0.07/4): ranges.nkwpc_ci; kappa_W re-targeted in both models.
% Flexible wages (kappa_W = 0) are the limit of a steep wage curve:
%   labor_ext = 0 stops nk_time_steadystate.m from computing kapW/epsW from the
%   wage-Phillips-curve target; they are taken from par instead. Wage markup = its natural
%   level, so the unemployment gap is (numerically) zero.
% Reduced-form output-gap slopes do not depend on wage stickiness -> static ratios = 1 ({}).
lamW_ci = ranges.nkwpc_ci;                      % [flatter, steeper] (negative)
c = c + 1;
checks(c).tag           = 'kapW';
checks(c).num           = 7;
checks(c).part          = 'B';
checks(c).table_order   = 7;
checks(c).title         = 'Wage Rigidity: 95% Interval of the Wage Phillips-Curve Slope';
checks(c).bench_changes = true;
checks(c).base_leg      = sprintf('$NKWPC_{Slope}=%.3f$ (baseline)', target.nkwpc_slope);
checks(c).base_group    = SAM;
checks(c).base_order    = 2;
checks(c).ext = [ ...
    mk_ext(sprintf('$NKWPC_{Slope}=%.3f$ (high $\\kappa_W$)', lamW_ci(1)), SAM, 1, [], '--', 'none', ...
           '7. Wage rigidity', sprintf('$NKWPC=%.3f$', lamW_ci(1)), ...
           {'target', 'nkwpc_slope', lamW_ci(1)}, {}), ...
    mk_ext(sprintf('$NKWPC_{Slope}=%.3f$ (low $\\kappa_W$)', lamW_ci(2)), SAM, 3, [], '-.', 'none', ...
           '', sprintf('$NKWPC=%.3f$', lamW_ci(2)), ...
           {'target', 'nkwpc_slope', lamW_ci(2)}, {}), ...
    mk_ext('Flexible wages, $\kappa_W=0$', SAM, 4, [], ':', 'o', ...
           '', 'Flexible wages', ...
           {'switches', 'labor_ext', 0; 'par', 'kapW', 0; 'par', 'epsW', epsW_flex}, {})];

% ---- 8. No home production ----------------------------------------------------
c = c + 1;
checks(c).tag           = 'nohp';
checks(c).num           = 8;
checks(c).part          = 'C';
checks(c).table_order   = 8;
checks(c).title         = 'No Home Production';
checks(c).bench_changes = true;
checks(c).base_leg      = 'Home production (baseline)';
checks(c).base_group    = SAM;
checks(c).base_order    = 1;
checks(c).ext = mk_ext('No home production', SAM, 2, [], '--', 'none', ...
           '8. No home prod.', '$\gamma_H=0.02$', ...
           {'parHW', 'gamH', 0.02; 'parHW', 'subH', 1e-4; ...
            'target', 'hnss', 1e-4; 'target', 'chgdpss', 1e-4}, ...
           {'flags', 'hw_select', 0});

% ---- 9. GHH preferences -------------------------------------------------------
c = c + 1;
checks(c).tag           = 'ghh';
checks(c).num           = 9;
checks(c).part          = 'C';
checks(c).table_order   = 9;
checks(c).title         = 'GHH Preferences';
checks(c).bench_changes = true;
checks(c).base_leg      = 'KPR preferences (baseline)';
checks(c).base_group    = SAM;
checks(c).base_order    = 1;
checks(c).ext = mk_ext('GHH preferences', SAM, 2, [], '--', 'none', ...
           '9. GHH pref.', '$\mathbb{I}_{\mathrm{GHH}}=1$', ...
           {'switches', 'ghh_pref', 1}, {'flags', 'ghh', 1});

% ---- 10. Employment adjustment costs x wage rigidity ---------------------------------------------
% Employment adjustment costs kappa_N (par.phiN, nk_time.dyn: cn = phiN/2*(n/n(-1)-1)^2) on top of
% sticky wages, as the former check 3 (b), now at the baseline kappa_W and at the bounds of its
% 95% CI (2026-10-06, per Konstantin: the effect of kappa_N depends on kappa_W). Benchmark
% recalibrated with the same changes. Not in the reduced form (NaN).
c = c + 1;
checks(c).tag           = 'hours';
checks(c).num           = 10;
checks(c).part          = 'C';
checks(c).table_order   = 10;
checks(c).title         = 'Employment Adjustment Costs and Wage Rigidity';
checks(c).bench_changes = true;
checks(c).base_leg      = 'No employment adjustment costs (baseline)';
checks(c).base_group    = SAM;
checks(c).base_order    = 1;
kN = ranges.phiN_act;
checks(c).ext = [ ...
    mk_ext(sprintf('$\\kappa_N=%g$', kN), SAM, 2, [], '--', 'none', ...
           '10. Empl. adj.', sprintf('$\\kappa_N=%g$, baseline $NKWPC$', kN), ...
           {'par', 'phiN', kN}, NaN), ...
    mk_ext(sprintf('$\\kappa_N=%g$, $NKWPC_{Slope}=%.3f$', kN, lamW_ci(1)), SAM, 3, [], '-.', 'none', ...
           '', sprintf('$\\kappa_N=%g$, $NKWPC=%.3f$', kN, lamW_ci(1)), ...
           {'par', 'phiN', kN; 'target', 'nkwpc_slope', lamW_ci(1)}, NaN), ...
    mk_ext(sprintf('$\\kappa_N=%g$, $NKWPC_{Slope}=%.3f$', kN, lamW_ci(2)), SAM, 4, [], ':', 'o', ...
           '', sprintf('$\\kappa_N=%g$, $NKWPC=%.3f$', kN, lamW_ci(2)), ...
           {'par', 'phiN', kN; 'target', 'nkwpc_slope', lamW_ci(2)}, NaN)];

% ---- 11. Capital: fixed vs variable utilization --------------------------------------
% As the former run_robust_capital.m ("full capital"); alpF is set in the
% steady state from the labor-share target (ls_target = 1).
c = c + 1;
checks(c).tag           = 'capital';
checks(c).num           = 11;
checks(c).part          = 'C';
checks(c).table_order   = 11;
checks(c).title         = 'Capital and Capital Utilization';
checks(c).bench_changes = true;
checks(c).base_leg      = 'No capital (baseline)';
checks(c).base_group    = SAM;
checks(c).base_order    = 1;
capK = {'switches', 'ls_target', 1; ...
        'par',      'delF1',     0.025; ...
        'par',      'kapF',      4; ...
        'parHW',    'alpH',      0.33; ...
        'parHW',    'delH1',     0.025; ...
        'parHW',    'kapH',      4};
checks(c).ext = [ ...
    mk_ext('Capital, fixed utilization', SAM, 2, [], '--', 'none', ...
           '11. Capital', 'Fixed utilization', ...
           [capK; {'par', 'delF2', delU_fixed; 'parHW', 'delH2', delU_fixed}], NaN), ...
    mk_ext('Capital, variable utilization', SAM, 3, [], '-.', 'none', ...
           '', 'Variable utilization', ...
           [capK; {'par', 'delF2', 0.3; 'parHW', 'delH2', 0.3}], NaN)];

% ---- (literature combinations, unnumbered; array position 12) Adverse literature combinations of the two Phillips-curve slopes (table rows only) --
% Added 2026-10-06 (per Konstantin): the two (NKPC_Slope, NKWPC_Slope) pairs from the literature
% that bring a shock closest to a regime threshold (scripts/online_VI_rigidity_grid.m):
% ranges.kap_corner. No IRF figure (.no_figure); rows in tab:robust_full only.
kc = ranges.kap_corner;
c = c + 1;
checks(c).tag           = 'kapcorner';
checks(c).num           = NaN;
checks(c).part          = 'B';
checks(c).table_order   = 7.5;
checks(c).title         = 'Adverse Literature Combinations of the Phillips-Curve Slopes';
checks(c).bench_changes = true;
checks(c).no_figure     = true;
checks(c).base_leg      = 'Baseline';
checks(c).base_group    = SAM;
checks(c).base_order    = 1;
checks(c).ext = [ ...
    mk_ext('Flat price, steep wage curve', SAM, 2, [], '--', 'none', ...
           'Lit. combinations', sprintf('$(%.3f,\\,%.3f)$', round(1e3*kc(1,1))/1e3, round(1e3*kc(1,2))/1e3), ...
           {'target', 'nkpc_slope', kc(1,1); 'target', 'nkwpc_slope', kc(1,2)}, {}), ...
    mk_ext('Steep price, flat wage curve', SAM, 3, [], '-.', 'none', ...
           '', sprintf('$(%.3f,\\,%.3f)$', round(1e3*kc(2,1))/1e3, round(1e3*kc(2,2))/1e3), ...
           {'target', 'nkpc_slope', kc(2,1); 'target', 'nkwpc_slope', kc(2,2)}, {})];

end

% =========================================================================
function e = mk_ext(leg, group, order, col, ls, marker, row, change, dyn_ovr, slopes_ovr)
e.leg        = leg;
e.group      = group;
e.order      = order;
e.col        = col;
e.ls         = ls;
e.marker     = marker;
e.row        = row;
e.change     = change;
e.dyn_ovr    = dyn_ovr;
e.slopes_ovr = slopes_ovr;
end
