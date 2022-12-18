function [tableZoned_mep_splitted, clusterName_new_new] = ...
    func_mepSeq_createTableZoned_mep ...
    (tableZoned_mep2, tableCompo_mep2, tableActivity_mep, clusterSplitRecord, ...
    nR, nM, nAllEleGuid)
%% Write a new tableZoned_splitted, with cost and duration data and compo index
varNames = ["ClusterNumNew", "ActName", "Class", "Floor", "Zone", "SubFloor", repmat(" ", 1, nR*(1+3*nM))];
varTypes = ["string", "string", "categorical", "double", "double", "string", repmat(" ", 1, nR*(1+3*nM))];
for res = 1:nR
    varNames(6 + (res-1)*(1+3*nM) + 1) = strcat("Resource_", num2str(res));
    varTypes(6 + (res-1)*(1+3*nM) + 1) = "string";
    for m = 1:nM
        varNames(6 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 1) = strcat("Res", num2str(res), "Mode", num2str(m));
        varNames(6 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 2) = strcat("TotalCost_r", num2str(res), "m", num2str(m));
        varNames(6 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 3) = strcat("Dura_r", num2str(res), "m", num2str(m));
        varTypes(6 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 1) = "string";
        varTypes(6 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 2) = "double";
        varTypes(6 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 3) = "double";
    end
