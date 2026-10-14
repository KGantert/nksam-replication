% *************************************************************************
% When Buying Takes Time:
% Implications for the New-Keynesian Business Cycle Model
% Reduced-Form Model: STEADY-STATE CALCULATIONS
% -------------------------------------------------------------------------
% Konstantin Gantert
% kgantert@mail.de
% 05/06/2026
% *************************************************************************

function [stst, par] = model_stst(p)
% MODEL_STST  Compute steady state given parameter struct p.
%
%   Fields read from p:
%     nuN, nuD, nuH, muN, muH, muD, psiH, gamH, subH, alpF, alpH,
%     sig, epsP, psiQ, gamQ, subQ, gamP, ue, tight, mp, n, q,
%     dN, hN, chGDP, ghh, stst_target, mp_select

% Unpack for readability
nuN = p.nuN; nuD = p.nuD; nuH = p.nuH;
muN = p.muN; muH = p.muH; muD = p.muD;
psiH = p.psiH; gamH = p.gamH; subH = p.subH;
alpF = p.alpF; alpH = p.alpH;
sig  = p.sig;  epsP = p.epsP; psiQ = p.psiQ;
gamQ = p.gamQ; subQ = p.subQ; gamP = p.gamP;
ue   = p.ue;   tight    = p.tight;    mp   = p.mp;
n   = p.n;   q    = p.q;
dN = p.dN; hN = p.hN; chGDP = p.chGDP;
ghh  = p.ghh;
stst_target = p.stst_target;
mp_select   = p.mp_select;

% Labor substitution parameter
epsW = (1+ue)^nuN / ((1+ue)^nuN - 1);

% Search effort elasticity of available capacity
phiG   = gamQ * tight^subQ / (1-gamQ);
% phiGam is the paper's phi_gamma (Appendix A): the normalized share
% phiG/(1+phiG) = gamQ*tight^subQ / (gamQ*tight^subQ + (1-gamQ)).
% phiG itself is the unnormalized "odds" form, not phi_gamma directly.
phiGam = phiG / (1+phiG);

% Price markups
if mp_select == 1
    epsP  = 1/(1-gamP) * (mp/(mp-1)*(1+phiG) - phiG - gamP);
    phiP  = gamP * (epsP-1)/epsP;
    phiQ  = phiGam * (1 - 1/(epsP*(1-phiP)));
else
    phiP  = gamP * (epsP-1)/epsP;
    phiQ  = phiGam * (1 - 1/(epsP*(1-phiP)));
    mp    = (1 - 1/epsP*(1-gamP) / (1-gamP*(epsP-1)/epsP) ...
               * ((1+phiQ/(1-phiQ))/(1-gamP)))^(-1);
end

% Search prices
ps = phiQ/(1-phiQ);

% Price elasticity
pe = (-epsP) * (1-phiP) / (1+ps);

% -------------------------------------------------------------------------
% Steady-state using time-use targets
% -------------------------------------------------------------------------
if stst_target == 1
    psiQ = q / ((gamQ*tight^subQ + (1-gamQ))^(1/subQ));
    hs   = dN * n;
    hh   = hN * n;
    if gamP == 0
        hp = 0;             % no price search
    else
        hp = hs * (1 + phiQ*(1-gamP)/gamP)^(-1);
    end
    t    = q * n^(1-alpF);
    ch   = chGDP * t;
    psiH = ch^(1/(1-alpH)) / hh;
    cm   = hp^gamP * t^(1-gamP);
    c    = (gamH*ch^subH + (1-gamH)*cm^subH)^(1/subH);
    muU  = (1-gamH)*(cm/c)^(subH-1)*(1-gamP)*(hp/t)^gamP / (1+ps);
    muN  = (1-alpF)*(epsW-1)/epsW * q/mp * muU/(ghh+(1-ghh)*c^sig) ...
            * ((hp^gamP*q^(1-gamP))/cm)^((nuN+alpF)/((1-alpF)*(1-gamP)));
    muH  = psiH^(1+nuH)*(1-alpH) * (ghh+(1-ghh)*c^sig) ...
            * gamH*(ch/c)^(subH-1) * ch^(1-(1+nuH)/(1-alpH));
    muD  = ps/hs^nuD * q/tight * muU/(ghh+(1-ghh)*c^sig);

