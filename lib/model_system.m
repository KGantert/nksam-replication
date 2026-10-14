% *************************************************************************
% When Buying Takes Time:
% Implications for the New-Keynesian Business Cycle Model
% Reduced-Form Model: DYNAMIC EQUATIONS SLOPES
% -------------------------------------------------------------------------
% Konstantin Gantert
% kgantert@mail.de
% 05/06/2026
% *************************************************************************

function out = model_system(p)
% MODEL_SYSTEM  Compute log-linearised equation slopes given parameter struct p.

% STEADY-STATE
[stst, par] = model_stst(p);

% Unpack composite parameters from steady-state
epsW = par.epsW;  epsP = par.epsP;
phiG = par.phiG;  phiQ = par.phiQ;  phiP = par.phiP;
pHH  = par.pHH;   pHM  = par.pHM;   pHS = par.pHS;

% Unpack scalars needed below
nuN  = p.nuN;  nuD  = p.nuD;  nuH = p.nuH;
alpF = p.alpF; alpH = p.alpH; gamP = p.gamP; gamQ = p.gamQ;
sig  = p.sig;  ghh  = p.ghh;
psiQ = p.psiQ; subQ = p.subQ; subH = p.subH;
okun = p.okun; pc_slope = p.pc_slope;

% Phillips-curve calibration mode (see build_p / get_params). Defaults keep
% hand-built parameter structs from older scripts working unchanged.
if isfield(p, 'kapP_select'), kapP_select = p.kapP_select; else, kapP_select = 0; end
if isfield(p, 'kapP_dir'),    kapP_dir    = p.kapP_dir;    else, kapP_dir    = NaN; end

% Home production and labour supply composite parameters (from model_stst)
chiCM = par.chiCM;
phiCM = par.phiCM;
phiCH = par.phiCH;
phiC  = par.phiC;
phiU  = par.phiU;
phiUC = par.phiUC;

% -------------------------------------------------------------------------
% PRECOMPUTED COMMON SUBEXPRESSIONS
% -------------------------------------------------------------------------
psiQ_phiG   = psiQ .* phiG;                        % appears ~10x
inv_psiG    = 1 ./ psiQ_phiG;                      % 1/(psiQ*phiG)
phiGp1_psiG = (1+phiG) ./ psiQ_phiG;               % (1+phiG)/(psiQ*phiG)

% Quality-search share of total search effort, chi_{D_P} = D_P/D
% (Appendix A, eq. ap_bar_composites): chiDP -> 0 as gamP -> 0.
chiDP       = gamP ./ (gamP + (1-gamP).*phiQ);

% -------------------------------------------------------------------------
% LEVEL 1: Utility function composite parameters
% -------------------------------------------------------------------------
pUt   = phiCM ...
        - ghh.*pHH./(1-alpH).*phiCM./phiCH ...
        - ghh.*pHM./(1-alpF) ...
        + ghh.*pHS./nuD.*phiC;
if gamQ > 0.01
    pUq   = gamP./(psiQ.*phiG).*phiCM ...
        - ghh.*pHH./(1-alpH).*gamP./(psiQ.*phiG).*phiCM./phiCH ...
        + ghh.*pHM./(1-alpF)./psiQ ...
        + ghh.*pHS./nuD./(psiQ.*phiG).*(1-gamP.*(1-phiC));
else
    pUq   = 0;
end

pUps  = gamP.*(1-phiQ).*phiCM ...
            - ghh.*gamP.*(1-phiQ).*pHH./(1-alpH).*phiCM./phiCH ...
            + ghh.* pHS./nuD.*(1-phiQ).*(1-gamP.*(1-phiC));
pUsi  = gamP.*(1+phiG)./(psiQ.*phiG).*phiCM ...
            - ghh.*pHH./(1-alpH).*phiCM./phiCH.*(1+phiG)./(psiQ.*phiG) ...
            + ghh.*pHS./nuD.*(1+phiG)./(psiQ.*phiG).*(1-gamP.*(1-phiC));
pUmu  = ghh.*(pHS./(1+nuD) - pHS./nuD);
pUa   = ghh.*pHM;

% -------------------------------------------------------------------------
% LEVEL 1: Euler Equation (M)
% -------------------------------------------------------------------------
pMt   = (1-subH).*(1-phiCM) - phiUC.*pUt;
pMq   = phiUC.*pUq + gamP./(psiQ.*phiG).*(1-(1-subH).*(1-phiCM));
pMps  = phiQ + phiUC.*pUps + gamP.*(1-phiQ).*(1-(1-subH).*(1-phiCM));
pMsi  = gamP.*(1+phiG)./(psiQ.*phiG).*(1-(1-subH).*(1-phiCM)) - phiUC.*pUsi;
pMmu  = (-phiUC).*pUmu;
pMa   = (-phiUC).*pUa;

