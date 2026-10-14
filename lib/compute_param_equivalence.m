% *************************************************************************
% When Buying Takes Time:
% Implications for the New-Keynesian Business Cycle Model
% Reduced-Form Model: GOODS MARKET SaM PARAMETER EQUIVALENCE EXPERIMENT
% -------------------------------------------------------------------------
% Konstantin Gantert
% kgantert@mail.de
% *************************************************************************

function eq = compute_param_equivalence(p0, par, opts)
% COMPUTE_PARAM_EQUIVALENCE  Search for alternative (gamQ, subQ, nuD)
%   combinations that reproduce the baseline calibration's Euler equation
%   (AD_ag), Phillips curve (kapP & AS_ag), and real wage equation
%   (WG_ag) slopes, and report how the utilization gap (CU), price
%   elasticity gap (PE), and labor wedge (LW) coefficients move at those
%   alternative combinations.
%
%   Question: the goods-market SaM extension is driven by three
%   parameters - gamQ (matching elasticity), subQ (matching CES
%   substitution/curvature), and nuD (shopping-time elasticity, relative
%   to the fixed labour-supply elasticity nuN). Are there alternative
%   combinations of these three that leave (c) the Euler equation, (d)
%   the Phillips curve, and (e) the real wage equation unchanged, and if
%   so, what happens to (a) the utilization gap, (b) the price
%   elasticity gap, and (f) the labor wedge?
%
% -------------------------------------------------------------------------
% STRUCTURAL FACT USED TO DESIGN THE SEARCH
% -------------------------------------------------------------------------
%   Because steady-state goods-market tightness is normalised to x = 1,
%   kapP (the Phillips-curve slope) turns out to be a function of gamQ
%   ONLY: it does not depend on subQ or nuD at all. This was verified
%   numerically. Consequently:
%     - There is no alternative gamQ that reproduces the same kapP; exact
%       equivalence for kapP requires gamQ = p0.gamQ exactly.
%
%   Under direct kappa_P calibration (p0.kapP_select == 1) kapP is imposed
%   and therefore constant by construction, so it carries no identifying
%   content. The roles of the two objects simply swap: the free
%   Phillips-curve invariant is then the IMPLIED labour-share slope
%   pc_slope_impl = pPIpi*sPImc/kapP. Since kapP is a constant, this is an
%   exact rescaling of the kapP of the slope-targeting mode, so it is a
%   function of gamQ only by the same argument and the experiment design
%   below is unchanged - only the name of the matched object differs.
%   pc_target_field() picks the right one for the active mode.
%     - AS_ag (the Okun-aggregated Phillips-curve slope reported in the
%       figures) DOES depend on subQ and nuD even though kapP does not,
%       because the output-gap/unemployment-gap mix underlying AS_ag is
%       not invariant to those two parameters.
%
% -------------------------------------------------------------------------
% EXPERIMENT DESIGN
% -------------------------------------------------------------------------
%   (1) AD_ag target : loop over a (subQ, nuD) grid; solve for gamQ such
%       that AD_ag matches its baseline value at each grid point.
%   (2) WG_ag target : identical procedure, targeting WG_ag.
%   (3) kapP (or pc_slope_impl, see above) & AS_ag target : gamQ is forced
%       to p0.gamQ (the only value consistent with matching the
%       Phillips-curve invariant). Loop over a subQ grid; solve for
%       nuD such that AS_ag matches its baseline value, holding
%       gamQ = p0.gamQ fixed.
%
%   At every solution found the full coefficient set (CU, PE, AD, AS, WG,
%   LW - both _ag and _t/_ue) is recomputed so the report can show how
%   the non-targeted coefficients move.
%
%   Root-finding: WG_ag is not monotonic in gamQ (it can have an interior
%   minimum), so each equation is first evaluated on a scan grid to
%   bracket every sign change, and each bracket is refined with fsolve.
%   This can return zero, one, or several roots per grid point; the
%   root furthest from the trivial baseline value is used to populate
%   the coefficient tables (the genuinely "alternative" solution), and
%   the full root count is retained for the report.
%
%   Inputs
%     p0   - baseline parameter struct (from build_p)
%     par  - parameter struct (from get_params), used for default grids
%     opts - (optional) struct overriding default grids/bounds:
%              .subQ_grid    - subQ values to loop over
%              .nuD_grid     - nuD level values to loop over (nuN held
%                              fixed at par.nuN)
%              .gamQ_bounds  - [low high] search bounds for gamQ
%              .gamQ_scan_n  - number of scan points for gamQ bracketing
%              .nuD_bounds   - [low high] search bounds for nuD
%              .nuD_scan_n   - number of scan points for nuD bracketing
%              .tol          - residual tolerance treated as a pole guard
%              .report_file  - path for the text report
%
%   Output
%     eq - struct with fields .AD, .WG, .AS (one per target experiment)
%          and .baseline (baseline parameters and coefficients)

