function [M_SSR, M1_seq, M_coordDiff, check1, check2, check3] = func_mepSeq_findSSR(tableCompo_mep, tableCompo_struct, ...
    Dmin_h, Dmin_v, Dwallmin, Dceilmin)
%% SEQ MEP STEP 2 - SSR: find all pairs of compo with special spatial relations
% Step 2: 17.5 seconds
% check flow segments only, no need to check flow fittings
% reasons: not primary compo for clashes; unnecessary relation with flow segments they connect to
% ---- Content
% ---- SEQ MEP STEP 2-1: Identify the level of all compo
% ---- SEQ MEP STEP 2-2: Calculate the coord diff of all pairs of compo, and record in matrix
% ---- SEQ MEP STEP 2-3: Calculate the coord diff of all pairs of compo and slab/column/wall, record in matrix
% ---- SEQ MEP STEP 2-4: Find the pairs of compo satisfying SSR (1): write as bool/pseudo-bool
% ---- SEQ MEP STEP 2-5: Find the pairs of compo satisfying SSR (2): write into one matrix
% ---- End of content
% Min distance (mm) between MEP compo, to be considered as "in proximity": Dmin_h, Dmin_v
% Min distance (mm) between MEP compo and structural compo, to be considered as "in proximity": Dceilmin, Dwallmin
% Dmin_h = 300; Dmin_v = 300;
% Dceilmin = 300; Dwallmin = 300;

% ---- SEQ MEP STEP 2-1: Identify the level of all compo
% for this file: al compo, include "FlowSegment", "FlowFitting" classes
% floorElevation = floorElevation*1000;
% Reset all the baselevel value (as string) first
% (in Excel, there is level info for flowfittings, but no for flowsegments)
% tableCompo_mep{:, 'BaseLevel'} = repmat("", height(tableCompo_mep), 1);  % WHY THIS IN THE FIRST PLACE? (0909)---------
% ---- SEQ MEP STEP 2-1-1: Find & record inter-level components
% ...
% (for now, assume there is no inter-level compo)
% ...
% ---- SEQ MEP STEP 2-1-2: Separate each floor level into sublevels: upper and lower


% ---- SEQ MEP STEP 2-2: Calculate the coord diff of all pairs of compo, and record in matrix
% M_coordDiff: to record coord difference (value, not bool)
M_coordDiff = zeros(height(tableCompo_mep), height(tableCompo_mep), 3);  % matrix of 3D
for i = 1:height(tableCompo_mep)
    M_coordDiff(:,i,1) = max([repmat(tableCompo_mep{i, 'X_max'}, height(tableCompo_mep), 1), ...
        tableCompo_mep{:, 'X_max'}], [], 2) ...  % to find the max of X_max of i and all others, as column vector
        - min([repmat(tableCompo_mep{i, 'X_min'}, height(tableCompo_mep), 1), tableCompo_mep{:, 'X_min'}], [], 2) ...
        - repmat(tableCompo_mep{i, 'Size_X'}, height(tableCompo_mep), 1) ...
        - tableCompo_mep{:, 'Size_X'};
    M_coordDiff(:,i,2) = max([repmat(tableCompo_mep{i, 'Y_max'}, height(tableCompo_mep), 1), ...
        tableCompo_mep{:, 'Y_max'}], [], 2) ...  % to find the max of Y_max of i and all others, as column vector
        - min([repmat(tableCompo_mep{i, 'Y_min'}, height(tableCompo_mep), 1), tableCompo_mep{:, 'Y_min'}], [], 2) ...
        - repmat(tableCompo_mep{i, 'Size_Y'}, height(tableCompo_mep), 1) ...
        - tableCompo_mep{:, 'Size_Y'};
    M_coordDiff(:,i,3) = max([repmat(tableCompo_mep{i, 'Z_max'}, height(tableCompo_mep), 1), ...
        tableCompo_mep{:, 'Z_max'}], [], 2) ...  % to find the max of Z_max of i and all others, as column vector
        - min([repmat(tableCompo_mep{i, 'Z_min'}, height(tableCompo_mep), 1), tableCompo_mep{:, 'Z_min'}], [], 2) ...
        - repmat(tableCompo_mep{i, 'Size_Z'}, height(tableCompo_mep), 1) ...
        - tableCompo_mep{:, 'Size_Z'};
