function [nD, nvars, Qrd, n1Res, n1Act, x0_reshaped_after, x0] = func_adjustBeforeOpt...
    (duration, nA, nR, nM, Qrdcoeff_struct, Qrdcoeff_mep, nvars_extraForx0, x0)
% more realistic, smaller nD
nD = ceil(sum(duration(:,:,1), 'all') * 0.8);  % UPDATEDD0912 --------------------- PDATEDD0912 --------
nvars = nA*(2 + nR*(2 + nM + 3 * nD));
Qrd = [Qrdcoeff_struct * ones(1, nD); Qrdcoeff_mep * ones(1, nD)];  % each row: one resource; each column: one day 


% delete extra days in x0
n1Res = 2+nM+3*nD;
n1Act = 2+nR*(2+nM+3*(nD+nvars_extraForx0));
x0_reshaped_after = reshape(x0, n1Act, nA)';

for res = 1:nR
    x0_reshaped_after(:, (2+(res-1)*n1Res+2+nM) +nD+1 : (2+(res-1)*n1Res+2+nM) +nD+nvars_extraForx0) = [];
    x0_reshaped_after(:, (2+(res-1)*n1Res+2+nM) +2*nD+1 : (2+(res-1)*n1Res+2+nM) +2*nD+nvars_extraForx0) = [];
    x0_reshaped_after(:, (2+(res-1)*n1Res+2+nM) +3*nD+1 : (2+(res-1)*n1Res+2+nM) +3*nD+nvars_extraForx0) = [];
end

x0 = reshape(x0_reshaped_after', 1, nvars);
n1Act = 2+nR*(2+nM+3*nD);