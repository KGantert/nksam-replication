function [gamH, subH, gamP] = apply_model_selection(gamH, subH, gamP, hw_select, hp_select)
% APPLY_MODEL_SELECTION  Zero out home production and/or price search
%   parameters according to model selection flags.
%   Used by both compute_wedges() and compute_gamQ_cutoff() to avoid duplication.
EPS_OFF = 1e-5;
if hw_select == 0
    gamH = EPS_OFF;
    subH = EPS_OFF;
end
if hp_select == 0
    gamP = EPS_OFF;
end
end
