function [duration_struct, cost_struct, nD_struct, nvars_struct] = func_structSeq_findDuraCost(tableZoned_struct, ...
    nA_struct, nR, nM, timeUnitConver)

% duration data to be fed into solve function: [hours] 3D matrix for a, r, m
duration_hr_struct = zeros(height(tableZoned_struct), nR, nM);  % 3D matrix for a, r, m
for res = 1:nR  % actually only 1 resource for now
    for m = 1:nM
        duration_hr_struct(:, res, m) = ceil(tableZoned_struct{:, strcat('Dura_r', string(res), 'm', string(m))});  % array; round duration (in hours)
    end
end
cost_struct = zeros(height(tableZoned_struct), nR, nM);  % 3D matrix for a, r, m
for res = 1:nR  % actually only 1 resource for now
    for m = 1:nM
        cost_struct(:, res, m) = ceil(tableZoned_struct{:, strcat('TotalCost_r', string(res), 'm', string(m))});
    end
end
duration_struct = ceil(duration_hr_struct / timeUnitConver);  % from hours to days


% nD: for mode 1 (the slowest mode), for each resource, calculate the sum of duration of all activities,
% then find the max sum
nD_struct = max(sum(duration_struct(:,:,1))); 
nvars_struct = nA_struct*(2 + nR*(2+nM+3*nD_struct));  % formu2
% Qrd_struct = Qrdcoeff_struct*ones(nR, nD_struct);  % each row: one resource; each column: one day