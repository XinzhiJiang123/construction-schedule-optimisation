% Find zone number for each activity and write into tableActivity
function [tableActivity, tableZoned] = func_findZoneNumForCompoTable(tableActivity, tableZoned, ...
    building_x_min, building_y_min, building_x_max, building_y_max, ...
    Zx, Zy, nZ_x, nZ_y, nZ, nClass, nLevel, compoClass, ...
    bottom2top_bool, left2right_bool, verticleDirFirst_bool)

% the location of zones:
% bottom2top = 1, left2right = 1:
    % Z2  Z4  Z6 
    % Z1  Z3  Z5 
% bottom2top = 0, left2right = 1:
    % Z1  Z3  Z5 
    % Z2  Z4  Z6

% create an extra column in tableActivity
tableActivity.Zone = zeros(height(tableActivity),1);
    
% bottom2top = 1, left2right = 1 =========================================================
    % Z2  Z4  Z6 
    % Z1  Z3  Z5
if bottom2top_bool == 1 && left2right_bool == 1 && verticleDirFirst_bool == 1
% find the elements falling into one zone
for ele = 1:height(tableActivity)
    for j = 1:nZ_y
        zone_temp = 0;
        if tableActivity{ele, "Y_min"}/1000 >= building_y_min + (j-1)*Zy
            if tableActivity{ele, "Y_max"}/1000 < building_y_min + j*Zy
                zone_temp = j;
                for i = 1:nZ_x
                    if tableActivity{ele, "X_min"}/1000 >= building_x_min + (i-1)*Zx
                        if tableActivity{ele, "X_max"}/1000 < building_x_min + i*Zx
                            tableActivity{ele, "Zone"} = zone_temp + (i-1)*nZ_y;
                            % test = zone_temp + (i-1)*nZ_y;
                            break
                        end
                    end
                end
            end      
        end
    end
end
% find the elements falling into more than one zones
row_SpanMultiZone = tableActivity{:,'Zone'} == 0;
for ele = 1:height(tableActivity)
    if row_SpanMultiZone(ele,1) == 1
    zones_temp = zeros(1,nZ);
    corners_toCheck = ["Y_min","Y_max";"X_min","X_max"];
    
    % UPDATED0926 ----------------------------
    flagToBreak = 0;
    for j = 1:nZ_y
        zone_temp = 0;
        % if tableActivity{ele, "Y_min"}/1000 >= building_y_min + (j-1)*Zy
            if tableActivity{ele, "Y_max"}/1000 < building_y_min + j*Zy
                zone_temp = j;
                for i = 1:nZ_x
                    % if tableActivity{ele, "X_min"}/1000 >= building_x_min + (i-1)*Zx
                        if tableActivity{ele, "X_max"}/1000 < building_x_min + i*Zx
                            zones_temp(zone_temp + (i-1)*nZ_y) = zone_temp + (i-1)*nZ_y;
                            % test = zone_temp + (i-1)*nZ_y;
                            flagToBreak = 1;
                            break
                        end
                    % end
                    if flagToBreak == 1
                        break
                    end
                end
            end      
        % end
    end
    
    
% COMMENTED 0926 ----------------------------    
%     % check which zone each of the 4 corners falls into
%     for y_coord = 1:2  
%         for x_coord = 1:2  % for all combintations of x and y coordinates in corners_toCheck
%             for j = 1:nZ_y
%                 if tableActivity{ele, corners_toCheck(y_coord,x_coord)}/1000 <= building_y_min + j*Zy
%                     zone_temp = j;
%                     for i = 1:nZ_x
%                         if tableActivity{ele, corners_toCheck(y_coord,3-x_coord)}/1000 <= building_x_min + i*Zx
%                             zones_temp(zone_temp + (i-1)*nZ_y) = zone_temp + (i-1)*nZ_y;
% %                             break
%                         end
%                     end
%                 end
%                 if ~isempty(zones_temp)
%                     break
%                 end
%             end
%         end
%     end
    tableActivity{ele,'Zone'} = max(zones_temp,[],'all');
    test = max(zones_temp,[],'all');
    end
end
end

% bottom2top = 0, left2right = 1 =========================================================
    % Z1  Z3  Z5 
    % Z2  Z4  Z6
if bottom2top_bool == 0 && left2right_bool == 1 && verticleDirFirst_bool == 1
% find the elements falling into one zone
for ele = 1:height(tableActivity)
    for j = 1:nZ_y
        zone_temp = 0;
        if tableActivity{ele, "Y_min"}/1000 >= building_y_max - (j-1)*Zy
            if tableActivity{ele, "Y_max"}/1000 < building_y_max - j*Zy
                zone_temp = j;
                for i = 1:nZ_x
                    if tableActivity{ele, "X_min"}/1000 >= building_x_min + (i-1)*Zx
                        if tableActivity{ele, "X_max"}/1000 < building_x_min + i*Zx
                            tableActivity{ele, "Zone"} = zone_temp + (i-1)*nZ_y;
                            break
                        end
                    end
                end
            end      
        end
    end
end
% find the elements falling into more than one zones
row_SpanMultiZone = tableActivity{:,'Zone'} == 0;
for ele = 1:height(tableActivity)
    if row_SpanMultiZone(ele,1) == 1
    zones_temp = zeros(1,nZ);
    corners_toCheck = ["Y_min","Y_max";"X_min","X_max"];
    % check which zone each of the 4 corners falls into
    for y_coord = 1:2  
        for x_coord = 1:2  % for all combintations of x and y coordinates in corners_toCheck
            for j = 1:nZ_y
                if tableActivity{ele, corners_toCheck(y_coord,x_coord)}/1000 > building_y_max - j*Zy  % TO CHECK!!!!
                    zone_temp = j;
                    for i = 1:nZ_x
                        if tableActivity{ele, corners_toCheck(y_coord,3-x_coord)}/1000 <= building_x_min + i*Zx
                            zones_temp(zone_temp + (i-1)*nZ_y) = zone_temp + (i-1)*nZ_y;
%                             break
                        end
                    end
                end
                if ~isempty(zones_temp)
                    break
                end
            end
        end
    end
    tableActivity{ele,'Zone'} = max(zones_temp,[],'all');
    end
end
end




% write activity name, level and zone number for all rows (activity clusters)
% first, list all names of activity clusters
% tableRowName = repmat("actcluster", 1, nA);
for lev = 1:nLevel  % UPDATED0909 -------------------------------------------
    for z = 1:nZ
        for class = 1:nClass
            loc = (lev-1)*nZ*nClass + (z-1)*nClass + class;
            tableZoned{loc,'Floor'} = lev-2;  % UPDATED0909 -------------------------------------------
            tableZoned{loc,'Zone'} = z;
            tableZoned{loc,'ActName'} = strcat("Mount ",string(compoClass(class)),"_F",num2str(lev-2),"_Z",num2str(z)); % UPDATED0909 -------
            tableZoned{loc,'Class'} = compoClass(class);
        end
    end
end