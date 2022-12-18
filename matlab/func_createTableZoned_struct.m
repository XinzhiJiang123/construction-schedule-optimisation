function [tableZoned_struct, tableActivity_struct, nA_struct, nZ] = func_createTableZoned_struct(tableActivity_struct, tableCompo_struct, ...
    building_x_max, building_x_min, building_y_max, building_y_min, ...
    Zx, Zy, nLevel, nAllEleGuid, nR, nM, ...
    SpecSeqName, SpecSeqName_class, SpecSeqName_countNonUndefined, ...
    bottom2top_bool, left2right_bool, verticleDirFirst_bool) 
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
% (will move to a later callback)  
nZ_x = ceil((building_x_max - building_x_min)/Zx);  % round upwards
nZ_y = ceil((building_y_max - building_y_min)/Zy);
nZ = nZ_x * nZ_y;  
% specify from which corner and in which direction the construction starts
% bottom2top_bool = 1;
% left2right_bool = 1;
% verticleDirFirst_bool = 1;

% Change the class of all roofs to slabs, to treat them as slabs when zoning
isInClass = tableActivity_struct{:,'Class'} == 'Roof';
tableActivity_struct{isInClass, 'Class'} = categorical("Slab");
% Exclude roof and pile from the list of struct classes (the list will be used to create rows in tableZoned)
% Rows for piles will be created separately in tableZoned
compoClass_struct = unique(tableCompo_struct.Class)';
compoClass_struct = compoClass_struct(compoClass_struct ~= categorical("Roof"));
compoClass_struct = compoClass_struct(compoClass_struct ~= categorical("Pile"));


