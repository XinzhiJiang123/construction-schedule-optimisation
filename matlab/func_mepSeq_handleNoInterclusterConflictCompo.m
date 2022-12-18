function [tableCompo_mep2, seq_pred_mep_constSeq, seq_succ_mep_constSeq, seq_pred_mep_SR, seq_succ_mep_SR,  ...
    clusterSplitRecord_befS2, tableCompo_mep2_befS2, seq_pred_mep_constSeq_befS2, seq_succ_mep_constSeq_befS2, ...
    seq_pred_mep_SR_befS2, seq_succ_mep_SR_befS2, toCreateNewSub, clusterSplitRecord] = ...
    func_mepSeq_handleNoInterclusterConflictCompo ...
    (tableCompo_mep2, clusterName_new, clusterSplitRecord, ...
    M_clusterSeq_befSplit, tableAllCompo_whenSplitting, ...
    seq_pred_mep_constSeq, seq_succ_mep_constSeq, seq_pred_mep_SR, seq_succ_mep_SR)
%% SEQ MEP STEP 6: Find the (sub)cluster number for each component
tableCompo_mep2.ClusterNew = repmat(" ", [height(tableCompo_mep2), 1]);

% find the clusters in clusterName_new which have been split -- TO CHECK!
% and update only those cluster names in tableCompo_mep2{:, "ClusterNew"}
% i.e. only write those 5-1, 5-2, 5-3, 8-1 to 8-4, ..., into tableCompo_mep2, and no 4, 6, ...
% otherwise, those compo with 4, 6, ... in tableCompo_mep2{:, "ClusterNew"} will not be considered
%       when dealling with scenario 1 & 2 next; they have SSR/CSR, but can be dealt with as non-SSR/CSR


for i = 1:length(clusterName_new)
    
    %if contains(clusterName_new(i), "_")  % find the clusters in clusterName_new which have been split
                                          % and update only those cluster names in tableCompo_mep2{:, "ClusterNew"}
        toSelect = tableAllCompo_whenSplitting{:, "Cluster1"} == clusterName_new(i);
        % r = find(toSelect > 0);
        toSelectCompoIdx = tableAllCompo_whenSplitting{toSelect, "Compo1"};

        tableCompo_mep2{toSelectCompoIdx, "ClusterNew"} = clusterName_new(i);

        toSelect = tableAllCompo_whenSplitting{:, "Cluster2"} == clusterName_new(i);
        % r = find(toSelect > 0);
        toSelectCompoIdx = tableAllCompo_whenSplitting{toSelect, "Compo2"};
        tableCompo_mep2{toSelectCompoIdx, "ClusterNew"} = clusterName_new(i);
    %end
end

% for those compo not appearing in conflict, thus not in (sub)clusters in tableAllCompo_whenSplitting
% UPDATE1109: when assigning compo with no SSR or CSR:
% scenario 1: have SSR/CSR and conflicting (M1<-two way->M2), i.e. have a pair which satisfies M1->M2
%                                                             so, find the pair of (sub)clusters and assign to them
% scenario 2: have SSR/CSR and non-conflicting, but diff from const. seq. (M1<-M2 from SSR/CSR but M1->M2 from const. seq.),
%                                                             i.e. no subclusters have M1x->M2y
%                                                             so, create new pairs of (sub)clusters and assign to them

% identify all pairs in scenario 2 first, and update everything necessary
% then assign non-SSR/CSR compo based on scenario 2
% and then deal with scenario 1

