function M_ = set_M_params(M_, par, parHW, parSAM, shock, target, switches)
% SET_M_PARAMS  Inject calibration into M_.params without touching the workspace.
%
%   Replicates every set_param_value call in nk_time.dyn by writing directly
%   to M_.params using the parameter index from M_.param_names.  Called once
%   per scenario inside run_dynare_scenario before stoch_simul is invoked.
%
%   Parameters computed analytically inside nk_time_steadystate.m
%   (delF3, delH3, muN, muH, muD, psiH, psiQ, psiD, kapW/epsW when
%   labor_ext=1, kapP when nkpc_target=1) are NOT set here — the steady-
%   state file returns them via the params output vector.

% Monetary
M_ = sp(M_, 'betta',      par.betta);
M_ = sp(M_, 'sig',        par.sig);
M_ = sp(M_, 'iR',         par.iR);
M_ = sp(M_, 'iPi',        par.iPi);
M_ = sp(M_, 'iGap',       par.iGap);

% Market labor
M_ = sp(M_, 'epsW',       par.epsW);
M_ = sp(M_, 'kapW',       par.kapW);
M_ = sp(M_, 'nuN',        par.nuN);
M_ = sp(M_, 'phiN',       par.phiN);

% Home production labor
M_ = sp(M_, 'gamH',       parHW.gamH);
M_ = sp(M_, 'subH',       parHW.subH);
M_ = sp(M_, 'nuH',        parHW.nuH);
M_ = sp(M_, 'gamP',       parHW.gamP);

% Search-and-matching
M_ = sp(M_, 'gamQ',       parSAM.gamQ);
M_ = sp(M_, 'subQ',       parSAM.subQ);
M_ = sp(M_, 'nuD',        parSAM.nuD);
M_ = sp(M_, 'delT',       parSAM.delT);
M_ = sp(M_, 'delI',       parSAM.delI);
M_ = sp(M_, 'epss',       par.epss);
M_ = sp(M_, 'kapP',       par.kapP);

% Capital
M_ = sp(M_, 'psiA',       par.psiA);
M_ = sp(M_, 'alpF',       par.alpF);
M_ = sp(M_, 'alpH',       parHW.alpH);
M_ = sp(M_, 'delF1',      par.delF1);
M_ = sp(M_, 'delF2',      par.delF2);
M_ = sp(M_, 'delH1',      parHW.delH1);
M_ = sp(M_, 'delH2',      parHW.delH2);
M_ = sp(M_, 'kapF',       par.kapF);
M_ = sp(M_, 'kapH',       parHW.kapH);

% Shock processes
M_ = sp(M_, 'stdA',       shock.stdA);
M_ = sp(M_, 'stdZ',       shock.stdZ);
M_ = sp(M_, 'stdM',       shock.stdM);
M_ = sp(M_, 'stdP',       shock.stdP);
M_ = sp(M_, 'stdT',       shock.stdT);
M_ = sp(M_, 'stdD',       shock.stdD);
M_ = sp(M_, 'rhoA',       shock.rhoA);
M_ = sp(M_, 'rhoZ',       shock.rhoZ);
M_ = sp(M_, 'rhoM',       shock.rhoM);
M_ = sp(M_, 'rhoP',       shock.rhoP);
M_ = sp(M_, 'rhoT',       shock.rhoT);
M_ = sp(M_, 'rhoD',       shock.rhoD);

% Steady-state calibration targets
M_ = sp(M_, 'cuss',       target.cuss);
M_ = sp(M_, 'uss',        target.uss);
M_ = sp(M_, 'xss',        target.xss);
M_ = sp(M_, 'nss',        target.nss);
M_ = sp(M_, 'dnss',       target.dnss);
M_ = sp(M_, 'hnss',       target.hnss);
M_ = sp(M_, 'chgdpss',    target.chgdpss);
M_ = sp(M_, 'ls_share',   target.ls_share);
M_ = sp(M_, 'markup',     target.markup);
M_ = sp(M_, 'nkpc_slope', target.nkpc_slope);
M_ = sp(M_, 'nkwpc_slope',target.nkwpc_slope);

% Functional-form switches
M_ = sp(M_, 'ghh',         switches.ghh_pref);
M_ = sp(M_, 'markup_stst', switches.markup_stst);
M_ = sp(M_, 'ls_target',   switches.ls_target);
M_ = sp(M_, 'nkpc_target', switches.nkpc_target);
M_ = sp(M_, 'labor_ext',   switches.labor_ext);
M_ = sp(M_, 'dAP',         switches.dAP);

end

% =========================================================================
% Local helper: set one parameter by name
% =========================================================================
function M_ = sp(M_, name, val)
    idx = strcmp(M_.param_names, name);
    if ~any(idx)
        error('set_M_params: parameter "%s" not found in M_.param_names.', name);
    end
    M_.params(idx) = val;
end