if nargin < 3
    opts = struct();
end
opts = default_opts(opts, par);

% -------------------------------------------------------------------------
% BASELINE
% -------------------------------------------------------------------------
out0 = eval_model(p0, p0.gamQ, p0.subQ, p0.nuD);
base = pack_base(p0, out0);

% -------------------------------------------------------------------------
% EXPERIMENTS
% -------------------------------------------------------------------------
eq.AD = run_gamQ_experiment(p0, 'AD_ag', base.AD_ag, opts.subQ_grid, opts.nuD_grid, opts);
eq.WG = run_gamQ_experiment(p0, 'WG_ag', base.WG_ag, opts.subQ_grid, opts.nuD_grid, opts);
eq.AS = run_nuD_experiment(p0, 'AS_ag', base.AS_ag, opts.subQ_grid, opts);
eq.baseline = base;
eq.pc_field = pc_target_field(p0);   % 'kapP' or 'pc_slope_impl'
eq.AS.pc_field = eq.pc_field;

% -------------------------------------------------------------------------
% REPORT
% -------------------------------------------------------------------------
report_param_equivalence(eq, opts);

end


% =========================================================================
% LOCAL HELPERS
% =========================================================================

function opts = default_opts(opts, par)
opts = set_default(opts, 'subQ_grid',   linspace(-3, -0.05, 7));
opts = set_default(opts, 'nuD_grid',    linspace(0.5*par.nuN, 1.5*par.nuN, 7));
opts = set_default(opts, 'gamQ_bounds', [0.01, 0.75]);
opts = set_default(opts, 'gamQ_scan_n', 200);
opts = set_default(opts, 'nuD_bounds',  [0.05, 6]);
opts = set_default(opts, 'nuD_scan_n',  200);
opts = set_default(opts, 'tol',         1e-4);
opts = set_default(opts, 'report_file', nksam_path('txt', 'param_equivalence.txt'));
end

function s = set_default(s, field, val)
if ~isfield(s, field) || isempty(s.(field))
    s.(field) = val;
end
end

function fields = coef_fields()
fields = {'CU_t','CU_ue','CU_ag', 'PE_t','PE_ue','PE_ag', ...
          'AD_t','AD_ue','AD_ag', 'AS_t','AS_ue','AS_ag', ...
          'kapP','pc_slope_impl', ...
          'WG_t','WG_ue','WG_ag', 'LW_t','LW_ue','LW_ag'};
end

function fld = pc_target_field(p0)
% PC_TARGET_FIELD  The Phillips-curve object that is free to move under the
%   active calibration mode, and hence the one that identifies gamQ.
%     kapP_select == 0 : kapP is endogenous       -> report/target kapP
%     kapP_select == 1 : kapP is imposed          -> report/target the
%                        implied labour-share slope pc_slope_impl
if isfield(p0, 'kapP_select') && p0.kapP_select == 1
    fld = 'pc_slope_impl';
else
    fld = 'kapP';
end
end

function base = pack_base(p0, out0)
base.gamQ = p0.gamQ;
base.subQ = p0.subQ;
base.nuD  = p0.nuD;
base.nuN  = p0.nuN;
fields = coef_fields();
for k = 1:numel(fields)
    base.(fields{k}) = out0.(fields{k});
end
end

function out = eval_model(p0, gamQ, subQ, nuD)
% EVAL_MODEL  Evaluate the SaM model at (gamQ, subQ, nuD), holding all
%   other parameters at their baseline (p0) values. Returns a struct of
%   NaN on infeasibility (complex or non-finite output).
p = p0;
p.gamQ = gamQ; p.subQ = subQ; p.nuD = nuD;
fields = coef_fields();
ok = true;
try
    [out_sam, ~] = compute_wedges(p);
    for k = 1:numel(fields)
        v = out_sam.(fields{k});
        if ~isreal(v) || ~isfinite(v)
            ok = false;
            break
        end
    end