end

% ---- SEQ MEP STEP 2-3: Calculate the coord diff of all pairs of compo and slab/column/wall, record in matrix
% each row: one MEP compo
% each column: one structural compo
M_coordDiffWithStruct = zeros(height(tableCompo_mep), height(tableCompo_struct), 3);  % matrix of 3D
for i = 1:height(tableCompo_struct)
    % to find the max of X_max of each MEP compo and struct compo i, as column vector
    M_coordDiffWithStruct(:,i,1) = max([tableCompo_mep{:, 'X_max'}, ... 
        repmat(tableCompo_struct{i, 'X_max'}, height(tableCompo_mep), 1)], [], 2) ...  
        - min([tableCompo_mep{:, 'X_min'}, ...
         repmat(tableCompo_struct{i, 'X_min'}, height(tableCompo_mep), 1)], [], 2) ...
        - tableCompo_mep{:, 'Size_X'}  ...
        - repmat(tableCompo_struct{i, 'Size_X'}, height(tableCompo_mep), 1);
    M_coordDiffWithStruct(:,i,2) = max([tableCompo_mep{:, 'Y_max'}, ... 
        repmat(tableCompo_struct{i, 'Y_max'}, height(tableCompo_mep), 1)], [], 2) ...  
        - min([tableCompo_mep{:, 'Y_min'}, ...
         repmat(tableCompo_struct{i, 'Y_min'}, height(tableCompo_mep), 1)], [], 2) ...
        - tableCompo_mep{:, 'Size_Y'}  ...
        - repmat(tableCompo_struct{i, 'Size_Y'}, height(tableCompo_mep), 1);
    M_coordDiffWithStruct(:,i,3) = max([tableCompo_mep{:, 'Z_max'}, ... 
        repmat(tableCompo_struct{i, 'Z_max'}, height(tableCompo_mep), 1)], [], 2) ...  
        - min([tableCompo_mep{:, 'Z_min'}, ...
         repmat(tableCompo_struct{i, 'Z_min'}, height(tableCompo_mep), 1)], [], 2) ...
        - tableCompo_mep{:, 'Size_Z'}  ...
        - repmat(tableCompo_struct{i, 'Size_Z'}, height(tableCompo_mep), 1);
end

