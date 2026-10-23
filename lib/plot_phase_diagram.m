function info = plot_phase_diagram(res_array, plot_cfg)
% 2026-09-28: regime geometry of Proposition 2 (prop:regimes) added as
% optional plot_cfg fields (defaults leave the figure unchanged):
%     .xi_beta      price-elasticity / Euler threshold beta*_Xi (scalar);
%                   draws the ray u_tilde = beta*_Xi * Y_tilde (Xi_tilde = 0)
%                   in the gap panels (b)-(d). NaN/absent = not drawn.
%     .shade_amp    true: shade the amplification region beta < beta*_Xi
%                   (between the threshold ray and the Y_tilde = 0 ray)
%     .mark_impact  true: enlarged marker on the impact quarter (+ shocks)
% PLOT_PHASE_DIAGRAM  Barro-Grossman regime phase diagram(s): levels, gaps,
%                     and the output gap against each margin separately.
%
%   Four panels, sharing one legend, in a 2x2 layout:
%     (a) LEVELS                   goods market tightness, $\hat{\theta}_t$,
%                                   vs. UNEMPLOYMENT, $\hat{u}_t$ (the plain
%                                   rate, NOT the gap: $\hat{u}_t$ is the
%                                   unemployment rate's own %-deviation from
%                                   its steady state).
%     (b) GAPS                     goods market tightness gap,
%                                   $\tilde{\theta}_t$, vs. unemployment gap,
%                                   $\tilde{u}_t$ (deviation from the
%                                   flexible-price/efficient counterpart).
%     (c) OUTPUT GAP VS. UNEMPLOYMENT GAP   output gap, $\tilde{Y}_t$, vs.
%                                   unemployment gap, $\tilde{u}_t$.
%     (d) TIGHTNESS GAP VS. OUTPUT GAP      goods market tightness gap,
%                                   $\tilde{\theta}_t$, vs. output gap,
%                                   $\tilde{Y}_t$ -- tightness gap is on the
%                                   x-axis here, same as in panel (b), so
%                                   (b) and (d) share their x-axis just as
%                                   (b) and (c) share their y-axis
%                                   (unemployment gap).
%
%   For each shock in plot_cfg.shocks, all four panels plot the simulated
%   trajectory over the IRF horizon together with its exact mirror-image
%   (log-linear symmetry: negate both coordinates, valid at first-order
%   perturbation) for the opposite-signed shock.
%
%   Panels (a) and (b) share their vertical axis and their horizontal scale,
%   so the HORIZONTAL DISPLACEMENT of a given shock/quarter between them is
%   exactly the flexible-price tightness path theta_hat_t^N. This is a
%   verified, not assumed, property: flexible-price unemployment is pinned
%   by the wage markdown epsW and never moves, so u_tilde_t = u_hat_t to
%   solver tolerance for every shock -- checked at run time below; warns if
%   it ever stops holding.
%
%   Panels (b), (c) and (d) are three views of ONE plane. The identity
%       theta_tilde_t = ThY * Y_tilde_t + Thu * u_tilde_t                (*)
%   holds in the model (verified below, R^2 = 1), so the three panels are
%   exact re-coordinatizations of one another: what changes is only which
%   pair of variables gets to be the axes. ThY and Thu are NOT hardcoded --
%   they are recovered by pooled least squares from the plotted scenario's
%   own IRFs, so the reference geometry below is guaranteed consistent with
%   the trajectories drawn on top of it.
%
%   REFERENCE LINES ON EVERY GAP PANEL (b, c, d) -- plot_cfg.okun_elast
%   ------------------------------------------------------------------
%   Each gap panel draws two reference lines through the origin:
%     - The OKUN LOCUS: the line (*) restricts to when unemployment and the
%       output gap are tied by the fixed two-variable Okun elasticity
%       Y_tilde = okun * u_tilde (plot_cfg.okun_elast, default -2.23,
%       knotekHow2007). Distance from this locus is exactly the ordinary
%       Okun RESIDUAL, nu_t = u_tilde_t - Y_tilde_t/okun (verified below).
%     - The ZERO ISO-CONTOUR of whichever one of {theta_tilde, u_tilde,
%       Y_tilde} is NOT one of that panel's own two axes: it is the
%       Barro-Grossman regime boundary of the missing variable, e.g. in
%       panel (c) the theta_tilde = 0 contour is the tightness-gap
%       regime boundary, invisible as an axis there but readable as a line.
%   No such construction exists for panel (a): the analogous LEVELS
%   regression (x on t, ue, pooled across shocks; checked for cu, 2026-10) fits each shock
%   separately at R^2 ~ 0.999 but with shock-specific coefficients, so
%   pooled it collapses to R^2 = 0.152 -- no shock-invariant map exists in
%   levels, so panel (a) gets no reference lines.
%
%   OPTIONAL IMPACT NORMALIZATION (plot_cfg.norm_impact)
%   ------------------------------------------------------------------
%   The shocks are calibrated to different standard deviations (get_params.m),
%   so their raw IRF paths are not visually comparable -- some barely leave
%   the origin, others dominate the plot. Because dynare_opts.approxorder = 1,
%   the model is exactly linear in shock size, so rescaling a shock's plotted
%   trajectory by a constant factor is mathematically identical to having
%   drawn it from a rescaled standard deviation. Setting
%   plot_cfg.norm_impact = true rescales EACH shock's whole trajectory (all
%   four panels, all horizons) by a single constant so that its LEVELS
%   PERIOD-1 IMPACT VECTOR, [theta_hat_1, u_hat_1], has the same Euclidean
%   norm across shocks -- plot_cfg.norm_target if given, otherwise the mean
%   of the shocks' own (unscaled) impact norms. One scale factor per shock,
%   applied identically everywhere that shock appears, preserves identity
%   (*) for that shock (it is homogeneous, so a uniform rescale of one
%   shock's whole trajectory still satisfies it with the SAME ThY, Thu) and
%   preserves every regime/sign classification. It does NOT rescale the
%   reference lines themselves (the Okun locus and iso-contours are drawn in
%   the model's natural units, since they are shared structural relationships,
%   not shock-specific data) -- so with norm_impact on, a shock's plotted
%   distance from a reference line is no longer directly comparable across
%   shocks (though its own regime/quadrant reading is unaffected, since
%   scaling by a positive constant never flips a sign). This changes only
%   what is drawn here; it does not touch res_array, get_params.m, or any
%   other figure, moment, or text number derived from the real calibration.
%   The applied scale factors are printed and returned in info.scale_factors
%   so the rescaling is auditable and any caption can disclose it.
%
%   Goods market tightness is the model's tightness x = psiD*dq/sf (Dynare
%   variable x; steady state 1, so its percent and percentage-point deviations
%   coincide), in levels (x) and gaps (x_gap = x/x_N - 1) for every shock.
%   (2026-10-06: replaces cu / cu - shT / cu_gap, i.e. utilization, which is
%   proportional to tightness net of matching efficiency, q - psiQ = psiQ*phi_gamma*theta,
%   and mixed pp and % for the matching-efficiency shock.) Regimes, rays and
%   thresholds are scale-free and unaffected; the identity (*) is fitted on x_gap,
%   so ThY, Thu are the utilization slopes divided by psiQ*phi_gamma.
%
% -------------------------------------------------------------------------
% INPUTS
% -------------------------------------------------------------------------
%   res_array   1xN struct array, each element the output of dynare_scenario
%
%   plot_cfg    Struct with fields:
%     .scenario      Index into res_array to use (e.g. 3 = Full Model CB)
%     .shocks        String array of shock names, e.g. ["eA","eM","eD","eT"]
%     .shock_labels  String array of human-readable labels, same length
%     .colors        Nx3 matrix of RGB colors, one row per shock
%     .fig_name      Figure window name
%     .fig_prefix    Output path prefix (".eps" appended)
%     .fig_size      [width height] in cm (optional, default [16 19]; 16cm
%                    fits standard A4 margins with room for a caption below;
%                    19cm keeps the 2x2 grid of square panels from being
%                    squeezed shorter than it is wide -- which is what left
%                    visible dead space around the panels before -- while
%                    also leaving room for the 5-row legend)
%     .font_size     Points (optional, default 8)
%     .legend_cols   Ignored (kept for backward compatibility): the
%                    legend is always 3 columns -- shock (+), shock (-),
%                    reference lines -- see the Legend section below.
%     .norm_impact   Rescale each shock to a common levels period-1 impact
%                    norm, applied to all four panels (optional, default false)
%     .norm_target   Target period-1 impact norm (optional; default: mean
%                    of the shocks' own unscaled impact norms). Ignored if
%                    norm_impact is false.
%     .okun_elast    Y_tilde/u_tilde elasticity for the Okun locus
%                    (optional, default -2.23, knotekHow2007)
%     .fit_shocks    Shocks used to recover ThY, Thu in (*) (optional;
%                    default: every shock stored in res.irfs, i.e. not
%                    necessarily just plot_cfg.shocks)
%
% -------------------------------------------------------------------------
% OUTPUT
% -------------------------------------------------------------------------
%   info        Struct:
%     .scale_factors   1xN vector, one per plot_cfg.shocks, applied to that
%                      shock's trajectory in all four panels (all 1 if
%                      norm_impact is false)
%     .impact_norms    1xN vector, each shock's ORIGINAL (unscaled) levels
%                      period-1 impact norm sqrt(theta_hat_1^2+u_hat_1^2)
%     .norm_target     The target impact norm actually used
%     .ThY, .Thu, .R2      recovered (*) coefficients and pooled fit
%     .okun_slope          dtheta_tilde/du_tilde along the Okun locus
%     .max_abs_ue_N        largest |flexible-price unemployment| found
%                          (should be ~0; see the header note above)
%     .regimes_level/.regimes_gap   shock -> 1xT cellstr of regime names
%     .regime_switch       shocks classified differently in levels vs. gaps

