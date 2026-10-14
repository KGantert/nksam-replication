% online_IV_equivalence.m -- Online Appendix IV: equivalence classes of the goods market SaM parameters
% -------------------------------------------------------------------------
% PRODUCES (chapters/online_appendix/ap_equivalence_classes.tex, sec:equivalence_classes):
%   results/tables/tab_param_equiv.tex   tab:param_equiv (\input by the paper from tables/)
%   results/txt/param_equivalence.txt    matching experiment: alternative (gamma_Q, Gamma_Q, nu_D)
%                                        that reproduce the baseline IS / Phillips / real wage slopes
%   results/txt/param_jacobian.txt       local identification: Jacobian of the slopes and its
%                                        singular values
% lib/figs_equivalence.m draws the matching experiment (not in the paper):
% call figs_equivalence(equiv, lwdth) after this script if wanted.
% -------------------------------------------------------------------------
run(fullfile(fileparts(mfilename('fullpath')), '..', 'lib', 'setup_slopes.m'));

equiv = compute_param_equivalence(p0, par);
jac   = compute_param_jacobian(p0);
write_equiv_table(equiv, jac);