% ---- SEQ MEP STEP 2-4: Find the pairs of compo satisfying SSR (1): write as bool/pseudo-bool
% to judge if the proximity satisfies SSR, from the coord diff values in M_coordDiff and M_coordDiffWithStruct
% M_SSR_prox (numCompo*numCompo*6): 2 if <= 0, 1 if <= dist for proximity, 0 otherwise
% M_SSR_bool (numCompo*numCompo*1): 1 if SSR scenarios are satisfied, 0 otherwise
% M_SSR_prox: for each pair of MEP compo, check all six criteria,
% criteria 1 to 3: M_coordDiff < 0 or < Dxmin or Dzmin
% criteria 4 to 6: either compo has M_coordDiffWithStruct < Dceilmin or Dwallmin
% and record the result of all six types 
M_SSR = zeros(height(tableCompo_mep), height(tableCompo_mep), 6);  % matrix of 3D
for i = 1:height(tableCompo_mep)
    % check criteria 1 to 3: M_coordDiff < 0 or < Dxmin or Dzmin
    for j = i+1:height(tableCompo_mep)
        for dim = 1:2      % Dx, Dy
            if M_coordDiff(i,j,dim) <= 0
                M_SSR(i,j,dim) = 2;
                M_SSR(j,i,dim) = 2; 
            elseif M_coordDiff(i,j,dim) <= Dmin_h  % UPDATED0909 -----------------------------
                M_SSR(i,j,dim) = 1;
                M_SSR(j,i,dim) = 1; 
            end
        end
        for dim = 3:3      % Dz
            if M_coordDiff(i,j,dim) <= 0
                M_SSR(i,j,dim) = 2;
                M_SSR(j,i,dim) = 2; 
            elseif M_coordDiff(i,j,dim) <= Dmin_v  % UPDATED0909 -----------------------------
                M_SSR(i,j,dim) = 1;
                M_SSR(j,i,dim) = 1;
            end
        end  
    end
    % check criteria 4 to 6: either compo has M_coordDiffWithStruct < Dceilmin or Dwallmin
    idx = M_coordDiffWithStruct(i,:,1) <= Dwallmin & M_coordDiffWithStruct(i,:,2) <= 0 ...
        & M_coordDiffWithStruct(i,:,3) <= 0;  % bool
    idxOfNonZero = find(idx > 0,1);  % find the first non-zero values in vector "idx", empty if none found
    if ~isempty(idxOfNonZero) % check if compo i has proximity with structural compo
        M_SSR(i,:,4) = ones(1, size(M_SSR,2));
        M_SSR(:,i,4) = ones(size(M_SSR,2), 1);
    end
    idx = M_coordDiffWithStruct(i,:,1) <= 0 & M_coordDiffWithStruct(i,:,2) <= Dwallmin ...
        & M_coordDiffWithStruct(i,:,3) <= 0;  % bool
    idxOfNonZero = find(idx > 0,1);  % find the first non-zero values in vector "idx", empty if none found
    if ~isempty(idxOfNonZero)
        M_SSR(i,:,5) = ones(1, size(M_SSR,2));
        M_SSR(:,i,5) = ones(size(M_SSR,2), 1);
    end
    idx = M_coordDiffWithStruct(i,:,1) <= 0 & M_coordDiffWithStruct(i,:,2) <= 0 ...
        & M_coordDiffWithStruct(i,:,3) <= Dceilmin;  % bool
    idxOfNonZero = find(idx > 0,1);  % find the first non-zero values in vector "idx", empty if none found
    if ~isempty(idxOfNonZero)
        M_SSR(i,:,6) = ones(1, size(M_SSR,2));
        M_SSR(:,i,6) = ones(size(M_SSR,2), 1);
    end
end

% ---- SEQ MEP STEP 2-5: Find the pairs of compo satisfying SSR (2): write into one matrix  % UPDATED0922/23 ------
% apply the criteria in SSR scenarios:
% Scenario 1: Dx<Dmin_h,  Dy<0,  Dz<0;  DwallPerpToX<Dwallmin, (--no need--),      (--no need--)
% Scenario 2: Dx<0,  Dy<Dmin_h,  Dz<0;  (--no need--),     DwallPerpToY<Dwallmin,  (--no need--)
% Scenario 3: Dx<0,  Dy<0,  Dz<Dmin_v;  (--no need--),     (--no need--),         Dceil<Dceilmin
% criteria 1 to 3: M_SSR(:,:,1:3) = 2 if <0, = 1 if < Dmin_h or Dmin_v
% criteria 4 to 6: M_SSR(:,:,4:6) = 1 if satisfies the following with at least one struct compo:
%                                     dist x or y < Dwallmin && overlap in other 2 dimensions; or
%                                     dist z < Dceilmin && overlap in other 2 dimensions
M1_seq = zeros(size(M_SSR,1), size(M_SSR,1));
% check Scenario 1 and write result into M_SSR
for i = 1:size(M_SSR,1)  % row i
    for j = i+1:size(M_SSR,2)  % column j
        if M_SSR(i,j,1) >= 1 && M_SSR(i,j,2) == 2 && M_SSR(i,j,3) == 2 ...
            && M_SSR(i,j,4) == 1  % if all criteria for scenario 1 are satisfied
            % in scenario 1, check which MEP compo is closer to which wall compo
            % first check the coord of the wall
            % check which wall compo i is closed to
            idx = M_coordDiffWithStruct(i,:,1) <= Dwallmin & M_coordDiffWithStruct(i,:,1) > 0 ...
                & M_coordDiffWithStruct(i,:,2) <= 0 ...
                & M_coordDiffWithStruct(i,:,3) <= 0;  % bool
            idxOfNonZero_i = find(idx > 0);  % find the loc of non-zero values in vector "idx"  % UPDATED0922 --------
            % check which wall compo j is closed to
            idx = M_coordDiffWithStruct(j,:,1) <= Dwallmin & M_coordDiffWithStruct(j,:,1) > 0 ...
                & M_coordDiffWithStruct(j,:,2) <= 0 ...
                & M_coordDiffWithStruct(j,:,3) <= 0;  % bool
            idxOfNonZero_j = find(idx > 0,1);  % find the loc of the first non-zero values in vector "idx"
            % compo i and j should be closed to the same wall
            structCompoInCommon = intersect(idxOfNonZero_i, idxOfNonZero_j);
            if ~isempty(structCompoInCommon)
                Xmin_struct_temp = tableCompo_struct{structCompoInCommon(1), 'X_min'};  % coordX of the wall close to compo
                Xmax_struct_temp = tableCompo_struct{structCompoInCommon(1), 'X_max'};
                % then check which of compo i and j has the closest x coord
                if tableCompo_mep{j, 'X_min'} <= Xmin_struct_temp  
                    if tableCompo_mep{i, 'X_min'} <= tableCompo_mep{j, 'X_min'}  % if Ximin <= Xjmin <= Xwallmin
                        M1_seq(i,j) = -1;  
                        M1_seq(j,i) = 1;  % j earlier than i
                    else          % if Xjmin < Ximin <= Xwallmin
                        M1_seq(i,j) = 1;  % i earlier than j
                        M1_seq(j,i) = -1;
                    end
                else
                    if tableCompo_mep{i, 'X_max'} <= tableCompo_mep{j, 'X_max'}  % if Xwallmax <= Ximax <= Xjmax
                        M1_seq(i,j) = 1;  % i earlier than j
                        M1_seq(j,i) = -1;
                    else          % if Xwallmax <= Xjmax <= Ximax
                        M1_seq(i,j) = -1;  
                        M1_seq(j,i) = 1;  % j earlier than i
                    end
                end
            end
        end
    end
