function build_grouped_subQ_legend(lwd, cG, cGray, clrs, gamQ_vals, pos)
% (Extracted 2026-09-29 from figs_slope.m, where it was a nested function, so that
%  online_VI_fixed_kapP.m can reuse it instead of a verbatim copy.)
% BUILD_GROUPED_SUBQ_LEGEND  Grouped Gamma_Q legend for a plot_slopes_panel_3line
%   figure: a single NK-benchmark entry spanning the top, and three columns
%   below it (one per Gamma_Q group: -2.7 / ~0 default / ~-infinity), each
%   titled with its Gamma_Q value and listing its 3 gamma_Q rows. Built
%   from dedicated invisible proxy axes (not the panels' own line handles)
%   so the layout is independent of MATLAB's ambiguous multi-column legend
%   fill order (2026-09-22, per Konstantin's iterative tuning on the cu_pe
%   figure -- reused here verbatim for lw_se_mc).
%   pos: struct with fields bench, col1, col2, col3, each a [x y w h]
%        normalized-figure-units Position vector.
gamLab = arrayfun(@(v) sprintf('$\\gamma_Q=%.3g$', v), gamQ_vals, 'UniformOutput', false);

axBench = axes('Position', pos.bench, 'Visible', 'off');
hold(axBench, 'on');
hBench = plot(axBench, NaN, NaN, 'LineWidth', lwd, 'Color', cG);
hold(axBench, 'off');
legend(axBench, hBench, {'NK benchmark ($\gamma_Q=0$)'}, 'Orientation', 'horizontal', ...
    'Location', 'north', 'Box', 'off', 'Interpreter', 'latex', 'FontSize', 7);

styles_k = {'k--','k-.','k-'};
axG1 = axes('Position', pos.col1, 'Visible', 'off');
hold(axG1, 'on');
hG1 = gobjects(1,3);
for gg = 1:3; hG1(gg) = plot(axG1, NaN, NaN, styles_k{gg}, 'LineWidth', 1); end
hold(axG1, 'off');
legG1 = legend(axG1, hG1, gamLab, 'Location', 'north', 'Box', 'off', 'Interpreter', 'latex', 'FontSize', 6);
title(legG1, '$\Gamma_Q=-2.7$ (CES)', 'Interpreter', 'latex', 'FontSize', 6.5);

styles_gray = {'--','-.','-'};
axG2 = axes('Position', pos.col2, 'Visible', 'off');
hold(axG2, 'on');
hG2 = gobjects(1,3);
for gg = 1:3; hG2(gg) = plot(axG2, NaN, NaN, styles_gray{gg}, 'Color', cGray, 'LineWidth', 1); end
hold(axG2, 'off');
legG2 = legend(axG2, hG2, gamLab, 'Location', 'north', 'Box', 'off', 'Interpreter', 'latex', 'FontSize', 6);
title(legG2, '$\Gamma_Q\to-\infty$ (perfect complements)', 'Interpreter', 'latex', 'FontSize', 6.5);

ls = {'--', '-.', '-'};
axG3 = axes('Position', pos.col3, 'Visible', 'off');
hold(axG3, 'on');
hG3 = gobjects(1,3);
for gg = 1:3; hG3(gg) = plot(axG3, NaN, NaN, ls{gg}, 'Color', clrs(gg,:), 'LineWidth', lwd); end
hold(axG3, 'off');
legG3 = legend(axG3, hG3, gamLab, 'Location', 'north', 'Box', 'off', 'Interpreter', 'latex', 'FontSize', 6);
title(legG3, '$\Gamma_Q\approx0$ (Cobb-Douglas, baseline)', 'Interpreter', 'latex', 'FontSize', 6.5);
end