% scenario 2 - identify all pairs in scenario 2 first
% what to update, if new subclusters are created:
% clusterSplitRecord, tableCompo_mep2, seq_pred_mep_constSeq, seq_succ_mep_constSeq
% toCreateNewSub_pred/succ: indices of clusters are before splitting/flattening
toCreateNewSub_pred = zeros(size(clusterSplitRecord,1)*(size(clusterSplitRecord,1)-1), 1);
toCreateNewSub_succ = zeros(size(clusterSplitRecord,1)*(size(clusterSplitRecord,1)-1), 1);
for r = 1:size(M_clusterSeq_befSplit, 1)
    for c = 1:size(M_clusterSeq_befSplit, 1)
        % flatten the indices, i.e. change cluster indices from 1, 2, 3-1, 3-2, 4,... to 1,2,3,4,5,...
        % i.e. change cluster indices from r, c to r_flat, c_flat
        if r == 1
            r_flat_base = 1;
        else
            r_flat_base = sum(clusterSplitRecord(1:r-1, 2), 'all') + 1;
        end
        if c == 1
            c_flat_base = 1;
        else
            c_flat_base = sum(clusterSplitRecord(1:c-1, 2), 'all') + 1;
        end
        for rii = 1:clusterSplitRecord(r, 2)  % to cover all subclusters if there is more than one
            for cii = 1:clusterSplitRecord(c, 2)
                r_flat = r_flat_base + rii-1;
                c_flat = c_flat_base + cii-1;

                % check if there is r2c prec from const. seq.
                % e.g. if r=5, c=2, there is prec from const. seq; then if r=2, c=5, there is no prec from const. seq
                toSelect1 = seq_pred_mep_constSeq == r_flat & seq_succ_mep_constSeq == c_flat;
                constSeq_r2c = false;
                if sum(toSelect1,'all') > 0
                    r2c = true;  % if pred is subcluster r_flat from const. seq.
                    constSeq_r2c = true;
                end
                % check if there is prec from SSR/CSR and they are non-/conflicting (M1<-one or two way->M2)
                srSeq_2way = false;
                srSeq_1way_r2c = false;
                srSeq_1way_c2r = false;
                if M_clusterSeq_befSplit(r, c) > 0 && M_clusterSeq_befSplit(c, r) > 0
                    srSeq_2way = true;
                elseif M_clusterSeq_befSplit(r, c) > 0 && M_clusterSeq_befSplit(c, r) == 0
                    srSeq_1way_r2c = true;
                elseif M_clusterSeq_befSplit(r, c) == 0 && M_clusterSeq_befSplit(c, r) > 0
                    srSeq_1way_c2r = true;    
                end

                if constSeq_r2c == true && srSeq_1way_r2c == true % scenario 2 satisfied
                    % record the cluster pair that satisfy scenario 2
                    toCreateNewSub_pred((r-1) * size(clusterSplitRecord,1) + c) = r;
                    toCreateNewSub_succ((r-1) * size(clusterSplitRecord,1) + c) = c;
                end
                if constSeq_r2c == true && srSeq_1way_c2r == true % scenario 2 satisfied
                    % record the cluster pair that satisfy scenario 2
                    toCreateNewSub_pred((r-1) * size(clusterSplitRecord,1) + c) = c;
                    toCreateNewSub_succ((r-1) * size(clusterSplitRecord,1) + c) = r;
                end
            end
        end
    end
end
toCreateNewSub_pred = toCreateNewSub_pred(~all(toCreateNewSub_pred == 0, 2),:)';  % delete the empty elements
toCreateNewSub_succ = toCreateNewSub_succ(~all(toCreateNewSub_succ == 0, 2),:)';

% scenario 2 - create new subclusters, and update what's necessary:
% clusterSplitRecord, tableCompo_mep2, seq_pred_mep_constSeq, seq_succ_mep_constSeq
% seq_pred_mep_SR, seq_succ_mep_SR
clusterSplitRecord_befS2 = clusterSplitRecord;
tableCompo_mep2_befS2 = tableCompo_mep2;
seq_pred_mep_constSeq_befS2 = seq_pred_mep_constSeq;
seq_succ_mep_constSeq_befS2 = seq_succ_mep_constSeq;
seq_pred_mep_SR_befS2 = seq_pred_mep_SR;
seq_succ_mep_SR_befS2 = seq_succ_mep_SR;
toCreateNewSub = [toCreateNewSub_pred, toCreateNewSub_succ];
for toUpdate = 1:length(toCreateNewSub)
    clusterSplitRecord(toCreateNewSub(toUpdate), 2) = clusterSplitRecord(toCreateNewSub(toUpdate), 2) + 1;
    % create a new subcluster with the largest idx among all subclusters