% -------------------------------------------------------------------------
% LEVEL 1: Quantity-Price Search (PS)
% -------------------------------------------------------------------------
pPSps = 1 - phiQ;
pPSmc = epsP .* (1-phiQ) .* (1-phiP);
pPSq  = subQ .* phiGp1_psiG;
pPSep = (-1) .* (1-gamP) ./ (1-phiP);

% Precompute PS ratios (used heavily in Level 2)
rPSmc = pPSmc ./ pPSps;
rPSq  = pPSq  ./ pPSps;
rPSep = pPSep ./ pPSps;

% -------------------------------------------------------------------------
% LEVEL 1: Marginal Costs (MC)
% -------------------------------------------------------------------------
pMCt  = (alpF+nuN)./(1-alpF) + phiC;
pMCq  = ((1+nuN)./(1-alpF) + gamP./phiG.*(1-phiC)) ./ psiQ;
pMCps = phiQ + gamP.*(1-phiQ).*(1-phiC);
pMCa  = (1+nuN);
pMCsi = gamP.*phiGp1_psiG.*(1-phiC);

% -------------------------------------------------------------------------
% LEVEL 1: Phillips Curve (PI)
% -------------------------------------------------------------------------
pPIpi = pPSmc ./ (pPSmc - 1);
pPImc = pPSmc - 1;
pPIep = (1-gamP) ./ (1-phiP);

% -------------------------------------------------------------------------
% LEVEL 1: Capacity Utilization (Q)
% -------------------------------------------------------------------------
pQt   = nuD + phiC;
pQps  = (1-phiQ) .* (1 + gamP.*(nuD./(gamP+phiQ.*(1-gamP))-1+phiC));
pQq   = (1+nuD-gamP.*(1-phiC)) .* inv_psiG;
pQsi  = (1+nuD-gamP.*(1-phiC)) .* phiGp1_psiG;

% -------------------------------------------------------------------------
% LEVEL 1: Labor Wedge (LW)
% -------------------------------------------------------------------------
LWfac = phiQ + gamP.*(1-phiC).*(1-phiQ);   % common factor in pLW*
pLWt  = phiC;
pLWu  = nuN.*phiU;
pLWmc = LWfac.*rPSmc - 1;
pLWq  = LWfac.*rPSq  - gamP.*(1-phiC).*inv_psiG;
pLWsi = LWfac.*rPSq  - gamP.*(1-phiC).*phiGp1_psiG;
pLWep = LWfac.*rPSep;

% -------------------------------------------------------------------------
% LEVEL 2: Substitute MC -> reduced-form MC coefficients
% -------------------------------------------------------------------------
sMCmc = 1 - pMCps.*rPSmc;
sMCq  = pMCq  - pMCps.*rPSq;
sMCep = pMCps.*rPSep;
sMCsi = pMCsi - pMCps.*rPSq;

% Precompute MC ratios
rMCt  = pMCt ./ sMCmc;
rMCq  = sMCq ./ sMCmc;
rMCa  = pMCa ./ sMCmc;
rMCep = sMCep ./ sMCmc;
rMCsi = sMCsi ./ sMCmc;

% -------------------------------------------------------------------------
% LEVEL 2: Real Wage Inflation (W)
% -------------------------------------------------------------------------
sWt  = rMCt  - alpF./(1-alpF);
sWu  = nuN.*phiU ./ sMCmc;
sWq  = rMCq  - 1./(1-alpF)./psiQ;
sWa  = 1 - rMCa;
sWep = rMCep;
sWsi = rMCsi;

% -------------------------------------------------------------------------
% LEVEL 2: Phillips Curve (PI)
% -------------------------------------------------------------------------
sPImc = pPImc + phiQ.*rPSmc;
sPIt  = sPImc.*rMCt;
sPIu  = nuN.*phiU.*sPImc./sMCmc;
sPIq  = sPImc.*rMCq  - phiQ.*rPSq;
sPIa  = sPImc.*rMCa;
sPIep = phiQ.*rPSep - pPIep + sPImc.*rMCep;
sPIsi = sPImc.*rMCsi - phiQ.*rPSq;