% -------------------------------------------------------------------------
% Defaults
% -------------------------------------------------------------------------
if ~isfield(plot_cfg, 'fig_size'),    plot_cfg.fig_size    = [16 19];   end
if ~isfield(plot_cfg, 'font_size'),   plot_cfg.font_size   = 8;         end
if ~isfield(plot_cfg, 'legend_cols'), plot_cfg.legend_cols = 3;         end
if ~isfield(plot_cfg, 'norm_impact'), plot_cfg.norm_impact = false;     end
if ~isfield(plot_cfg, 'okun_elast'),  plot_cfg.okun_elast  = -2.23;     end
if ~isfield(plot_cfg, 'xi_beta'),     plot_cfg.xi_beta     = NaN;       end
if ~isfield(plot_cfg, 'shade_amp'),   plot_cfg.shade_amp   = false;     end
if ~isfield(plot_cfg, 'mark_impact'), plot_cfg.mark_impact = false;     end

res  = res_array(plot_cfg.scenario);
n    = numel(plot_cfg.shocks);
fs   = plot_cfg.font_size;
okun = plot_cfg.okun_elast;

if ~isfield(plot_cfg, 'fit_shocks')
    plot_cfg.fit_shocks = string(fieldnames(res.irfs))';
end

% -------------------------------------------------------------------------
% 0. Collect raw trajectories (levels and gaps) and, if requested, rescale
%    to a common LEVELS period-1 impact norm before anything is plotted
% -------------------------------------------------------------------------
theta_lvl_raw = cell(1, n);
u_lvl_raw     = cell(1, n);
theta_gap_raw = cell(1, n);
u_gap_raw     = cell(1, n);
Y_gap_raw     = cell(1, n);
impact_norms  = zeros(1, n);

