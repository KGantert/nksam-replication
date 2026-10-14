function figs_slope(res_sam, res_nk, res_gray, gamQ_low, gamQ_cut, gamQ_high, nuD_loop, nuD_base, lwdth)
% FIGS_SLOPE  Reduced-form slope figures of the paper (called by scripts/main_s3_s4_slopes.m).
%
%   Writes (results/figures, results/txt):
%     fig_slopes_5eq_cu_pe.eps     Section 3, fig:slopes_5eq_util (utilization and price-elasticity gaps)
%     fig_slopes_5eq_ee_pc_rw.eps  Section 4, fig:slopes_5eq (dynamic IS, price Phillips curve, real wage growth)
%     fig_slopes_5eq_lw_se_mc.eps  Online Appendix V.2 (labor wedge, search effort, marginal cost gaps)
%     fig_slopes_5eq_*.txt         endpoint/crossing tables of each figure
%   Each panel shows Gamma_Q ~ 0 (coloured), Gamma_Q = -2.7 (black) and
%   Gamma_Q -> -infinity (grey) for gamma_Q = gamQ_low / gamQ_cut / gamQ_high.
%
%   Inputs
%     res_sam, res_nk - compute_sensitivity results (NK-SaM, benchmark), from setup_slopes.m
%     res_gray        - Gamma_Q -> -infinity (par.subQ_low) variant, from setup_slopes.m
%     gamQ_low, gamQ_cut, gamQ_high - the three gamma_Q values
%     nuD_loop        - nu_D grid (x-axis; nu_N fixed at baseline)
%     nuD_base        - baseline nu_D (marked in the endpoint tables)
%     lwdth           - line width
%   Shared helpers: plot_slopes_panel_3line.m, build_grouped_subQ_legend.m (lib/).

% Shared style constants
cGreen  = [0.4660, 0.6740, 0.1880];
cBlue   = [0,      0.4470, 0.7410];
cOrange = [0.8500, 0.3250, 0.0980];
cYellow = [0.9290, 0.6940, 0.1250];
cGray   = [0.65,   0.65,   0.65];   % NEW 2026-09-22: Gamma_Q -> -infinity line color
clrs    = [cBlue; cOrange; cYellow];


% Names of the two res_sam subQ variants in the .txt endpoint tables.
% Must match get_params.m: par.subQ_loop = [par.subQ_mid, par.subQ].
subQ_labels = {'GamQ=-2.7 (CES)', 'GamQ~0 (CD, default)'};

%% ------------------------------------------------------------------------
% Figure: Capacity Utilization & Price Elasticity (2x2, separate t and ue)
% 2026-09-22 (per Konstantin): extended to a 3rd (gray, Gamma_Q->-infinity)
% line pair with a grouped Gamma_Q legend -- see plot_slopes_panel_3line and
% build_grouped_subQ_legend below. write_endpoint_table's .txt dump further
% below is deliberately left on the original 2-variant res_sam data (see
% lib/setup_slopes.m's res_gray comment for why the 3rd variant is kept
% separate from that pipeline).
% -------------------------------------------------------------------------
CU_t_3  = cat(2, res_sam.nuD.CU_t (:,1,:), res_sam.nuD.CU_t (:,2,:), res_gray.nuD.CU_t (:,1,:));
CU_ue_3 = cat(2, res_sam.nuD.CU_ue(:,1,:), res_sam.nuD.CU_ue(:,2,:), res_gray.nuD.CU_ue(:,1,:));
PE_t_3  = cat(2, res_sam.nuD.PE_t (:,1,:), res_sam.nuD.PE_t (:,2,:), res_gray.nuD.PE_t (:,1,:));
PE_ue_3 = cat(2, res_sam.nuD.PE_ue(:,1,:), res_sam.nuD.PE_ue(:,2,:), res_gray.nuD.PE_ue(:,1,:));

figure('Name','Capacity Utilization & Price Elasticity: output and unemployment gaps')
tl = tiledlayout(2, 2, 'TileIndexing', 'columnmajor');
tl.OuterPosition = [0 0.171 1 0.829];
tl.Padding = 'compact';
tl.TileSpacing = 'compact';