% -------------------------------------------------------------------------
% LEVEL 2: Euler Equation (M)
% -------------------------------------------------------------------------
sMt  = pMt  + pMps.*rPSmc.*rMCt;
sMq  = pMps.*rPSq - pMq - pMps.*rPSmc.*rMCq;
sMu  = nuN.*phiU.*pMps.*rPSmc./sMCmc;
sMa  = pMa  - pMps.*rPSmc.*rMCa;
sMep = pMps.*rPSep + pMps.*rPSmc.*rMCep;
sMsi = pMsi - pMps.*rPSq  + pMps.*rPSmc.*rMCsi;
sMmu = pMmu;

% -------------------------------------------------------------------------
% LEVEL 2: Capacity Utilization (Q)
% -------------------------------------------------------------------------
rQpq  = pQps ./ pQq;   % common factor
sQt   = rQpq.*rPSmc.*rMCt  - pQt./pQq;
sQu   = nuN.*phiU.*rQpq.*rPSmc./sMCmc;
sQq   = 1 - rQpq.*rPSq + rQpq.*rPSmc.*rMCq;
sQa   = rQpq.*rPSmc.*rMCa;
sQep  = rQpq.*rPSmc.*rMCep + rQpq.*rPSep;
sQsi  = rQpq.*rPSmc.*rMCsi + (pQsi - pQps.*rPSq)./pQq;
sQmu  = 1./pQq;

% -------------------------------------------------------------------------
% LEVEL 2: Price Elasticity of Demand (XI)
% -------------------------------------------------------------------------
sXIt  = phiQ.*rPSmc.*rMCt;
sXIu  = nuN.*phiU.*phiQ.*rPSmc./sMCmc;
sXIq  = phiQ.*(rPSq - rPSmc.*rMCq);
sXIa  = phiQ.*rPSmc.*rMCa;
sXIep = pPIep - phiQ.*rPSep - phiQ.*rPSmc.*rMCep;
sXIsi = phiQ.*(rPSq - rPSmc.*rMCsi);

% -------------------------------------------------------------------------
% LEVEL 2: Labor Wedge (LW)
% -------------------------------------------------------------------------
sLWt  = pLWt + pLWmc.*rMCt;
sLWu  = pLWu .* (1 + pLWmc./sMCmc);
sLWq  = pLWq - pLWmc.*rMCq;
sLWa  = pLWmc.*rMCa;
sLWsi = pLWsi - pLWmc.*rMCsi;
sLWep = pLWep + pLWmc.*rMCep;

% =========================================================================
% OUTPUT: Steady-states
% =========================================================================
out.stst_ps   = stst.ps;
out.stst_mp   = stst.mp;
out.stst_t    = stst.t;
out.stst_muc  = stst.muc;
out.stst_hq   = stst.hq;
out.stst_hp   = stst.hp;
out.stst_pe   = stst.pe;
out.stst_epsP = epsP;

% =========================================================================
% OUTPUT: Equation slopes (substituting out capacity utilization q_hat)
% =========================================================================
% Helper: substitute q_hat  ->  X_t - X_q*(sQt/sQq),  X_ue + X_q*(sQu/sQq)
% Naming: _t = output gap slope, _ue = unemployment gap slope

% Capacity Utilization
out.CU_t   =        sQt./sQq;
out.CU_ue  =        sQu./sQq;
out.CU_a   = (-1).*sQa./sQq;
out.CU_ep  =        sQep./sQq;
out.CU_si  =        sQsi./sQq;
out.CU_mu  = (-1).*sQmu./sQq;

% Real Wage Growth
out.WG_t   = sWt  - sWq.*sQt./sQq;
out.WG_ue  = sWu  - sWq.*sQu./sQq;
out.WG_a   = sWa  + sWq.*sQa./sQq;
out.WG_ep  = sWep - sWq.*sQep./sQq;
out.WG_si  = sWsi - sWq.*sQsi./sQq;
out.WG_mu  =        sWq.*sQmu./sQq;

% Price Elasticity of Demand
out.PE_t   = (-1).*(sXIt + sXIq.*sQt./sQq);
out.PE_ue  = (-1).*(sXIu + sXIq.*sQu./sQq);
out.PE_a   =        sXIa + sXIq.*sQa./sQq;
out.PE_ep  =        sXIep - sXIq.*sQep./sQq;
out.PE_si  =        sXIsi - sXIq.*sQsi./sQq;
out.PE_mu  =        sXIq.*sQmu./sQq;

