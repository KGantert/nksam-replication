function [ys,params,check] = nk_time_steadystate(ys,exo,M_,options_)

% read out parameters to access them with their name
NumberOfParameters = M_.param_nbr;
for ii = 1:NumberOfParameters
  paramname = M_.param_names{ii};
  eval([ paramname ' = M_.params(' int2str(ii) ');']);
end
% initialize indicator
check = 0;

%% Model equations block - Default and Natural Model
% Steady-State Targets
% -------------------------------------------------------------------------

% Shock processes
shA     = 1; shZ = 1; shM = 1; shP = 1; shT = 1; shD = 1;
% Capital utilization rate
eh      = 1; eh_N = eh; ef = 1; ef_N = ef;
% Price inflation and adjustment costs
piC     = 0; cp = 0; cpp = 0;
% Wage inflation adjustment costs
piW     = 0; cw = 0; cww = 0;
% Hours adjustment costs
cn      = 0; cn_N  = cn; cnn = 0; cnn_N = cnn;
% Capital adjustment costs
chi     = 0; chi_N  = chi; chhi = 0; chhi_N = chhi;
cfi     = 0; cfi_N  = cfi; cffi = 0; cffi_N = cffi;
% Capacity utilization
cu      = cuss;
cu_N    = cu;
% Goods market tightness
x       = xss;
x_N     = x;
% Market total hours worked
n       = nss;
n_N     = n;
% Goods market search hours
d       = dnss*n;
d_N     = d;
% Homeproduction hours worked
h       = hnss*n;
h_N     = h;
% Real interest rate
r       = 1/betta - 1;
r_N     = r;
% Goods selling probability
q       = cu*delT*delI / (1-cu*(delT*(1-delI)+(1-delT)));
q_N     = q;
% Goods finding probability
f       = q/x;
f_N     = f;
% Set market capital utilization costs to target ef = 1 in steady-state
delF3   = (1-betta*(1-delF1))/betta;
% Set homeproduction capital utilization costs to target eh = 1 in steady-state
delH3   = (1-betta*(1-delH1))/betta;
% Labor frictions
if labor_ext == 1
    epsW = ((1+uss)^nuN) / ((1+uss)^nuN - 1);
    kapW = (-1)*(epsW-1)*nuN/(1+uss)/nkwpc_slope;   % = -(epsW-1)*eta_u^mc/slope, slope per pp of u (eq. lin_wage_phillips)
end
% Capacity-to-output ratio
yft     = ((1-delT)*q+delT*(1-(1-delI)*(1-q))) / q;
% Numerator for psiD (SEPARATELY CALCULATED FOR NUMERICAL STABILITY, see
% more comment down below for psiD)
NUM_psiD = x * yft / (1+(1-delT)/delT*q-(1-delI)*(1-q));
% Solving for market equilibrium
% -------------------------------------------------------------------------
% Setting fsolve options
options = optimoptions('fsolve','Display','off');
% Creating function handle to solve model numerically
fun_solv = @(xx) solve_time(xx, ls_target, markup_stst, q, cu, x, d, ls_share, markup, ...
                            chgdpss, hnss, nss, NUM_psiD, alpH, alpF, delT, delI, delF1, delH1, gamH, ...
                            subH, gamP, nuD, betta, epss, gamQ, subQ, psiA, dAP);
