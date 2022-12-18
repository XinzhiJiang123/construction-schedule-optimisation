function [seq_pred_mep_constSeq, seq_succ_mep_constSeq, seq_pred_mep_SR, seq_succ_mep_SR, buffer_mep_SR, ...
    clusterName_new, clusterSplitRecord, tableAllCompo_whenSplitting, M_clusterSeq_whenSplitting] = ...
    func_mepSeq_findConstSeqAndSRSeq ...
    (tableZoned_mep2, ...
    M_clusterSeq_befSplit, tableAllCompoClusterBeforeSplit, nZ)
%% SEQ MEP STEP 5: Split the clusters which contain conflicting prec results
% ---- SEQ MEP STEP 5-1-1: Check which cells symmetric to diagnol line has non-zero values (M_clusterSeq_befSplit)
% ---- SEQ MEP STEP 5-1-2: Find which row (i.e. cluster) has the highest number of nonzeros values, and other param
% ---- SEQ MEP STEP 5-1-3: Split that cluster, update M_clusterSeq_befSplit

% ---- SEQ MEP STEP 5-1: Split the clusters iteratively using function
% record the change in cluster splitting in each iteration
% create a text array to track
% also, in every iteration, update the cluster name in tableAllCompoBeforeSplit (to be done within the function)
% step 5: 0.05 s
clusterName = repmat(" ", [1, height(tableZoned_mep2)]);
for i = 1:length(clusterName)
    clusterName(i) = num2str(i);
end


% calculate the original num of conflicts (excl. green cells)
numConflictCluster = zeros(size(M_clusterSeq_befSplit, 1), 1);  % to record the num of coflict for each cluster
for r = 1:size(M_clusterSeq_befSplit, 1)
    for c = 1:size(M_clusterSeq_befSplit, 2)
        if M_clusterSeq_befSplit(r, c) > 0 && M_clusterSeq_befSplit(c, r) > 0
            numConflictCluster(r, 1) = numConflictCluster(r, 1) + 1;
        end
    end
end
count = 0;
M_clusterSeq_toSplit = M_clusterSeq_befSplit;
tableAllCompo_toSplit = tableAllCompoClusterBeforeSplit;
tableAllCompo_toSplit.Cluster1 = string(tableAllCompo_toSplit.Cluster1);
tableAllCompo_toSplit.Cluster2 = string(tableAllCompo_toSplit.Cluster2);
clusterSplitRecord_toUpdate = ones(length(clusterName), 2);
clusterSplitRecord_toUpdate(:, 1) = str2double(clusterName);

% while count < 1
while sum(numConflictCluster, 'all') > 0
    % clusterSplitRecord:
    %   [num of original cluster * 2] double matrix
    %   column 1: original cluster idx; column 2: num of (sub)clusters it is splitted into
    %   size is unchanged during the iteration
    % clusterName_new:
    %   [num of total (sub)clusters] string array
    [M_clusterSeq_whenSplitting, tableAllCompo_whenSplitting, clusterName_new, clusterSplitRecord] ...
        = func_mepSeq_splitCluster...
        (M_clusterSeq_toSplit, tableAllCompo_toSplit, clusterName, clusterSplitRecord_toUpdate);
    M_clusterSeq_toSplit = M_clusterSeq_whenSplitting;
%     tableAllCompoClusterBeforeSplit = tableAllCompo_whenSplitting;
    tableAllCompo_toSplit = tableAllCompo_whenSplitting;
    clusterName = clusterName_new;
    clusterSplitRecord_toUpdate = clusterSplitRecord;
    % update numConflictCluster
    numConflictCluster = zeros(size(M_clusterSeq_whenSplitting, 1), 1);  % to record the num of coflict for each cluster
    for r = 1:size(M_clusterSeq_whenSplitting, 1)
        for c = 1:size(M_clusterSeq_whenSplitting, 2)
            if M_clusterSeq_whenSplitting(r, c) > 0 && M_clusterSeq_whenSplitting(c, r) > 0
                numConflictCluster(r, 1) = numConflictCluster(r, 1) + 1;
            end
        end
    end
    count = count + 1;
end

if count == 0
    clusterName_new = clusterName;
    clusterSplitRecord = clusterSplitRecord_toUpdate;
    tableAllCompo_whenSplitting = tableAllCompo_toSplit;
    M_clusterSeq_whenSplitting = M_clusterSeq_toSplit;
end


% use flattened indices, i.e. change cluster indices from 1, 2, 3-1, 3-2, 4,... to 1,2,3,4,5,...
% in the precedence from construction seq. and SSR/CSR

