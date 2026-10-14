function stst = compute_stst_experiments( ...
        p0, gamQ_loop_stst, mp_loop_stst, epsP_loop_stst, psiQ_loop_stst)
% COMPUTE_STST_EXPERIMENTS  Run steady-state experiments over gamQ.
%
%   Experiment 1: gamQ x markup (mp_select==1) or gamQ x epsP (mp_select==0)
%   Experiment 2: gamQ x capacity utilization
%
%   Inputs
%     p0             - baseline parameter struct
%     gamQ_loop_stst - gamQ grid (common x-axis for both experiments)
%     mp_loop_stst   - markup values for experiment 1  (mp_select == 1)
%     epsP_loop_stst - epsP values for experiment 1    (mp_select == 0)
%     psiQ_loop_stst   - capacity utilization values for experiment 2
%
%   Output
%     stst - struct with fields *_epsP_sam/nk and *_psiQ_sam/nk

% --- Experiment 1: gamQ x epsP/mp nexus ------------------------------------
if p0.mp_select == 1
    outer_loop = mp_loop_stst;
else
    outer_loop = epsP_loop_stst;
end

n1 = length(gamQ_loop_stst);
n2 = length(outer_loop);

[stst.ps_epsP_sam,  stst.eps_epsP_sam, stst.pe_epsP_sam, ...
 stst.t_epsP_sam,   stst.muc_epsP_sam, ...
 stst.eps_epsP_nk,  stst.pe_epsP_nk,   stst.t_epsP_nk, ...
 stst.muc_epsP_nk, stst.mp_epsP_sam, stst.mp_epsP_nk] = deal(NaN(n1, n2));

for ii = 1:n1
    for tt = 1:n2
        p = p0;  p.gamQ = gamQ_loop_stst(ii);
        if p0.mp_select == 1
            p.mp   = mp_loop_stst(tt);
        else
            p.epsP = epsP_loop_stst(tt);
        end
        [out_sam, out_nk] = compute_wedges(p);
        stst.ps_epsP_sam(ii,tt)  = out_sam.stst_ps;
        stst.eps_epsP_sam(ii,tt) = out_sam.stst_epsP;
        stst.pe_epsP_sam(ii,tt)  = out_sam.stst_pe;
        stst.t_epsP_sam(ii,tt)   = out_sam.stst_t;
        stst.muc_epsP_sam(ii,tt) = out_sam.stst_muc;
        stst.eps_epsP_nk(ii,tt)  = out_nk.stst_epsP;
        stst.pe_epsP_nk(ii,tt)   = out_nk.stst_pe;
        stst.t_epsP_nk(ii,tt)    = out_nk.stst_t;
        stst.muc_epsP_nk(ii,tt)  = out_nk.stst_muc;
        stst.mp_epsP_sam(ii,tt)  = out_sam.stst_mp;
        stst.mp_epsP_nk(ii,tt)   = out_nk.stst_mp;
    end
end

% --- Experiment 2: gamQ x capacity utilization -----------------------------
n3 = length(psiQ_loop_stst);

[stst.ps_psiQ_sam,  stst.mp_psiQ_sam,  stst.pe_psiQ_sam, ...
 stst.t_psiQ_sam,   stst.muc_psiQ_sam, stst.mp_psiQ_nk, ...
 stst.pe_psiQ_nk,   stst.t_psiQ_nk,  stst.muc_psiQ_nk] = deal(NaN(n1, n3));

for ii = 1:n1
    for tt = 1:n3
        p = p0;  p.gamQ = gamQ_loop_stst(ii);  p.psiQ = psiQ_loop_stst(tt);
        [out_sam, out_nk] = compute_wedges(p);
        stst.ps_psiQ_sam(ii,tt)  = out_sam.stst_ps;
        stst.mp_psiQ_sam(ii,tt)  = out_sam.stst_mp;
        stst.pe_psiQ_sam(ii,tt)  = out_sam.stst_pe;
        stst.t_psiQ_sam(ii,tt)   = out_sam.stst_t;
        stst.muc_psiQ_sam(ii,tt) = out_sam.stst_muc;
        stst.mp_psiQ_nk(ii,tt)   = out_nk.stst_mp;
        stst.pe_psiQ_nk(ii,tt)   = out_nk.stst_pe;
        stst.t_psiQ_nk(ii,tt)    = out_nk.stst_t;
        stst.muc_psiQ_nk(ii,tt)  = out_nk.stst_muc;
    end
end

end