for ii = 1:n
    shock = char(plot_cfg.shocks(ii));

    theta_lvl = res.irfs.(shock).x(:);       % goods market tightness x = psiD*dq/sf (steady state 1: % = pp)
    u_lvl = res.irfs.(shock).ue(:);          % unemployment (levels, NOT the gap)

    theta_gap = res.irfs.(shock).x_gap(:);   % tightness gap x/x_N - 1 (steady state 1: % = pp)
    u_gap     = res.irfs.(shock).ue_gap(:);
    Y_gap     = res.irfs.(shock).gdp_gap(:);

    theta_lvl_raw{ii} = theta_lvl;
    u_lvl_raw{ii}     = u_lvl;
    theta_gap_raw{ii} = theta_gap;
    u_gap_raw{ii}     = u_gap;
    Y_gap_raw{ii}     = Y_gap;
    impact_norms(ii)  = hypot(theta_lvl(1), u_lvl(1));
end

scale_factors = ones(1, n);
if plot_cfg.norm_impact
    if isfield(plot_cfg, 'norm_target') && ~isempty(plot_cfg.norm_target)
        norm_target = plot_cfg.norm_target;
    else
        norm_target = mean(impact_norms);
    end
    zero_impact = impact_norms < 1e-10;
    if any(zero_impact)
        warning(['plot_phase_diagram: shock(s) [%s] have ~zero levels period-1 ' ...
                 'impact and cannot be normalized; left unscaled.'], ...
                strjoin(plot_cfg.shocks(zero_impact), ', '));
    end
    scale_factors(~zero_impact) = norm_target ./ impact_norms(~zero_impact);
    fprintf('plot_phase_diagram: normalizing to common levels period-1 impact norm %.4f\n', norm_target);
    for ii = 1:n
        fprintf('    %-6s impact %.4f -> scale x%.4f\n', ...
                char(plot_cfg.shocks(ii)), impact_norms(ii), scale_factors(ii));
    end
else
    norm_target = NaN;