%     newSubpred_idx_flat = toCreateNewSub_pred(toUpdate);  % the unflattened idx of the cluster
    newSub_idx_flat = sum(clusterSplitRecord(1:toCreateNewSub(toUpdate), 2), 'all');  % the flattened idx of the new subcluster
    % to update the (sub)cluster number in all pred & succ arrays
    toSelect = seq_pred_mep_constSeq >= newSub_idx_flat;
    seq_pred_mep_constSeq(toSelect) = seq_pred_mep_constSeq(toSelect) + 1;    
    toSelect = seq_succ_mep_constSeq >= newSub_idx_flat;
    seq_succ_mep_constSeq(toSelect) = seq_succ_mep_constSeq(toSelect) + 1;    
    toSelect = seq_pred_mep_SR >= newSub_idx_flat;
    seq_pred_mep_SR(toSelect) = seq_pred_mep_SR(toSelect) + 1;   
    toSelect = seq_succ_mep_SR >= newSub_idx_flat;
    seq_succ_mep_SR(toSelect) = seq_succ_mep_SR(toSelect) + 1;
    
    % to add the newly created subcluster number to constSeq pred & succ arrays
    % (and some subcluster numbers will be deleted from the arrays later)
    % find all pred & succ pairs containing the toCreateNewSub_pred(toUpdate),
    % and duplicate all of them, with toCreateNewSub_pred(toUpdate) changed to toCreateNewSub_pred(toUpdate)+1
    seq_pred_mep_constSeq_toAdd = zeros(1, 2*length(seq_pred_mep_constSeq));
    seq_succ_mep_constSeq_toAdd = zeros(1, 2*length(seq_pred_mep_constSeq));
    % if pred array contains the toCreateNewSub_pred(toUpdate)
    toSelect1 = seq_pred_mep_constSeq == newSub_idx_flat - 1;
    seq_pred_mep_constSeq_toAdd(toSelect1) = newSub_idx_flat;
    seq_succ_mep_constSeq_toAdd(toSelect1) = seq_succ_mep_constSeq(toSelect1);
    % if succ array contains the toCreateNewSub_pred(toUpdate)
    toSelect2 = false(1, 2*length(seq_pred_mep_constSeq));
    toSelect2(length(seq_pred_mep_constSeq)+1:end) = seq_succ_mep_constSeq == newSub_idx_flat - 1;
    seq_succ_mep_constSeq_toAdd(toSelect2) = newSub_idx_flat;
    seq_pred_mep_constSeq_toAdd(toSelect2) = ...
        seq_pred_mep_constSeq(toSelect2(length(seq_pred_mep_constSeq)+1:end));
    % delete the empty elements
    seq_pred_mep_constSeq_toAdd = seq_pred_mep_constSeq_toAdd(:, ~all(seq_pred_mep_constSeq_toAdd == 0, 1)); 
    seq_succ_mep_constSeq_toAdd = seq_succ_mep_constSeq_toAdd(:, ~all(seq_succ_mep_constSeq_toAdd == 0, 1));
    % delete the original pairs
    % e.g. (flattened) original: 4 -> 8; newly added: 4 -> 9; so should delete 4 -> 8
    seq_pred_mep_constSeq(toSelect1 | toSelect2(length(seq_pred_mep_constSeq)+1:end)) = [];
    seq_succ_mep_constSeq(toSelect1 | toSelect2(length(seq_succ_mep_constSeq)+1:end)) = [];
    % add to the constSeq pred & succ arrays
    seq_pred_mep_constSeq = [seq_pred_mep_constSeq, seq_pred_mep_constSeq_toAdd];  % inefficient
    seq_succ_mep_constSeq = [seq_succ_mep_constSeq, seq_succ_mep_constSeq_toAdd];  % inefficient

end

% scenario 2 - assign non-SSR/CSR compo to newly created subclusters
for toUpdate = 1:length(toCreateNewSub_pred)
    r = toCreateNewSub_pred(toUpdate);
    c = toCreateNewSub_succ(toUpdate);
    toSelect_r = tableCompo_mep2{:, "ClusterNumber"} == r & tableCompo_mep2{:, "ClusterNew"} == " ";
    toSelect_c = tableCompo_mep2{:, "ClusterNumber"} == c & tableCompo_mep2{:, "ClusterNew"} == " ";
    tableCompo_mep2{toSelect_r, "ClusterNew"} = strcat(num2str(r), "_", num2str(clusterSplitRecord(r, 2)));
    tableCompo_mep2{toSelect_c, "ClusterNew"} = strcat(num2str(c), "_", num2str(clusterSplitRecord(c, 2))); 
end