end
check1 = sum(M1_seq(:,:) > 0, 'all');
% check Scenario 2 and write result into M_SSR
for i = 1:size(M_SSR,1)  % row i
    for j = i+1:size(M_SSR,2)  % column j
        if M_SSR(i,j,1) == 2 && M_SSR(i,j,2) >= 1 && M_SSR(i,j,3) == 2 ...
            && M_SSR(i,j,5) == 1  % if all criteria for scenario 2 are satisfied
            % in scenario 2, check which MEP compo is closer to which wall compo
            % first check the coord of the wall
            % check which wall compo i is closed to
            idx = M_coordDiffWithStruct(i,:,1) <= 0 ...
                & M_coordDiffWithStruct(i,:,2) <= Dwallmin & M_coordDiffWithStruct(i,:,2) > 0 ...
                & M_coordDiffWithStruct(i,:,3) <= 0;  % bool
            idxOfNonZero_i = find(idx > 0,1);  % find the loc of the first non-zero values in vector "idx"
            % check which wall compo j is closed to
            idx = M_coordDiffWithStruct(j,:,1) <= 0 ...
                & M_coordDiffWithStruct(j,:,2) <= Dwallmin & M_coordDiffWithStruct(j,:,2) > 0 ...
                & M_coordDiffWithStruct(j,:,3) <= 0;  % bool
            idxOfNonZero_j = find(idx > 0,1);  % find the loc of the first non-zero values in vector "idx"
            % compo i and j should be closed to the same wall
            structCompoInCommon = intersect(idxOfNonZero_i, idxOfNonZero_j);
            if ~isempty(structCompoInCommon)
                Ymin_struct_temp = tableCompo_struct{structCompoInCommon(1), 'Y_min'};  % coordX of the wall close to compo
                Ymax_struct_temp = tableCompo_struct{structCompoInCommon(1), 'Y_max'};
                % then check which of compo i and j has the closest x coord
                if tableCompo_mep{j, 'Y_min'} <= Ymin_struct_temp  
                    if tableCompo_mep{i, 'Y_min'} <= tableCompo_mep{j, 'Y_min'}  % if Ximin <= Xjmin <= Xwallmin
                        M1_seq(i,j) = -1;  
                        M1_seq(j,i) = 1;  % j earlier than i
                    else          % if Xjmin < Ximin <= Xwallmin
                        M1_seq(i,j) = 1;  % i earlier than j
                        M1_seq(j,i) = -1;
                    end    
                else
                    if tableCompo_mep{i, 'Y_max'} <= tableCompo_mep{j, 'Y_max'}  % if Xwallmax <= Ximax <= Xjmax
                        M1_seq(i,j) = 1;  % i earlier than j
                        M1_seq(j,i) = -1;
                    else          % if Xwallmax <= Xjmax <= Ximax
                        M1_seq(i,j) = -1;  
                        M1_seq(j,i) = 1;  % j earlier than i
                    end
                end
            end
        end
    end