catch
    ok = false;
end
if ~ok
    out = struct();
    for k = 1:numel(fields)
        out.(fields{k}) = NaN;
    end
else
    out = out_sam;
end
end

function res = residual_fn(x, p0, field, target_val, gamQ, subQ, nuD, which)
% RESIDUAL_FN  Generic residual: substitute x for whichever of
%   gamQ/subQ/nuD is being solved for ('which'), evaluate the model, and
%   return the deviation of the requested field from target_val.
switch which
    case 'gamQ'
        gamQ = x;
    case 'subQ'
        subQ = x;
    case 'nuD'
        nuD = x;
end
out = eval_model(p0, gamQ, subQ, nuD);
res = out.(field) - target_val;
end

function roots = bracket_and_solve(fun, scan_grid, pole_tol, fsolve_opts)
% BRACKET_AND_SOLVE  Scan fun over scan_grid, bracket every sign change
%   (ignoring NaN and pole-like jumps), and refine each bracket with
%   fsolve. Returns a (possibly empty) row vector of distinct roots.
n = numel(scan_grid);
fvals = NaN(1, n);
for ii = 1:n
    try
        v = fun(scan_grid(ii));
    catch
        v = NaN;
    end
    if isfinite(v) && abs(v) < 1e6
        fvals(ii) = v;
    end
end

roots = [];
for ii = 1:n-1
    f1 = fvals(ii); f2 = fvals(ii+1);
    if isnan(f1) || isnan(f2) || f1*f2 > 0
        continue
    end
    x0 = 0.5*(scan_grid(ii) + scan_grid(ii+1));
    [xr, fr, exitflag] = fsolve(fun, x0, fsolve_opts);
    if exitflag > 0 && abs(fr) < pole_tol
        roots(end+1) = xr; %#ok<AGROW>
    end
end

if isempty(roots)
    return
end

roots = sort(roots);
keep = true(size(roots));
for ii = 2:numel(roots)
    if abs(roots(ii) - roots(ii-1)) < 1e-4
        keep(ii) = false;
    end
end
roots = roots(keep);
end

function exp_out = run_gamQ_experiment(p0, field, target_val, subQ_grid, nuD_grid, opts)
% RUN_GAMQ_EXPERIMENT  For every (subQ, nuD) grid point, solve for gamQ
%   such that out.(field) matches target_val.
nS = numel(subQ_grid); nT = numel(nuD_grid);
gamQ_scan   = linspace(opts.gamQ_bounds(1), opts.gamQ_bounds(2), opts.gamQ_scan_n);
fsolve_opts = optimoptions('fsolve', 'Display', 'off');

gamQ_sol  = cell(nS, nT);
gamQ_used = NaN(nS, nT);   % the root actually used to populate coef (below)
n_roots   = zeros(nS, nT);
fields    = coef_fields();
coef      = struct();
for k = 1:numel(fields)
    coef.(fields{k}) = NaN(nS, nT);
end

for ii = 1:nS
    for tt = 1:nT
        subQ = subQ_grid(ii); nuD = nuD_grid(tt);
        fun   = @(gamQ) residual_fn(gamQ, p0, field, target_val, gamQ, subQ, nuD, 'gamQ');
        roots = bracket_and_solve(fun, gamQ_scan, opts.tol, fsolve_opts);
        gamQ_sol{ii,tt} = roots;
        n_roots(ii,tt)  = numel(roots);
        if ~isempty(roots)
            [~, idx] = max(abs(roots - p0.gamQ));   % furthest = genuine alternative
            gq  = roots(idx);
            gamQ_used(ii,tt) = gq;
            out = eval_model(p0, gq, subQ, nuD);
            for k = 1:numel(fields)
                coef.(fields{k})(ii,tt) = out.(fields{k});
            end
        end
    end
end

