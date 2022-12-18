function [M_SIZE, M2_seq, M_length, M_section] = func_mepSeq_findCSR(tableCompo_mep, ...
    Dmin_h2, Dmin_v2, D_length_long, D_length_short, D_crosssec_large, D_crosssec_small, M_coordDiff)
%% SEQ MEP STEP 2 - compo size: find all pairs of compo with compo size relations
% ---- SEQ MEP STEP 2-1: find the MEP compo pairs which are close enough to each other
% ---- SEQ MEP STEP 2-2: record the MEP compo pairs which have very different lengths
% ---- SEQ MEP STEP 2-3: record the MEP compo pairs which have very different sectional areas
% ---- SEQ MEP STEP 2-4: find M2_seq based on M_length and M_section


% ---- SEQ MEP STEP 2-1: find the MEP compo pairs which are close enough to each other
% use M_coordDiff (coord diff bet. MEP compo pairs in mm), taken from SEQ MEP STEP 2 - SSR
M_SIZE = zeros(height(tableCompo_mep), height(tableCompo_mep), 6);  % matrix of 3D
for i = 1:height(tableCompo_mep)
    % check criteria 1 to 3: M_coordDiff < 0 or < Dxmin or Dzmin
    for j = 1:height(tableCompo_mep)
        for dim = 1:2      % Dx, Dy
            if M_coordDiff(i,j,dim) <= 0
                M_SIZE(i,j,dim) = 2;
                M_SIZE(j,i,dim) = 2; 
            elseif M_coordDiff(i,j,dim) <= Dmin_h2  
                M_SIZE(i,j,dim) = 1;
                M_SIZE(j,i,dim) = 1; 
            end
        end
        for dim = 3:3      % Dz
            if M_coordDiff(i,j,dim) <= 0
                M_SIZE(i,j,dim) = 2;
                M_SIZE(j,i,dim) = 2; 
            elseif M_coordDiff(i,j,dim) <= Dmin_v2 
                M_SIZE(i,j,dim) = 1;
                M_SIZE(j,i,dim) = 1;
            end
        end  
    end
end

% ---- SEQ MEP STEP 2-2: record the MEP compo pairs which have very different lengths
M_length = zeros(height(tableCompo_mep), height(tableCompo_mep), 2);
size_sorted = sort([tableCompo_mep{:,'Size_X'}, tableCompo_mep{:,'Size_Y'}, tableCompo_mep{:,'Size_Z'}], 2, 'ascend');
toSelect_long = size_sorted(:,3) > D_length_long;  % mm
toSelect_short = size_sorted(:,3) < D_length_short;
M_length(toSelect_long,:,1) = 1;
M_length(:,toSelect_long,1) = 1;
M_length(toSelect_short,:,2) = 1;
M_length(:,toSelect_short,2) = 1;
% toSelect_longShort = M_length(:,:,1) == 1 & M_length(:,:,2) == 1;
% for i = 1:height(tableCompo_mep)
%     for j = 1:height(tableCompo_mep)
%         if M_length(i,j,1) == 1 && M_length(i,j,2) == 1
%             M_SIZE(i,j,4) = 1;
%             M_SIZE(j,i,4) = -1;
%         end            
%     end
% end
M_SIZE(toSelect_long, toSelect_short, 4) = 1;
M_SIZE(toSelect_short, toSelect_long, 4) = -1;
% check_4 = M_SIZE(:,:,4);
% sum(M_SIZE(:,:,4)>0, 'all')


% ---- SEQ MEP STEP 2-3: record the MEP compo pairs which have very different sectional areas
M_section = zeros(height(tableCompo_mep), height(tableCompo_mep), 2);
size_sorted = sort([tableCompo_mep{:,'Size_X'}, tableCompo_mep{:,'Size_Y'}, tableCompo_mep{:,'Size_Z'}], 2, 'ascend');
toSelect_large = size_sorted(:,1) .* size_sorted(:,2) > D_crosssec_large;  % mm2
toSelect_small = size_sorted(:,1) .* size_sorted(:,2) < D_crosssec_small;
M_section(toSelect_large,:,1) = 1;
M_section(:,toSelect_large,1) = 1;
M_section(toSelect_small,:,2) = 1;
M_section(:,toSelect_small,2) = 1;
M_SIZE(toSelect_large, toSelect_small, 5) = 1;
M_SIZE(toSelect_small, toSelect_large, 5) = -1;
% sum(M_SIZE(:,:,5)>0, 'all')

% ---- SEQ MEP STEP 2-4: find M2_seq based on M_length and M_section
% write non-zero values in M_length into M2_seq first
% if non-zero values in M_section is not in conflict with M2_seq, then write non-zero values in M_section
M2_seq = zeros(height(tableCompo_mep), height(tableCompo_mep));
bool_lengthBefSectionArea = 1;  % for customisable rules later 
if bool_lengthBefSectionArea == 1
    % two compo are close enough and overlap in >= 2 dimensions
    toSelect_close = M_SIZE(:,:,1) + M_SIZE(:,:,2) + M_SIZE(:,:,3) >= 5;
    
    toSelect_M_SIZE_4 = M_SIZE(:,:,4) == 1;
    M2_seq(toSelect_close & toSelect_M_SIZE_4) = 1;
    toSelect_M_SIZE_4 = M_SIZE(:,:,4) == -1;
    M2_seq(toSelect_close & toSelect_M_SIZE_4) = -1;
    sum(M2_seq>0, 'all');
    
    toSelect_M_SIZE_5 = M_SIZE(:,:,5) == 1;
    toSelect_M2_seq_zero = M2_seq == 0;
    M2_seq(toSelect_close & toSelect_M_SIZE_5 & toSelect_M2_seq_zero) = 1;
    toSelect_M_SIZE_5 = M_SIZE(:,:,5) == -1;
    toSelect_M2_seq_zero = M2_seq == 0;
    M2_seq(toSelect_close & toSelect_M_SIZE_5 & toSelect_M2_seq_zero) = -1;
end
% disp(['No. MEP compo pairs with CSR: ', num2str(sum(M2_seq>0, 'all'))])
