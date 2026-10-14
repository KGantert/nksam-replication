% main_s3_s4_slopes.m -- Sections 3-4 (reduced-form slopes), plus the numbers and
%   figures that come from the same computation (Section 2 calibration,
%   Appendix C cutoffs, Online Appendix V.2)
% -------------------------------------------------------------------------
% PRODUCES
%   results/figures/fig_slopes_5eq_cu_pe.eps     Section 3, fig:slopes_5eq_util (dynamics.tex)
%   results/figures/fig_slopes_5eq_ee_pc_rw.eps  Section 4, fig:slopes_5eq (curves.tex)
%   results/figures/fig_slopes_5eq_lw_se_mc.eps  Online Appendix V.2, fig:app_slopes_tot_wedge
%   results/figures/fig_stst_gamES_cutoff.eps    Appendix C, fig:cutoff_gammaQ (ap_cutoffs.tex)
%   results/txt/fig_slopes_5eq_*.txt             endpoint/crossing tables of the three slope figures
%   results/txt/calibration_summary.txt          Section 2 (sec:calibration, tab:calibration),
%                                                Appendix A, kappa_P footnote in Section 4
%   results/txt/nuD_cutoffs.txt                  nu_D cutoffs: Appendix C (sec:cutoff_nuD),
%                                                Section 4, Section 6 / Online Appendix VI
% The gamma_Q and nu_D cutoffs are computed here because both determine
% elements of the slope figures (the gamma_Q values of the three lines, the
% crossings with the benchmark).
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_slopes.m'));

% -- Slope figures (Sections 3-4, Online Appendix V.2) --------------------------
figs_slope(res_sam, res_nk, res_gray, par.gamQ_low, gamQ_cut, par.gamQ_high, par.nuD_sens_loop, par.nuN, lwdth);

% -------------------------------------------------------------------------
% GAMMA_Q CUTOFF FIGURE (Appendix C, fig:cutoff_gammaQ)
% Shows BOTH the epsilon-conditional cutoff (general form, eq:cutoff_gammaQ_eps)
% and the markup-conditional cutoff (self-consistent under the calibration's
% own epsilon(gamQ) mapping, eq:cutoff_gammaQ_selfconsistent) side by side.
% setup_slopes' cached gamQ_cut_loop is computed under the global
% flags.mp_select (markup targeting, == 1 by default); the opposite-convention
% curve is computed here on a local copy of p0 (flags, p0, cache untouched).
% -------------------------------------------------------------------------
p0_alt = p0;
p0_alt.mp_select = 1 - flags.mp_select;
[~, gamQ_cut_loop_alt, ~] = compute_gamQ_cutoff( ...
    p0_alt, par.mp_cut_loop, par.epsP_cut_loop, par.gamQ_low, par.gamQ_high);
if flags.mp_select == 1
    gamQ_cut_loop_mp  = gamQ_cut_loop;
    gamQ_cut_loop_eps = gamQ_cut_loop_alt;
else
    gamQ_cut_loop_mp  = gamQ_cut_loop_alt;
    gamQ_cut_loop_eps = gamQ_cut_loop;
end
figs_gamQ_cutoff(gamQ_cut_loop_mp, gamQ_cut_loop_eps, par.mp_cut_loop, par.epsP_cut_loop, lwdth);
clearvars p0_alt gamQ_cut_loop_alt gamQ_cut_loop_mp gamQ_cut_loop_eps;

% -------------------------------------------------------------------------
% TEXT REPORTS
%   calibration_summary.txt: epsilon, kappa_P, kappa_W, ... (Section 2, Appendix A)
%   nuD_cutoffs.txt: closed-form nu_D cutoffs at Gamma_Q ~ 0, cross-checked
%     against the numerical crossings of the fig_slopes_5eq_ee_pc_rw curves
% -------------------------------------------------------------------------
subQ_labels = {'GamQ=-2.7 (CES)', 'GamQ~0 (CD, default)'};  % must match get_params.m: par.subQ_loop = [par.subQ_mid, par.subQ]
report_calibration(nksam_path('txt', 'calibration_summary.txt'), p0, gamQ_loop, par.subQ_loop, subQ_labels);
report_nuD_cutoffs(nksam_path('txt', 'nuD_cutoffs.txt'), p0, gamQ_loop, gamQ_cut, par.subQ_loop, par.subQ, ...
    res_sam, res_nk, par.nuD_sens_loop);

% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================
function report_calibration(fname_txt, p0, gamQ_loop, subQ_loop, subQ_labels)
% REPORT_CALIBRATION  Calibrated parameters and composites of both models at
% the baseline (gamQ = p0.gamQ, Gamma_Q = p0.subQ, nuD = p0.nuD), plus
% kappa_P and epsilon across the gamQ x Gamma_Q sweep of the slope figures.
[cs, cn] = model_composites(p0);

