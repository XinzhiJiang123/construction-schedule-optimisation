function [M_clusterSeq_whenSplitting, tableAllCompo_whenSplitting, clusterName_new, clusterSplitRecord] = ...
    func_mepSeq_splitCluster(M_clusterSeq_befSplit, tableAllCompo_toSplit, clusterName, clusterSplitRecord_toUpdate)

tableAllCompo_whenSplitting = tableAllCompo_toSplit;
clusterSplitRecord = clusterSplitRecord_toUpdate;

% ---- SEQ MEP STEP 5-1-1: Check which cells symmetric to diagnol line has non-zero values (M_clusterSeq_befSplit)
numConflictCluster = zeros(size(M_clusterSeq_befSplit, 1), 1);  % to record the num of coflict for each cluster
for r = 1:size(M_clusterSeq_befSplit, 1)
    for c = 1:size(M_clusterSeq_befSplit, 2)
        if M_clusterSeq_befSplit(r, c) > 0 && M_clusterSeq_befSplit(c, r) > 0
            numConflictCluster(r, 1) = numConflictCluster(r, 1) + 1;
        end
    end
end

% ---- SEQ MEP STEP 5-1-2: Find which row (i.e. cluster) has the highest number of nonzeros values, and other param
maxValue = max(numConflictCluster,[],'all');  
idx_bool = find(numConflictCluster == maxValue);  % find idx of the maximum values in (each) column
if size(idx_bool) == 1
    idxToSplit = idx_bool;
else
    seed = RandStream('mlfg6331_64');  % create the random seed for reproducibility
    idxToSplit = randsample(seed, idx_bool, 1);  % the index of the cluster to split
end
% find parameters:
% nGreen = 0;  % number of green cells in row idxToSplit and column idxToSplit
rIdx = zeros(size(M_clusterSeq_befSplit, 1), 1);  % to record the idx of red cells (to be splitted)
rIdxGreenCol = zeros(size(M_clusterSeq_befSplit, 1), 1);  % to record the idx of green cells along column
rIdxGreenRow = zeros(size(M_clusterSeq_befSplit, 1), 1);  % to record the idx of green cells along column
% first half: green cell along column idxToSplit; second half: along row idxToSplit
for idx = 1:size(M_clusterSeq_befSplit, 1)
    % green cells
    if M_clusterSeq_befSplit(idx, idxToSplit) > 0 && M_clusterSeq_befSplit(idxToSplit, idx) == 0
        rIdxGreenCol(idx, 1) = idx; 
    elseif M_clusterSeq_befSplit(idxToSplit, idx) > 0 && M_clusterSeq_befSplit(idx, idxToSplit) == 0
        rIdxGreenRow(idx, 1) = idx; 
    end
    % red cells
    if M_clusterSeq_befSplit(idx, idxToSplit) > 0 && M_clusterSeq_befSplit(idxToSplit, idx) > 0
        rIdx(idx, 1) = idx; 
    end
end
% delete (rows with) all zeros in rIdx (which is a column vector)
rIdx(~any(rIdx,2), :) = [];  % delete all zero rows
rIdxGreenCol(~any(rIdxGreenCol,2), :) = [];  % delete all zero rows
rIdxGreenRow(~any(rIdxGreenRow,2), :) = [];  % delete all zero rows
% e.g. rIdx(1) = 3, rIdx(2) = 5, ...
% e.g. rIdxGreenCol(1) = 2, rIdxGreenCol(2) = 7, ...
nSub = 2 * size(rIdx, 1);  % numSubCLuster to be splitted into = 2 * num of indices of red cells
nGreen = size(rIdxGreenCol, 1) + size(rIdxGreenRow, 1); 


% ---- SEQ MEP STEP 5-1-3: Split that cluster, update M_clusterSeq_befSplit
% create a new matrix which has the cluster as (nSub+nGreen) number of subclusters
M_clusterSeq_whenSplitting = zeros(size(M_clusterSeq_befSplit, 1) + (nSub+nGreen)-1, ...
    size(M_clusterSeq_befSplit, 1) + (nSub+nGreen)-1);
% the sections that remain the same:
% top-left:
M_clusterSeq_whenSplitting(1 : idxToSplit-1,  1 : idxToSplit-1) = ...
    M_clusterSeq_befSplit(1 : idxToSplit-1,   1 : idxToSplit-1);  
% bottom-left:
M_clusterSeq_whenSplitting(idxToSplit+(nSub+nGreen) : end,  1 : idxToSplit-1) = ...
    M_clusterSeq_befSplit(idxToSplit+1 : end,                 1 : idxToSplit-1);
% top-right:
M_clusterSeq_whenSplitting(1 : idxToSplit-1,  idxToSplit+(nSub+nGreen) : end) = ...
    M_clusterSeq_befSplit(1 : idxToSplit-1,   idxToSplit+1 : end);
% bottom-right:
M_clusterSeq_whenSplitting(idxToSplit+(nSub+nGreen) : end,  idxToSplit+(nSub+nGreen) : end) = ...
    M_clusterSeq_befSplit(idxToSplit+1 : end,                 idxToSplit+1 : end);