plot_slopes_panel_3line('Output Gap -- Capacity Utilization Gap',             CU_t_3,  [], nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Unemployment Gap -- Capacity Utilization Gap',       CU_ue_3, [], nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Output Gap -- Price Elasticity of Demand Gap',       PE_t_3,  [], nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Unemployment Gap -- Price Elasticity of Demand Gap', PE_ue_3, [], nuD_loop, lwdth, cGreen, cGray, clrs);

build_grouped_subQ_legend(lwdth, cGreen, cGray, clrs, [gamQ_low, gamQ_cut, gamQ_high], ...
    struct('bench', [0.08 0.134 0.84 0.040], ...
           'col1',  [0.06  0.009 0.27 0.131], ...
           'col2',  [0.365 0.009 0.27 0.131], ...
           'col3',  [0.67  0.009 0.27 0.131]));

save_fig(nksam_path('figures', 'fig_slopes_5eq_cu_pe.eps'), 14, 12.7)
write_endpoint_table(nksam_path('txt', 'fig_slopes_5eq_cu_pe.txt'), ...
    'Capacity Utilization & Price Elasticity (output and unemployment gaps)', ...
    {'Output Gap -- CU Gap',             res_sam.nuD.CU_t,  []; ...
     'Unemployment Gap -- CU Gap',       res_sam.nuD.CU_ue, []; ...
     'Output Gap -- PE Gap',             res_sam.nuD.PE_t,  []; ...
     'Unemployment Gap -- PE Gap',       res_sam.nuD.PE_ue, []}, ...
    [gamQ_low, gamQ_cut, gamQ_high], nuD_loop, nuD_base, ...
    {res_gray.nuD.CU_t; res_gray.nuD.CU_ue; res_gray.nuD.PE_t; res_gray.nuD.PE_ue}, subQ_labels)

%% ------------------------------------------------------------------------
% Figure: Dynamic IS Curve, Price Phillips Curve & Real Wage Growth (2x3, separate t and ue)
% 2026-09-22 (per Konstantin): extended to 3 lines / grouped legend, same
% template as the CU & PE figure above. Output filename restored to
% fig_slopes_5eq_ee_pc_rw.eps (was fig_slopes_5eq_ee_pc.eps since the
% 2026-09-15/16 reorg) to match what curves.tex's fig:slopes_5eq has
% included all along -- the mismatch meant the compiled PDF was showing a
% stale, pre-reorg copy of this figure regardless of any code changes here.
% -------------------------------------------------------------------------
AD_t_3  = cat(2, res_sam.nuD.AD_t (:,1,:), res_sam.nuD.AD_t (:,2,:), res_gray.nuD.AD_t (:,1,:));
AD_ue_3 = cat(2, res_sam.nuD.AD_ue(:,1,:), res_sam.nuD.AD_ue(:,2,:), res_gray.nuD.AD_ue(:,1,:));
AS_t_3  = cat(2, res_sam.nuD.AS_t (:,1,:), res_sam.nuD.AS_t (:,2,:), res_gray.nuD.AS_t (:,1,:));
AS_ue_3 = cat(2, res_sam.nuD.AS_ue(:,1,:), res_sam.nuD.AS_ue(:,2,:), res_gray.nuD.AS_ue(:,1,:));
WG_t_3  = cat(2, res_sam.nuD.WG_t (:,1,:), res_sam.nuD.WG_t (:,2,:), res_gray.nuD.WG_t (:,1,:));
WG_ue_3 = cat(2, res_sam.nuD.WG_ue(:,1,:), res_sam.nuD.WG_ue(:,2,:), res_gray.nuD.WG_ue(:,1,:));

figure('Name','Dynamic IS Curve, Price Phillips Curve & Real Wage Growth: output and unemployment gaps')
tl = tiledlayout(2, 3, 'TileIndexing', 'columnmajor');
tl.OuterPosition = [0 0.171 1 0.829];
tl.Padding = 'compact';
tl.TileSpacing = 'compact';

ax = plot_slopes_panel_3line('Output Gap -- Dynamic IS Curve',        AD_t_3,  res_nk.nuD.AD_t,  nuD_loop, lwdth, cGreen, cGray, clrs);
ylim(ax, [-0.5 max(AD_t_3,[],'all')]);
plot_slopes_panel_3line('Unemployment Gap -- Dynamic IS Curve',       AD_ue_3, res_nk.nuD.AD_ue, nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Output Gap -- Price Phillips Curve',       AS_t_3,  res_nk.nuD.AS_t,  nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Unemployment Gap -- Price Phillips Curve', AS_ue_3, res_nk.nuD.AS_ue, nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Output Gap -- Real Wage Growth',           WG_t_3,  res_nk.nuD.WG_t,  nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Unemployment Gap -- Real Wage Growth',     WG_ue_3, res_nk.nuD.WG_ue, nuD_loop, lwdth, cGreen, cGray, clrs);

build_grouped_subQ_legend(lwdth, cGreen, cGray, clrs, [gamQ_low, gamQ_cut, gamQ_high], ...
    struct('bench', [0.08 0.134 0.84 0.040], ...
           'col1',  [0.06  0.009 0.27 0.131], ...
           'col2',  [0.365 0.009 0.27 0.131], ...
           'col3',  [0.67  0.009 0.27 0.131]));

save_fig(nksam_path('figures', 'fig_slopes_5eq_ee_pc_rw.eps'), 21, 12.7)
write_endpoint_table(nksam_path('txt', 'fig_slopes_5eq_ee_pc_rw.txt'), ...
    'Dynamic IS Curve, Price Phillips Curve & Real Wage Growth (output and unemployment gaps)', ...
    {'Output Gap -- Dynamic IS Curve',         res_sam.nuD.AD_t,  mean(res_nk.nuD.AD_t,  'all'); ...
     'Unemployment Gap -- Dynamic IS Curve',   res_sam.nuD.AD_ue, mean(res_nk.nuD.AD_ue, 'all'); ...
     'Output Gap -- Price Phillips Curve',   res_sam.nuD.AS_t,  mean(res_nk.nuD.AS_t,  'all'); ...
     'Unemployment Gap -- Price Phillips Curve', res_sam.nuD.AS_ue, mean(res_nk.nuD.AS_ue, 'all'); ...
     'Output Gap -- Real Wage Growth',       res_sam.nuD.WG_t,  mean(res_nk.nuD.WG_t,  'all'); ...
     'Unemployment Gap -- Real Wage Growth', res_sam.nuD.WG_ue, mean(res_nk.nuD.WG_ue, 'all')}, ...
    [gamQ_low, gamQ_cut, gamQ_high], nuD_loop, nuD_base, ...
    {res_gray.nuD.AD_t; res_gray.nuD.AD_ue; res_gray.nuD.AS_t; res_gray.nuD.AS_ue; res_gray.nuD.WG_t; res_gray.nuD.WG_ue}, subQ_labels)

%% ------------------------------------------------------------------------
% Figure: Labor Wedge, Total Search Effort & Marginal Cost Gap (2x3, separate t and ue)
% 2026-09-22 (per Konstantin): extended to 3 lines / grouped legend, same
% template as the CU & PE figure above -- see that block's comment.
% -------------------------------------------------------------------------
LW_t_3  = cat(2, res_sam.nuD.LW_t (:,1,:), res_sam.nuD.LW_t (:,2,:), res_gray.nuD.LW_t (:,1,:));
LW_ue_3 = cat(2, res_sam.nuD.LW_ue(:,1,:), res_sam.nuD.LW_ue(:,2,:), res_gray.nuD.LW_ue(:,1,:));
D_t_3   = cat(2, res_sam.nuD.D_t  (:,1,:), res_sam.nuD.D_t  (:,2,:), res_gray.nuD.D_t  (:,1,:));
D_ue_3  = cat(2, res_sam.nuD.D_ue (:,1,:), res_sam.nuD.D_ue (:,2,:), res_gray.nuD.D_ue (:,1,:));
MC_t_3  = cat(2, res_sam.nuD.MC_t (:,1,:), res_sam.nuD.MC_t (:,2,:), res_gray.nuD.MC_t (:,1,:));
MC_ue_3 = cat(2, res_sam.nuD.MC_ue(:,1,:), res_sam.nuD.MC_ue(:,2,:), res_gray.nuD.MC_ue(:,1,:));

figure('Name','Labor Wedge, Total Search Effort & Marginal Cost Gap: output and unemployment gaps')
tl = tiledlayout(2, 3, 'TileIndexing', 'columnmajor');
tl.OuterPosition = [0 0.171 1 0.829];
tl.Padding = 'compact';
tl.TileSpacing = 'compact';

plot_slopes_panel_3line('Output Gap -- Labor Wedge',                LW_t_3,  res_nk.nuD.LW_t,  nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Unemployment Gap -- Labor Wedge',          LW_ue_3, res_nk.nuD.LW_ue, nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Output Gap -- Total Search Effort',        D_t_3,   [], nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Unemployment Gap -- Total Search Effort',  D_ue_3,  [], nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Output Gap -- Marginal Cost Gap',          MC_t_3,  res_nk.nuD.MC_t,  nuD_loop, lwdth, cGreen, cGray, clrs);
plot_slopes_panel_3line('Unemployment Gap -- Marginal Cost Gap',    MC_ue_3, res_nk.nuD.MC_ue, nuD_loop, lwdth, cGreen, cGray, clrs);

build_grouped_subQ_legend(lwdth, cGreen, cGray, clrs, [gamQ_low, gamQ_cut, gamQ_high], ...
    struct('bench', [0.08 0.134 0.84 0.040], ...
           'col1',  [0.06  0.009 0.27 0.131], ...
           'col2',  [0.365 0.009 0.27 0.131], ...
           'col3',  [0.67  0.009 0.27 0.131]));

save_fig(nksam_path('figures', 'fig_slopes_5eq_lw_se_mc.eps'), 21, 12.7)
write_endpoint_table(nksam_path('txt', 'fig_slopes_5eq_lw_se_mc.txt'), ...
    'Labor Wedge, Total Search Effort & Marginal Cost Gap (output and unemployment gaps)', ...
    {'Output Gap -- Labor Wedge',               res_sam.nuD.LW_t,  mean(res_nk.nuD.LW_t,  'all'); ...
     'Unemployment Gap -- Labor Wedge',         res_sam.nuD.LW_ue, mean(res_nk.nuD.LW_ue, 'all'); ...
     'Output Gap -- Total Search Effort',       res_sam.nuD.D_t,   []; ...
     'Unemployment Gap -- Total Search Effort', res_sam.nuD.D_ue,  []; ...
     'Output Gap -- Marginal Cost Gap',         res_sam.nuD.MC_t,  mean(res_nk.nuD.MC_t,  'all'); ...
     'Unemployment Gap -- Marginal Cost Gap',   res_sam.nuD.MC_ue, mean(res_nk.nuD.MC_ue, 'all')}, ...
    [gamQ_low, gamQ_cut, gamQ_high], nuD_loop, nuD_base, ...
    {res_gray.nuD.LW_t; res_gray.nuD.LW_ue; res_gray.nuD.D_t; res_gray.nuD.D_ue; res_gray.nuD.MC_t; res_gray.nuD.MC_ue}, subQ_labels)



% =========================================================================
% LOCAL HELPERS
% =========================================================================

function ax = plot_slopes_panel(ttl, sam, nk_or_empty, x, lwd, cG, clrs)
% Plot a single tile showing both subQ variants (dim 2 = 1 or 2).
nexttile; hold on;
styles = {'k--','k-.','k-'};
for gg = 1:3
    plot(x, squeeze(sam(gg,1,:))', styles{gg}, 'Linewidth', 1, 'HandleVisibility', 'off');
end
if isempty(nk_or_empty)
    yline(0, 'LineWidth', lwd, 'Color', cG);
else
    yline(squeeze(mean(nk_or_empty,'all')), 'LineWidth', lwd, 'Color', cG);
end
ls = {'--','-.', '-'};
for gg = 1:3
    plot(x, squeeze(sam(gg,2,:))', ls{gg}, 'Linewidth', lwd, 'Color', clrs(gg,:));
end
hold off; axis tight;
xlabel('$\nu_D$','Interpreter','latex'); title(ttl, 'Interpreter', 'latex');
ax = gca;
end

function write_endpoint_table(fname_txt, fig_title, panels, gamQ_vals, x, nuD_base, gray_panels, var_labels)
% WRITE_ENDPOINT_TABLE  Print and save curve endpoint values for a figure.
%   panels      : nP x 3 cell {panel_name, sam_data [nG x nV x nT], ref_val}
%                 ref_val: scalar NK reference value, or [] to omit
%   gray_panels : (optional) nP x 1 cell, each [nG x 1 x nT] Gamma_Q->-infinity
%                 slopes (res_gray) for that panel, or [] to omit
%   var_labels  : (optional) 1 x nV cellstr naming the subQ variants
%   Default calibration: last gamQ (gamQ_high), last subQ variant, nuD = nuD_base.
%
% 2026-09-23 (Section 4 review, item 5): adds a "benchmark crossing" column --
% the nu_D value(s) at which each NK-SaM curve crosses the NK reference,
% linearly interpolated on the nu_D grid -- plus optional Gamma_Q->-infinity
% (gray) rows and named subQ variants. For the price Phillips curve and real
% wage growth panels these crossings are the four nu_D cutoffs of print
% Appendix C (sec:cutoff_nuD); at Gamma_Q~0 they should equal the closed forms
%   PC output gap:  nu_N              PC unemployment gap:  (1+nu_N)/mc - 1
%   RWG unempl.gap: nu_N/mc - 1       RWG output gap:       eq:cutoff_nuDw_closed
if nargin < 7; gray_panels = {}; end
nG   = length(gamQ_vals);
nV   = size(panels{1,2}, 2);
if nargin < 8 || isempty(var_labels)
    var_labels = arrayfun(@(v) sprintf('subQ=%d', v), 1:nV, 'UniformOutput', false);
end
sep  = repmat('-', 1, 92);
sep2 = repmat('=', 1, 92);
hdr  = sprintf('  %-34s  %12s  %12s  %s', '', ...
    sprintf('nuD=%.4f', x(1)), sprintf('nuD=%.4f', x(end)), 'benchmark crossing (nuD)');

% Index of default calibration: nuD closest to the baseline level (nuD_base)
[~, idx_def] = min(abs(x - nuD_base));

lines    = {};
lines{end+1} = sprintf('Figure: %s', fig_title);
lines{end+1} = sprintf('nuD range: [%.4f, %.4f]', x(1), x(end));
lines{end+1} = 'Benchmark crossing: nuD where the NK-SaM slope equals the NK reference (linear interpolation on the nuD grid).';
lines{end+1} = sep2;

for pp = 1:size(panels, 1)
    pname   = panels{pp,1};
    sam     = panels{pp,2};   % [nG x nV x nT]
    ref_val = panels{pp,3};

    left    = sam(:,:,1);
    right   = sam(:,:,end);
    def_val = sam(nG, nV, idx_def);

    lines{end+1} = '';
    lines{end+1} = sprintf('Panel: %s', pname);
    lines{end+1} = sprintf('  Default calibration (gamQ=%.4f, nuD=%.4f):  %.4f', ...
        gamQ_vals(nG), x(idx_def), def_val);
    lines{end+1} = hdr;
    lines{end+1} = sep;
    for gg = 1:nG
        for vv = 1:nV
            lbl = sprintf('gamQ=%.4f | %s', gamQ_vals(gg), var_labels{vv});
            lines{end+1} = sprintf('  %-34s  %12.4f  %12.4f  %s', lbl, left(gg,vv), right(gg,vv), ...
                crossing_str(x, squeeze(sam(gg,vv,:)), ref_val));
        end
    end
    if ~isempty(gray_panels) && pp <= numel(gray_panels) && ~isempty(gray_panels{pp})
        gry = gray_panels{pp};   % [nG x 1 x nT]
        for gg = 1:nG
            lbl = sprintf('gamQ=%.4f | GamQ->-inf', gamQ_vals(gg));
            lines{end+1} = sprintf('  %-34s  %12.4f  %12.4f  %s', lbl, gry(gg,1,1), gry(gg,1,end), ...
                crossing_str(x, squeeze(gry(gg,1,:)), ref_val));
        end
    end
    if ~isempty(ref_val)
        lines{end+1} = sprintf('  %-34s  %12.4f  (constant)', 'NK reference', ref_val);
    end
end
lines{end+1} = '';

% Print to console
for ii = 1:numel(lines); disp(lines{ii}); end

% Save to file
ensure_dir(fname_txt);
fid = fopen(fname_txt, 'w');
if fid == -1
    error('figs_slope:write_endpoint_table: could not open "%s" for writing (check that its directory exists/is writable).', fname_txt);
end
for ii = 1:numel(lines); fprintf(fid, '%s\n', lines{ii}); end
fclose(fid);
end

function s = crossing_str(x, y, ref_val)
% CROSSING_STR  nu_D value(s) where curve y(x) crosses the constant ref_val.
%   '-' if no reference; 'coincides' if |y-ref| < 2e-3 on the whole grid;
%   'none in range' if no sign change; otherwise the interpolated crossings.
if isempty(ref_val); s = '-'; return; end
x = x(:)'; d = y(:)' - ref_val;
if max(abs(d)) < 2e-3; s = 'coincides with benchmark'; return; end
cr = x(d == 0);
idx = find(d(1:end-1) .* d(2:end) < 0);
for ii = idx
    cr(end+1) = x(ii) - d(ii) * (x(ii+1) - x(ii)) / (d(ii+1) - d(ii)); %#ok<AGROW>
end
cr = unique(round(sort(cr), 4));
if isempty(cr)
    if all(d > 0); s = 'none in range (above)'; else; s = 'none in range (below)'; end
else
    s = strjoin(arrayfun(@(c) sprintf('%.3f', c), cr, 'UniformOutput', false), ', ');
end
end

end
