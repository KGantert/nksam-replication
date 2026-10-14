function jac = compute_param_jacobian(p0, report_file)
% COMPUTE_PARAM_JACOBIAN  Local identification of (gamQ, subQ, nuD) from the
%   six reduced-form slopes (IS, price Phillips, real wage growth; each on
%   the output gap _t and the unemployment gap _ue).
%
%   J(i,k) = d ln|slope_i| / d x_k * s_k  (central differences), with
%   parameter scales s = (gamQ, 1, nuD) at baseline, i.e. proportional
%   changes for gamQ and nuD and a unit change for subQ (= Gamma_Q, which
%   is close to zero at baseline). The singular values of J measure how
%   well the slopes pin down each direction in parameter space; the right
%   singular vector of the smallest one is the weakest direction.
%
%   Evaluated at the baseline and at the alternative (gamQ, subQ, nuD)
%   points listed in pts (rows). Output-gap slopes only are also reported.

if nargin < 2, report_file = nksam_path('txt', 'param_jacobian.txt'); end

slopes = {'AD_t','AD_ue','AS_t','AS_ue','WG_t','WG_ue'};
pts = [p0.gamQ,  p0.subQ, p0.nuD;
       p0.gamQ, -0.5,     p0.nuD;
       p0.gamQ, -2.7,     p0.nuD;
       0.20,    -1.0,     p0.nuD];

jac.pts = pts; jac.sv = NaN(size(pts,1),3); jac.sv_out = NaN(size(pts,1),3);
jac.weak = NaN(size(pts,1),3); jac.base_slopes = [];
for r = 1:size(pts,1)
    x0 = pts(r,:);
    s  = [x0(1), 1, x0(3)];
    v0 = eval_slopes(p0, x0, slopes);
    if r == 1, jac.base_slopes = v0; end
    J = zeros(numel(slopes), 3);
    for k = 1:3
        h = 1e-5*max(1, abs(x0(k)));
        xp = x0; xm = x0; xp(k) = xp(k)+h; xm(k) = xm(k)-h;
        J(:,k) = (eval_slopes(p0, xp, slopes) - eval_slopes(p0, xm, slopes)) / (2*h);
    end
    Jr = (J ./ abs(v0(:))) .* s;
    [~, S, V] = svd(Jr);
    jac.sv(r,:)     = diag(S)';
    jac.weak(r,:)   = abs(V(:,3))';
    jac.sv_out(r,:) = svd(Jr([1 3 5],:))';
end

lines = {'Local identification of (gamQ, subQ, nuD) from six slopes', repmat('=',1,78), ...
    sprintf('Baseline slopes (%s): %s', strjoin(slopes,','), sprintf('%.4f ', jac.base_slopes)), ...
    'Relative Jacobian d ln|slope| / d ln(param); subQ in level units', ...
    sprintf('%-9s %-8s %-6s | %-25s | %-20s | %s', 'gamQ','subQ','nuD','sing.val. (all 6 slopes)','min/max ratio','weakest direction |v| (gamQ,subQ,nuD)')};
for r = 1:size(pts,1)
    lines{end+1} = sprintf('%-9.3f %-8.4f %-6.2f | %7.3f %7.3f %7.3f | %-20.3f | %.3f %.3f %.3f', ...
        pts(r,:), jac.sv(r,:), jac.sv(r,3)/jac.sv(r,1), jac.weak(r,:)); %#ok<AGROW>
end
lines{end+1} = '';
lines{end+1} = 'Output-gap slopes only (IS, PC, RW on _t): singular values';
for r = 1:size(pts,1)
    lines{end+1} = sprintf('%-9.3f %-8.4f %-6.2f | %7.3f %7.3f %7.3f', pts(r,:), jac.sv_out(r,:)); %#ok<AGROW>
end
for ii = 1:numel(lines), disp(lines{ii}); end
d = fileparts(report_file); if ~isempty(d) && ~exist(d,'dir'), mkdir(d); end
fid = fopen(report_file,'w'); fprintf(fid,'%s\n',lines{:}); fclose(fid);
end

function v = eval_slopes(p0, x, slopes)
p = p0; p.gamQ = x(1); p.subQ = x(2); p.nuD = x(3);
[out, ~] = compute_wedges(p);
v = zeros(numel(slopes),1);
for k = 1:numel(slopes), v(k) = out.(slopes{k}); end
end