% scenario 1
for r = 1:size(M_clusterSeq_befSplit, 1)
    for c = 1:size(M_clusterSeq_befSplit, 1)
        % flatten the indices, i.e. change cluster indices from 1, 2, 3-1, 3-2, 4,... to 1,2,3,4,5,...
        % i.e. change cluster indices from r, c to r_flat, c_flat
        if r == 1
            r_flat_base = 1;
        else
            r_flat_base = sum(clusterSplitRecord(1:r-1, 2), 'all') + 1;
        end
        if c == 1
            c_flat_base = 1;
        else
            c_flat_base = sum(clusterSplitRecord(1:c-1, 2), 'all') + 1;
        end
        for rii = 1:clusterSplitRecord(r, 2)  % to cover all subclusters if there is more than one
            for cii = 1:clusterSplitRecord(c, 2)
                r_flat = r_flat_base + rii-1;
                c_flat = c_flat_base + cii-1;

                % check if there is r2c prec from const. seq.
                % e.g. if r=5, c=2, there is prec from const. seq; then if r=2, c=5, there is no prec from const. seq
                toSelect1 = seq_pred_mep_constSeq == r_flat & seq_succ_mep_constSeq == c_flat;
                constSeq_r2c = false;
                if sum(toSelect1,'all') > 0
                    r2c = true;  % if pred is subcluster r_flat from const. seq.
                    constSeq_r2c = true;
                % else
                %     toSelect2 = seq_pred_mep_constSeq == r_flat & seq_succ_mep_constSeq == c_flat;
                %     if sum(toSelect2,'all') > 0
                %         r2c = false;  % if pred is subcluster c_flat from const. seq.
                %         constSeq_r2c = true;
                %     end
                end
                % check if there is prec from SSR/CSR and they are non-/conflicting (M1<-one or two way->M2)
                srSeq_2way = false;
                srSeq_1way_r2c = false;
                srSeq_1way_c2r = false;
                if M_clusterSeq_befSplit(r, c) > 0 && M_clusterSeq_befSplit(c, r) > 0
                    srSeq_2way = true;
                elseif M_clusterSeq_befSplit(r, c) > 0 && M_clusterSeq_befSplit(c, r) == 0
                    srSeq_1way_r2c = true;
                elseif M_clusterSeq_befSplit(r, c) == 0 && M_clusterSeq_befSplit(c, r) > 0
                    srSeq_1way_c2r = true;    
                end

                % scenario 1: have SSR/CSR and conflicting (M1<-two way->M2), i.e. have a pair which satisfies M1->M2
                %                                                             so, find the pair of (sub)clusters and assign to them
                if constSeq_r2c == true && srSeq_2way == true  % scenario 1 satisfied
                    % find the (sub)cluster pair which satisfies the const. seq.: toAssign_pred_flat -> toAssign_succ_flat
                    % if r2c == true  % if pred is subcluster r_flat from const. seq.
                    %     toAssign_pred_flat = seq_pred_mep_constSeq(toSelect1);
                    %     toAssign_succ_flat = seq_succ_mep_constSeq(toSelect1);
                    % elseif r2c == false  % if pred is subcluster c_flat from const. seq.
                    %     toAssign_pred_flat = seq_pred_mep_constSeq(toSelect2);
                    %     toAssign_succ_flat = seq_succ_mep_constSeq(toSelect2);
                    % end
                    
                    % find and assign the non-SSR/CSR compo
                    toSelect_r = tableCompo_mep2{:, "ClusterNumber"} == r & tableCompo_mep2{:, "ClusterNew"} == " ";
                    toSelect_c = tableCompo_mep2{:, "ClusterNumber"} == c & tableCompo_mep2{:, "ClusterNew"} == " ";
                    tableCompo_mep2{toSelect_r, "ClusterNew"} = strcat(num2str(clusterSplitRecord(r, 1)), "_", num2str(rii));
                    tableCompo_mep2{toSelect_c, "ClusterNew"} = strcat(num2str(clusterSplitRecord(c, 1)), "_", num2str(cii));
                end
                
            end
        end
    end
end
   