end
% Optional per-shock factor on top of the normalization (plot_cfg.extra_scale,
% same order as plot_cfg.shocks); purely visual, signs and regimes unchanged.
if isfield(plot_cfg, 'extra_scale') && ~isempty(plot_cfg.extra_scale)
    scale_factors = scale_factors .* plot_cfg.extra_scale(:).';
    fprintf('plot_phase_diagram: extra per-shock scale [%s]\n', num2str(plot_cfg.extra_scale(:).'));
end

% Scaled trajectories actually plotted (uniform per-shock factor -> (*)
% and every regime sign is preserved; see header)
theta_lvl_s = cell(1, n); u_lvl_s = cell(1, n);
theta_gap_s = cell(1, n); u_gap_s = cell(1, n); Y_gap_s = cell(1, n);
for ii = 1:n
    theta_lvl_s{ii} = scale_factors(ii) * theta_lvl_raw{ii};
    u_lvl_s{ii}     = scale_factors(ii) * u_lvl_raw{ii};
    theta_gap_s{ii} = scale_factors(ii) * theta_gap_raw{ii};
    u_gap_s{ii}     = scale_factors(ii) * u_gap_raw{ii};
    Y_gap_s{ii}     = scale_factors(ii) * Y_gap_raw{ii};
end

% -------------------------------------------------------------------------
% 1. Check the shared-axis property (panels a/b), on the RAW (unscaled) IRFs
% -------------------------------------------------------------------------
ueN_max = 0;
for s = plot_cfg.fit_shocks
    sh = char(s);
    if isfield(res.irfs.(sh), 'ue_N')
        ueN_max = max(ueN_max, max(abs(res.irfs.(sh).ue_N(:))));
    end
end
if ueN_max > 1e-8
    warning(['plot_phase_diagram: flexible-price unemployment is NOT ' ...
             'constant (max|ue_N| = %.3g). Panels (a) and (b) no longer ' ...
             'share their vertical axis.'], ueN_max);
end

% -------------------------------------------------------------------------
% 2. Recover identity (*) from the RAW (unscaled) IRFs, pooled across
%    plot_cfg.fit_shocks -- scale-invariant per shock, so norm_impact does
%    not change ThY, Thu (see header)
% -------------------------------------------------------------------------
X = []; Y = [];
for s = plot_cfg.fit_shocks
    sh = char(s);
    X = [X; res.irfs.(sh).gdp_gap(:), res.irfs.(sh).ue_gap(:)];  %#ok<AGROW>
    Y = [Y; res.irfs.(sh).x_gap(:)];                             %#ok<AGROW>
end
Th  = X \ Y;
ThY = Th(1);
Thu = Th(2);
R2  = 1 - sum((Y - X*Th).^2) / sum((Y - mean(Y)).^2);

fprintf(['plot_phase_diagram: identity (*) recovered from %d shocks -- ' ...
         'ThY = %.4f, Thu = %.4f, R^2 = %.8f\n'], ...
        numel(plot_cfg.fit_shocks), ThY, Thu, R2);
if R2 < 1 - 1e-6
    warning(['plot_phase_diagram: identity (*) does not hold exactly ' ...
             '(R^2 = %.6f). The reference geometry on panels b/c/d is then ' ...
             'an approximation and any caption must say so.'], R2);
end

okun_slope = ThY*okun + Thu;    % dtheta_tilde/du_tilde along the Okun locus

% -------------------------------------------------------------------------
% 3. Axis limits (precomputed across ALL shocks so contour spacing and
%    plotting share one consistent scale per panel)
%      lim_ab_th, lim_ab_u  limits for panels (a) and (b): they intentionally
%              share both axes (see header), so mirrored trajectories double
%              the range needed on levels theta/u AND gap theta/u alike.
%      lim_Y   panel (c) horizontal axis, panel (d) vertical axis (output gap)
%      lim_u   panel (c) vertical axis (unemployment gap)
%      lim_th  panel (d) horizontal axis (tightness gap)
% -------------------------------------------------------------------------
mx = @(c) max(cellfun(@(v) max(abs(v)), c));
lim_ab_th = 1.15 * max([mx(theta_lvl_s), mx(theta_gap_s)]);   % (a)/(b) share each axis,
lim_ab_u  = 1.15 * max([mx(u_lvl_s),     mx(u_gap_s)]);       % but not one common square range
lim_Y  = 1.15 * mx(Y_gap_s);
lim_u  = 1.15 * mx(u_gap_s);
lim_th = 1.15 * mx(theta_gap_s);

% -------------------------------------------------------------------------
% 4. Panel specifications
%    .theta / .u   recover the two classifying (gap-space) variables from
%                  panel coordinates, so regime shading/reporting is generic
%    .miss         the ONE variable of {theta_tilde,u_tilde,Y_tilde} that is
%                  NOT one of this panel's axes (gap panels only)
%    .contour_line(xx,k)  the line miss(x,y) = k, as y = f(xx), in THIS
%                  panel's coordinates (gap panels only)
%    .okun_ref     slope of the Okun locus in this panel's coordinates
%                  (gap panels only; [] for levels)
% -------------------------------------------------------------------------
P = struct('id', {}, 'title', {}, 'xf', {}, 'yf', {}, 'xlab', {}, 'ylab', {}, ...
           'xlim', {}, 'ylim', {}, 'theta', {}, 'u', {}, 'miss', {}, ...
           'contour_line', {}, 'okun_ref', {});

% NOTE: xf/yf are cell arrays (1xn, one trajectory per shock). struct()
% treats an UNWRAPPED cell-array value as something to broadcast into a
% struct ARRAY (one element per cell) -- not what we want here, since each
% P(pp) must stay a single scalar struct holding the whole cell array. Wrap
% each cell-array value in an extra {...} to suppress that broadcasting.
P(1) = struct('id', 'a', 'title', '(a) Levels', ...
    'xf', {theta_lvl_s}, 'yf', {u_lvl_s}, ...
    'xlab', 'Goods market tightness, $\hat{\theta}_t$ (\%-dev.)', ...
    'ylab', 'Unemployment, $\hat{u}_t$ (pp-dev.)', ...
    'xlim', lim_ab_th, 'ylim', lim_ab_u, ...
    'theta', @(x,y) x, 'u', @(x,y) y, 'miss', [], 'contour_line', [], 'okun_ref', []);

P(2) = struct('id', 'b', 'title', '(b) Gaps', ...
    'xf', {theta_gap_s}, 'yf', {u_gap_s}, ...
    'xlab', 'Goods market tightness gap, $\tilde{\theta}_t$ (\%-dev.)', ...
    'ylab', 'Unemployment gap, $\tilde{u}_t$ (pp-dev.)', ...
    'xlim', lim_ab_th, 'ylim', lim_ab_u, ...
    'theta', @(x,y) x, 'u', @(x,y) y, ...
    'miss', @(x,y) (x - Thu*y)/ThY, ...             % missing: Y_tilde
    'contour_line', @(xx,k) (xx - ThY*k)/Thu, ...   % y at Y_tilde = k
    'okun_ref', 1/okun_slope);

P(3) = struct('id', 'c', 'title', '(c) Output Gap vs.\ Unemployment Gap', ...
    'xf', {Y_gap_s}, 'yf', {u_gap_s}, ...
    'xlab', 'Output gap, $\tilde{Y}_t$ (\%-dev.)', ...
    'ylab', 'Unemployment gap, $\tilde{u}_t$ (pp-dev.)', ...
    'xlim', lim_Y, 'ylim', lim_u, ...
    'theta', @(x,y) ThY*x + Thu*y, 'u', @(x,y) y, ...
    'miss', @(x,y) ThY*x + Thu*y, ...               % missing: theta_tilde
    'contour_line', @(xx,k) (k - ThY*xx)/Thu, ...   % y at theta_tilde = k
    'okun_ref', 1/okun);

P(4) = struct('id', 'd', 'title', '(d) Tightness Gap vs.\ Output Gap', ...
    'xf', {theta_gap_s}, 'yf', {Y_gap_s}, ...
    'xlab', 'Goods market tightness gap, $\tilde{\theta}_t$ (\%-dev.)', ...
    'ylab', 'Output gap, $\tilde{Y}_t$ (\%-dev.)', ...
    'xlim', lim_th, 'ylim', lim_Y, ...
    'theta', @(x,y) x, 'u', @(x,y) (x - ThY*y)/Thu, ...
    'miss', @(x,y) (x - ThY*y)/Thu, ...             % missing: u_tilde
    'contour_line', @(xx,k) (xx - Thu*k)/ThY, ...   % y at u_tilde = k
    'okun_ref', 1/(ThY + Thu/okun));

% --- Prop. 2 geometry per panel --------------------------------
%   .beta_line(xx,b)  the ray u_tilde = b*Y_tilde in THIS panel's coords
%   .map(Yv,uv)       (Y_tilde,u_tilde) -> [x y] of this panel
P(1).beta_line = []; P(1).map = [];
P(2).beta_line = @(xx,b) xx ./ (ThY./b + Thu);
P(2).map       = @(Yv,uv) [ThY*Yv + Thu*uv, uv];
P(3).beta_line = @(xx,b) b .* xx;
P(3).map       = @(Yv,uv) [Yv, uv];
P(4).beta_line = @(xx,b) xx ./ (ThY + Thu.*b);
P(4).map       = @(Yv,uv) [ThY*Yv + Thu*uv, Yv];
%   .contour_tag      label of the zero contour of the missing gap: each
%                     reference line is a value of the comovement omega
%                     (u_tilde = omega*Y_tilde), cf. sec. 5.1 of the paper
P(1).contour_tag = '';
P(2).contour_tag = '$\tilde{Y}=0$: $\omega\to-\infty$';
P(3).contour_tag = '$\tilde{\theta}=0$: $\omega=\omega^*_q$';
P(4).contour_tag = '$\tilde{u}=0$: $\omega=0$';
xi_beta = plot_cfg.xi_beta;
col_xi  = [0.70 0.09 0.17];

% -------------------------------------------------------------------------
% 5. Figure
% -------------------------------------------------------------------------
figure('Name', plot_cfg.fig_name);
tl = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

h   = gobjects(1, 2*n);
leg = cell(1, 2*n);
hOk = gobjects(1); hMiss0 = gobjects(1); hXi = gobjects(1); hShade = gobjects(1);

LBL = struct('ax', {}, 'obsN', {}, 'p', {}, 'xl', {}, 'yl', {});
for pp = 1:4
    p  = P(pp);
    ax = nexttile(tl); hold(ax, 'on');
    xl = p.xlim; yl = p.ylim;
    xx = [-xl xl];

    % --- Prop. 2: amplification region beta < beta*_Xi (gap panels only) -----
    %   In (Y_tilde,u_tilde) space it is the cone between A = (1, beta*_Xi)
    %   and B = (0,-1), plus its mirror image; the linear panel maps keep it
    %   a cone. Opaque light fill drawn first (EPS has no transparency).
    if plot_cfg.shade_amp && ~isnan(xi_beta) && ~isempty(p.map)
        Lc = 1e3; A = [1 xi_beta]; B = [0 -1];
        V  = [0 0; Lc*A; Lc*(A+B); Lc*B];
        for sgn = [1 -1]
            W  = p.map(sgn*V(:,1), sgn*V(:,2));
            hs = patch(ax, W(:,1), W(:,2), [0.98 0.91 0.91], 'EdgeColor', 'none', ...
                       'HandleVisibility', 'off');
            if pp == 2 && sgn == 1, hShade = hs; end
        end
    end

    % --- zero iso-contour of the missing variable (gap panels only) -------
    if ~isempty(p.miss)
        % 2026-10-23: in (c) and (d) this contour IS a Barro-Grossman regime
        % boundary (theta_tilde = 0 resp. u_tilde = 0), so it is drawn heavier;
        % in (b) it is the output-gap contour, not a regime boundary.
        lw_miss = 0.9 + 0.7*(pp >= 3);
        hMiss0 = plot(ax, xx, p.contour_line(xx, 0), '-', 'Color', [0.55 0.55 0.55], ...
                       'LineWidth', lw_miss, 'HandleVisibility', 'off');
        % (contour label placed after the trajectories, see below)
    end

    % --- Okun locus (gap panels only) --------------------------------------
    if ~isempty(p.okun_ref)
        hOk = plot(ax, xx, p.okun_ref*xx, '-.', 'Color', [0.15 0.15 0.15], ...
                   'LineWidth', 0.9, 'HandleVisibility', 'off');
    end

    % --- Prop. 2: price-elasticity / Euler threshold ray (gap panels only) ---
    if ~isnan(xi_beta) && ~isempty(p.beta_line)
        hx_ = plot(ax, xx, p.beta_line(xx, xi_beta), '--', 'Color', col_xi, ...
                   'LineWidth', 1.1, 'HandleVisibility', 'off');
        if pp == 2, hXi = hx_; end
    end

    % 2026-10-23: the axis that is the output-gap zero line (x = 0 in (c),
    % y = 0 in (d)) is not a regime boundary there: drawn light and dotted.
    ax_y = struct('c', [0.4 0.4 0.4], 'w', 0.8, 's', '-');
    ax_x = ax_y;
    lite = struct('c', [0.70 0.70 0.70], 'w', 0.6, 's', ':');
    if pp == 3, ax_x = lite; end        % Y_tilde = 0 (vertical axis)
    if pp == 4, ax_y = lite; end        % Y_tilde = 0 (horizontal axis)
    yline(ax, 0, ax_y.s, 'Color', ax_y.c, 'LineWidth', ax_y.w, 'HandleVisibility', 'off');
    xline(ax, 0, ax_x.s, 'Color', ax_x.c, 'LineWidth', ax_x.w, 'HandleVisibility', 'off');

    % --- trajectories --------------------------------------------------
    for ii = 1:n
        lbl = char(plot_cfg.shock_labels(ii));
        col = plot_cfg.colors(ii, :);
        xd  = p.xf{ii}; yd = p.yf{ii};

        % Expansionary (+)
        p1 = plot(ax, xd, yd, '-o', 'Color', col, 'MarkerFaceColor', col, ...
                  'MarkerSize', 3, 'LineWidth', 1.2);
        % Contractionary mirror (exact negation, log-linear symmetry)
        p2 = plot(ax, -xd, -yd, '--s', 'Color', col, 'MarkerFaceColor', 'w', ...
                  'MarkerSize', 3, 'LineWidth', 1.2);
        % enlarged impact-quarter marker (expansionary shock)
        if plot_cfg.mark_impact
            plot(ax, xd(1), yd(1), 'o', 'MarkerSize', 6, 'MarkerFaceColor', col, ...
                 'MarkerEdgeColor', 'k', 'LineWidth', 0.6, 'HandleVisibility', 'off');
        end

        if pp == 1
            h(2*ii-1) = p1; leg{2*ii-1} = sprintf('%s (+)', lbl);
            h(2*ii)   = p2; leg{2*ii}   = sprintf('%s (-)', lbl);
        end
    end

    xlim(ax, [-xl xl]); ylim(ax, [-yl yl]);
    axis(ax, 'square'); box(ax, 'on');

    % --- labels, placed where they interfere least with lines and text -----
    %   Obstacles: all trajectories (+ and - mirror, densified), the axes, all
    %   reference lines and every label already placed, in axis-normalized
    %   coordinates. Label sizes are measured from the rendered text (Extent),
    %   every box stays inside the axes, and no box may cover an obstacle.
    xs  = linspace(-xl, xl, 401)';
    obs = [xs, zeros(size(xs)); zeros(size(xs)), linspace(-yl, yl, 401)'];
    for ii = 1:n
        xd = p.xf{ii}(:); yd = p.yf{ii}(:);
        obs = [obs; densify(xd, yd); densify(-xd, -yd)]; %#ok<AGROW>
    end
    if ~isempty(p.okun_ref), obs = [obs; xs, p.okun_ref*xs]; end
    if ~isnan(xi_beta) && ~isempty(p.beta_line), obs = [obs; xs, p.beta_line(xs, xi_beta)]; end
    if ~isempty(p.miss), obs = [obs; xs, p.contour_line(xs, 0)]; end
    obs = obs(abs(obs(:,1)) <= xl & abs(obs(:,2)) <= yl, :);
    obsN = obs ./ [xl yl];
    % enlarged impact markers are obstacles too (small disc around each)
    for ii = 1:n
        c0 = [p.xf{ii}(1)/xl, p.yf{ii}(1)/yl];
        obsN = [obsN; c0 + 0.035*[cos(linspace(0, 2*pi, 13))', sin(linspace(0, 2*pi, 13))']; c0]; %#ok<AGROW>
    end
    % labels are placed after the final figure size and font sizes are set
    % (see Export below), so their measured extents are the printed ones
    LBL(pp) = struct('ax', ax, 'obsN', obsN, 'p', p, 'xl', xl, 'yl', yl); %#ok<AGROW>

    title(ax, p.title, 'Interpreter', 'latex', 'FontSize', fs);
    xlabel(ax, p.xlab, 'Interpreter', 'latex');
    ylabel(ax, p.ylab, 'Interpreter', 'latex');
    hold(ax, 'off');
end

% (no figure title: the paper's figure note states the rescaling)

% -------------------------------------------------------------------------
% Legend
%   Three columns, filled row by row: column 1 holds the expansionary (+)
%   entry of each shock, column 2 its contractionary (-) mirror, and column 3
%   the reference lines (Okun locus, zero contour, threshold, amplification
%   region). The number of rows is max(n shocks, n reference lines); blank()
%   pads the shorter columns with invisible entries. plot_cfg.legend_cols is
%   ignored by this layout.
%   Interpreter is 'latex' so the math in the reference-line labels typesets.
% -------------------------------------------------------------------------
% NOTE: blank() uses line(), not plot(). `ax` here is left over from the
% panel loop (panel (d)'s axes) with hold already turned off for it;
% plot(ax,...) on an axes with hold off REPLACES its entire contents, which
% would silently delete panel (d)'s trajectories/contours and invalidate
% any handles captured on that axes right before they're passed into
% legend(). line() always appends to an axes regardless of hold state, so
% it can't clobber existing content.
blank = @() line('Parent', ax, 'XData', NaN, 'YData', NaN, ...
                  'LineStyle', 'none', 'Marker', 'none');

% --- extra (reference-line) entries: column 3 ---
extra_h = gobjects(1, 0); extra_l = {};
if isgraphics(hOk)
    extra_h(end+1) = hOk;
    extra_l{end+1} = sprintf('Okun locus ($\\omega=%.2f$)', 1/okun);
end
if isgraphics(hMiss0)
    extra_h(end+1) = hMiss0;
    % Panel-agnostic legend entry: the same line style is the Y_tilde=0
    % contour in (b), theta_tilde=0 in (c) and u_tilde=0 in (d); each panel
    % labels its own contour with the comovement value it represents
    % (omega -> -inf, omega*_q, 0), see contour_tag above.
    extra_l{end+1} = 'Zero contour of the third gap (labeled)';
end
if isgraphics(hXi)
    extra_h(end+1) = hXi;
    extra_l{end+1} = sprintf('Price-elasticity threshold, $\\tilde{\\Xi}=0$ ($\\omega^*_\\Xi=%.2f$)', xi_beta);
end
if isgraphics(hShade)
    extra_h(end+1) = hShade;
    extra_l{end+1} = 'Amplification region ($\omega<\omega^*_\Xi$)';
end

% --- assemble row by row: [shock (+) | shock (-) | reference line] ---
nRows = max(n, numel(extra_h));
hx = gobjects(1, 0); lx = {};
for k = 1:nRows
    if k <= n
        hx(end+1) = h(2*k-1); lx{end+1} = leg{2*k-1};   %#ok<AGROW>
        hx(end+1) = h(2*k);   lx{end+1} = leg{2*k};     %#ok<AGROW>
    else
        hx(end+1) = blank(); lx{end+1} = '';             %#ok<AGROW>
        hx(end+1) = blank(); lx{end+1} = '';             %#ok<AGROW>
    end
    if k <= numel(extra_h)
        hx(end+1) = extra_h(k); lx{end+1} = extra_l{k}; %#ok<AGROW>
    else
        hx(end+1) = blank(); lx{end+1} = '';             %#ok<AGROW>
    end
end

lg = legend(hx, lx, 'Orientation', 'horizontal', 'NumColumns', 3, ...
            'Box', 'off', 'FontSize', fs-1, 'Interpreter', 'latex');
lg.Layout.Tile = 'south';

% -------------------------------------------------------------------------
% Export
% -------------------------------------------------------------------------
set(gcf, 'Units',             'centimeters');
set(gcf, 'Position',          [0 0 plot_cfg.fig_size(1) plot_cfg.fig_size(2)]);
set(gcf, 'PaperUnits',        'centimeters');
set(gcf, 'PaperSize',         plot_cfg.fig_size);
set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperPosition',     [0 0 plot_cfg.fig_size(1) plot_cfg.fig_size(2)]);
fontsize(gcf, fs, 'points');
drawnow;
for pp = 1:numel(LBL)
    place_panel_labels(LBL(pp), fs);
end

ensure_dir(sprintf('%s.eps', plot_cfg.fig_prefix));
exportgraphics(gcf, sprintf('%s.eps', plot_cfg.fig_prefix), 'ContentType', 'vector');

% -------------------------------------------------------------------------
% 6. Regime bookkeeping (returned, not plotted)
% -------------------------------------------------------------------------
info.scale_factors = scale_factors;
info.impact_norms  = impact_norms;
info.norm_target   = norm_target;
info.ThY           = ThY;
info.Thu           = Thu;
info.R2             = R2;
info.okun_slope     = okun_slope;
info.okun_elast     = okun;
info.max_abs_ue_N   = ueN_max;
info.xi_beta        = xi_beta;

info.regime_switch = {};
for ii = 1:n
    sh = char(plot_cfg.shocks(ii));
    rl = classify_regime(theta_lvl_s{ii}, u_lvl_s{ii});
    rg = classify_regime(theta_gap_s{ii}, u_gap_s{ii});
    info.regimes_level.(sh) = rl;
    info.regimes_gap.(sh)   = rg;
    if ~isequal(rl, rg)
        info.regime_switch{end+1} = sh;  %#ok<AGROW>
        fprintf(['plot_phase_diagram: %s (%s) is classified DIFFERENTLY ' ...
                 'in levels and gaps.\n    levels: %s\n    gaps  : %s\n'], ...
                char(plot_cfg.shock_labels(ii)), sh, regime_runs(rl), regime_runs(rg));
    end
end

end

% =========================================================================
% Helpers
% =========================================================================
function place_panel_labels(L, fs)
% Zero-contour label (parallel to its line, just beside it) and the four
% regime labels of one panel, placed where they cover no obstacle (L.obsN:
% trajectories, impact markers, axes, reference lines, labels already
% placed) and keep the most clearance; all text stays inside the axes.
ax = L.ax; p = L.p; xl = L.xl; yl = L.yl; obsN = L.obsN;
hold(ax, 'on');
if ~isempty(p.miss) && ~isempty(p.contour_tag)
    xs  = linspace(-xl, xl, 401)';
    yc  = p.contour_line(xs, 0);
    sl  = (p.contour_line(xl, 0) - p.contour_line(-xl, 0)) / (2*xl);
    ang = atan2d(sl*xl/yl, 1);                       % on-screen angle (square axes)
    [a, b] = label_size(ax, p.contour_tag, 'latex', fs-2, xl, yl);
    on  = abs(xs) <= xl & abs(yc) <= yl;
    Lp  = [xs(on)/xl, yc(on)/yl];
    nv  = [-sind(ang), cosd(ang)];                   % unit normal (normalized units)
    C   = [Lp + (b + 0.012)*nv; Lp - (b + 0.012)*nv];
    C   = C(hypot(C(:,1), C(:,2)) >= 0.2, :);
    k   = best_rect(C, obsN, a, b, ang);
    if ~isempty(k)
        text(ax, C(k,1)*xl, C(k,2)*yl, p.contour_tag, 'Interpreter', 'latex', ...
             'FontSize', fs-2, 'Color', [0.40 0.40 0.40], 'Rotation', ang, ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
        obsN = [obsN; rect_points(C(k,:), a, b, ang)];
    end
end
region_labels(ax, p.theta, p.u, xl, yl, fs, obsN);
hold(ax, 'off');
end

function region_labels(ax, thetaf, uf, xl, yl, fs, obsN)
% Place the four Barro-Grossman region names inside their regions, each at
% the admissible spot farthest from all obstacles (obsN, axis-
% normalized: trajectories, axes, reference lines, labels already placed).
% A spot is admissible if the box lies inside the axes and covers no obstacle
% (if no such spot exists, the one covering the fewest is used). Regions are
% read from the box centre: quadrants in (a)/(b), cones in (c)/(d).
[gu, gv] = meshgrid(linspace(-1, 1, 81));
th = thetaf(gu*xl, gv*yl);
uu = uf(gu*xl, gv*yl);

specs = { ...
    {'Classical',       'Unemployment'},  @() th > 0 & uu > 0; ...
    {'Keynesian',       'Unemployment'},  @() th <= 0 & uu > 0; ...
    {'Repressed',       'Inflation'},     @() th > 0 & uu <= 0; ...
    {'Underconsumption', ''},             @() th <= 0 & uu <= 0};

for k = 1:size(specs, 1)
    txt = specs{k, 1};
    if isempty(txt{end}), txt = txt(1:end-1); end
    m = specs{k, 2}();
    if ~any(m(:)), continue; end
    [a, b] = label_size(ax, txt, 'tex', fs-2, xl, yl);
    C  = [gu(m), gv(m)];
    kk = best_rect(C, obsN, a, b, 0);
    if isempty(kk), continue; end
    text(ax, C(kk,1)*xl, C(kk,2)*yl, txt, 'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', 'FontSize', fs-2, 'Color', [0.35 0.35 0.35]);
    obsN = [obsN; rect_points(C(kk,:), a, b, 0)]; %#ok<AGROW>
end
end

function [a, b] = label_size(ax, str, interp, fsz, xl, yl)
% Half-width a and half-height b of a label (unrotated, incl. box margin) in
% axis-normalized units (axis half-range = 1), measured from the rendered text.
t = text(ax, 0, 0, str, 'Interpreter', interp, 'FontSize', fsz, 'Units', 'data', ...
         'Margin', 0.5, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
e = get(t, 'Extent'); delete(t);
a = 0.5*e(3)/xl + 0.015;         % measured after the final layout (see Export),
b = 0.5*e(4)/yl + 0.015;         % plus a small clearance
end

function k = best_rect(C, O, a, b, ang)
% Index of the candidate centre (row of C) for a box of half-sizes (a, b),
% rotated by ang degrees, all in axis-normalized units: the box must lie
% inside the axes (margin 0.03); among those, fewest obstacles (rows of O)
% inside the box, then largest clearance to the nearest obstacle.
k = [];
if isempty(C), return; end
c = cosd(ang); s = sind(ang);
ex = abs(c)*a + abs(s)*b;  ey = abs(s)*a + abs(c)*b;     % half-extent of the box
ok = abs(C(:,1)) <= 0.97 - ex & abs(C(:,2)) <= 0.97 - ey;
if ~any(ok), return; end
idx = find(ok);
dx = O(:,1).' - C(idx,1);  dy = O(:,2).' - C(idx,2);
sp = abs( dx*c + dy*s) - a;                               % along the label
tp = abs(-dx*s + dy*c) - b;                               % across the label
cnt = sum(sp <= 0 & tp <= 0, 2);
clr = min(max(sp, tp), [], 2);
best = cnt == min(cnt);
clr(~best) = -Inf;
[~, j] = max(clr);
k = idx(j);
end

function P = rect_points(c, a, b, ang)
% Grid of points covering a (rotated) label box, as obstacles for later labels.
[s, t] = meshgrid(linspace(-a, a, 9), linspace(-b, b, 5));
P = [c(1) + s(:)*cosd(ang) - t(:)*sind(ang), c(2) + s(:)*sind(ang) + t(:)*cosd(ang)];
end

function P = densify(x, y)
% Points along the polyline (x,y), 10 per segment, as obstacles for labels.
x = x(:); y = y(:);
if numel(x) < 2, P = [x y]; return; end
t = linspace(0, 1, 10);
P = [reshape(x(1:end-1) + (x(2:end) - x(1:end-1)) .* t, [], 1), ...
     reshape(y(1:end-1) + (y(2:end) - y(1:end-1)) .* t, [], 1)];
end

function r = classify_regime(theta, u)
% Sign(theta) x sign(u) -> the four cells of barroGeneral1971.
T = numel(theta); r = cell(1, T);
for t = 1:T
    if     theta(t) >  0 && u(t) > 0, r{t} = 'Classical unemployment';
    elseif theta(t) <= 0 && u(t) > 0, r{t} = 'Keynesian unemployment';
    elseif theta(t) >  0,             r{t} = 'Repressed inflation';
    else,                             r{t} = 'Underconsumption';
    end
end
end

function s = regime_runs(r)
% Compact "Q1:X -> Q6:Y" summary of a regime sequence.
parts = {};
for t = 1:numel(r)
    if t == 1 || ~strcmp(r{t}, r{t-1})
        parts{end+1} = sprintf('Q%d:%s', t, r{t});  %#ok<AGROW>
    end
end
s = strjoin(parts, ' -> ');
end
