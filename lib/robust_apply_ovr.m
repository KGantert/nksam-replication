function s = robust_apply_ovr(s, ovr)
% ROBUST_APPLY_OVR  Apply an n x 3 override cell {struct, field, value} to
%   a scenario cfg (Dynare) or to a struct with fields .par/.flags (slopes).
%   Missing sub-structs are created. An empty cell leaves s unchanged.
for ii = 1:size(ovr, 1)
    s.(ovr{ii, 1}).(ovr{ii, 2}) = ovr{ii, 3};
end
end
