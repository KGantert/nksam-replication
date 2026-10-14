function varargout = get_params(context)
% GET_PARAMS  Calibration of the paper (Section 2, Appendix A, Online Appendix II):
%   single source of every parameter value for both models, the full
%   nonlinear model in Dynare (model/, lib/setup_dynare.m) and the
%   linearized reduced-form model (lib/setup_slopes.m).
%
%   USAGE
%     [par, parHW, parSAM, shock, target, ranges] = get_params('dynare');
%     par                                          = get_params('slopes');
%
%   STRUCTURE
%     1. core   -- values shared by both models, defined ONCE (so the two
%                  models cannot drift apart): preferences, labor and goods
%                  market SaM, home production, time-use targets, markup,
%                  Phillips-curve slope target, the Gamma_Q values
%                  (subQ_low/mid/high = -infinity / -2.7 / ~0 (Cobb-Douglas))
%                  and the nu_D/nu_N sweep band (0.5-1.5)
%     2. get_params_dynare -- Dynare only: shock processes, monetary policy,
%                  extension parameters and the ranges used by the
%                  robustness checks (Online Appendix VI)
%     3. get_params_slopes -- reduced-form model only: grids and bounds of
%                  the sweeps behind the slope, cutoff and steady-state figures
%   Note: gamP differs on purpose (Dynare parHW.gamP = 1e-5 is the
%   quality-search-off default; slopes par.gamP = 0.1 is the magnitude used
%   when price search is switched on).
%   Every change here is picked up automatically: lib/check_cache_signature.m
%   deletes all caches when any value returned by this function changes.

if nargin < 1
    error('get_params:context', ...
        'Call get_params(''dynare'') or get_params(''slopes'') explicitly.');
end

% =========================================================================
% 1. CORE -- SHARED VALUES (identical in both original get_params.m files)
% =========================================================================
core.sig        = 1.5;      % Inverse EIS / CRRA coefficient
core.nuN        = 2.0;      % Inverse Frisch elasticity of market labor supply
core.eps_sub    = 6.0;      % Elasticity of substitution across goods (dynare: epss; slopes: epsP)
core.gamH       = 0.55;     % Home production weight in CES aggregator
core.subH       = 0.5;      % CES substitution parameter, cm vs ch
core.nuH        = core.nuN; % Inverse Frisch elasticity of home production labor (= nuN)
core.gamQ       = 0.32;     % Matching elasticity (Bai et al., 2025)
core.subQ       = -1e-4;    % Matching CES substitution parameter (~Cobb-Douglas)
core.nuD        = core.nuN; % Inverse Frisch elasticity of search effort (= nuN)
core.markup     = 1.20;     % Steady-state gross price markup (dynare: target.markup; slopes: par.mp)
core.cu_ss      = 0.86;     % Steady-state capacity utilization (dynare: target.cuss; slopes: par.cu)
core.ue_ss      = 0.043;    % Steady-state unemployment rate (dynare: target.uss; slopes: par.ue)
core.tight_ss   = 1.00;     % Steady-state goods market tightness (dynare: target.xss; slopes: par.tight)
core.n_ss       = 1.00;     % Normalised steady-state employment (market work) (dynare: target.nss; slopes: par.n)
core.dn_share   = 0.21;     % Search time relative to market work (dynare: target.dnss; slopes: par.dN); ATUS 2003-2019 = 0.2105
core.total_nonmarket_time = 0.707;   % Total non-market time share (search + home production); ATUS 2003-2019, BLS Table A-1: (household activities + purchasing goods and services)/(working and work-related activities). Was 0.7247 (2003-2025, miscalculated) until 2026-09-28; linearized dynamics are invariant to it (only psi_H, mu_H rescale).
core.hn_share   = core.total_nonmarket_time - core.dn_share;  % Home hours rel. to market work (dynare: target.hnss; slopes: par.hN) 
core.chgdp_ss   = 0.30;     % Home production output relative to market GDP (dynare: target.chgdpss; slopes: par.chGDP)
core.nkpc_slope = 0.051;    % Labour-share NK Phillips curve slope target: Gali-Gertler (1999), Table 4, GDP deflator,
                            % 1980Q1-1997Q4: lambda = 0.051 (se 0.006). Full sample 1960-97 (Table 1): 0.047 (until 2026-10-06)
