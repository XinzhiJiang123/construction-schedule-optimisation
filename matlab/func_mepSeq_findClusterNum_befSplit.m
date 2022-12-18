function [tableCompo_mep2, recordCompoInClusterIdx, tableZoned_mep2] = func_mepSeq_findClusterNum_befSplit(tableCompo_mep, ...
    tableActivity_mep, nClass_mep, nLevel, nZ, tableZoned_mep, compoClass_mep)
%% SEQ MEP STEP 3: clustering: create groups and assign compo to groups + Map the duration and cost data
% tic  % step 3: < 0.1 seconds
% ---- SEQ MEP STEP 3-1: Use table to store clusters and their corresponding compo
% ---- SEQ MEP STEP 3-2: Determine which cluster each compo is in
% ---- SEQ MEP STEP 3-3: 


% ---- SEQ MEP STEP 3-1: Use table to store clusters and their corresponding compo (before splitting)


% ---- SEQ MEP STEP 3-2: Determine which cluster each compo is in
% create a new column in tableCompo to record the cluster number (row number in tableZoned)
tableCompo_mep.ClusterNumber = zeros(height(tableCompo_mep), 1);



% Method 2: 98 seconds if record the compo idx in new columns in tableZoned2
% Method 2: 0.03 seconds if record the compo idx in a designated matrix clusterCompoIdxRecord
tableCompo_mep2 = tableCompo_mep;
tableZoned_mep2 = tableZoned_mep; 

recordClusterContainCompoIdx = zeros(height(tableZoned_mep2), height(tableActivity_mep));  % may save more time than cat'íng
for class = 1:nClass_mep
    for lev = 1:nLevel  % UPDATED0909 -------------------------------------------------------
        for z = 1:nZ  
            toSelect_wo_subL = tableActivity_mep{:,'Class'} == compoClass_mep(class) & ...
            contains(tableActivity_mep{:,'BaseLevel'},strcat("0",num2str(lev-2)),'IgnoreCase',true) & ... % UPDATED0909 ---------
            tableActivity_mep{:,'Zone'} == z;
            loc = (lev-1)*nZ*nClass_mep + (z-1)*nClass_mep + class;
            toSelect = toSelect_wo_subL;
            tableCompo_mep2{toSelect,'ClusterNumber'} = loc;      
            % below: 0.03 seconds if record the compo idx in a designated matrix clusterCompoIdxRecord
            % find the locations of all =1 value in toSelect
            toSelect_idx = find(toSelect == 1);
            if ~isempty(toSelect_idx)
                for i = 1:length(toSelect_idx)
                    for col = 1:height(tableActivity_mep)
                        % if the cell is not yet filled, i.e. =0
                        if recordClusterContainCompoIdx(loc, col) == 0 
                            recordClusterContainCompoIdx(loc, col) = toSelect_idx(i);
                            break
                        end
                    end
                end
            end
        end
    end
end

% for later: for simplicity, delete all the fitting compo from tableZoned2

% Record which cluster each compo falls into, in a separate matrix compoInClusterIdxRecord
recordCompoInClusterIdx = tableCompo_mep2{:, 'ClusterNumber'};