% kappa_W: closed form of print Appendix A (eq:add_kapP_slope), using the
% wage Phillips curve slope target of the Dynare calibration.
kapW_s = NaN; kapW_n = NaN; nkwpc = NaN;
try
    [~, ~, ~, ~, target] = get_params('dynare');
    nkwpc  = target.nkwpc_slope;
    kapW_s = -(cs.epsW-1)*p0.nuN/(1+p0.ue)/nkwpc;   % slope per pp of u
    kapW_n = -(cn.epsW-1)*p0.nuN/(1+p0.ue)/nkwpc;
catch
    warning('report_calibration: could not read target.nkwpc_slope from get_params(''dynare''); kappa_W not reported.');
end

L = {};
L{end+1} = 'Calibration summary: NK-SaM vs benchmark NK model (baseline calibration)';
L{end+1} = sprintf('gamQ = %.4f, Gamma_Q = %.4g, nuD = %.4f, nuN = %.4f, sigma = %.4f', ...
    p0.gamQ, p0.subQ, p0.nuD, p0.nuN, p0.sig);
L{end+1} = repmat('=', 1, 92);
L{end+1} = '';
L{end+1} = 'Targets (common to both models)';
L{end+1} = sprintf('  %-46s %12.4f', 'Gross price markup, 1/mc', p0.mp);
L{end+1} = sprintf('  %-46s %12.4f', 'Capacity utilization, cu (NK-SaM only)', p0.q);
L{end+1} = sprintf('  %-46s %12.4f', 'Unemployment rate, u', p0.ue);
L{end+1} = sprintf('  %-46s %12.4f', 'Home work / market work, H/N', p0.hN);
L{end+1} = sprintf('  %-46s %12.4f', 'Search time / market work, D_Q/N', p0.dN);
L{end+1} = sprintf('  %-46s %12.4f', 'Total non-market time, H/N + D_Q/N', p0.hN + p0.dN);
L{end+1} = sprintf('  %-46s %12.4f', 'Home production / GDP, C_H/GDP', p0.chGDP);
L{end+1} = sprintf('  %-46s %12.4f', 'Labor-share Phillips curve slope', p0.pc_slope);
L{end+1} = sprintf('  %-46s %12.4f', 'Wage Phillips slope (per pp of u, quarterly)', nkwpc);
L{end+1} = '';
L{end+1} = sprintf('  %-46s %12s %12s', 'Calibrated parameter / composite', 'NK-SaM', 'Benchmark');
L{end+1} = repmat('-', 1, 92);
rows = { ...
    'Elasticity of substitution, epsilon',          cs.epsP,  cn.epsP; ...
    'Price adjustment cost, kappa_P',               cs.kapP,  cn.kapP; ...
    'Wage adjustment cost, kappa_W (App. A)',       kapW_s,   kapW_n; ...
    'Labor substitution elasticity, epsilon_W',     cs.epsW,  cn.epsW; ...
    'Implied gross markup, 1/mc (check)',           cs.mp,    cn.mp; ...
    'Effective elasticity, epsilon(1-phi_Xi)',      cs.M,     cn.M; ...
    'Search price, P_Q',                            cs.ps,    cn.ps; ...
    'Price elasticity of demand, Xi',               cs.pe,    cn.pe; ...
    'Search-effort elasticity, phi_gamma',          cs.phiGam, cn.phiGam; ...
    'Super-elasticity, phi_Xi',                     cs.phiXi, cn.phiXi; ...
    'Feedback sign, zeta = epsilon*phi_Xi - 1',     cs.zeta,  cn.zeta; ...
    'Consumption smoothing, phi_C',                 cs.phiC,  cn.phiC; ...
    'Unemployment elasticity of mc, eta_u^mc',      cs.eta_u_mc, cn.eta_u_mc; ...
    'Labor disutility, mu_N',                       cs.muN,   cn.muN; ...
    'Home prod. disutility, mu_H (red.-form norm.)', cs.muH,   cn.muH; ...
    'Home production productivity, psi_H',          cs.psiH,  cn.psiH; ...
    'Search disutility, mu_D (red.-form norm.)',    cs.muD,   NaN; ...
    'Matching efficiency, psi_Q',                   cs.psiQ,  NaN};
for rr = 1:size(rows, 1)
    L{end+1} = sprintf('  %-46s %12.4f %12.4f', rows{rr,1}, rows{rr,2}, rows{rr,3}); %#ok<AGROW>