% the sections to be changed:
% non-green cells
for i = 1:length(rIdx)
    % check which section the idx falls into
    if rIdx(i) < idxToSplit  % top & left sections
        M_clusterSeq_whenSplitting(rIdx(i), (idxToSplit-1)+2*i-1+nGreen) = M_clusterSeq_befSplit(rIdx(i), idxToSplit);
        M_clusterSeq_whenSplitting((idxToSplit-1)+2*i+nGreen,   rIdx(i)) = M_clusterSeq_befSplit(idxToSplit, rIdx(i));
        
    else  % bottom & right sections
        M_clusterSeq_whenSplitting(rIdx(i)+nSub-1+nGreen,   (idxToSplit-1)+2*i+nGreen) = M_clusterSeq_befSplit(rIdx(i), idxToSplit);
        M_clusterSeq_whenSplitting((idxToSplit-1)+2*i-1+nGreen, rIdx(i)+nSub-1+nGreen) = M_clusterSeq_befSplit(idxToSplit, rIdx(i));
    end
end
% green cells along column
for j = 1:length(rIdxGreenCol)
    if rIdxGreenCol(j) < idxToSplit  % top section
        M_clusterSeq_whenSplitting(rIdxGreenCol(j), (idxToSplit-1)+j) = M_clusterSeq_befSplit(rIdxGreenCol(j), idxToSplit);
    else  % bottom section
        M_clusterSeq_whenSplitting(rIdxGreenCol(j)+nSub-1+nGreen, (idxToSplit-1)+j) = M_clusterSeq_befSplit(rIdxGreenCol(j), idxToSplit);
    end
end
% green cells along row
for j = 1:length(rIdxGreenRow)  % UPDATED0909 --------------------------------------------------------
    if rIdxGreenRow(j) < idxToSplit  % left section
        M_clusterSeq_whenSplitting((idxToSplit-1)+j+length(rIdxGreenCol), rIdxGreenRow(j)) = M_clusterSeq_befSplit(idxToSplit, rIdxGreenRow(j));
    else  % right section
        M_clusterSeq_whenSplitting((idxToSplit-1)+j+length(rIdxGreenCol), rIdxGreenRow(j)+nSub-1+nGreen) = M_clusterSeq_befSplit(idxToSplit, rIdxGreenRow(j));
    end
end

%%
% update clusterName and tableAllCompoBeforeSplit
% split the clusterName at idxToSplit to (nGreen+nSub) subclusters
clusterName_new = repmat("", [1, length(clusterName) + (nGreen+nSub)-1]);
clusterName_new(1 : idxToSplit-1) = clusterName(1 : idxToSplit-1); 
clusterName_new(idxToSplit+(nGreen+nSub): end) = clusterName(idxToSplit+1: end); 
for i = 1:(nGreen+nSub)
    clusterName_new(idxToSplit +i-1) = strcat(clusterName(idxToSplit), "_", num2str(i));
end
% update the record 
toSelect = clusterSplitRecord(:, 1) == str2double(clusterName(idxToSplit));
clusterSplitRecord(toSelect, 2) = (nGreen+nSub);

%%
% update the clusterName in tableAllCompoBeforeSplit
% by going through all the nonzero value in green and non-green cells in M_clusterSeq_whenSplitting
% in top and bottom sections
for c = 1:(nGreen+nSub)
    idx_bool = find(M_clusterSeq_whenSplitting(:, idxToSplit+c-1) > 0);  % find idx of all nonzero values in (each) column
    if ~isempty(idx_bool)
        for r = 1:length(idx_bool)
            if idx_bool(r) < idxToSplit
                toSelect_cluster1 = strcmp(tableAllCompo_whenSplitting{:, 'Cluster1'}, clusterName(idx_bool(r)));
            elseif idx_bool(r) >= idxToSplit && idx_bool(r) < idxToSplit+(nGreen+nSub)
                toSelect_cluster1 = strcmp(tableAllCompo_whenSplitting{:, 'Cluster1'}, clusterName(idxToSplit));
            else
                toSelect_cluster1 = strcmp(tableAllCompo_whenSplitting{:, 'Cluster1'}, clusterName(idx_bool(r)-(nGreen+nSub)+1));
            end
            toSelect_cluster2 = strcmp(tableAllCompo_whenSplitting{:, 'Cluster2'}, clusterName(idxToSplit));
            % update cluster2 name; cluster1 is unchanged
            tableAllCompo_whenSplitting{toSelect_cluster1 & toSelect_cluster2, 'Cluster2'} = clusterName_new(idxToSplit+c-1);
        end
    end
end
%%
% in left and right sections
for r = 1:(nGreen+nSub)
    idx_bool = find(M_clusterSeq_whenSplitting(idxToSplit+r-1, :) > 0);  % find idx of all nonzero values in (each) row
    if ~isempty(idx_bool)
        for c = 1:length(idx_bool)
            if idx_bool(c) < idxToSplit
                toSelect_cluster2 = strcmp(tableAllCompo_whenSplitting{:, 'Cluster2'}, clusterName(idx_bool(c)));
            elseif idx_bool(c) >= idxToSplit && idx_bool(c) < idxToSplit+(nGreen+nSub)
                toSelect_cluster2 = strcmp(tableAllCompo_whenSplitting{:, 'Cluster2'}, clusterName(idxToSplit));
            else
                toSelect_cluster2 = strcmp(tableAllCompo_whenSplitting{:, 'Cluster2'}, clusterName(idx_bool(c)-(nGreen+nSub)+1));
            end              
            toSelect_cluster1 = strcmp(tableAllCompo_whenSplitting{:, 'Cluster1'}, clusterName(idxToSplit));
            % update cluster1 name; cluster2 is unchanged
            tableAllCompo_whenSplitting{toSelect_cluster1 & toSelect_cluster2, 'Cluster1'} = clusterName_new(idxToSplit+r-1);
        end
    end
end
    