% precedence from construction seq.
seq_pred_mep_constSeq = zeros(length(clusterName_new)*(length(clusterName_new)-1), 1);
seq_succ_mep_constSeq = zeros(length(clusterName_new)*(length(clusterName_new)-1), 1);
for zi = 1:length(clusterSplitRecord)
    for zj = zi+1:length(clusterSplitRecord)
        % ==== CASE 1.1: Same zone, different floors, same class:
        if zj == zi + nZ
            if zi == 1
                count_zi = 1;
                count_zj = sum(clusterSplitRecord(1:zj-1, 2), 'all') + 1;
            else
                count_zi = sum(clusterSplitRecord(1:zi-1, 2), 'all') + 1;
                count_zj = sum(clusterSplitRecord(1:zj-1, 2), 'all') + 1;
            end                
            for zii = 1:clusterSplitRecord(zi, 2)
                for zjj = 1:clusterSplitRecord(zj, 2)
                    loc = (count_zi+zii-1-1) * length(clusterName_new) + count_zj+zjj-1;
                    seq_pred_mep_constSeq(loc) = count_zi+zii-1;
                    seq_succ_mep_constSeq(loc) = count_zj+zjj-1;
                end
            end
        end
        % ==== CASE 3.1: Different zone, same floor, same activity types:    
        if mod(zi+nZ-1,nZ) == 0 && zj < zi + nZ  % e.g. taking nZ=3, zi == 1,4,5,...
            if zi == 1
                count_zi = 1;
                count_zj = sum(clusterSplitRecord(1:zj-1, 2), 'all') + 1;
            else
                count_zi = sum(clusterSplitRecord(1:zi-1, 2), 'all') + 1;
                count_zj = sum(clusterSplitRecord(1:zj-1, 2), 'all') + 1;
            end                
            for zii = 1:clusterSplitRecord(zi, 2)
                for zjj = 1:clusterSplitRecord(zj, 2)
                    loc = (count_zi+zii-1-1) * length(clusterName_new) + count_zj+zjj-1;
                    seq_pred_mep_constSeq(loc) = count_zi+zii-1;
                    seq_succ_mep_constSeq(loc) = count_zj+zjj-1;
                end
            end
        end
%         if tableZoned_mep{i,'Zone'} == tableZoned_mep{j,'Zone'}  % TO UPDATE!!!
%             
%             % ==== CASE 1.1: Same zone, different floors, same class:
%             % if sum(tableZoned{i,'Class'} == classEssential) > 0 % if the class is found in classEssential array
%             %     if sum(tableZoned{j,'Class'} == classEssential) > 0 % if the class is found in classEssential array
%             if tableZoned_mep{i,'Class'} == tableZoned_mep{j,'Class'}
%                 % if both classes are found in classEssential array
%                 if tableZoned_mep{i,'Floor'} +1 == tableZoned_mep{j,'Floor'}  % UPDATED0912 ----------
%                     seq_pred_mep_constSeq((i-1)*height(tableZoned_mep)+j) = i;
%                     seq_succ_mep_constSeq((i-1)*height(tableZoned_mep)+j) = j;
%                 elseif tableZoned_mep{i,'Floor'} -1 == tableZoned_mep{j,'Floor'}  % UPDATED0912 ----------
%                     seq_pred_mep_constSeq((i-1)*height(tableZoned_mep)+j) = j;
%                     seq_succ_mep_constSeq((i-1)*height(tableZoned_mep)+j) = i;
%                 end
%             end
% 
%         end
%         % different zones
%         % ==== CASE 3.1: Different zone, same floor, same activity types:
%         if tableZoned_mep{i,'Floor'} == tableZoned_mep{j,'Floor'} && ...
%             tableZoned_mep{i,'Class'} == tableZoned_mep{j,'Class'}
%             if tableZoned_mep{i,'Zone'} < tableZoned_mep{j,'Zone'} 
%                 seq_pred_mep_constSeq((i-1)*height(tableZoned_mep)+j) = i;
%                 seq_succ_mep_constSeq((i-1)*height(tableZoned_mep)+j) = j;
%             elseif tableZoned_mep_constSeq{i,'Zone'} > tableZoned_mep{j,'Zone'} 
%                 seq_pred_mep_constSeq((i-1)*height(tableZoned_mep)+j) = j;
%                 seq_succ_mep_constSeq((i-1)*height(tableZoned_mep)+j) = i;
%             end     
%         end
    end
end
seq_pred_mep_constSeq = seq_pred_mep_constSeq(~all(seq_pred_mep_constSeq == 0, 2),:)';  % delete the empty elements
seq_succ_mep_constSeq = seq_succ_mep_constSeq(~all(seq_succ_mep_constSeq == 0, 2),:)';


% precedence from SSR/CSR
seq_pred_mep_SR = zeros(length(clusterName_new)*(length(clusterName_new)-1), 1);
seq_succ_mep_SR = zeros(length(clusterName_new)*(length(clusterName_new)-1), 1);
for r = 1:size(M_clusterSeq_whenSplitting)  % in row r, i.e. cluster r is earlier than other clusters
    toSelect = find(M_clusterSeq_whenSplitting(r,:) > 0);  % all indices of (sub)clusters
    for i = 1:length(toSelect)
        c = toSelect(i);
        seq_pred_mep_SR((r-1)*length(clusterName_new)+c, 1) = r;
        seq_succ_mep_SR((r-1)*length(clusterName_new)+c, 1) = c;
    end
end
seq_pred_mep_SR = seq_pred_mep_SR(~all(seq_pred_mep_SR == 0, 2),:)';  % delete the empty elements
seq_succ_mep_SR = seq_succ_mep_SR(~all(seq_succ_mep_SR == 0, 2),:)';
buffer_mep_SR = zeros(1,length(seq_pred_mep_SR));   