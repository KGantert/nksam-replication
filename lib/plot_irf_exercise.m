function plot_irf_exercise(res_array, plot_cfg)
% PLOT_IRF_EXERCISE  Plot per-shock IRF comparison panels for one exercise.
%
%   Creates one figure per shock, each with a tiled layout of variable panels.
%   Supports both shaded-area and line rendering per scenario.
%
% -------------------------------------------------------------------------
% INPUTS
% -------------------------------------------------------------------------
%   res_array   1×N struct array, each element the output of run_dynare_scenario
%
%   plot_cfg    Struct with fields:
%     .var_select    String array — variable names to plot (must be in res.irfs)
%     .title_select  String array — panel titles, same length as var_select
%     .shocks        String array — shock names to loop over, e.g. ["eA","eM"]
%     .shock_labels  String array — human-readable shock names for figure titles
%     .shock_tags    String array — filename suffixes, e.g. ["tfp","policy"]
%     .fig_prefix    String — output path prefix, e.g. nksam_path('figures', 'fig_irf_default')
%     .legend        Cell array of strings — one label per scenario (can be {})
%     .styles        1×N struct array, one per scenario:
%                      .type       'line' or 'area'
%                      .color      RGB triplet [r g b]
%                      .marker     Marker string, e.g. 'o', 'x', 'v', '' (line only)
%                      .linestyle  Line style string, e.g. '-', '--' (line only)
%                      .alpha      Fill transparency 0-1 (area only, default 1)
%     .layout        [nrows ncols] for tiledlayout (optional, default auto-square)
%     .fig_size      [width height] in cm (optional, default [21 9])
%     .font_size     Points (optional, default 7)
%     .legend_cols   Number of legend columns (optional, default 4)

% -------------------------------------------------------------------------
% Defaults
% -------------------------------------------------------------------------
if ~isfield(plot_cfg, 'fig_size'),    plot_cfg.fig_size   = [21 9]; end
if ~isfield(plot_cfg, 'font_size'),   plot_cfg.font_size  = 7;      end
if ~isfield(plot_cfg, 'legend_cols'), plot_cfg.legend_cols = 4;     end
if ~isfield(plot_cfg, 'unit_select')
    plot_cfg.unit_select = repmat("%-Dev.", 1, numel(plot_cfg.var_select));
end
if ~isfield(plot_cfg, 'layout')
    nn = numel(plot_cfg.var_select);
    nr = ceil(sqrt(nn));
    nc = ceil(nn / nr);
    plot_cfg.layout = [nr nc];
end

n_shocks   = numel(plot_cfg.shocks);
n_scenarios = numel(res_array);
w = plot_cfg.fig_size(1);
hh = plot_cfg.fig_size(2);

% -------------------------------------------------------------------------
% Loop over shocks — one figure per shock
% -------------------------------------------------------------------------
for ss = 1:n_shocks
    shock_name = char(plot_cfg.shocks(ss));
    fig_title  = sprintf('IRFs to a %s Shock', plot_cfg.shock_labels(ss));

    figure('Name', fig_title);
    tiledlayout(plot_cfg.layout(1), plot_cfg.layout(2));

    % -- Variable panels --------------------------------------------------
    for ii = 1:numel(plot_cfg.var_select)
        vname = char(plot_cfg.var_select(ii));
        nexttile;
        hold on;
        yline(0, 'Color', [0.6 0.6 0.6], 'LineStyle', '-');

        for kk = 1:n_scenarios
            sty = plot_cfg.styles(kk);

            % Retrieve IRF vector
            if ~isfield(res_array(kk).irfs, shock_name) || ...
               ~isfield(res_array(kk).irfs.(shock_name), vname)
                warning('plot_irf_exercise: IRF not found for shock=%s, var=%s, scenario=%d', ...
                        shock_name, vname, kk);
                continue;
            end
            irf_data = res_array(kk).irfs.(shock_name).(vname);

            if strcmp(sty.type, 'area')
                alpha_val = 1;
                if isfield(sty, 'alpha'), alpha_val = sty.alpha; end
                area(irf_data, 'LineStyle', 'none', ...
                               'FaceColor', sty.color, ...
                               'FaceAlpha', alpha_val);
            else
                ls = '-';
                if isfield(sty, 'linestyle'), ls = sty.linestyle; end
                mk = '';
                if isfield(sty, 'marker'), mk = sty.marker; end
                plot(irf_data, [mk ls], 'LineWidth', 1, 'Color', sty.color);
            end
        end

        hold off;
        axis tight;
        title(char(plot_cfg.title_select(ii)));
        ylabel(char(plot_cfg.unit_select(ii)));
        xlabel('Quarters');
    end

    % -- Legend -----------------------------------------------------------
    if isfield(plot_cfg, 'legend') && ~isempty(plot_cfg.legend)
        leg = legend(plot_cfg.legend{:}, ...
                     'Location',    'southoutside', ...
                     'Orientation', 'horizontal',   ...
                     'NumColumns',  plot_cfg.legend_cols);
        leg.Layout.Tile = 'South';
    end

    % -- Figure formatting and export -------------------------------------
    set(gcf, 'Units',            'centimeters');
    set(gcf, 'Position',         [0 0 w hh]);
    set(gcf, 'PaperUnits',       'centimeters');
    set(gcf, 'PaperSize',        [w hh]);
    set(gcf, 'PaperPositionMode','manual');
    set(gcf, 'PaperPosition',    [0 0 w hh]);
    fontsize(gcf, plot_cfg.font_size, 'points');

    out_file = sprintf('%s_%s.eps', plot_cfg.fig_prefix, plot_cfg.shock_tags(ss));
    ensure_dir(char(out_file));
    exportgraphics(gcf, char(out_file), 'ContentType', 'vector');
end

end