% assign the rest of non-SSR/CSR compo (not satisfying scenario 1 or 2) to (sub)clusters
for i = 1:size(clusterSplitRecord, 1)  % the num of the original cluster before splitting
    toSelect_noClusterNumYet = tableCompo_mep2{:, "ClusterNumber"} == i & ...
        tableCompo_mep2{:, "ClusterNew"} == " ";
    
    % should not blindly assign all non-SSR/CSR compo to the last (sub)cluster:
    % if the cluster is split in the second round (when dealing with scenario 1 & 2), 
    %       then add to the last (sub)cluster
    % if the cluster is split in the first round (before dealing with scenario 1 & 2), 
    %       then add to the most reasonable subcluster:
    %       a subcluster which does not have opposite seq from constSeq and SR
    %       e.g. if 5_2 -> 6 and 6 ->5_3 from SR, and 5 -> 6 from constSeq, then should add to 5_2 and not 5_3
    
    % if the cluster is split in the second round (when dealing with scenario 1 & 2)
    toSelect_splitIn2ndRound = clusterSplitRecord_befS2(i, 2) == 1;  % bool
    toSelect2 = toSelect_noClusterNumYet & toSelect_splitIn2ndRound;
    tableCompo_mep2{toSelect2, "ClusterNew"} = strcat(num2str(i), "_", num2str(clusterSplitRecord(i, 2)));
    
    % if the cluster is split in the first round (before dealing with scenario 1 & 2)
    toSelect_splitIn1stRound = clusterSplitRecord_befS2(i, 2) > 1;  % bool
    toSelect1 = toSelect_noClusterNumYet & toSelect_splitIn1stRound;
    % check which subcluster to assign the compo to
    if i == 1
        i_flat_base = 1;
    else
        i_flat_base = sum(clusterSplitRecord(1:i-1, 2), 'all') + 1;
    end
    for ii = 1:clusterSplitRecord(i, 2)
        i_flat = i_flat_base + ii-1;
        % check if there is opposite seq from constSeq and SR, with any other (sub)cluster j_jj
        jump2nextIteration = false;
        for j = 1:size(clusterSplitRecord, 1)
            if j == 1
                j_flat_base = 1;
            else
                j_flat_base = sum(clusterSplitRecord(1:j-1, 2), 'all') + 1;
            end
            for jj = 1:clusterSplitRecord(i, 2)
                j_flat = j_flat_base + jj-1;
            % if there is opposite seq from constSeq and SR
                if (any(seq_pred_mep_constSeq == i_flat) && any(seq_succ_mep_constSeq == j_flat)) && ...
                        (any(seq_succ_mep_SR == i_flat) && any(seq_pred_mep_SR == j_flat))
                    jump2nextIteration = true;  % jump to the next iteration
                elseif (any(seq_pred_mep_constSeq == j_flat) && any(seq_succ_mep_constSeq == i_flat)) && ...
                        (any(seq_succ_mep_SR == j_flat) && any(seq_pred_mep_SR == i_flat))
                    jump2nextIteration = true;  % jump to the next iteration
                end
            end
        end
        if jump2nextIteration == false
            tableCompo_mep2{toSelect1, "ClusterNew"} = strcat(num2str(i), "_", num2str(ii));
        end
    end
end


% deal with the "ClusterNew" in "(number)" form, e.g. change "7" to "7_1"
% (compo taking "7" form: have prec with other compo, but cluster is not split)
for i = 1:size(clusterSplitRecord, 1)
    toSelect = strcmp(tableCompo_mep2{:, "ClusterNew"}, string(clusterSplitRecord(i, 1)));
    tableCompo_mep2{toSelect, "ClusterNew"} = strcat(num2str(clusterSplitRecord(i, 1)), "_1");
end




% the flattened (sub)cluster number in seq_pred_mep_constSeq: general construction sequence
% but are not always satisfied
% e.g. not 5_1 -> 8, 5_2 -> 8, 5_3 -> 8, but 5_3 -> 8 only
% so, should find where the non-SSR/CSR compo are assigned to (likely the largest subcluster)
% and use only those sub)cluster number in the optimisation problem
% precedence from construction seq.
for i = 1:size(clusterSplitRecord, 1) 
    % if the cluster is split in the first round (before dealing with scenario 1 & 2)
    % then delete its appearance, from seq_pred_mep_constSeq and seq_succ_mep_constSeq
    if clusterSplitRecord_befS2(i, 2) > 1  % those that will be deleted
        % find the flattened number of those that will be deleted
        if i == 1
            i_flat_base = 1;
        else
            i_flat_base = sum(clusterSplitRecord(1:i-1, 2), 'all');
        end
        for ii = 1:clusterSplitRecord(i, 2)
            i_flat = i_flat_base + ii;
            % to delete the appearance from seq_pred_mep_constSeq and seq_succ_mep_constSeq
            toSelect = seq_pred_mep_constSeq == i_flat;
            seq_pred_mep_constSeq(toSelect) = [];
            seq_succ_mep_constSeq(toSelect) = [];
            toSelect = seq_succ_mep_constSeq == i_flat;
            seq_pred_mep_constSeq(toSelect) = [];
            seq_succ_mep_constSeq(toSelect) = [];
        end
    end
end