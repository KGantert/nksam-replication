function [res_sam, res_nk] = compute_sensitivity(p0, gamQ_loop, nuD_loop, exps)
% COMPUTE_SENSITIVITY  Run all sensitivity experiments defined in exps.
%
%   Each experiment in exps varies one parameter across gamQ_loop x values x nuD_loop.
%
%   Inputs
%     p0        - baseline parameter struct
%     gamQ_loop - gamQ values to loop over (outer dimension)
%     nuD_loop  - nuD level values to loop over (inner dimension); nuN is
%                 held fixed at p0.nuN throughout
%     exps      - struct array; each entry has fields:
%                     .name       string key for output structs
%                     .param      parameter field name to vary ('' = none)
%                     .values     values to loop over for that parameter
%                     .sam_fields cell array of out_sam field names to collect
%                     .nk_fields  cell array of out_nk  field names to collect
%
%   Outputs
%     res_sam - nested struct: res_sam.(exp.name).(field) = [nG x nV x nT]
%     res_nk  - nested struct: res_nk.(exp.name).(field)  = [nG x nV x nT]

nG = length(gamQ_loop);
nT = length(nuD_loop);

res_sam = struct();
res_nk  = struct();

for ee = 1:length(exps)
    ex = exps(ee);
    nV = length(ex.values);

    res_sam.(ex.name) = struct();
    res_nk.(ex.name)  = struct();
    for f = ex.sam_fields;  res_sam.(ex.name).(f{1}) = NaN(nG, nV, nT);  end
    for f = ex.nk_fields;   res_nk.(ex.name).(f{1})  = NaN(nG, nV, nT);  end

    for ii = 1:nG
        for vv = 1:nV
            for tt = 1:nT
                p      = p0;
                p.gamQ = gamQ_loop(ii);
                p.nuD  = nuD_loop(tt);
                if ~isempty(ex.param)
                    p.(ex.param) = ex.values(vv);
                end
                [out_sam, out_nk] = compute_wedges(p);
                for f = ex.sam_fields
                    res_sam.(ex.name).(f{1})(ii,vv,tt) = out_sam.(f{1});
                end
                for f = ex.nk_fields
                    res_nk.(ex.name).(f{1})(ii,vv,tt)  = out_nk.(f{1});
                end
            end
        end
    end
end

end
