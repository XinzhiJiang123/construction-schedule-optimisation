function tableActivity = func_mapCompoAndDatabase(tableDatabase, tableActivity, ...
    matList, matCode, classList, classCode, newVarNames)

dbCode = repmat("", height(tableActivity), 1);

% check the class ------------------------------
for class = 1:length(classList)
    toSelect = tableActivity{:,'Class'} == classList(class);
    dbCode(toSelect,1) = classCode(class);
end
% check the material ------------------------------
for mat = 1:length(matList)
    toSelect = tableActivity{:,'C_Material'} == matList(mat);
    dbCode(toSelect,1) = strcat(dbCode(toSelect,1), matCode(mat), "_");
end
% check the floor level ------------------------------
toSelect1 = contains(tableActivity{:,'BaseLevel'},"-1",'IgnoreCase',true);
dbCode(toSelect1,1) = strcat(dbCode(toSelect1,1), "ug_");
toSelect2 = contains(tableActivity{:,'BaseLevel'},"00",'IgnoreCase',true);
dbCode(toSelect2,1) = strcat(dbCode(toSelect2,1), "0f_");
toSelect = ~(toSelect1 | toSelect2);
dbCode(toSelect,1) = strcat(dbCode(toSelect,1), "1f_");  % no distinction among floors above 0F
% check the size ------------------------------
for i = 1:height(tableActivity)
size_sorted = sort([tableActivity{i,'Size_X'},tableActivity{i,'Size_Y'},tableActivity{i,'Size_Z'}],'ascend');
    tableRows = tableDatabase(contains(tableDatabase{:,'Code'},dbCode(i,1),'IgnoreCase',false), :);
    for j = 1:height(tableRows)
        % when the smallest and the largest dimensions fall into a specific size category
        % here, alternatively: size_sorted(2) <= tableRows{j,'MaxSize_1'}
        if size_sorted(1) <= tableRows{j,'MaxSize_1'} && size_sorted(3) <= tableRows{j,'MaxSize_3'} 
            dbCode(i,1) = strcat(dbCode(i,1), string(tableRows{j,'SizeCategory'}));
            break
        end
    end
end    

tableActivity.Code = dbCode;

% Map the activities with the database, using activity code
for i = 1:height(tableDatabase)
    row_codeMatched = contains(dbCode,tableDatabase{i,'Code'},'IgnoreCase',false);
    for j = 2:length(newVarNames)  % without "AtomActName""(j=1)
        tableActivity{row_codeMatched, newVarNames(j)} = tableDatabase{i, newVarNames(j)};
    end
end