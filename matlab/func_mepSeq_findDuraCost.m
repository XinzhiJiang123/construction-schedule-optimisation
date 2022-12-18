function [seq_pred_mep, seq_succ_mep, buffer_mep, nD_mep, nvars_mep, duration_mep, cost_mep, nA_mep] = ...
    func_mepSeq_findDuraCost ...
    (tableZoned_mep_splitted, ...
    nR, nM, timeUnitConver, ...
    seq_pred_mep_constSeq, seq_succ_mep_constSeq, seq_pred_mep_SR, seq_succ_mep_SR)
%% Prepare tableZoned for the optimisation problem: inputs for "solve" function - MEP

% duration data to be fed into solve function: [hours] 3D matrix for a, r, m
duration_hr_mep = zeros(height(tableZoned_mep_splitted), nR, nM);  % 3D matrix for a, r, m
for res = 1:nR  % actually only 1 resource for now
    for m = 1:nM
        duration_hr_mep(:, res, m) = ceil(tableZoned_mep_splitted{:, strcat('Dura_r', string(res), 'm', string(m))});  % array; round duration (in hours)
    end
end
cost_mep = zeros(height(tableZoned_mep_splitted), nR, nM);  % 3D matrix for a, r, m
for res = 1:nR  % actually only 1 resource for now
    for m = 1:nM
        cost_mep(:, res, m) = ceil(tableZoned_mep_splitted{:, strcat('TotalCost_r', string(res), 'm', string(m))});
    end
end
nA_mep = size(duration_hr_mep,1);  % duration: % 3D matrix for a, r, m
duration_mep = ceil(duration_hr_mep / timeUnitConver);  % from hours to days
 

% nD: for mode 1 (the slowest mode), for each resource, calculate the sum of duration of all activities,
% then find the max sum
nD_mep = max(sum(duration_mep(:,:,1))); 
nvars_mep = nA_mep*(2 + nR*(2+nM+3*nD_mep));  % formu2
% Qrd_mep = Qrdcoeff_mep*ones(nR, nD_mep);  % each row: one resource; each column: one day


% precedence of MEP clusters: use what's identified before
seq_pred_mep = [seq_pred_mep_constSeq, seq_pred_mep_SR];
seq_succ_mep = [seq_succ_mep_constSeq, seq_succ_mep_SR];
buffer_mep = zeros(1,length(seq_pred_mep));  