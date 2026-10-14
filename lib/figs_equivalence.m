% *************************************************************************
% When Buying Takes Time:
% Implications for the New-Keynesian Business Cycle Model
% Reduced-Form Model: GOODS MARKET SaM PARAMETER EQUIVALENCE - FIGURES
% -------------------------------------------------------------------------
% Konstantin Gantert
% kgantert@mail.de
% *************************************************************************

function figs_equivalence(eq, lwdth)
% FIGS_EQUIVALENCE  Plot the goods-market SaM parameter equivalence
%   experiment results from compute_param_equivalence.
%
%   Inputs
%     eq    - output struct from compute_param_equivalence (fields .AD,
%             .WG, .AS, .baseline)
%     lwdth - line width for all graphs
%
%   Figures
%     fig_equiv_AD.eps - AD_ag target: heatmaps of the solved gamQ, and
%                         of CU_ag/PE_ag/LW_ag/AS_ag/WG_ag, over the
%                         (subQ, nuD) grid.
%     fig_equiv_WG.eps - WG_ag target: same layout, targeting WG_ag.
%     fig_equiv_AS.eps - AS_ag/kapP target: gamQ is fixed at baseline, so
%                         results are plotted as line panels against subQ
%                         (solved nuD, CU_ag, PE_ag, LW_ag, AD_ag, kapP).

plot_gamQ_experiment(eq.AD, eq.baseline, lwdth, {'AS_ag','WG_ag'}, {'AS_{ag}','WG_{ag}'}, ...
    '$AD_{ag}$ Equivalence: solving for $\gamma_Q$ to match the Euler equation', ...
    nksam_path('figures', 'fig_equiv_AD.eps'));

plot_gamQ_experiment(eq.WG, eq.baseline, lwdth, {'AS_ag','AD_ag'}, {'AS_{ag}','AD_{ag}'}, ...
    '$WG_{ag}$ Equivalence: solving for $\gamma_Q$ to match the real wage equation', ...
    nksam_path('figures', 'fig_equiv_WG.eps'));

plot_nuD_experiment(eq.AS, eq.baseline, lwdth, ...
    '$AS_{ag} / \kappa_P$ Equivalence: $\gamma_Q$ fixed at baseline, solving for $\nu_D$', ...
    nksam_path('figures', 'fig_equiv_AS.eps'));

end


% =========================================================================
% LOCAL HELPERS
% =========================================================================

function plot_gamQ_experiment(ex, base, lwdth, diag_fields, diag_labels, fig_title, fname)
% PLOT_GAMQ_EXPERIMENT  2x3 heatmap grid over (subQ, nuD): the solved
%   gamQ itself, then CU_ag, PE_ag, LW_ag, and the two diagnostic fields
%   passed in (the priority coefficients NOT being targeted here).

panel_fields = [{'gamQ_used'}, {'CU_ag'}, {'PE_ag'}, {'LW_ag'}, diag_fields];
panel_labels = [{'\gamma_Q^*'}, {'CU_{ag}'}, {'PE_{ag}'}, {'LW_{ag}'}, diag_labels];

figure('Name', fig_title);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

for pp = 1:numel(panel_fields)
    fld = panel_fields{pp};
    if strcmp(fld, 'gamQ_used')
        Z        = ex.gamQ_used;
        base_val = base.gamQ;
    else
        Z        = ex.coef.(fld);
        base_val = base.(fld);
    end

    nexttile; hold on;

    % Heatmap over the (subQ, nuD) grid; NaN cells (no feasible root) are
    % left blank.
    pcolor(ex.nuD_grid, ex.subQ_grid, Z);
    shading interp;
    colorbar;

    % Contour at the coefficient's baseline value, if it is actually
    % spanned by the grid (shows where a coefficient incidentally
    % matches baseline even though it was not the solved-for target).
    finite_vals = Z(isfinite(Z));
    if numel(finite_vals) >= 2 && min(finite_vals) < base_val && base_val < max(finite_vals)
        contour(ex.nuD_grid, ex.subQ_grid, Z, [base_val base_val], 'k-', 'LineWidth', lwdth);
    end

    % Baseline calibration point
    plot(base.nuD, base.subQ, 'k+', 'MarkerSize', 10, 'LineWidth', lwdth);

    hold off;
    xlabel('$\nu_D$', 'Interpreter', 'latex');
    ylabel('$\Gamma_Q$', 'Interpreter', 'latex');
    title(['$' panel_labels{pp} '$'], 'Interpreter', 'latex');
end

sgtitle(fig_title, 'Interpreter', 'latex');
save_fig(fname, 21, 12)
end

function plot_nuD_experiment(ex, base, lwdth, fig_title, fname)
% PLOT_NUS_EXPERIMENT  2x3 line-plot grid against subQ (gamQ fixed at
%   baseline): the solved nuD itself, then CU_ag, PE_ag, LW_ag, AD_ag,
%   kapP, each with the baseline value marked by a dashed reference line.

% Last panel shows whichever Phillips-curve object is free under the active
% calibration mode: kappa_P when the labour-share slope is targeted, the
% implied labour-share slope when kappa_P is imposed directly.
if isfield(ex, 'pc_field') && strcmp(ex.pc_field, 'pc_slope_impl')
    pc_fld = 'pc_slope_impl';   pc_lab = 'NKPC_{Slope}';
else
    pc_fld = 'kapP';            pc_lab = '\kappa_P';
end
panel_fields = {'nuD_used', 'CU_ag', 'PE_ag', 'LW_ag', 'AD_ag', pc_fld};
panel_labels = {'\nu_D^*', 'CU_{ag}', 'PE_{ag}', 'LW_{ag}', 'AD_{ag}', pc_lab};

figure('Name', fig_title);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

for pp = 1:numel(panel_fields)
    fld = panel_fields{pp};
    if strcmp(fld, 'nuD_used')
        y        = ex.nuD_used;
        base_val = base.nuD;
    else
        y        = ex.coef.(fld);
        base_val = base.(fld);
    end

    nexttile; hold on;
    plot(ex.subQ_grid, y, 'o-', 'LineWidth', lwdth, 'Color', [0, 0.4470, 0.7410]);
    yline(base_val, 'k--', 'LineWidth', lwdth);
    plot(base.subQ, base_val, 'k+', 'MarkerSize', 10, 'LineWidth', lwdth);
    hold off; axis tight;
    xlabel('$\Gamma_Q$', 'Interpreter', 'latex');
    title(['$' panel_labels{pp} '$'], 'Interpreter', 'latex');
end

sgtitle(fig_title, 'Interpreter', 'latex');
save_fig(fname, 21, 12)
end

% ----------------------------- End of file -------------------------------
