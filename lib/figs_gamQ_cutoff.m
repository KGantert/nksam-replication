function figs_gamQ_cutoff(gamQ_cut_loop_mp, gamQ_cut_loop_eps, mp_cut_loop, epsP_cut_loop, lwdth)
% FIGS_GAMQ_CUTOFF  Cutoff-value figure for gamma_Q (Appendix C, fig:cutoff_gammaQ; called by scripts/main_s3_s4_slopes.m).
%   The two steady-state experiments of Online Appendix V.1 are in figs_stst_experiments.m (called by scripts/online_V1_steady_states.m).
%
%   Inputs
%     gamQ_cut_loop_mp   - cutoff values along the markup grid (self-consistent
%                          under the calibration's own epsilon(gamQ) mapping)
%     gamQ_cut_loop_eps  - cutoff values along the epsP grid (epsilon held fixed)
%     mp_cut_loop        - markup grid of the markup-conditional panel
%     epsP_cut_loop      - epsP grid of the epsilon-conditional panel
%     lwdth              - line width

% Colour palette
c1   = [0,      0.4470, 0.7410];
c2   = [0.8500, 0.3250, 0.0980];
c3   = [0.9290, 0.6940, 0.1250];
clrs = [c1; c2; c3];

%% Cutoff value of gamma_Q: conditional on epsilon (general), and self-consistent
%  under the markup calibration -- both carry distinct content (see
%  chapters/appendix/ap_cutoffs.tex, eq:cutoff_gammaQ_eps vs.
%  eq:cutoff_gammaQ_selfconsistent), so both are shown side by side.
figure('Name','Cutoff Value of gamQ: epsilon-conditional and markup-conditional')
tiledlayout(1,2);

nexttile; hold on;
plot(epsP_cut_loop, gamQ_cut_loop_eps, 'LineWidth', lwdth);
hold off; axis tight;
xlabel('$\epsilon$', 'Interpreter', 'latex');
ylabel('Cutoff Value $\gamma_Q$', 'Interpreter', 'latex');
title('Conditional on $\epsilon$', 'Interpreter', 'latex');

nexttile; hold on;
plot(mp_cut_loop, gamQ_cut_loop_mp, 'LineWidth', lwdth);
hold off; axis tight;
xlabel('StSt Price Markup', 'Interpreter', 'latex');
ylabel('Cutoff Value $\gamma_Q$', 'Interpreter', 'latex');
title('Self-Consistent (Markup)', 'Interpreter', 'latex');

save_fig(nksam_path('figures', 'fig_stst_gamES_cutoff.eps'), 18, 6)

end