nClass_struct = size(compoClass_struct,2);   % type of activities; column and beam here
nA_struct_woFound = nZ * (nLevel-1) * nClass_struct;  
tableZoned_struct = table('Size',[nA_struct_woFound length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);


% (will move to a later callback)            
% Find zone number for each activity and write into tableActivity
[tableActivity_struct, tableZoned_struct]  = func_findZoneNumForCompoTable_struct ...
    (tableActivity_struct, tableZoned_struct, ...
    building_x_min, building_y_min, building_x_max, building_y_max, ...
    Zx, Zy, nZ_x, nZ_y, nZ, nClass_struct, nLevel, compoClass_struct, ...
    bottom2top_bool, left2right_bool, verticleDirFirst_bool);

% Add non-regular act clusters to tableZoned: foundation, and those compo with SpecSeqName
% Add foundation to tableZoned_struct: nZ number of activities
tableZoned_struct_toAddSpecial = tableZoned_struct(1:nZ, :);
tableZoned_struct_toAddSpecial{:, 'Class'} = repmat(categorical("Pile"), nZ, 1);
for zone = 1:nZ
    tableZoned_struct_toAddSpecial{zone,'ActName'} = strcat("Foundation_Fug_Z",num2str(zone));
    tableZoned_struct_toAddSpecial{zone,'Zone'} = zone;
    tableZoned_struct_toAddSpecial{zone,'Floor'} = -1;
end
tableZoned_struct = [tableZoned_struct_toAddSpecial; tableZoned_struct];

% (will move to a later callback)
% Add compo with SpecSeqName to tableZoned_struct: nZ*nSpecSeqName number of activities
tableZoned_struct_toAddSpecial = tableZoned_struct(1:nZ*SpecSeqName_countNonUndefined, :);
tableZoned_struct_toAddSpecial{:, 'Class'} = repmat(categorical("NA"), nZ, 1);
for nSpec = 1:length(SpecSeqName) 
    for zone = 1:nZ   
        tableZoned_struct_toAddSpecial{nZ*(length(SpecSeqName)-1)+zone,'Class'} = ...
            SpecSeqName_class(nSpec);
        tableZoned_struct_toAddSpecial{nZ*(length(SpecSeqName)-1)+zone,'ActName'} = ...
            strcat(string(SpecSeqName(nSpec)), "_Z", num2str(zone));
        tableActivity_struct{nZ*(length(SpecSeqName)-1)+zone,'Zone'} = zone;
        tableZoned_struct_toAddSpecial{nZ*(length(SpecSeqName)-1)+zone,'Floor'} = ...
            0;  % does not matter, seq will be overwritten by special rules later
    end
end
tableZoned_struct = [tableZoned_struct; tableZoned_struct_toAddSpecial];

nA_struct = (nZ + nZ*SpecSeqName_countNonUndefined) + nA_struct_woFound;





%% For tableZoned_struct: update the cost, dura data, and compo index
%nAllEleGuid = 20;
for nGuid = 1:nAllEleGuid
    tableZoned_struct{:, ['AllEleGuid',num2str(nGuid)]} = repmat(" ", height(tableZoned_struct), 1);
end

for i = 1:height(tableActivity_struct)  % (inefficient)

    % Case 1: if it has SpecSeqName
    flagToBreak = 0;  % if it has SpecSeqName, then flagToBreak is changed to 1
    for nSpec = 1:length(SpecSeqName) 
        if isundefined(tableActivity_struct{i, strcat("SpecSeqName", num2str(nSpec))}) == 0
            flagToBreak = 1;
            for z = 1:nZ       
                if tableActivity_struct{i,'Zone'} == z
                    loc = nZ + nA_struct_woFound + nZ*(length(SpecSeqName)-1) + z;

                    for res = 1:nR
                        tableZoned_struct{loc, strcat("Resource_", num2str(res))} = ...
                        tableActivity_struct{i, strcat("Resource_", num2str(res))};
                        for m = 1:nM
                            tableZoned_struct{loc, strcat("Res", num2str(res), "Mode", num2str(m))} = ...
                                tableActivity_struct{i, strcat("Res", num2str(res), "Mode", num2str(m))};
                            % tableZoned{loc,'TotalCost_r1m1'}: [euro], calculated from sum([euro/hr]*[hr/ele])
                            tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} = ...
                                tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} + ...
                                tableActivity_struct{i, strcat("Cost_r", num2str(res), "m", num2str(m))} * ...
                                tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
                            % tableZoned{loc,'Eff_r1m1'}: [hr], calculated from sum([hr/ele]*[numEle]) = sum([hr/ele]*1)
                            tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} = ...
                                tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} + ...
                                + tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
                        end
                    end
                    for nGuid = 1:nAllEleGuid
                        if strlength(tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}) <= 230
                            tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]} = ...
                                strcat(tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}, tableActivity_struct{i,'GlobalID'},", ");
                            break
                        end
                    end
                end
            end  
        end
    end
    if flagToBreak == 1
        continue  % break out of the checking for this element and start the next iteration
    end

    % Case 2 (general case): if there is no SpecSeqName
    for class = 1:nClass_struct
        if tableActivity_struct{i,'Class'} == compoClass_struct(class)
            for lev = 1:nLevel-1
                if contains(tableActivity_struct{i,'BaseLevel'},strcat("0",num2str(lev-1)),'IgnoreCase',true)  
                    for z = 1:nZ       
                        if tableActivity_struct{i,'Zone'} == z
                            loc = nZ + (lev-1)*nZ*nClass_struct + (z-1)*nClass_struct + class;  % UPDATED0912 for piles ------
                            for res = 1:nR
                                tableZoned_struct{loc, strcat("Resource_", num2str(res))} = ...
                                tableActivity_struct{i, strcat("Resource_", num2str(res))};
                                for m = 1:nM
                                    tableZoned_struct{loc, strcat("Res", num2str(res), "Mode", num2str(m))} = ...
                                        tableActivity_struct{i, strcat("Res", num2str(res), "Mode", num2str(m))};
                                    % tableZoned{loc,'TotalCost_r1m1'}: [euro], calculated from sum([euro/hr]*[hr/ele])
                                    tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} = ...
                                        tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} + ...
                                        tableActivity_struct{i, strcat("Cost_r", num2str(res), "m", num2str(m))} * ...
                                        tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
                                    % tableZoned{loc,'Eff_r1m1'}: [hr], calculated from sum([hr/ele]*[numEle]) = sum([hr/ele]*1)
                                    tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} = ...
                                        tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} + ...
                                        + tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
                                end
                            end
                            for nGuid = 1:nAllEleGuid
                                if strlength(tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}) <= 230
                                    tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]} = ...
                                        strcat(tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}, tableActivity_struct{i,'GlobalID'},", ");
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    % Case 3: if it is a pile
    if tableActivity_struct{i,'Class'} == categorical(["Pile"])
        for z = 1:nZ       
            if tableActivity_struct{i,'Zone'} == z
                loc = z;  
                for res = 1:nR
                    tableZoned_struct{loc, strcat("Resource_", num2str(res))} = ...
                    tableActivity_struct{i, strcat("Resource_", num2str(res))};
                    for m = 1:nM
                        tableZoned_struct{loc, strcat("Res", num2str(res), "Mode", num2str(m))} = ...
                            tableActivity_struct{i, strcat("Res", num2str(res), "Mode", num2str(m))};
                        % tableZoned{loc,'TotalCost_r1m1'}: [euro], calculated from sum([euro/hr]*[hr/ele])
                        tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} = ...
                            tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} + ...
                            tableActivity_struct{i, strcat("Cost_r", num2str(res), "m", num2str(m))} * ...
                            tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
                        % tableZoned{loc,'Eff_r1m1'}: [hr], calculated from sum([hr/ele]*[numEle]) = sum([hr/ele]*1)
                        tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} = ...
                            tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} + ...
                            + tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
                    end
                end
                for nGuid = 1:nAllEleGuid
                    if strlength(tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}) <= 230
                        tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]} = ...
                            strcat(tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}, tableActivity_struct{i,'GlobalID'},", ");
                        break
                    end
                end
            end
        end
    end
