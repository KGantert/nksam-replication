function [gamQ_cut, gamQ_cut_loop, gamQ_loop] = compute_gamQ_cutoff( ...
        p0, mp_cut_loop, epsP_cut_loop, gamQ_low, gamQ_high)
% COMPUTE_GAMQ_CUTOFF  Solve for the gamQ cutoff curve and the default cutoff value.
%
%   Inputs
%     p0            - baseline parameter struct (from build_p)
%     mp_cut_loop   - markup grid for the cutoff curve  (mp_select == 1)
%     epsP_cut_loop - epsP grid for the cutoff curve    (mp_select == 0)
%     gamQ_low      - lower gamQ value for gamQ_loop
%     gamQ_high     - upper gamQ value for gamQ_loop
%
%   Outputs
%     gamQ_cut      - scalar cutoff at baseline calibration
%     gamQ_cut_loop - cutoff values along mp_cut_loop / epsP_cut_loop
%     gamQ_loop     - [gamQ_low, gamQ_cut, gamQ_high]

fsolve_opts = optimoptions('fsolve', 'Display', 'off');

% --- Cutoff curve -----------------------------------------------------------
jj = length(mp_cut_loop);
gamQ_cut_loop = NaN(jj, 1);

for ii = 1:jj
    if p0.mp_select == 1
        mp_ii   = mp_cut_loop(ii);
        epsP_ii = p0.epsP;
    else
        mp_ii   = p0.mp;
        epsP_ii = epsP_cut_loop(ii);
    end
    gamQ_fn = @(gamQ) mc_cutoff_calc(gamQ, p0.hN, p0.dN, p0.n, p0.q, p0.tight, ...
        mp_ii, p0.gamH, p0.subH, p0.nuH, p0.alpH, p0.gamP, p0.alpF, ...
        p0.sig, epsP_ii, p0.subQ, p0.ghh, p0.hw_select, p0.hp_select, p0.mp_select);
    gamQ_cut_loop(ii) = fsolve(gamQ_fn, 0.2, fsolve_opts);
end

% --- Default cutoff at baseline calibration ---------------------------------
gamQ_fn_default = @(gamQ) mc_cutoff_calc(gamQ, p0.hN, p0.dN, p0.n, p0.q, p0.tight, ...
    p0.mp, p0.gamH, p0.subH, p0.nuH, p0.alpH, p0.gamP, p0.alpF, ...
    p0.sig, p0.epsP, p0.subQ, p0.ghh, p0.hw_select, p0.hp_select, p0.mp_select);
gamQ_cut = fsolve(gamQ_fn_default, 0.2, fsolve_opts);

gamQ_loop = [gamQ_low, gamQ_cut, gamQ_high];

end


% =========================================================================
% LOCAL HELPER
% =========================================================================

function F = mc_cutoff_calc(gamQ, hN, dN, n, cu, tight, mp, gamH, subH, ...
                            nuH, alpH, gamP, alpF, sig, epsP, ...
                            subQ, ghh, hw_select, hp_select, mp_select)
% MC_CUTOFF_CALC  Evaluate the MC-channel sign-change condition at gamQ.
%   Returns F = 0 at the cutoff; passed to fsolve as an anonymous function.

[gamH, subH, gamP] = apply_model_selection(gamH, subH, gamP, hw_select, hp_select);

% Steady-state markups
phiG   = gamQ .* tight.^subQ ./ (1-gamQ);
% phiGam is the paper's phi_gamma (Appendix A): the normalized share
% phiG/(1+phiG). phiG itself is the unnormalized "odds" form.
phiGam = phiG ./ (1+phiG);
if mp_select == 1
    epsP  = (mp./(mp-1).*(1+phiG) - phiG - gamP) ./ (1-gamP);
    phiP  = gamP .* (epsP-1) ./ epsP;
    phiQ  = phiGam .* (1 - 1./(epsP.*(1-phiP)));
else
    phiP  = gamP .* (epsP-1) ./ epsP;
    phiQ  = phiGam .* (1 - 1./(epsP.*(1-phiP)));
    mp    = (1 - 1./(epsP.*(1-phiQ).*(1-phiP))).^(-1);
end

% Steady-state capacity utilization
q   = cu;
% Price search effort
hp  = dN .* n .* (1 + phiQ.*(1-gamP)./gamP).^(-1);
% Home goods consumption
ch  = (hN .* n).^(1-alpH);
% Market goods consumption
cm  = ch ./ (hN.^(1-alpH) .* n.^(alpF-alpH-gamP.*(1-alpF)) ...
             .* q.^(gamP-1) .* hp.^(-gamP));
% Composite consumption good
c   = (gamH.*ch.^subH + (1-gamH).*cm.^subH).^(1./subH);

% Home production coefficients
chiCM = (1-gamH) .* (cm./c).^subH;
phiCM = chiCM ./ (1 - (1-chiCM).*(1-subH-(1-ghh).*sig) ...
                       ./ ((1+nuH)./(1-alpH)-subH));
phiCH = (1-subH) .* (1-phiCM);
phiC  = phiCH + (1-ghh).*sig.*phiCM;

% Cutoff condition
F = (phiQ + gamP.*(1-phiC).*(1-phiQ)) .* epsP.*(1-phiP) - 1;

end