end
L{end+1} = '';
L{end+1} = 'kappa_P and epsilon across the slope-figure sweep (NK-SaM; invariant to nuD)';
L{end+1} = sprintf('  %-34s %12s %12s', '', 'kappa_P', 'epsilon');
L{end+1} = repmat('-', 1, 92);
for gg = 1:numel(gamQ_loop)
    for vv = 1:numel(subQ_loop)
        p = p0; p.gamQ = gamQ_loop(gg); p.subQ = subQ_loop(vv);
        c = model_composites(p);
        L{end+1} = sprintf('  %-34s %12.4f %12.4f', ...
            sprintf('gamQ=%.4f | %s', gamQ_loop(gg), subQ_labels{vv}), c.kapP, c.epsP); %#ok<AGROW>
    end
end
L{end+1} = sprintf('  %-34s %12.4f %12.4f', 'Benchmark NK', cn.kapP, cn.epsP);
L{end+1} = '';
write_lines(fname_txt, L);
end

function report_nuD_cutoffs(fname_txt, p0, gamQ_loop, gamQ_cut, subQ_loop, subQ_cd, res_sam, res_nk, nuD_loop)
% REPORT_NUD_CUTOFFS  Closed-form nu_D cutoffs at Gamma_Q~0 (print Appendix C)
% and the numerical benchmark crossings of the slope curves, for each gamQ.
%   Phillips curve (PC), output gap:        nuD = nuN
%   PC, unemployment gap:                   1+nuD = (1+nuN) * M/(M-1)
%   Real wage growth (RWG), unempl. gap:    1+nuD = nuN * M/(M-1)
%   RWG, output gap: [A(M(nuN-1)+1) - phiC(1+nuN+zeta)] / [A(M-1)+1+nuN+zeta]
% with M = epsilon(1-phi_Xi) (M/(M-1) = gross markup 1/mc), A = nuN+phiC,
% zeta = epsilon*phi_Xi - 1. gamQ cutoff (zeta = 0, theta = 1): (mp-1)/mp.
idx_cd = find(abs(subQ_loop - subQ_cd) < 1e-12, 1);
nuN    = p0.nuN;
panels = {'PC,  output gap',       'AS_t';  'PC,  unemployment gap', 'AS_ue'; ...
          'RWG, output gap',       'WG_t';  'RWG, unemployment gap', 'WG_ue'};

L = {};
L{end+1} = 'nu_D cutoffs: NK-SaM slope = benchmark slope (print Appendix C, sec:cutoff_nuD)';
L{end+1} = sprintf('Closed forms at Gamma_Q = %.4g (~Cobb-Douglas), nuN = %.4f; numerical crossings', p0.subQ, nuN);
L{end+1} = sprintf('from the slope curves on the nuD grid [%.4f, %.4f] (%d points), Gamma_Q~0 variant.', ...
    nuD_loop(1), nuD_loop(end), numel(nuD_loop));
L{end+1} = repmat('=', 1, 92);
L{end+1} = '';
L{end+1} = sprintf('gamQ cutoff (zeta = 0): closed form (mp-1)/mp = %.4f, numerical = %.4f', ...
    (p0.mp-1)/p0.mp, gamQ_cut);
