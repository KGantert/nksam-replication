function ax = plot_slopes_panel_3line(ttl, sam, nk_or_empty, x, lwd, cG, cGray, clrs)
% (Extracted 2026-09-29 from figs_slope.m, where it was a nested function, so that
%  online_VI_fixed_kapP.m can reuse it instead of a verbatim copy.)
% Like plot_slopes_panel above, but sam is [nG x 3 x nT] using the
% extended (figure-local, not par.subQ_loop) convention:
%   dim2=1: black   (Gamma_Q=-2.7)
%   dim2=2: colored (Gamma_Q~0, default)
%   dim2=3: gray    (Gamma_Q~-infinity)   <- NEW, 2026-09-22
% No legend is built here -- the caller builds one grouped legend via
% build_grouped_subQ_legend() after all panels in the figure are drawn.
nexttile; hold on;
styles_k = {'k--','k-.','k-'};
for gg = 1:3
    plot(x, squeeze(sam(gg,1,:))', styles_k{gg}, 'Linewidth', 1, 'HandleVisibility', 'off');
end
styles_gray = {'--','-.','-'};
for gg = 1:3
    plot(x, squeeze(sam(gg,3,:))', styles_gray{gg}, 'Color', cGray, 'Linewidth', 1, 'HandleVisibility', 'off');
end
if isempty(nk_or_empty)
    yline(0, 'LineWidth', lwd, 'Color', cG, 'HandleVisibility', 'off');
else
    yline(squeeze(mean(nk_or_empty,'all')), 'LineWidth', lwd, 'Color', cG, 'HandleVisibility', 'off');
end
ls = {'--','-.', '-'};
for gg = 1:3
    plot(x, squeeze(sam(gg,2,:))', ls{gg}, 'Linewidth', lwd, 'Color', clrs(gg,:), 'HandleVisibility', 'off');
end
hold off; axis tight;
xlabel('$\nu_D$','Interpreter','latex'); title(ttl, 'Interpreter', 'latex');
ax = gca;
end