end
tableZoned_mep_splitted = table('Size',[sum(clusterSplitRecord(:,2),'all') length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);


% update clusterName (not the same as the ones right after splitting, but with extra subclusters from non-SSR/CSR compo)
clusterName_new_new = repmat(" ", 1, sum(clusterSplitRecord(:,2),'all'));
for i = 1:size(clusterSplitRecord, 1)
    if i == 1
        i_flat_base = 1;
    else
        i_flat_base = sum(clusterSplitRecord(1:i-1, 2), 'all') + 1;
    end
    for ii = 1:clusterSplitRecord(i, 2)  % to cover all subclusters if there is more than one
        i_flat = i_flat_base + ii - 1;
        clusterName_new_new(i_flat) = strcat(num2str(i), "_", num2str(ii));
    end
end
tableZoned_mep_splitted.ClusterNumNew = clusterName_new_new';


% % deal with the "ClusterNew" in "(number)" form, e.g. change "7" to "7_1"
% % (compo taking "7" form: have prec with other compo, but cluster is not split)
% for i = 1:size(clusterSplitRecord, 1)
%     toSelect = strcmp(tableZoned_mep_splitted{:, "ClusterNumNew"}, string(clusterSplitRecord(i, 1)));
%     tableZoned_mep_splitted{toSelect, "ClusterNew"} = strcat(num2str(clusterSplitRecord(i, 1)), "_1");
% end

% write data into the new table
for i = 1:size(clusterSplitRecord, 1)  % the num of the original cluster before splitting
%     toSelect = tableCompo2{:, "ClusterNumber"} == clusterSplitRecord(i, 1) & ...
    if i == 1
        count = 1;
    else
        count = sum(clusterSplitRecord(1:i-1, 2), 'all') + 1;
    end
    if clusterSplitRecord(i, 2) > 1  % there is not one cluster but >= 2 subclusters
        for r = 1:clusterSplitRecord(i, 2)
            tableZoned_mep_splitted{count+r-1, "ActName"} = tableZoned_mep2{i, "ActName"};
            tableZoned_mep_splitted{count+r-1, "Class"} = tableZoned_mep2{i, "Class"};
            tableZoned_mep_splitted{count+r-1, "Floor"} = tableZoned_mep2{i, "Floor"};
            tableZoned_mep_splitted{count+r-1, "Zone"} = tableZoned_mep2{i, "Zone"};
        end
    else  % there is only one cluster, i.e. not splitted
        tableZoned_mep_splitted{count, "ClusterNumNew"} = strcat(num2str(i), "_1");
        tableZoned_mep_splitted{count, "ActName"} = tableZoned_mep2{i, "ActName"};
        tableZoned_mep_splitted{count, "Class"} = tableZoned_mep2{i, "Class"};
        tableZoned_mep_splitted{count, "Floor"} = tableZoned_mep2{i, "Floor"};
        tableZoned_mep_splitted{count, "Zone"} = tableZoned_mep2{i, "Zone"};
    end
end


% update the cost and duration data in tableZoned_splitted
recordClusterContainCompoIdx = zeros(height(tableZoned_mep_splitted), height(tableCompo_mep2));  % may save more time than cat'íng
for i = 1:length(clusterName_new_new)
    toSelect = tableCompo_mep2{:, "ClusterNew"} == clusterName_new_new(i);
    
    % update the name of resources and modes
    if sum(toSelect, 'all') ~= 0
        for res = 1:nR
            for m = 1:nM
                tableZoned_mep_splitted{i, strcat("Resource_", string(res))} = ...
                    tableActivity_mep{toSelect(find(toSelect == 1, 1)), strcat("Resource_", string(res))};
                tableZoned_mep_splitted{i, strcat("Res", string(res), "Mode", string(m))} = ...
                    tableActivity_mep{toSelect(find(toSelect == 1, 1)), strcat("Res", string(res), "Mode", string(m))};
            end
        end
    end
    
    for res = 1:nR
        for m = 1:nM
            tableZoned_mep_splitted{i, strcat("TotalCost_r", num2str(res), "m", num2str(m))} = ...
                tableZoned_mep_splitted{i, strcat("TotalCost_r", num2str(res), "m", num2str(m))} ...
                + sum(tableActivity_mep{toSelect, strcat("Cost_r", num2str(res), "m", num2str(m))}, 'all');
            tableZoned_mep_splitted{i, strcat("Dura_r", num2str(res), "m", num2str(m))} = ...
                tableZoned_mep_splitted{i, strcat("Dura_r", num2str(res), "m", num2str(m))} ...
                + sum(tableActivity_mep{toSelect, strcat("Eff_r", num2str(res), "m", num2str(m))}, 'all');
        end
    end
end

% update the compo index in tableZoned_splitted
% nAllEleGuid = 20;
for nGuid = 1:nAllEleGuid
    tableZoned_mep_splitted{:, ['AllEleGuid',num2str(nGuid)]} = repmat(" ", height(tableZoned_mep_splitted), 1);
end

for cluster = 1:length(clusterName_new_new)
    toSelect = find(tableCompo_mep2{:, "ClusterNew"} == clusterName_new_new(cluster));  % all indices of compo in that cluster
    for i = 1:length(toSelect)
        idx = toSelect(i);   
        for nGuid = 1:nAllEleGuid
            if strlength(tableZoned_mep_splitted{cluster,['AllEleGuid',num2str(nGuid)]}) <= 230
                if idx <= 9   % to keep the same length of the index number
                    tableZoned_mep_splitted{cluster,['AllEleGuid',num2str(nGuid)]} = ...
                        strcat(tableZoned_mep_splitted{cluster,['AllEleGuid',num2str(nGuid)]}, "0000", num2str(idx),", ");
                elseif idx <= 99
                    tableZoned_mep_splitted{cluster,['AllEleGuid',num2str(nGuid)]} = ...
                        strcat(tableZoned_mep_splitted{cluster,['AllEleGuid',num2str(nGuid)]}, "000", num2str(idx),", ");
                elseif idx <= 999
                    tableZoned_mep_splitted{cluster,['AllEleGuid',num2str(nGuid)]} = ...
                        strcat(tableZoned_mep_splitted{cluster,['AllEleGuid',num2str(nGuid)]}, "00", num2str(idx),", ");
                elseif idx <= 9999
                    tableZoned_mep_splitted{cluster,['AllEleGuid',num2str(nGuid)]} = ...
                        strcat(tableZoned_mep_splitted{cluster,['AllEleGuid',num2str(nGuid)]}, "0", num2str(idx),", ");
                else
                    tableZoned_mep_splitted{cluster,['AllEleGuid',num2str(nGuid)]} = ...
                        strcat(tableZoned_mep_splitted{cluster,['AllEleGuid',num2str(nGuid)]}, num2str(idx),", ");
                end
                break
            end
        end
    end
end