end
check2 = sum(M1_seq(:,:) > 0, 'all');  % 4721 number of >0 values by now
% check Scenario 3 and write result into M_SSR
for i = 1:size(M_SSR,1)  % row i
    for j = i+1:size(M_SSR,2)  % column j
        if M_SSR(i,j,1) == 2 && M_SSR(i,j,2) == 2 && M_SSR(i,j,3) >= 1 ...
            && M_SSR(i,j,6) == 1  % if all criteria for scenario 3 are satisfied
            % in scenario 3, check which MEP compo is closer to which wall compo
            % first check the coord of the wall
            % check which wall compo i is closed to
            idx = M_coordDiffWithStruct(i,:,1) <= 0 ...
                & M_coordDiffWithStruct(i,:,2) <= 0 ...
                & M_coordDiffWithStruct(i,:,3) <= Dceilmin ...
                & M_coordDiffWithStruct(i,:,3) > 0;  % bool
            idxOfNonZero_i = find(idx > 0,1);  % find the loc of the first non-zero values in vector "idx"
            % check which wall compo j is closed to
            idx = M_coordDiffWithStruct(j,:,1) <= 0 ...
                & M_coordDiffWithStruct(j,:,2) <= 0 ...
                & M_coordDiffWithStruct(j,:,3) <= Dceilmin ...
                & M_coordDiffWithStruct(j,:,3) > 0;  % bool
            idxOfNonZero_j = find(idx > 0,1);  % find the loc of the first non-zero values in vector "idx"
            % compo i and j should be closed to the same wall
            structCompoInCommon = intersect(idxOfNonZero_i, idxOfNonZero_j);
            if ~isempty(structCompoInCommon)
                Zmin_struct_temp = tableCompo_struct{structCompoInCommon(1), 'Z_min'};  % coordX of the wall close to compo
                Zmax_struct_temp = tableCompo_struct{structCompoInCommon(1), 'Z_max'};
                % then check which of compo i and j has the closest x coord
                if tableCompo_mep{j, 'Z_min'} <= Zmin_struct_temp  
                    if tableCompo_mep{i, 'Z_min'} <= tableCompo_mep{j, 'Z_min'}  % if Ximin <= Xjmin <= Xwallmin
                        M1_seq(i,j) = -1;  
                        M1_seq(j,i) = 1;  % j earlier than i
                    else          % if Xjmin < Ximin <= Xwallmin
                        M1_seq(i,j) = 1;  % i earlier than j
                        M1_seq(j,i) = -1;
                    end
                else
                    if tableCompo_mep{i, 'Z_max'} <= tableCompo_mep{j, 'Z_max'}  % if Xwallmax <= Ximax <= Xjmax
                        M1_seq(i,j) = 1;  % i earlier than j
                        M1_seq(j,i) = -1;
                    else          % if Xwallmax <= Xjmax <= Ximax
                        M1_seq(i,j) = -1;  
                        M1_seq(j,i) = 1;  % j earlier than i
                    end
                end
            end
        end
    end
end
check3 = sum(M1_seq(:,:) > 0, 'all');  % 11675 number of >0 values by now
% to check the number of 1 or -1 in M_seq in command window
% sum(M_seq==1,'all')
% only 0.06% of the all pairs, 11675 pairs with SSR for 12336w

% disp(['No. MEP compo pairs with SSR: ', num2str(sum(M1_seq>0, 'all'))])


