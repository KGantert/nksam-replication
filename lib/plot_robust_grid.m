function fac = plot_robust_grid(base, out, chk, g)
% PLOT_ROBUST_GRID  One-page robustness IRF figure (Online Appendix VI).
%
%   Layout: one row per variable (g.vars, 8 rows), one column per shock
%   (g.shocks, 4 columns, main-text order).
%   Normalization: ONE factor per shock, 1 / (baseline NK-SaM impact
%   response of real GDP), applied to every line in that column.
%   Encoding: benchmark lines grey (g.col_bench), NK-SaM lines orange
%   (g.col_sam) unless a variant sets its own colour (.col); baseline solid,
%   variants with their own line style/marker (.ls/.marker). Benchmark
%   variants reuse the style of the matching NK-SaM variant. The benchmark
%   is drawn once if chk.bench_changes is false, and never in the
%   g.no_bench_shock column (no search-effort shock in the benchmark).
%
%   Legend: grouped like the main-text slope figures
%   (slopes/plotting/figs_slope.m, build_grouped_subQ_legend): one column
%   per group with a LaTeX headline -- "Benchmark model" first, then the
%   NK-SaM group(s) in order of first appearance (baseline group first);
%   entries within a group sorted by .order. Built from invisible proxy
%   axes below the grid, so labels can never shift against the lines.
%
%   Returns fac (1 x nShocks normalization factors) for the log.

nS = numel(g.shocks);
nV = numel(g.vars);
nE = numel(chk.ext);

% ---- normalization factors ---------------------------------------------------
fac = zeros(1, nS);
for s = 1:nS
    y0 = base.sam.irfs.(char(g.shocks(s))).gdp_obs(1);
    if abs(y0) < 1e-6
        error('plot_robust_grid: baseline NK-SaM impact GDP ~ 0 for shock %s.', g.shocks(s));
    end
    fac(s) = 1 / y0;
end

% ---- series (group, order, style) -------------------------------------------
BENCH = 'Benchmark model';
ser = mkser(base.nk, g.col_bench, '-', 'none', g.lw_base, chk.base_leg, true, BENCH, chk.base_order);
if chk.bench_changes
    for k = 1:nE
        if isempty(out.nk{k}), continue; end          % failed variant
        e = chk.ext(k);
        ser(end+1) = mkser(out.nk{k}, g.col_bench, e.ls, e.marker, g.lw_ext, e.leg, true, BENCH, e.order); %#ok<AGROW>
    end
else
    ser(1).lab = 'Unchanged';
end
ser(end+1) = mkser(base.sam, g.col_sam, '-', 'none', g.lw_base, chk.base_leg, false, chk.base_group, chk.base_order);
for k = 1:nE
    if isempty(out.sam{k}), continue; end              % failed variant
    e = chk.ext(k);
    col = g.col_sam; if ~isempty(e.col), col = e.col; end
    ser(end+1) = mkser(out.sam{k}, col, e.ls, e.marker, g.lw_ext, e.leg, false, e.group, e.order); %#ok<AGROW>
end

% legend groups: benchmark, then NK-SaM groups in order of first appearance
gnames = unique({ser.group}, 'stable');
gnames = [{BENCH}, setdiff(gnames, {BENCH}, 'stable')];
nG     = numel(gnames);
nMax   = max(cellfun(@(gn) nnz(strcmp({ser.group}, gn)), gnames));

% ---- figure and legend band --------------------------------------------------
w = g.fig_size(1); hh = g.fig_size(2);
fig = figure('Name', chk.title, 'Color', 'w', 'Units', 'centimeters', 'Position', [0 0 w hh]);
band = (0.42 * (nMax + 1) + 0.25) / hh;          % legend band, share of height

tl = tiledlayout(fig, nV, nS, 'TileSpacing', 'compact', 'Padding', 'compact');
tl.OuterPosition = [0 band 1 1-band];

for v = 1:nV
    vn = char(g.vars(v));
    for s = 1:nS
        sh = char(g.shocks(s));
        ax = nexttile(tl);
        hold(ax, 'on');
        yline(ax, 0, 'Color', [0.75 0.75 0.75], 'LineWidth', 0.5, 'HandleVisibility', 'off');
        T = 0;
        for j = 1:numel(ser)
            if ser(j).bench && strcmp(sh, g.no_bench_shock), continue; end
            if ~isfield(ser(j).res.irfs, sh) || ~isfield(ser(j).res.irfs.(sh), vn)
                warning('plot_robust_grid: IRF %s/%s missing for "%s".', sh, vn, ser(j).lab);
                continue;
            end
            y = ser(j).res.irfs.(sh).(vn)(:)' .* fac(s);
            T = max(T, numel(y));
            plot(ax, 1:numel(y), y, 'Color', ser(j).col, 'LineStyle', ser(j).ls, ...
                 'Marker', ser(j).marker, 'MarkerSize', g.marker_size, 'LineWidth', ser(j).lw);
        end
        hold(ax, 'off');

        axis(ax, 'tight');
        yl = ylim(ax); r = diff(yl); if r <= 0, r = max(abs(yl(1)), 1e-3); end
        ylim(ax, yl + [-0.08 0.08] .* r);
        xlim(ax, [1 max(T, 2)]);
        xticks(ax, unique([1, 4:4:max(T, 4)]));
        if v < nV, xticklabels(ax, {}); else, xlabel(ax, 'Quarters'); end
        if v == 1, title(ax, g.shock_titles(s), 'FontWeight', 'normal'); end
        if s == 1, ylabel(ax, g.var_titles(v)); end
        box(ax, 'off');
        ax.TickLength = [0.02 0.02];
    end
end
fontsize(fig, g.font_size, 'points');     % before the legends, which set their own sizes

% ---- grouped legend (proxy axes, one column per group) --------------------------
colw = 1 / nG;
for gi = 1:nG
    idx = find(strcmp({ser.group}, gnames{gi}));
    [~, o] = sort([ser(idx).order]); idx = idx(o);
    axL = axes(fig, 'Position', [(gi-1)*colw, 0.005, colw, band - 0.01], 'Visible', 'off');
    hold(axL, 'on');
    hp = gobjects(1, numel(idx));
    for jj = 1:numel(idx)
        sj = ser(idx(jj));
        hp(jj) = plot(axL, NaN, NaN, 'Color', sj.col, 'LineStyle', sj.ls, 'Marker', sj.marker, ...
                      'MarkerSize', g.marker_size, 'LineWidth', sj.lw);
    end
    hold(axL, 'off');
    lg = legend(axL, hp, {ser(idx).lab}, 'Location', 'north', 'Box', 'off', ...
                'Interpreter', 'latex', 'FontSize', g.font_size - 1);
    title(lg, gnames{gi}, 'Interpreter', 'latex', 'FontSize', g.font_size - 0.5);
end

% ---- export ---------------------------------------------------------------------
set(fig, 'PaperUnits', 'centimeters', 'PaperSize', [w hh], ...
         'PaperPositionMode', 'manual', 'PaperPosition', [0 0 w hh]);
out_file = nksam_path('figures', sprintf('fig_robust_%s.eps', chk.tag));
ensure_dir(out_file);
exportgraphics(fig, out_file, 'ContentType', 'vector');
fprintf('  wrote %s\n', out_file);
end

% =========================================================================
function s = mkser(res, col, ls, marker, lw, lab, bench, group, order)
s.res    = res;
s.col    = col;
s.ls     = ls;
s.marker = marker;
s.lw     = lw;
s.lab    = lab;
s.bench  = bench;
s.group  = group;
s.order  = order;
end
