function figs_stst_experiments(stst_fixed, stst_targ, gamQ, epsP_loop, mp_loop, psiQ_loop, lwdth)
% FIGS_STST_EXPERIMENTS  The two steady-state experiments of Online Appendix V.1
%   (chapters/online_appendix/ap_additional_results.tex), one figure each.
%
%   Experiment 1 -- FIXED PARAMETERS (stst_target = 0, mp_select = 0): psiQ, muN, ... stay at
%     their baseline-calibrated values, epsilon is an input; gamQ varies for three values of
%     epsilon (output-by-psiQ panel: for three values of psiQ instead).
%       -> results/figures/fig_stst_fixed.eps (2x2): search price | price elasticity ; output | output (by psiQ)
%   Experiment 2 -- TARGETED CALIBRATION (stst_target = 1, mp_select = 1): q, N and the markup are
%     targets, psiQ, muN and epsilon are solved for; gamQ varies for three markups.
%       -> results/figures/fig_stst_targeted.eps: search price | epsilon
%     Output is omitted (equals q for every gamQ and markup; stated in the text). Marginal
%     utility is omitted in both figures (not needed for the argument).
%
%   Written 2026-09-25 without a MATLAB run; check legend placement (tile legends need R2019b+).

c1 = [0, 0.4470, 0.7410]; c2 = [0.8500, 0.3250, 0.0980]; c3 = [0.9290, 0.6940, 0.1250];
clrs = [c1; c2; c3];
eps_lbl = string(num2cell(round(epsP_loop, 1)));
psi_lbl = string(num2cell(round(psiQ_loop, 2)));
mp_lbl  = string(num2cell(round(mp_loop, 1)));

%% Experiment 1: fixed parameters ------------------------------------------
% 2x2 grid built from two nested 1x2 layouts: top = search price | price elasticity
% (one epsilon legend centered below the pair); bottom = output (epsilon) | output
% (psiQ), each with its own legend centered below its tile (different line families).
figure('Name', 'Steady State: fixed parameters');
outer = tiledlayout(2, 1, 'TileSpacing', 'loose', 'Padding', 'compact');

top = tiledlayout(outer, 1, 2, 'TileSpacing', 'compact');
top.Layout.Tile = 1;
ax1 = nexttile(top); hold on;
for kk = 1:3, plot(gamQ, stst_fixed.ps_epsP_sam(:,kk), 'LineWidth', lwdth, 'Color', clrs(kk,:)); end
hold off; axis tight; xlabel('$\gamma_Q$', 'Interpreter', 'latex');
ylabel('Price Level', 'Interpreter', 'latex'); title('Search Price', 'Interpreter', 'latex');

ax2 = nexttile(top); hold on;
for kk = 1:3, plot(gamQ, stst_fixed.pe_epsP_sam(:,kk) ./ stst_fixed.pe_epsP_nk(:,kk), 'LineWidth', lwdth, 'Color', clrs(kk,:)); end
hold off; axis tight; xlabel('$\gamma_Q$', 'Interpreter', 'latex');
ylabel('Ratio to NK', 'Interpreter', 'latex'); title('Price Elasticity', 'Interpreter', 'latex');

lg1 = legend(ax2, eps_lbl, 'Orientation', 'horizontal', 'Interpreter', 'latex');
title(lg1, '$\epsilon$', 'Interpreter', 'latex');
lg1.Layout.Tile = 'south';

bot = tiledlayout(outer, 1, 2, 'TileSpacing', 'compact');
bot.Layout.Tile = 2;
ax3 = nexttile(bot); hold on;
for kk = 1:3, plot(gamQ, stst_fixed.t_epsP_sam(:,kk) ./ stst_fixed.t_epsP_nk(:,kk), 'LineWidth', lwdth, 'Color', clrs(kk,:)); end
hold off; axis tight; xlabel('$\gamma_Q$', 'Interpreter', 'latex');
ylabel('Ratio to NK', 'Interpreter', 'latex'); title('Output', 'Interpreter', 'latex');

ax4 = nexttile(bot); hold on;
for kk = 1:3, plot(gamQ, stst_fixed.t_psiQ_sam(:,kk) ./ stst_fixed.t_psiQ_nk(:,kk), 'LineWidth', lwdth, 'Color', clrs(kk,:)); end
hold off; axis tight; xlabel('$\gamma_Q$', 'Interpreter', 'latex');
ylabel('Ratio to NK', 'Interpreter', 'latex'); title('Output (by $\psi_Q$)', 'Interpreter', 'latex');

lg3 = legend(ax3, eps_lbl, 'Orientation', 'horizontal', 'Location', 'southoutside', 'Interpreter', 'latex');
title(lg3, '$\epsilon$', 'Interpreter', 'latex');
lg4 = legend(ax4, psi_lbl, 'Orientation', 'horizontal', 'Location', 'southoutside', 'Interpreter', 'latex');
title(lg4, '$\psi_Q$', 'Interpreter', 'latex');

save_fig(nksam_path('figures', 'fig_stst_fixed.eps'), 14, 11)

%% Experiment 2: targeted calibration -------------------------------------
figure('Name', 'Steady State: targeted calibration');
tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile; hold on;
for kk = 1:3, plot(gamQ, stst_targ.ps_epsP_sam(:,kk), 'LineWidth', lwdth, 'Color', clrs(kk,:)); end
hold off; axis tight; xlabel('$\gamma_Q$', 'Interpreter', 'latex');
ylabel('Price Level', 'Interpreter', 'latex'); title('Search Price', 'Interpreter', 'latex');

axe = nexttile; hold on;
for kk = 1:3, plot(gamQ, stst_targ.eps_epsP_sam(:,kk) ./ stst_targ.eps_epsP_nk(:,kk), 'LineWidth', lwdth, 'Color', clrs(kk,:)); end
hold off; axis tight; xlabel('$\gamma_Q$', 'Interpreter', 'latex');
ylabel('Ratio to NK', 'Interpreter', 'latex'); title('$\epsilon$ (Fixed Markup)', 'Interpreter', 'latex');

lg3 = legend(axe, mp_lbl, 'Orientation', 'horizontal', 'Interpreter', 'latex');
title(lg3, '$\mathrm{Markup}$', 'Interpreter', 'latex');
lg3.Layout.Tile = 'south';

save_fig(nksam_path('figures', 'fig_stst_targeted.eps'), 14, 6.5)

end