exp_out.field      = field;
exp_out.target_val = target_val;
exp_out.subQ_grid   = subQ_grid;
exp_out.nuD_grid    = nuD_grid;
exp_out.gamQ_sol    = gamQ_sol;   % cell array: all roots found per grid point
exp_out.gamQ_used   = gamQ_used;  % the root actually used to populate coef
exp_out.n_roots     = n_roots;
exp_out.coef        = coef;       % struct of [nSubQ x nNuS] matrices at the used root
end

function exp_out = run_nuD_experiment(p0, field, target_val, subQ_grid, opts)
% RUN_NUS_EXPERIMENT  kapP depends on gamQ only, so matching kapP forces
%   gamQ = p0.gamQ. For every subQ grid value, solve for nuD such that
%   out.(field) (AS_ag) matches target_val at that fixed gamQ.
nS = numel(subQ_grid);
nuD_scan    = linspace(opts.nuD_bounds(1), opts.nuD_bounds(2), opts.nuD_scan_n);
fsolve_opts = optimoptions('fsolve', 'Display', 'off');
gamQ_fixed  = p0.gamQ;

nuD_sol  = cell(1, nS);
nuD_used = NaN(1, nS);   % the root actually used to populate coef (below)
n_roots  = zeros(1, nS);
fields   = coef_fields();
coef     = struct();
for k = 1:numel(fields)
    coef.(fields{k}) = NaN(1, nS);
end

for ii = 1:nS
    subQ = subQ_grid(ii);
    fun   = @(nuD) residual_fn(nuD, p0, field, target_val, gamQ_fixed, subQ, nuD, 'nuD');
    roots = bracket_and_solve(fun, nuD_scan, opts.tol, fsolve_opts);
    nuD_sol{ii} = roots;
    n_roots(ii) = numel(roots);
    if ~isempty(roots)
        [~, idx] = max(abs(roots - p0.nuD));
        nu  = roots(idx);
        nuD_used(ii) = nu;
        out = eval_model(p0, gamQ_fixed, subQ, nu);
        for k = 1:numel(fields)
            coef.(fields{k})(ii) = out.(fields{k});
        end
    end
end

exp_out.field      = field;
exp_out.target_val = target_val;
exp_out.gamQ_fixed = gamQ_fixed;
exp_out.subQ_grid  = subQ_grid;
exp_out.nuD_sol    = nuD_sol;
exp_out.nuD_used   = nuD_used;   % the root actually used to populate coef
exp_out.n_roots    = n_roots;
exp_out.coef       = coef;
end


% =========================================================================
% REPORTING
% =========================================================================

function report_param_equivalence(eq, opts)
lines = {};
lines{end+1} = 'Goods-Market SaM Parameter Equivalence Experiment';
lines{end+1} = repmat('=', 1, 78);
lines{end+1} = '';
lines{end+1} = sprintf('Baseline: gamQ=%.4f  subQ=%.4f  nuD=%.4f (nuN=%.4f)', ...
    eq.baseline.gamQ, eq.baseline.subQ, eq.baseline.nuD, eq.baseline.nuN);
pcf = eq.pc_field;
lines{end+1} = sprintf(['Baseline coefficients: AD_ag=%.4f  AS_ag=%.4f  kapP=%.4f  ' ...
    'pc_slope_impl=%.4f  WG_ag=%.4f  CU_ag=%.4f  PE_ag=%.4f  LW_ag=%.4f'], ...
    eq.baseline.AD_ag, eq.baseline.AS_ag, eq.baseline.kapP, ...
    eq.baseline.pc_slope_impl, eq.baseline.WG_ag, ...
    eq.baseline.CU_ag, eq.baseline.PE_ag, eq.baseline.LW_ag);
lines{end+1} = '';
if strcmp(pcf, 'kapP')
    lines{end+1} = 'Phillips-curve calibration: slope targeted, kappa_P endogenous (kapP_select = 0).';
else
    lines{end+1} = 'Phillips-curve calibration: kappa_P imposed directly (kapP_select = 1), so it is';
    lines{end+1} = 'constant by construction; the free invariant is the implied labour-share slope.';
end
lines{end+1} = sprintf('Note: %s is a function of gamQ only. Experiment 3 therefore fixes', pcf);
lines{end+1} = 'gamQ = baseline and searches for nuD (given subQ) so AS_ag also matches,';
lines{end+1} = 'rather than solving for gamQ as in Experiments 1-2.';
lines{end+1} = '';

