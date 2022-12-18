function [tableZoned_mep, tableActivity_mep, nZ, nClass_mep, compoClass_mep] ...
    = func_createTableZoned_mep_empty ...
    (tableActivity_mep, building_x_max, building_x_min, building_y_max, building_y_min, ...
    Zx, Zy, nLevel, nR, nM, bottom2top_bool, left2right_bool, verticleDirFirst_bool) 
% varNames = ["ActName", "Class", "Floor", "Zone", "Resource_1", ...
%     "Res1Mode1", "TotalCost_r1m1", "Dura_r1m1", "Res1Mode2", "TotalCost_r1m2", "Dura_r1m2", ...
%     "Resource_2", ...
%     "Res2Mode1", "TotalCost_r2m1", "Dura_r2m1", "Res2Mode2", "TotalCost_r2m2", "Dura_r2m2"];

varNames = ["ActName", "Class", "Floor", "Zone", repmat(" ", 1, nR*(1+3*nM))];
varTypes = ["string", "categorical", "double", "double", repmat(" ", 1, nR*(1+3*nM))];
for res = 1:nR
    varNames(4 + (res-1)*(1+3*nM) + 1) = strcat("Resource_", num2str(res));
    varTypes(4 + (res-1)*(1+3*nM) + 1) = "string";
    for m = 1:nM
        varNames(4 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 1) = strcat("Res", num2str(res), "Mode", num2str(m));
        varNames(4 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 2) = strcat("TotalCost_r", num2str(res), "m", num2str(m));
        varNames(4 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 3) = strcat("Dura_r", num2str(res), "m", num2str(m));
        varTypes(4 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 1) = "string";
        varTypes(4 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 2) = "double";
        varTypes(4 + (res-1)*(1+3*nM) + 1 + (m-1)*3 + 3) = "double";
    end
end

% to create tableZoned
nZ_x = ceil((building_x_max - building_x_min)/Zx);  % round upwards
nZ_y = ceil((building_y_max - building_y_min)/Zy);
nZ = nZ_x * nZ_y;  


% create a table containing activity clusters (before splitting):  
compoClass_mep = categorical(["Flow segment"]);
nClass_mep = size(compoClass_mep,2);   % type of activities; only flow segment here
nA_mep = nZ * (nLevel) * nClass_mep;  % UPDATED0909 ----------------------------------------------
% tablesz_mep = [nA_mep length(varNames)];
tableZoned_mep = table('Size',[nA_mep length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);
% Find zone number for each activity and write into tableActivity
[tableActivity_mep, tableZoned_mep] = func_findZoneNumForCompoTable_mep(tableActivity_mep, tableZoned_mep, ...
    building_x_min, building_y_min, building_x_max, building_y_max, ...
    Zx, Zy, nZ_x, nZ_y, nZ, nClass_mep, nLevel, compoClass_mep,...
    bottom2top_bool, left2right_bool, verticleDirFirst_bool);       % TO CHECK AND COMPLETE THE SCENARIOS!!!