% -------------------------------------------------------------------------
% Steady-state using time disutility parameters
% -------------------------------------------------------------------------
else
    q    = psiQ * ((gamQ*tight^subQ + (1-gamQ))^(1/subQ));
    sol_options   = optimoptions('fsolve', 'Display', 'off');
    model_fnc_solve = @(xx) sol_stst_par(xx, epsW, sig, nuN, muN, nuH, ...
                                alpF, alpH, gamH, subH, muH, psiH, ...
                                gamP, q, mp, ps, tight, ghh);
    xx   = fsolve(model_fnc_solve, [1, 1], sol_options);
    t    = xx(1);
    ch   = xx(2);
    hp   = gamP/(1-gamP) * (1+ps)/ps * tight/q * t;
    cm   = hp^gamP * t^(1-gamP);
    c    = (gamH*ch^subH + (1-gamH)*cm^subH)^(1/subH);
    n   = (t/q)^(1/(1-alpF));
    muU  = (1-gamH)*(cm/c)^(subH-1)*(1-gamP)*(hp/t)^gamP / (1+ps);
    hs   = (ps/muD * q/tight * muU/(ghh+(1-ghh)*c^sig))^(1/nuD);
end

% Utility function auxiliary variables
pHH = (1-alpH)/(ghh+(1-ghh)*c^sig) * gamH*(ch/c)^subH;
pHM = muN/c * (cm*hp^(-gamP)*q^(gamP-1))^(1/((1-alpF)*(1-gamP)));
pHS = phiQ/cm * (1-gamH)*(cm/c)^subH * (1-gamP)*t^(1-gamP)*hp^gamP ...
        / (ghh+(1-ghh)*c^sig);

% Marginal consumption utility
uC  = c^(-sig) * (1 - ghh*(pHS/(1+nuD) + pHH/(1+nuH) + pHM/(1+nuN)))^(-sig);
muc = uC * ((1-gamH)*(cm/c)^(subH-1)*(1-gamP)*(hp/t)^gamP) / (1+ps);

% Quantity search effort
hq  = hs - hp;

% Pack steady-state output
stst.ps  = ps;
stst.mp  = mp;
stst.t   = t;
stst.hp  = hp;
stst.hq  = hq;
stst.muc = muc;
stst.cm  = cm;
stst.ch  = ch;
stst.c   = c;
stst.pe  = pe;

% Pack parameter output
if stst_target == 1
    par.muN  = muN;
    par.muH  = muH;
    par.muD  = muD;
    par.psiH = psiH;
    par.psiQ = psiQ;
end

% Home production and labour supply composite parameters
chiCM = (1-gamH) .* (cm./c).^subH;
phiCH = ((1+nuH)./(1-alpH)-subH) ./ (1-subH-(1-ghh).*sig);
phiCM = (1-(1-chiCM)./phiCH).^(-1) .* chiCM;
phiC  = (1-ghh).*sig.*phiCM + (1-subH).*(1-phiCM);
phiU  = ((epsW-1)./epsW).^(1/nuN);
phiUC = (-sig).*uC.^(1./sig).*c;

% Pack composite parameters
par.epsW   = epsW;
par.epsP   = epsP;
par.phiG   = phiG;
par.phiGam = phiGam;
par.phiQ   = phiQ;
par.phiP   = phiP;
par.pHH   = pHH;
par.pHM   = pHM;
par.pHS   = pHS;
par.chiCM = chiCM;
par.phiCM = phiCM;
par.phiCH = phiCH;
par.phiC  = phiC;
par.phiU  = phiU;
par.phiUC = phiUC;

% -------------------------------------------------------------------------
% Nested: steady-state equilibrium conditions for fsolve
% -------------------------------------------------------------------------
function F = sol_stst_par(xx, epsW, sig, nuN, muN, nuH, alpF, alpH, ...
                           gamH, subH, muH, psiH, gamP, q, mp, ps, tight, ghh)
    hp_  = gamP/(1-gamP) * (1+ps)/ps * tight/q * xx(1);
    cm_  = hp_^gamP * xx(1)^(1-gamP);
    c_   = (gamH*xx(2)^subH + (1-gamH)*cm_^subH)^(1/subH);
    muU_ = (1-gamH)*(cm_/c_)^(subH-1) * (1-gamP)*(hp_/xx(1))^gamP / (1+ps);
    F(1) = xx(1) - q * ((1-alpF)/muN*(epsW-1)/epsW*muU_ ...
                        *q/mp/(ghh+(1-ghh)*c_^(sig)))^((1-alpF)/(nuN+alpF));
    F(2) = xx(2) - (psiH^(1+nuH)*(1-alpH)/muH*gamH ...
                    *c_^(1-subH-(1-ghh)*sig))^(1/((1+nuH)/(1-alpH)-subH));
end

end