% Total Search Effort (D_t = (1-chiDP)*D_Q,t + chiDP*D_P,t; Appendix A,
% eq. ap_qualsearch_gap_theta combined with ap_lin_totalsearch)
out.D_t    = 1 + inv_psiG.*out.CU_t  - chiDP.*(1-phiQ)./phiQ .* out.PE_t;
out.D_ue   =     inv_psiG.*out.CU_ue - chiDP.*(1-phiQ)./phiQ .* out.PE_ue;

% Marginal Costs
out.MC_t   = rMCt  - rMCq.*sQt./sQq;
out.MC_ue  = nuN.*phiU./sMCmc - rMCq.*sQu./sQq;
out.MC_a   = (-1).*(rMCa  - rMCq.*sQa./sQq);
out.MC_eps = rMCep - rMCq.*sQep./sQq;
out.MC_psiQ = rMCsi - rMCq.*sQsi./sQq;
out.MC_muu = rMCq.*sQmu./sQq;

% -------------------------------------------------------------------------
% MODEL-IMPLIED OKUN'S LAW (calibration sanity check)
% -------------------------------------------------------------------------
% Along the natural allocation the marginal-cost gap closes, mc_hat = 0, so
% the benchmark model (alpF = 0, no goods-market SaM) implies
%       Y_tilde = -eta_u^mc / (nuN + phiC) * u_tilde,
% with eta_u^mc = out.MC_ue the unemployment-gap slope of marginal costs.
% Compare out.okun_impl against the empirical coefficient p.okun (data) as
% a check on the calibration. The statistic is computed for every
% specification, but the denominator nuN + phiC is the marginal-cost output-
% gap slope only in the benchmark: away from alpF = 0 the exact slope is
% (alpF+nuN)/(1-alpF) + phiC, and under goods-market SaM capacity
% utilisation adds further terms.
out.okun_impl = (-1) .* out.MC_ue ./ (nuN + phiC);

% Labor Wedge
out.LW_t   =        sLWt + sLWq.*sQt./sQq;
out.LW_ue  =        sLWu + sLWq.*sQu./sQq;
out.LW_a   = (-1).*(sLWa + sLWq.*sQa./sQq);
out.LW_psiQ = (-1).*(sLWsi - sLWq.*sQsi./sQq);
out.LW_eps =        sLWep + sLWq.*sQep./sQq;
out.LW_muu = (-1).*(sLWq.*sQmu./sQq);

% Euler Equation
out.AD_t   =        sMt  + sMq.*sQt./sQq;
out.AD_ue  =        sMu  + sMq.*sQu./sQq;
out.AD_a   =        sMa  - sMq.*sQa./sQq;
out.AD_eps =        sMep + sMq.*sQep./sQq;
out.AD_psiQ =        sMsi + sMq.*sQsi./sQq;
out.AD_muu = (-1).*(sMmu + sMq.*sQmu./sQq);

% Phillips Curve
% Two calibration modes (p.kapP_select), exact inverses of one another:
%   0 : match the empirical labour-share slope pc_slope, kappa_P endogenous
%         kapP = pPIpi * sPImc / pc_slope
%   1 : impose kappa_P directly, labour-share slope endogenous
%         pc_slope_impl = pPIpi * sPImc / kapP
% pc_slope_impl is always reported; it equals pc_slope by construction
% under mode 0 and is the free diagnostic under mode 1.
if kapP_select == 0
    out.kapP = pPIpi .* sPImc ./ pc_slope;
else
    if ~isfinite(kapP_dir)
        error('model_system:kapPmissing', ...
              'kapP_select == 1 requires a finite p.kapP_dir (set par.kapP).');
    end
    out.kapP = kapP_dir;
end
out.pc_slope_impl = pPIpi .* sPImc ./ out.kapP;
kP         = 1./out.kapP .* pPIpi;
out.AS_t   =        kP.*(sPIt  - sPIq.*sQt./sQq);
out.AS_ue  =        kP.*(sPIu  - sPIq.*sQu./sQq);
out.AS_a   = (-1).*kP.*(sPIa  - sPIq.*sQa./sQq);
out.AS_eps =        kP.*(sPIep - sPIq.*sQep./sQq);
out.AS_psiQ =        kP.*(sPIsi - sPIq.*sQsi./sQq);
out.AS_muu =        kP.*(sPIq.*sQmu./sQq);

% =========================================================================
% Okun's Law aggregation  (_ag = _t + _ue/okun)
% =========================================================================
eqs = {'CU','PE','LW','AS','AD','WG','MC','D'};
for k = 1:numel(eqs)
    out.([eqs{k} '_ag']) = out.([eqs{k} '_t']) + out.([eqs{k} '_ue'])./okun;
end

end