% Solving equilibrium
xx      = fsolve(fun_solv,[1 0.5 (1.01-delF1)*5 (1.01-delF1)*5 1], options);
% -------------------------------------------------------------------------
% Marginal utility
mucW    = real(xx(1));
% Search prices
pq      = real(xx(2));
pq_N    = pq;
% Market capital stock
kf      = real(xx(3));
kf_N    = kf;
% Home production capital stock
kh      = real(xx(4));
kh_N    = kh;
% Traded goods (GDP)
t       = real(xx(5));
t_N     = t;
% Home production capital investment
ivh     = delH1*kh;
ivh_N   = ivh;
% Market capital investment
ivf     = delF1*kf;
ivf_N   = ivf;
% Search technology: iterative fixed-point for psiD.
% The analytical formula psiD = NUM/(d/t - A^(1/gamP)) is catastrophically
% ill-conditioned as gamP->0: A->1 from below while 1/gamP->inf, so A^(1/gamP)
% collapses to 0 through exp(log(A)/gamP) with extreme sensitivity to A.
% Instead we iterate: psiD_{k+1} = NUM/(d/t - dpS_k) with
% dpS_k = (gamP*x/(q*pq*mucW*psiD_k))^(1/(1-gamP)).
% dpS = dp/t -> 0 as gamP->0, so this converges in 1-2 steps for small gamP.
psiD     = NUM_psiD * t / d;    % gamP=0 limit as starting guess
dpS      = 0;                   % dp/t -> 0 as gamP->0
for kk = 1:100
    dpS_new  = (gamP * x / (q * pq * mucW * psiD))^(1/(1-gamP));
    psiD_new = NUM_psiD / (d/t - dpS_new);
    if abs(psiD_new - psiD) < 1e-12 * abs(psiD)
        dpS = dpS_new;
        psiD = psiD_new;
        break;
    end
    dpS = dpS_new; psiD = psiD_new;
end
% Price search ratio: derive from dpD = 1/(1+delT*x*t/(q*psiD*dp)).
% The original (mucW*pq/gamP)^(1/(1-gamP)) -> inf as gamP->0; the clean
% equivalent avoids this by using dp directly.
dpD = q*psiD*(dpS*t) / (q*psiD*(dpS*t) + delT*x*t);

% Real marginal costs
if  markup_stst == 1
    % Marginal capacity costs 
    mcY     = cu/markup;
    mcY_N   = mcY;
    % Elasticity of substitution
    aEPS    = 1 - (1-betta*(1-delT))/q * ( mcY*(1-betta*(1-delI)*(1-q)+(q*betta*(1-delT))/(1-betta*(1-delT))) + dAP*nuD*q/delT*pq );
    epss    = ((1+pq*(1-betta*(1-delT)))/(1-gamP)-gamP/(1-gamP)*aEPS-dAP*nuD*dpD*pq) / (aEPS-dAP*nuD*dpD*pq);
else
    % Marginal capacity costs 
    mcY     = (1-betta*(1-delI)*(1-q)+q*betta*(1-delT)/(1-betta*(1-delT)))^(-1) ...
                * ( q/(1-betta*(1-delT))*(1-1/epss*(1-gamP)/(1-gamP*(epss-1)/epss)*((1+pq*(1-betta*(1-delT)))/(1-gamP)+dAP*nuD*(epss-1)*dpD*pq)) - dAP*nuD*q/delT*pq );
    mcY_N   = mcY;
end
% Prodution elasticity calculated by labor share
if ls_target == 1
        alpF = 1 - ls_share*cu/mcY;