end


%%
% % to create tableZoned
%             % (will move to a later callback)  
%             app.nZ_x = ceil((app.building_x_max - app.building_x_min)/app.Zx);  % round upwards
%             app.nZ_y = ceil((app.building_y_max - app.building_y_min)/app.Zy);
%             app.nZ = app.nZ_x * app.nZ_y;  
%             % specify from which corner and in which direction the construction starts
%             bottom2top_bool = 1;
%             left2right_bool = 1;
%             verticleDirFirst_bool = 1;
%             
%             % Change the class of all roofs to slabs, to treat them as slabs when zoning
%             isInClass = app.tableActivity_struct{:,'Class'} == 'Roof';
%             app.tableActivity_struct{isInClass, 'Class'} = categorical("Slab");
%             % Exclude roof and pile from the list of struct classes (the list will be used to create rows in tableZoned)
%             % Rows for piles will be created separately in tableZoned
%             compoClass_struct = unique(app.tableCompo_struct.Class);
%             compoClass_struct = compoClass_struct(compoClass_struct ~= categorical("Roof"));
%             compoClass_struct = compoClass_struct(compoClass_struct ~= categorical("Pile"));
%             
%             
%             nClass_struct = size(compoClass_struct,2);   % type of activities; column and beam here
%             nA_struct_woFound = app.nZ * (app.nLevel-1) * nClass_struct;  
%             app.tableZoned_struct = table('Size',[nA_struct_woFound length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);
%             
%             
%             % (will move to a later callback)            
%             % Find zone number for each activity and write into tableActivity
%             [app.tableActivity_struct, app.tableZoned_struct]  = func_findZoneNumForCompoTable_struct ...
%                 (app.tableActivity_struct, app.tableZoned_struct, ...
%                 app.building_x_min, app.building_y_min, app.building_x_max, app.building_y_max, ...
%                 app.Zx, app.Zy, app.nZ_x, app.nZ_y, app.nZ, nClass_struct, app.nLevel, compoClass_struct, ...
%                 bottom2top_bool, left2right_bool, verticleDirFirst_bool);
%             
%             % Add non-regular act clusters to tableZoned: foundation, and those compo with SpecSeqName
%             % Add foundation to tableZoned_struct: nZ number of activities
%             tableZoned_struct_toAddSpecial = app.tableZoned_struct(1:app.nZ, :);
%             tableZoned_struct_toAddSpecial{:, 'Class'} = repmat(categorical("Foundation"), app.nZ, 1);
%             for zone = 1:app.nZ
%                 tableZoned_struct_toAddSpecial{zone,'ActName'} = strcat("Foundation_Fug_Z",num2str(zone));
%                 tableZoned_struct_toAddSpecial{zone,'Zone'} = zone;
%                 tableZoned_struct_toAddSpecial{zone,'Floor'} = -1;
%             end
%             app.tableZoned_struct = [tableZoned_struct_toAddSpecial; app.tableZoned_struct];
%             
%             % (will move to a later callback)
%             % Add compo with SpecSeqName to tableZoned_struct: nZ*nSpecSeqName number of activities
%             tableZoned_struct_toAddSpecial = app.tableZoned_struct(1:app.nZ*app.SpecSeqName_countNonUndefined, :);
%             tableZoned_struct_toAddSpecial{:, 'Class'} = repmat(categorical("Foundation"), app.nZ, 1);
%             for nSpec = 1:length(SpecSeqName) 
%                 for zone = 1:app.nZ   
%                     tableZoned_struct_toAddSpecial{app.nZ*(length(SpecSeqName)-1)+zone,'Class'} = ...
%                         SpecSeqName_class(nSpec);
%                     tableZoned_struct_toAddSpecial{app.nZ*(length(SpecSeqName)-1)+zone,'ActName'} = ...
%                         strcat(string(SpecSeqName(nSpec)), "_Z", num2str(zone));
%                     app.tableActivity_struct{app.nZ*(length(SpecSeqName)-1)+zone,'Zone'} = zone;
%                     tableZoned_struct_toAddSpecial{app.nZ*(length(SpecSeqName)-1)+zone,'Floor'} = ...
%                         0;  % does not matter, seq will be overwritten by special rules later
%                 end
%             end
%             app.tableZoned_struct = [app.tableZoned_struct; tableZoned_struct_toAddSpecial];
%             
%             app.nA_struct = (app.nZ + app.nZ*app.SpecSeqName_countNonUndefined) + nA_struct_woFound;
%             
%             
%             
%             
%             
%             %% For tableZoned_struct: update the cost, dura data, and compo index
%             nAllEleGuid = 20;
%             for nGuid = 1:nAllEleGuid
%                 app.tableZoned_struct{:, ['AllEleGuid',num2str(nGuid)]} = repmat(" ", height(app.tableZoned_struct), 1);
%             end
% 
%             for i = 1:height(app.tableActivity_struct)  % (inefficient)
%                 
%                 % Case 1: if it has SpecSeqName
%                 flagToBreak = 0;  % if it has SpecSeqName, then flagToBreak is changed to 1
%                 for nSpec = 1:length(SpecSeqName) 
%                     if isundefined(app.tableActivity_struct{i, strcat("SpecSeqName", num2str(nSpec))}) == 0
%                         flagToBreak = 1;
%                         for z = 1:app.nZ       
%                             if app.tableActivity_struct{i,'Zone'} == z
%                                 loc = app.nZ + nA_struct_woFound + app.nZ*(length(SpecSeqName)-1) + z;
%                                 
%                                 for res = 1:app.nR
%                                     app.tableZoned_struct{loc, strcat("Resource_", num2str(res))} = ...
%                                     app.tableActivity_struct{i, strcat("Resource_", num2str(res))};
%                                     for m = 1:app.nM
%                                         app.tableZoned_struct{loc, strcat("Res", num2str(res), "Mode", num2str(m))} = ...
%                                             app.tableActivity_struct{i, strcat("Res", num2str(res), "Mode", num2str(m))};
%                                         % tableZoned{loc,'TotalCost_r1m1'}: [euro], calculated from sum([euro/hr]*[hr/ele])
%                                         app.tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} = ...
%                                             app.tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} + ...
%                                             app.tableActivity_struct{i, strcat("Cost_r", num2str(res), "m", num2str(m))} * ...
%                                             app.tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
%                                         % tableZoned{loc,'Eff_r1m1'}: [hr], calculated from sum([hr/ele]*[numEle]) = sum([hr/ele]*1)
%                                         app.tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} = ...
%                                             app.tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} + ...
%                                             + app.tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
%                                     end
%                                 end
% %                                 app.tableZoned_struct{loc,'Resource_1'} = app.tableActivity_struct{i,'Resource_1'};
% %                                 app.tableZoned_struct{loc,'Res1Mode1'} = app.tableActivity_struct{i,'Res1Mode1'};
% %                                 app.tableZoned_struct{loc,'Res1Mode2'} = app.tableActivity_struct{i,'Res1Mode2'};
% %                                 % tableZoned{loc,'TotalCost_r1m1'}: [euro], calculated from sum([euro/hr]*[hr/ele])
% %                                 app.tableZoned_struct{loc,'TotalCost_r1m1'} = app.tableZoned_struct{loc,'TotalCost_r1m1'} + ...
% %                                     app.tableActivity_struct{i,'Cost_r1m1'}*app.tableActivity_struct{i,'Eff_r1m1'};
% %                                 app.tableZoned_struct{loc,'TotalCost_r1m2'} = app.tableZoned_struct{loc,'TotalCost_r1m2'} + ...
% %                                     app.tableActivity_struct{i,'Cost_r1m2'}*app.tableActivity_struct{i,'Eff_r1m2'};
% %                                 % tableZoned{loc,'Eff_r1m1'}: [hr], calculated from sum([hr/ele]*[numEle]) = sum([hr/ele]*1)
% %                                 app.tableZoned_struct{loc,'Dura_r1m1'} = app.tableZoned_struct{loc,'Dura_r1m1'} + app.tableActivity_struct{i,'Eff_r1m1'};
% %                                 app.tableZoned_struct{loc,'Dura_r1m2'} = app.tableZoned_struct{loc,'Dura_r1m2'} + app.tableActivity_struct{i,'Eff_r1m2'};
% %             
% %                                 app.tableZoned_struct{loc,'Resource_2'} = app.tableActivity_struct{i,'Resource_2'};
% %                                 app.tableZoned_struct{loc,'Res2Mode1'} = app.tableActivity_struct{i,'Res2Mode1'};
% %                                 app.tableZoned_struct{loc,'Res2Mode2'} = app.tableActivity_struct{i,'Res2Mode2'};
% %                                 % tableZoned{loc,'TotalCost_r1m1'}: [euro], calculated from sum([euro/hr]*[hr/ele])
% %                                 app.tableZoned_struct{loc,'TotalCost_r2m1'} = app.tableZoned_struct{loc,'TotalCost_r2m1'} + ...
% %                                     app.tableActivity_struct{i,'Cost_r2m1'}*app.tableActivity_struct{i,'Eff_r2m1'};
% %                                 app.tableZoned_struct{loc,'TotalCost_r2m2'} = app.tableZoned_struct{loc,'TotalCost_r2m2'} + ...
% %                                     app.tableActivity_struct{i,'Cost_r2m2'}*app.tableActivity_struct{i,'Eff_r2m2'};
% %                                 % tableZoned{loc,'Eff_r1m1'}: [hr], calculated from sum([hr/ele]*[numEle]) = sum([hr/ele]*1)
% %                                 app.tableZoned_struct{loc,'Dura_r2m1'} = app.tableZoned_struct{loc,'Dura_r2m1'} + app.tableActivity_struct{i,'Eff_r2m1'};
% %                                 app.tableZoned_struct{loc,'Dura_r2m2'} = app.tableZoned_struct{loc,'Dura_r2m2'} + app.tableActivity_struct{i,'Eff_r2m2'};
%                                 for nGuid = 1:nAllEleGuid
%                                     if strlength(app.tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}) <= 230
%                                         app.tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]} = ...
%                                             strcat(app.tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}, app.tableActivity_struct{i,'GlobalID'},", ");
%                                         break
%                                     end
%                                 end
%                             end
%                         end  
%                     end
%                 end
%                 if flagToBreak == 1
%                     continue  % break out of the checking for this element and start the next iteration
%                 end
%                 
%                 % Case 2 (general case): if there is no SpecSeqName
%                 for class = 1:nClass_struct
%                     if app.tableActivity_struct{i,'Class'} == compoClass_struct(class)
%                         for lev = 1:app.nLevel-1
%                             if contains(app.tableActivity_struct{i,'BaseLevel'},strcat("0",num2str(lev-1)),'IgnoreCase',true)  
%                                 for z = 1:app.nZ       
%                                     if app.tableActivity_struct{i,'Zone'} == z
%                                         loc = app.nZ + (lev-1)*app.nZ*nClass_struct + (z-1)*nClass_struct + class;  % UPDATED0912 for piles ------
%                                         for res = 1:app.nR
%                                             app.tableZoned_struct{loc, strcat("Resource_", num2str(res))} = ...
%                                             app.tableActivity_struct{i, strcat("Resource_", num2str(res))};
%                                             for m = 1:app.nM
%                                                 app.tableZoned_struct{loc, strcat("Res", num2str(res), "Mode", num2str(m))} = ...
%                                                     app.tableActivity_struct{i, strcat("Res", num2str(res), "Mode", num2str(m))};
%                                                 % tableZoned{loc,'TotalCost_r1m1'}: [euro], calculated from sum([euro/hr]*[hr/ele])
%                                                 app.tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} = ...
%                                                     app.tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} + ...
%                                                     app.tableActivity_struct{i, strcat("Cost_r", num2str(res), "m", num2str(m))} * ...
%                                                     app.tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
%                                                 % tableZoned{loc,'Eff_r1m1'}: [hr], calculated from sum([hr/ele]*[numEle]) = sum([hr/ele]*1)
%                                                 app.tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} = ...
%                                                     app.tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} + ...
%                                                     + app.tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
%                                             end
%                                         end
%                                         for nGuid = 1:nAllEleGuid
%                                             if strlength(app.tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}) <= 230
%                                                 app.tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]} = ...
%                                                     strcat(app.tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}, app.tableActivity_struct{i,'GlobalID'},", ");
%                                                 break
%                                             end
%                                         end
%                                     end
%                                 end
%                             end
%                         end
%                     end
%                 end
%                 
%                 % Case 3: if it is a pile
%                 if app.tableActivity_struct{i,'Class'} == categorical(["Pile"])
%                     for z = 1:app.nZ       
%                         if app.tableActivity_struct{i,'Zone'} == z
%                             loc = z;  
%                             for res = 1:app.nR
%                                 app.tableZoned_struct{loc, strcat("Resource_", num2str(res))} = ...
%                                 app.tableActivity_struct{i, strcat("Resource_", num2str(res))};
%                                 for m = 1:app.nM
%                                     app.tableZoned_struct{loc, strcat("Res", num2str(res), "Mode", num2str(m))} = ...
%                                         app.tableActivity_struct{i, strcat("Res", num2str(res), "Mode", num2str(m))};
%                                     % tableZoned{loc,'TotalCost_r1m1'}: [euro], calculated from sum([euro/hr]*[hr/ele])
%                                     app.tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} = ...
%                                         app.tableZoned_struct{loc, strcat("TotalCost_r", num2str(res), "m", num2str(m))} + ...
%                                         app.tableActivity_struct{i, strcat("Cost_r", num2str(res), "m", num2str(m))} * ...
%                                         app.tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
%                                     % tableZoned{loc,'Eff_r1m1'}: [hr], calculated from sum([hr/ele]*[numEle]) = sum([hr/ele]*1)
%                                     app.tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} = ...
%                                         app.tableZoned_struct{loc, strcat("Dura_r", num2str(res), "m", num2str(m))} + ...
%                                         + app.tableActivity_struct{i, strcat("Eff_r", num2str(res), "m", num2str(m))};
%                                 end
%                             end
%                             for nGuid = 1:nAllEleGuid
%                                 if strlength(app.tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}) <= 230
%                                     app.tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]} = ...
%                                         strcat(app.tableZoned_struct{loc,['AllEleGuid',num2str(nGuid)]}, app.tableActivity_struct{i,'GlobalID'},", ");
%                                     break
%                                 end
%                             end
%                         end
%                     end
%                 end
%             end