for gg = 1:numel(gamQ_loop)
    p = p0; p.gamQ = gamQ_loop(gg); p.subQ = subQ_cd;
    [c, cn] = model_composites(p);
    M = c.M; A = nuN + c.phiC; z = c.zeta;
    cf = [nuN, ...
          (1+nuN)*M/(M-1) - 1, ...
          (A*(M*(nuN-1)+1) - c.phiC*(1+nuN+z)) / (A*(M-1)+1+nuN+z), ...
          nuN*M/(M-1) - 1];
    % order of cf matches panels: PC_Y, PC_u, RWG_Y, RWG_u
    L{end+1} = ''; %#ok<AGROW>
    L{end+1} = sprintf('gamQ = %.4f:  epsilon = %.4f, phi_gamma = %.4f, phi_Xi = %.4f, zeta = %.4f, phi_C = %.4f (benchmark %.4f), markup M/(M-1) = %.4f', ...
        gamQ_loop(gg), c.epsP, c.phiGam, c.phiXi, z, c.phiC, cn.phiC, M/(M-1)); %#ok<AGROW>
    L{end+1} = sprintf('  %-26s %14s %22s', '', 'closed form', 'numerical crossing'); %#ok<AGROW>
    L{end+1} = repmat('-', 1, 92); %#ok<AGROW>
    for pp = 1:size(panels, 1)
        y   = squeeze(res_sam.nuD.(panels{pp,2})(gg, idx_cd, :));
        ref = mean(res_nk.nuD.(panels{pp,2}), 'all');
        cr  = grid_crossings(nuD_loop, y, ref);
        if isempty(cr)
            if all(y(:) > ref); crs = 'none in range (above)'; else; crs = 'none in range (below)'; end
        else
            crs = strjoin(arrayfun(@(v) sprintf('%.4f', v), cr, 'UniformOutput', false), ', ');
        end
        L{end+1} = sprintf('  %-26s %14.4f %22s', panels{pp,1}, cf(pp), crs); %#ok<AGROW>
    end
    % Utilization feedback loop Theta_q^q (sec:sam_gap_channels, footnote): at Gamma_Q = 0,
    % Theta_q^q = 0 at 1+nuD = M(1+nuN)(1+zeta)/(zeta(M-1)); positive below, negative above (zeta > 0).
    % At the gamQ cutoff zeta is zero only up to rounding; the cutoff then diverges, so |zeta| < 1e-4
    % (zero at the four decimals printed) counts as zeta = 0.
    if abs(z) < 1e-4
        L{end+1} = '  feedback loop Theta_q^q > 0 for every nuD (zeta = 0)'; %#ok<AGROW>
    elseif z > 0
        nuD_fb = M*(1+nuN)*(1+z)/(z*(M-1)) - 1;
        L{end+1} = sprintf('  feedback loop Theta_q^q < 0 for nuD > %.4f (= %.2f nuN)', nuD_fb, nuD_fb/nuN); %#ok<AGROW>
    else
        L{end+1} = '  feedback loop Theta_q^q > 0 for every nuD (zeta < 0)'; %#ok<AGROW>
    end
end
L{end+1} = '';
L{end+1} = 'Closed forms hold at Gamma_Q = 0 only (tightness leg off); for Gamma_Q = -2.7 and';
L{end+1} = 'Gamma_Q -> -inf see the crossing column of results/txt/fig_slopes_5eq_ee_pc_rw.txt.';
L{end+1} = '';
write_lines(fname_txt, L);
end

function [cs, cn] = model_composites(p)
% MODEL_COMPOSITES  Steady-state composites and calibrated parameters of the
% NK-SaM model (cs) and the benchmark NK model (cn) for parameter struct p.
% The benchmark settings MUST mirror lib/compute_wedges.m.
[p.gamH, p.subH, p.gamP] = apply_model_selection(p.gamH, p.subH, p.gamP, p.hw_select, p.hp_select);
p_nk       = p;
p_nk.muD   = 1e-5;  p_nk.gamQ = 1e-5;  p_nk.subQ = 1e-5;  p_nk.gamP = 1e-5;
p_nk.psiQ  = 1;     p_nk.tight = 1;    p_nk.q    = 1;
cs = one_model(p);
cn = one_model(p_nk);
end

function c = one_model(p)
[st, pr] = model_stst(p);
out      = model_system(p);
c.epsP   = pr.epsP;           c.epsW   = pr.epsW;
c.phiGam = pr.phiGam;         c.phiXi  = pr.phiQ;
c.zeta   = pr.epsP*pr.phiQ - 1;
c.M      = pr.epsP*(1 - pr.phiQ);
c.phiC   = pr.phiC;           c.eta_u_mc = p.nuN*pr.phiU;
c.mp     = st.mp;             c.ps     = st.ps;     c.pe = st.pe;
c.kapP   = out.kapP;
if isfield(pr, 'muN')
    c.muN = pr.muN; c.muH = pr.muH; c.muD = pr.muD; c.psiH = pr.psiH; c.psiQ = pr.psiQ;
else
    c.muN = p.muN;  c.muH = p.muH;  c.muD = p.muD;  c.psiH = p.psiH;  c.psiQ = p.psiQ;
end
end

function cr = grid_crossings(x, y, ref)
% GRID_CROSSINGS  nu_D values where y(x) crosses ref (linear interpolation).
x = x(:)'; d = y(:)' - ref;
cr = x(d == 0);
for ii = find(d(1:end-1) .* d(2:end) < 0)
    cr(end+1) = x(ii) - d(ii) * (x(ii+1) - x(ii)) / (d(ii+1) - d(ii)); %#ok<AGROW>
end
cr = unique(round(sort(cr), 6));
end

function write_lines(fname_txt, L)
for ii = 1:numel(L); disp(L{ii}); end
ensure_dir(fname_txt);
fid = fopen(fname_txt, 'w');
if fid == -1
    error('main_s3_s4_slopes: could not open "%s" for writing.', fname_txt);
end
for ii = 1:numel(L); fprintf(fid, '%s\n', L{ii}); end
fclose(fid);
end