core.nkpc_se    = 0.006;    % its standard error (95% CI in ranges.nkpc_ci, robustness check 6 and the literature combinations)
core.gamQ_low   = 0.11;     % Robustness-sweep lower bound for gamQ
core.gamQ_high  = 0.32;     % Robustness-sweep upper bound for gamQ (= baseline gamQ)
core.subQ_low    = -1e4;    % Matching CES substitution parameter: ~-infinity (strong complements) 
core.subQ_mid    = -2.7;    % Matching CES substitution parameter: CES, literature value (Qiu, 2022) 
core.subQ_high   = -1e-5;   % Matching CES substitution parameter: ~0 (Cobb-Douglas) 
core.nuDnuN_low  = 0.5;     % Robustness-sweep lower bound for nu_D/nu_N ratio 
core.nuDnuN_high = 1.5;     % Robustness-sweep upper bound for nu_D/nu_N ratio 
core.alpF       = 1e-5;     % "No capital" placeholder (dynare: par.alpF; slopes: par.alpF) 

switch context
    case 'dynare'
        [varargout{1:nargout}] = get_params_dynare(core);
    case 'slopes'
        varargout{1} = get_params_slopes(core);
    otherwise
        error('get_params:context', ...
            'Unknown context "%s" -- use ''dynare'' or ''slopes''.', context);
end

end


% =========================================================================
% 2. DYNARE-ONLY CALIBRATION
% =========================================================================
function [par, parHW, parSAM, shock, target, ranges] = get_params_dynare(core)

par.betta  = 0.99;
par.sig    = core.sig;
par.iR     = 0.80;
par.iPi    = 1.50;
par.iGap   = 0.12;
par.epss   = core.eps_sub;
par.kapP   = 0.0;
par.epsW   = 11.0;
par.kapW   = 0.0;
par.nuN    = core.nuN;
par.phiN   = 0.0;
par.psiA   = 1.0;
par.alpF   = core.alpF;
par.delF1  = 0.999;
par.delF2  = 99;
par.kapF   = 99;

parHW.gamH  = core.gamH;
parHW.subH  = core.subH;
parHW.nuH   = core.nuH;
parHW.gamP  = 1e-5;
parHW.alpH  = 1e-5;
parHW.delH1 = 0.999;
parHW.delH2 = 9;
parHW.kapH  = 9;

parSAM.gamQ  = core.gamQ;
parSAM.subQ  = core.subQ;
parSAM.nuD   = core.nuD;
parSAM.delT  = 1.0;
parSAM.delI  = 1.0;

shock.rhoA  = 0.90;  shock.rhoZ  = 0.80;  shock.rhoM  = 0.50;
shock.rhoP  = 0.50;  shock.rhoT  = 0.50;  shock.rhoD  = 0.50;
shock.stdA  = 0.0064; shock.stdZ = 0.0100; shock.stdM = 0.0010;
shock.stdP  = 0.1000; shock.stdT = 0.0080; shock.stdD = 0.0800;

target.markup       = core.markup;
target.cuss         = core.cu_ss;
target.uss           = core.ue_ss;
target.xss          = core.tight_ss;
target.nss          = core.n_ss;
target.dnss         = core.dn_share;
target.hnss         = core.hn_share;
target.chgdpss      = core.chgdp_ss;
target.ls_share     = 0.64;
target.nkpc_slope   = core.nkpc_slope;
target.nkwpc_slope  = -0.145;   % slope of quarterly wage inflation on the unemployment rate per percentage point;
                                  % Gali-Gambetti (2019), Table 1A, 1986Q1-2007Q2: -0.58 (se 0.07, annualized) / 4

