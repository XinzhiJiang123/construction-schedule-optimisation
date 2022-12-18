function [seq_pred_structmep, seq_succ_structmep, buffer_structmep, nvars_extraForx0, ...
    duration, cost, seq_pred, seq_succ, buffer, nA, nD, UR_ar, URp_ar, nvars, Qrd] = ...
    func_combineStructAndMep...
    (tableZoned_struct, tableZoned_mep_splitted, classEssential_struct, nR, nM, ...
    duration_struct, duration_mep, cost_struct, cost_mep, buffer_struct, buffer_mep, nA_struct, nA_mep, ...
    seq_pred_struct, seq_pred_mep, seq_succ_struct, seq_succ_mep, Qrdcoeff_struct, Qrdcoeff_mep)
%% Find precedence between struct and MEP systems

% same floor, same zone: struct essential -> MEP
seq_pred_structmep = zeros(height(tableZoned_struct)*height(tableZoned_mep_splitted), 1);
seq_succ_structmep = zeros(height(tableZoned_struct)*height(tableZoned_mep_splitted), 1);
% classEssential_struct = categorical(["Foundation", "Column", "Beam", "Slab"]);
% classNonEssential_struct = categorical("Wall");

for i = 1:height(tableZoned_struct)
    toSelect_zonefloor = tableZoned_mep_splitted{:, 'Zone'} == tableZoned_struct{i,'Zone'} & ...
        tableZoned_mep_splitted{:, 'Floor'} == tableZoned_struct{i,'Floor'};
    for class = 1:size(classEssential_struct, 2)
        toSelect_class = tableZoned_struct{i,'Class'} == classEssential_struct(class);
        toSelect = toSelect_zonefloor & toSelect_class;
        toSelectIdx = find(toSelect > 0);
        if ~isempty(toSelectIdx)
            for idx = 1:length(toSelectIdx)
                seq_pred_structmep(i*height(tableZoned_mep_splitted)+idx) = i;
                seq_succ_structmep(i*height(tableZoned_mep_splitted)+idx) = toSelectIdx(idx);
            end
        end
    end
end
seq_pred_structmep = seq_pred_structmep(~all(seq_pred_structmep == 0, 2),:)';  % delete the empty elements
seq_succ_structmep = seq_succ_structmep(~all(seq_succ_structmep == 0, 2),:)';
buffer_structmep = zeros(1,length(seq_pred_structmep));    






%% Combine tableZoned_struct and tableZoned_mep_splitted, and prep the inputs for "solve" function
% concat the duration data
duration = cat(1, duration_struct, duration_mep);
cost = cat(1, cost_struct, cost_mep);
seq_pred = cat(2, seq_pred_struct, seq_pred_mep + nA_struct, ...
    seq_pred_structmep);
seq_succ = cat(2, seq_succ_struct, seq_succ_mep + nA_struct, ...
    seq_succ_structmep + nA_struct);
buffer = cat(2, buffer_struct, buffer_mep, buffer_structmep);

nD = sum(duration(:,:,1), 'all') + 35; % only for the purpose of getting UR_ar_struct, URp_ar_struct
% nD will be overwritten later

% Generate UR_ar, URp_ar to indicate which res is used/unused for each act

% UR_ar = zeros(nA, nR);
% URp_ar = zeros(nA, nR);
% UR_ar = [1 nD; 1 nD; 1 nD; 1 nD; nD 1; nD 1];
% URp_ar = [1 0; 1 0; 1 0; 1 0; 0 1; 0 1];
% Structural file ===================================================================
% UR_ar = [1 nD; 1 nD; 1 nD; 1 nD; nD 1; nD 1];
UR_ar_struct = ones(nA_struct, nR);
toSelect_noRes1 = contains(tableZoned_struct{:, 'Resource_1'}, "NA", 'IgnoreCase', false);
UR_ar_struct(toSelect_noRes1, 1) = nD;
toSelect_noRes2 = contains(tableZoned_struct{:, 'Resource_2'}, "NA", 'IgnoreCase', false);
UR_ar_struct(toSelect_noRes2, 2) = nD;
% URp_ar = [1 0; 1 0; 1 0; 1 0; 0 1; 0 1];
URp_ar_struct = ones(nA_struct, nR);
toSelect_noRes1 = contains(tableZoned_struct{:, 'Resource_1'}, "NA", 'IgnoreCase', false);
URp_ar_struct(toSelect_noRes1, 1) = 0;
toSelect_noRes2 = contains(tableZoned_struct{:, 'Resource_2'}, "NA", 'IgnoreCase', false);
URp_ar_struct(toSelect_noRes2, 2) = 0;

% MEP file ===================================================================
UR_ar_mep = ones(nA_mep, nR);
toSelect_noRes1 = contains(tableZoned_mep_splitted{:, 'Resource_1'}, "NA", 'IgnoreCase', false);
UR_ar_mep(toSelect_noRes1, 1) = nD;
toSelect_noRes2 = contains(tableZoned_mep_splitted{:, 'Resource_2'}, "NA", 'IgnoreCase', false);
UR_ar_mep(toSelect_noRes2, 2) = nD;
% URp_ar = [1 0; 1 0; 1 0; 1 0; 0 1; 0 1];
URp_ar_mep = ones(nA_mep, nR);
toSelect_noRes1 = contains(tableZoned_mep_splitted{:, 'Resource_1'}, "NA", 'IgnoreCase', false);
URp_ar_mep(toSelect_noRes1, 1) = 0;
toSelect_noRes2 = contains(tableZoned_mep_splitted{:, 'Resource_2'}, "NA", 'IgnoreCase', false);
URp_ar_mep(toSelect_noRes2, 2) = 0;

% combine UR_ar and URp_ar for struct and mep files
UR_ar = cat(1, UR_ar_struct, UR_ar_mep);
URp_ar = cat(1, URp_ar_struct, URp_ar_mep);

nA = nA_struct + nA_mep;

% extra for initial solutions
nvars_extraForx0 = ceil(sum(duration(:,:,1), 'all') * 1.2);
nD = ceil(sum(duration(:,:,1), 'all') * 0.8) + nvars_extraForx0;  % UPDATEDD0912 --------------------- UPDATEDD0930 --------
nvars = nA*(2 + nR*(2 + nM + 3 * nD));
Qrd = [Qrdcoeff_struct * ones(1, nD); Qrdcoeff_mep * ones(1, nD)];  % each row: one resource; each column: one day 


% add dummy finish
nA = nA_struct + nA_mep + 1;
duration = [duration; zeros(1, nR, nM)];
cost = [cost; zeros(1, nR, nM)];
seq_pred = [seq_pred, 1:(nA-1)];
seq_succ = [seq_succ, nA*ones(1, nA-1)];
buffer = [buffer, zeros(1, nA-1)];
UR_ar = [UR_ar; [nD, 1]];
URp_ar = [URp_ar; [0, 1]];