end
% Market production capacity
yf      = (psiA*n)^(1-alpF)*kf^alpF;
yf_N    = yf;
% Real market goods traded
% Price search time: dpS = dp/t already converged in psiD loop above
dp     = dpS * t;
dp_N   = dp;
% Quantity search
dq     = d - dp;
dq_N   = dq;
% Market consumption goods: (gamP*x/(q*pq*mucW*psiD))^(gamP/(1-gamP)) = (dp/t)^gamP,
% expressed this way the exponent gamP/(1-gamP)->0 as gamP->0, so the whole
% expression -> 1*t cleanly, avoiding the 0^0 form in t^(1-gamP)*dp^gamP.
cm      = (gamP*x/(q*pq*mucW*psiD))^(gamP/(1-gamP))*t - ivf - ivh;
cm_N    = cm;
% Homeproduction consumption
ch      = chgdpss .* t;
ch_N    = ch;
% Home production productivity
psiH    = ( ch/kh^alpH )^(1/(1-alpH)) / h;
% Overall consumption (in the utility function)
c       = (gamH*ch^subH + (1-gamH)*cm^subH)^(1/subH);
c_N     = c;
% Goods market matching efficiency
psiQ    = q/((gamQ*x^subQ+(1-gamQ))^(1/subQ));
% Disutility level search effort
muD     = pq*mucW*(1-gamH)*(cm/c)^(subH-1)/(ghh+(1-ghh)*c^sig)*f*psiD/(d^nuD);
% Disutility level labor supply
muN     = (1-alpF)*(epsW-1)/epsW*mcY*mucW*(1-gamH)*(cm/c)^(subH-1)/(ghh+(1-ghh)*c^sig)*psiA^(1-alpF)*(kf/n)^alpF*n^(-nuN);
% Disutility level home production: compute bounded product first to avoid h->0 singularity
% muH*h^(1+nuH) = gamH*(1-alpH)/(ghh+(1-ghh)*c^sig)*ch^subH*c^(1-subH)  is O(gamH*ch^subH) -> 0
muH_times_h1nuH = gamH*(1-alpH)/(ghh+(1-ghh)*c^sig)*ch^subH*c^(1-subH);
muH             = muH_times_h1nuH / h^(1+nuH);
% Available market goods production capacity
sf      = yf / (1+(1-delT)/delT*q-(1-delI)*(1-q));
sf_N    = sf;
% Utilized available capacity
et      = t / yf;
et_N    = et;
% Marginal utility of consumption (uses bounded product directly)
uC  = ( c - ghh * (   muD*d^(1+nuD)/(1+nuD) ...
                    + muH_times_h1nuH/(1+nuH) ...
                    + muN*n^(1+nuN)/(1+nuN) ) )^(-sig);
uC_N    = uC;
% Marginal disutility of homeproduction work
uH     = (-muH)*h^nuH * (ghh*uC+(1-ghh));
uH_N   = uH;
% Marginal disutility of search
uD     = (-muD)*d^nuD * (ghh*uC+(1-ghh));
uD_N   = uD;
% Marginal disutility of market work
uN     = (-muN)*n^nuN * (ghh*uC+(1-ghh));
uN_N   = uN;
% Marginal utility of market consumption goods
wCM     = uC  * (1-gamH)*c^(1-subH)*cm^(subH-1);
wCM_N   = wCM;
% Marginal utility of homeproduction consumption goods (stable identity: uC*c - wCM*cm)
wCH     = uC*c - wCM*cm;
wCH_N   = wCH;
% Marginal net utility of consumption
muc     = mucW*(1-gamH)*(cm/c)^(subH-1)*uC;
muc_N   = muc;
% Tobin's Q market capital stock
qf      = wCM;
qf_N    = qf;
% Tobin's Q homeproduction capital stock
qh      = wCM;
qh_N    = qh;
% Total goods price: dp^gamP*t^(1-gamP) = cm+ivf+ivh by the final goods identity
pt      = wCM*(cm+ivf+ivh)/muc;
pt_N    = pt;
% Real marginal cost of matching (mc_{T,t} in the paper)
mcT     = 1/q * ( (1-betta*(1-delI)*(1-q))*mcY + dAP*nuD*t/sf*pq );
mcT_N   = mcT;
% Pricing kernel
vphi    = (mcT-betta*(1-delI)*mcY)*(gamQ*x^subQ)*q*sf/pq ...
            / ((1-gamQ)+dAP*nuD*(gamQ*x^subQ+(1-gamQ)));
vphi_N  = vphi;
% Real wage rate
w       = mcY*(1-alpF)*psiA^(1-alpF)*(kf/n)^alpF;
w_N     = w;
wh      = w;     % union wage = xi_N*w with xi_N = 1 in steady state
piWh    = 0;
% Real capital interest rate
rk      = mcY*alpF*psiA^(1-alpF)*(kf/n)^(alpF-1);
rk_N    = rk;
% Unemployment rate
ue      = ( w/muN * muc/(ghh*uC+(1-ghh)) )^(1/nuN) * n^(-1) - 1;
ue_N    = ue;
% Price elasticity of demand
ped     = (-epss) * (1-gamP*(epss-1)/epss)/(1 + pq - (1-delT)*1/(1+r)*pq);
ped_N   = ped;
% Labor wedge
lw      = 1 - (epsW-1)/epsW*mcY/et*ef^alpF*muc/(ghh*uC+(1-ghh));
lw_N    = lw;

