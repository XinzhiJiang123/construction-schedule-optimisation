function [M_clusterSeq_befSplit, tableAllCompoClusterBeforeSplit] = func_mepSeq_prepareForSplit(tableZoned_mep2, ...
    M_seq, recordCompoInClusterIdx)
%% SEQ MEP STEP 4: Prepare for the splitting
% tic  % Step 4: 6.5 seconds -> 0.08 s
% ---- SEQ MEP STEP 4-1: Check if there is conflicting seq between compo, i.e. in a loop (skipped for now)
% ---- SEQ MEP STEP 4-2: Create a table to record: seq between compo pairs -> seq between cluster pairs
% ---- SEQ MEP STEP 4-3: Create matrix for seq between all cluster pairs, with number of compo pairs

% ---- SEQ MEP STEP 4-1: Check if there is conflicting seq between compo, i.e. in a loop (skipped for now)
% ...

% ---- SEQ MEP STEP 4-2: Create a table to record: seq between compo pairs -> seq between cluster pairs
%{
Compo 1     Compo 2     Cluster 1       Cluster 2       Cluster Seq (always = 1)
1           2           Ma              Mb              1
2           3           Mb              Mc              1
3           4           Mc              Mb              1
%}
% find the number of compo pairs with seq, i.e. how many rows need to be pre-allocated
% here clusterNumber = 0 is included
% coz of incomplete cluster identification
numCompoPairWithSeq = sum(M_seq==1,'all');
varNames3 = ["Compo1", "Compo2", "Cluster1", "Cluster2", "ClusterSeq"];
varTypes3 = ["double", "double", "double", "double", "double"];
tableAllCompoClusterBeforeSplit = table('Size',[numCompoPairWithSeq length(varNames3)],'VariableTypes',varTypes3,'VariableNames',varNames3);
% tic  % 6.5 seconds
row = 1;
for r = 1:size(M_seq, 1)
%     for c = 1:size(M_seq, 2)
    for c = r+1:size(M_seq, 1)
        if recordCompoInClusterIdx(r) ~= recordCompoInClusterIdx(c)
            if M_seq(r, c) == 1  % compo r is before compo c
                % check which clusters these two compo are in
                % update the row in the table
                tableAllCompoClusterBeforeSplit{row, :} = [r, c, recordCompoInClusterIdx(r), recordCompoInClusterIdx(c), 1];
                row = row + 1;
            elseif M_seq(r, c) == -1  % compo c is before compo r
                tableAllCompoClusterBeforeSplit{row, :} = [c, r, recordCompoInClusterIdx(c), recordCompoInClusterIdx(r), 1];
                row = row + 1;
            end
        end
    end
end

% ---- SEQ MEP STEP 4-3: Create matrix for seq between all cluster pairs, with number of compo pairs
M_clusterSeq_befSplit = zeros(height(tableZoned_mep2), height(tableZoned_mep2));
for i = 1:height(tableZoned_mep2)
    for j = 1:height(tableZoned_mep2)
        toSelect = tableAllCompoClusterBeforeSplit{:, 'Cluster1'} == i & tableAllCompoClusterBeforeSplit{:, 'Cluster2'} == j;
        M_clusterSeq_befSplit(i, j) = sum(toSelect==1,'all');
    end
end
% toc
% disp(['No. MEP compo pairs with SSR and non-conflicting CSR, present in zone boundary: ', ...
%     num2str(sum(M_clusterSeq_befSplit>0, 'all'))])