lines = append_gamQ_report(lines, eq.AD, ...
    'Experiment 1: match AD_ag (Euler equation) by solving for gamQ over a (subQ, nuD) grid');
lines = append_gamQ_report(lines, eq.WG, ...
    'Experiment 2: match WG_ag (real wage equation) by solving for gamQ over a (subQ, nuD) grid');
lines = append_nuD_report(lines, eq.AS, ...
    sprintf(['Experiment 3: match %s & AS_ag (Phillips curve); gamQ forced to ' ...
             'baseline, solving for nuD over a subQ grid'], pcf));

for ii = 1:numel(lines)
    disp(lines{ii});
end

ensure_dir(opts.report_file);
fid = fopen(opts.report_file, 'w');
if fid == -1
    error('compute_param_equivalence:report_param_equivalence: could not open "%s" for writing (check that its directory exists/is writable).', opts.report_file);
end
for ii = 1:numel(lines)
    fprintf(fid, '%s\n', lines{ii});
end
fclose(fid);
end

function lines = append_gamQ_report(lines, ex, title)
lines{end+1} = title;
lines{end+1} = repmat('-', 1, 78);
lines{end+1} = sprintf('Target: %s = %.4f', ex.field, ex.target_val);
lines{end+1} = sprintf('%-8s %-8s %-7s %10s %10s %10s %10s %10s %10s', ...
    'subQ', 'nuD', '#roots', 'gamQ*', 'CU_ag', 'PE_ag', 'LW_ag', 'AS_ag', 'WG_ag');
lines{end+1} = repmat('-', 1, 78);

nS = numel(ex.subQ_grid); nT = numel(ex.nuD_grid);
for ii = 1:nS
    for tt = 1:nT
        nr = ex.n_roots(ii,tt);
        if nr == 0
            lines{end+1} = sprintf('%-8.3f %-8.3f %-7d %10s %10s %10s %10s %10s %10s', ...
                ex.subQ_grid(ii), ex.nuD_grid(tt), 0, '-', '-', '-', '-', '-', '-');
            continue
        end
        gq_used = ex.gamQ_used(ii,tt);
        lines{end+1} = sprintf('%-8.3f %-8.3f %-7d %10.4f %10.4f %10.4f %10.4f %10.4f %10.4f', ...
            ex.subQ_grid(ii), ex.nuD_grid(tt), nr, gq_used, ...
            ex.coef.CU_ag(ii,tt), ex.coef.PE_ag(ii,tt), ex.coef.LW_ag(ii,tt), ...
            ex.coef.AS_ag(ii,tt), ex.coef.WG_ag(ii,tt));
    end
end
lines{end+1} = '';
end

function lines = append_nuD_report(lines, ex, title)
lines{end+1} = title;
lines{end+1} = repmat('-', 1, 78);
lines{end+1} = sprintf('Target: %s = %.4f   (gamQ fixed at %.4f)', ...
    ex.field, ex.target_val, ex.gamQ_fixed);
if isfield(ex, 'pc_field'), pcf = ex.pc_field; else, pcf = 'kapP'; end
lines{end+1} = sprintf('%-8s %-7s %10s %10s %10s %10s %10s %13s', ...
    'subQ', '#roots', 'nuD*', 'CU_ag', 'PE_ag', 'LW_ag', 'AD_ag', pcf);
lines{end+1} = repmat('-', 1, 78);

nS = numel(ex.subQ_grid);
for ii = 1:nS
    nr = ex.n_roots(ii);
    if nr == 0
        lines{end+1} = sprintf('%-8.3f %-7d %10s %10s %10s %10s %10s %13s', ...
            ex.subQ_grid(ii), 0, '-', '-', '-', '-', '-', '-');
        continue
    end
    nu_used = ex.nuD_used(ii);
    lines{end+1} = sprintf('%-8.3f %-7d %10.4f %10.4f %10.4f %10.4f %10.4f %13.4f', ...
        ex.subQ_grid(ii), nr, nu_used, ...
        ex.coef.CU_ag(ii), ex.coef.PE_ag(ii), ex.coef.LW_ag(ii), ...
        ex.coef.AD_ag(ii), ex.coef.(pcf)(ii));
end
lines{end+1} = '';
end

% ----------------------------- End of file -------------------------------