% FURTHER VARIABLES
% -------------------------------------------------------------------------
% Gap variables
gdp_gap = 0;
cu_gap  = 0;
ue_gap  = 0;
x_gap   = 0;
gdp_obs = log(t);
n_obs   = log(n);
mc_obs  = log(mcY/et);
w_obs   = log(w);
ls_obs  = log(w*n/t);
lpr_obs = log(t/n);
lw_obs  = -log(1-lw);
d_obs   = d/n;
ped_obs = 0;


% PHILLIPS CURVE SLOPE TARGET
% -------------------------------------------------------------------------
if nkpc_target == 1
    % Composite Parameters
    phiG    = gamQ.*x.^subQ ./ (1-gamQ);
    phiP    = gamP .* (epss-1)./epss;
    phiQ    = phiG./(1+phiG) .* ( 1 - 1/(epss.*(1-phiP)) );
    pPSps   = 1 - phiQ;
    pPSmc   = epss.*(1-phiQ).*(1-phiP);
    pPIpi   = epss.*(1-phiQ).*(1-phiP) ./ (epss.*(1-phiQ).*(1-phiP)-1);
    pPImc   = epss.*(1-phiQ).*(1-phiP) - 1;
    % Phillips curve slope
    kapP    = 1./nkpc_slope .* pPIpi.*(pPImc+phiQ.*pPSmc./pPSps);
    if dAP == 1
        % Firm-specific search convexity (I_Q = 1), 2026-09-25. The formula above rests on the
        % I_Q = 0 relation mc = 1 - 1/(eps*(1-phiXi)) (stst:mc), which fails for I_Q = 1. Linearizing the
        % pricing constraint, marginal capacity cost, the theta FOC (vphi) and the Rotemberg FOC at
        % gamP = 0, delT = delI = 1, Gamma_Q -> 0 gives pr_hat = mc_hat, P_Q_hat = eps*mc_hat and
        %   kappa_P*(pi - beta*E pi') = (eps-1)/mc * mc_hat,   i.e.
        %   kappa_P = (eps-1) / (mc * nkpc_slope),   mc = mcY/et = 1/markup,
        % which coincides with the formula above for I_Q = 0 (verified numerically, dln(phi/T)/dln(mc) = 1-eps).
        % gamP is the near-zero default 1e-5 in the baseline (get_params: parHW.gamP), not exactly 0
        if gamP > 1e-3 || abs(delT - 1) > 1e-12 || abs(delI - 1) > 1e-12
            error('nk_time_steadystate:kapP_dAP', 'kappa_P for I_Q = 1 is derived for gamP = 0 and delT = delI = 1 only.');
        end
        kapP = (epss - 1) ./ (nkpc_slope .* (mcY ./ et));
    end
end

%% end own model equations

params=NaN(NumberOfParameters,1);
for iter = 1:length(M_.params) %update parameters set in the file
  eval([ 'params(' num2str(iter) ') = ' M_.param_names{iter} ';' ])
end

NumberOfEndogenousVariables = M_.orig_endo_nbr; %auxiliary variables are set automatically
for ii = 1:NumberOfEndogenousVariables
  varname = M_.endo_names{ii};
  eval(['ys(' int2str(ii) ') = ' varname ';']);
end

end

%% SETUP FUNCTION TO NUMERICALLY SOLVE THE NON-ANALYTICAL PART
function F = solve_time(xx, ls_target, markup_stst, q, cu, x, d, ls_share, markup, ...
                        chGDP, hN, n, NUM_psiD, alpH, alpF, delT, delI, delF1, delH1, gamH, ...
                        subH, gamP, nuD, betta, epss, gamQ, subQ, psiA, dAP)
    
    % xx(1): mucW; xx(2): pq; xx(3): kf; xx(4): kh; xx(5): t

    % Search technology: iterative fixed-point (mirrors main steadystate block)
    psiD      = NUM_psiD * xx(5) / d;   % gamP=0 limit as starting guess
    dpS_loc   = 0;
    for kk = 1:100
        dpS_new  = (gamP * x / (xx(2) * q * xx(1) * psiD))^(1/(1-gamP));
        psiD_new = NUM_psiD / (d/xx(5) - dpS_new);
        if abs(psiD_new - psiD) < 1e-12 * abs(psiD)
            dpS_loc = dpS_new;
            psiD = psiD_new;
            break;
        end
        dpS_loc = dpS_new; psiD = psiD_new;
    end
    % Price search ratio: clean formula
    dpD = q*psiD*(dpS_loc*xx(5)) / (q*psiD*(dpS_loc*xx(5)) + delT*x*xx(5));

    % Real marginal costs
    if  markup_stst == 1
        % Marginal capacity costs
        mcY   = cu/markup;
        % Elasticity of substitution
        aEPS    = 1 - (1-betta*(1-delT))/q * ( mcY*(1-betta*(1-delI)*(1-q)+(q*betta*(1-delT))/(1-betta*(1-delT))) + dAP*nuD*q/delT*xx(2) );
        epss    = ((1+xx(2)*(1-betta*(1-delT)))/(1-gamP)-gamP/(1-gamP)*aEPS-dAP*nuD*dpD*xx(2)) / (aEPS-dAP*nuD*dpD*xx(2));
    else
        % Marginal capacity costs
        mcY   = (1-betta*(1-delI)*(1-q)+(q*betta*(1-delT))/(1-betta*(1-delT)))^(-1) ...
                * ( q/(1-betta*(1-delT))*(1-1/epss*(1-gamP)/(1-gamP*(epss-1)/epss)*((1+xx(2)*(1-betta*(1-delT)))/(1-gamP)+dAP*nuD*(epss-1)*dpD*xx(2))) - dAP*nuD*q/delT*xx(2) );
    end
    % Labor share
    if ls_target == 1
        alpF    = 1 - ls_share*cu/mcY;
    end
    % Effective consumption goods
    cm      = (gamP*x/(xx(1)*xx(2)*q*psiD))^(gamP/(1-gamP))*xx(5) - delF1*xx(3) - delH1*xx(4);
    % Homeproduction consumption
    ch      = chGDP * xx(5);

    % mucW
    F(1) = xx(1)^(1/(1-gamP)) - (1-gamP)/(1+xx(2)*(1-betta*(1-delT)))*(gamP*x/(xx(2)*q*psiD))^(gamP/(1-gamP));
    % pq
    F(2) = xx(2)/delT*((1-gamQ)/(gamQ*x^subQ)+dAP*nuD*(1+(1-gamQ)/(gamQ*x^subQ))) ...
            - 1/(1-betta*(1-delT))*(1-1/epss*(1-gamP)/(1-gamP*(epss-1)/epss)*((1+xx(2)*(1-betta*(1-delT)))/(1-gamP)+dAP*nuD*(epss-1)*dpD*xx(2))) ...
            + (betta*(1-delI) + betta*(1-delT)/(1-betta*(1-delT)))*mcY;
    % kf
    F(3) = (xx(3)/(psiA*n))^(1-alpF) - xx(1)*betta*alpF/(1-betta*(1-delF1))*mcY;
    % kh
    F(4) = xx(4) - alpH*gamH/(1-gamH)*betta/(1-betta*(1-delH1))*(ch/cm)^subH*cm;
    % t
    F(5) = xx(5) - q*n*psiA^(1-alpF)*(xx(3)/n)^alpF/((1-delT)*q+delT*(1-(1-delI)*(1-q)));
    
end