ranges.gamQ_low  = core.gamQ_low;
ranges.gamQ_high = core.gamQ_high;
ranges.nuDnuN_low  = core.nuDnuN_low;
ranges.nuDnuN_high = core.nuDnuN_high;
ranges.subQ_low  = core.subQ_low;
ranges.subQ_mid  = core.subQ_mid;
ranges.subQ_high = core.subQ_high;
% 95% confidence intervals of the Phillips-curve slope targets (point estimate +/- 1.96 se;
% robustness checks 6, 7, 10, the literature combinations and scripts/online_VI_rigidity_grid.m). Order: [low, high] slope.
ranges.nkpc_ci   = core.nkpc_slope + 1.96*[-1, 1]*core.nkpc_se;             % [0.0392, 0.0628] -> kappa_P high/low
ranges.nkwpc_se  = 0.07/4;                                                   % Gali-Gambetti se, quarterly
ranges.nkwpc_ci  = target.nkwpc_slope + 1.96*[1, -1]*ranges.nkwpc_se;       % [-0.1107, -0.1793]: flatter / steeper
% Adverse literature combinations (unnumbered, after check 7), rows = [nkpc_slope, nkwpc_slope]:
%   (a) Kuttner-Robinson (2010) 1984-2007 price slope with the steepest wage slope of the 95% CI
%       (technology closest to omega*_Xi);  (b) steepest price slope of the 95% CI with
%       Gali-Gambetti (2019) 1964Q1-2007Q2, -0.29/4 (monetary policy closest to omega*_q)
ranges.kap_corner = [0.014, ranges.nkwpc_ci(2); ranges.nkpc_ci(2), -0.29/4];
ranges.delT_loop = 0.25;   % Online VI, check 4 (tab:calibration_sources_extended)
ranges.delI_loop = 0.74;
ranges.phiN_act  = 2.89;  % Employment adjustment costs kappa_N (nk_time.dyn: cn = phiN/2*(n/n(-1)-1)^2); Online VI, check 10 ( dibEstimated2003, lechthalerQuadraticLaborAdjustment2013)
ranges.gamP_loop = 0.10;   % quality-search value (Online II tab:calibration_sources_extended; Online VI check 2)
ranges.gamP_high = 0.16;   % second quality-search value, Online VI check 2 (0.20 has no steady state; diagnostics/diag_quality_search.m)

end


% =========================================================================
% 3. SLOPES-ONLY CALIBRATION
% =========================================================================
function par = get_params_slopes(core)

loop_grid_size = 101;

par.n         = core.n_ss;
par.dN        = core.dn_share;
par.hN        = core.hn_share;
par.slopeLS   = core.nkpc_slope;
par.cu        = core.cu_ss;
par.tight     = core.tight_ss;
par.ue        = core.ue_ss;
par.chGDP     = core.chgdp_ss;
par.mp        = core.markup;

par.nuN   = core.nuN;
par.sig   = core.sig;
par.alpF  = core.alpF;
par.epsP  = core.eps_sub;
par.gamP  = 0.1;

par.kapP  = 180;

par.nuH   = par.nuN;
par.gamH  = core.gamH;
par.subH  = core.subH;
par.alpH  = 0;

par.nuD   = par.nuN;
par.gamQ  = core.gamQ;
par.subQ  = core.subQ;

par.muN   = NaN;  par.muH   = NaN;  par.psiH  = NaN;
par.muD   = NaN;  par.psiQ  = NaN;

par.gamQ_low    = core.gamQ_low;
par.gamQ_high   = core.gamQ_high;
par.subQ_low    = core.subQ_low;
par.subQ_mid    = core.subQ_mid;
par.psiQ_low    = 0.72;
par.psiQ_high   = 1;
par.mp_low      = 1.0001;
par.mp_high     = 1.4;
par.epsP_low    = 3.5;
par.epsP_high   = 31;
par.nuD_sens_low  = core.nuDnuN_low  * par.nuN;
par.nuD_sens_high = core.nuDnuN_high * par.nuN;

par.gamQ_loop_stst  = linspace(0.0001, par.gamQ_high, loop_grid_size);
par.mp_loop_stst    = [par.mp_low, par.mp, par.mp_high];
par.epsP_loop_stst  = [par.epsP_low, par.epsP, par.epsP_high];
par.psiQ_loop_stst  = [par.psiQ_low, par.cu, par.psiQ_high];

par.nuD_sens_loop = linspace(par.nuD_sens_low, par.nuD_sens_high, 51);

par.subQ_loop   = [par.subQ_mid, par.subQ];   % Gamma_Q = -2.7 (CES) and ~0 (Cobb-Douglas); -infinity: res_gray in lib/setup_slopes.m

par.mp_cut_loop   = linspace(par.mp_low, par.mp_high, loop_grid_size);
par.epsP_cut_loop = linspace(par.epsP_low, par.epsP_high, loop_grid_size);

end
