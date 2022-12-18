function [x0, x0_reshaped_after, ESa, EFa, ESar, EFar, Uard_sumA] = func_generateInitialSolution_v3(duration, cost, nA, nD, nR, nM, nvars, ...
    Qrd, seq_pred_x0, seq_succ_x0, buffer, UR_ar, URp_ar, options)

n1Res = 2+nM+3*nD;
n1Act = 2+nR*(2+nM+3*nD);

% To initialise the initial solution
x0 = zeros(1,nvars);
ESa = zeros(nA,1);
EFa = zeros(nA,1);
ESar = zeros(nA, nR);
EFar = zeros(nA, nR);

for a = 1:nA
    % initialise ES_a = 1, EF_a = 0:
    x0((a-1)*n1Act + 1) = 1;
    x0((a-1)*n1Act + 2) = 0;
    ESa(a) = 1;
    EFa(a) = 0;
    for res = 1:nR
        % initialise ES_ar = 1, EF_ar = 0:
        x0((a-1)*n1Act + 2 + (res-1)*n1Res + 1) = 1;
        x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2) = 0;
        ESar(a,res) = 1;
        EFar(a,res) = 0;
        % initialise M_ar1 = 1:
        x0((a-1)*n1Act + 2 + (res-1)*n1Res + 3) = 1;
        % initialise U_ard = 0, Z_ard = 1, Zp_ard = 0:
        for d = 1:nD
            x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + d) = 0;
            x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + nD + d) = 1;
            x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + 2*nD + d) = 0;
        end
    end
end
% x0_reshaped = reshape(x0, n1Act, nA)';  % to check


%% To assign values based on precedence, res availability

% assuming the activities with lower indices are executed before activities with higher indices
% i.e. seq_pred(i) < seq_succ(i)

Uard = zeros(nA, nR, nD);
Uard_sumA = zeros(nR, nD);

for a = 1:nA
    for res = 1:nR
        % EF_ar = ES_ar + duration - 1
        EFar(a,res) = ESar(a,res) + duration(a,res,1) - 1;
        % update ES_a or later?
    end
    
    % first, check if a is inside the successor list ======================================
    if isempty(find(seq_succ_x0 == a, 1))  % if not inside the successor list ================
        % check if there is enough resource available during the span of the activity
        % for each r and d
        for res = 1:nR
            
            % updated res checking 0917 -------------------------------------------------
            d_toCheck = ESar(a,res);
            for checktimes = ESar(a,res):nD
                flagToBreakOutOfNestedLoop2_count = 0;
                for d_delta = 0 : duration(a,res,1) - 1
                    d = d_toCheck + d_delta;
                    if Uard_sumA(res,d) + 1 > Qrd(res,d)  % if not enough res availibility
                        d_toCheck = d_toCheck + 1;  % if not enough res, then check the next day
                        earliestDate = d_toCheck;

                    else  % if there is enough res availability
                        flagToBreakOutOfNestedLoop2_count = ...
                            flagToBreakOutOfNestedLoop2_count + 1; % count how many days checked have enough res
                        earliestDate = d_toCheck;  % no effect here, but to prevent isempty(earliestDate)                           
                    end
                    % if enough res for all d_delta, then break out of this nested for loop
                    if (flagToBreakOutOfNestedLoop2_count == duration(a,res,1))
                        break
                    end
                end
            end
            
            % update ES_ar, EF_ar
            % ES_ar = earliestIdx
            ESar(a,res) = earliestDate;
            % EF_ar = ES_ar + duration - 1
            EFar(a,res) = ESar(a,res) + duration(a,res,1) - 1;
            % update Uard, Uard_sumA, based on ES_ar, EF_ar
            for d = ESar(a,res) : EFar(a,res)
                Uard(a,res,d) = Uard(a,res,d) + 1;
                Uard_sumA(res,d) = sum(Uard(:,res,d), 'all'); 
            end
        end
        % update ESa, EFa
        ESa(a) = min(UR_ar(a,:).*ESar(a,:));
        EFa(a) = max(URp_ar(a,:).*EFar(a,:));
        
    else  % if inside the successor list =================================================
        % find all its predecessors
        pred_list = find(seq_succ_x0 == a);
        % find the max (EF + buffer) date of all predecessors
        pred_EF_plusBuffer = max(EFa(seq_pred_x0(pred_list)) + buffer(pred_list)');
        
        % ES_ar should at least > pred_EF_plusBuffer + 1
        for res = 1:nR
            % EF_ar = ES_ar + duration - 1
            ESar(a,res) = pred_EF_plusBuffer + 1;
            EFar(a,res) = ESar(a,res) + duration(a,res,1) - 1;
            % update ES_a or later?
        end
        
        % check if there is enough resource available during the span of the activity
        % for each r and d
        for res = 1:nR
            % updated res checking 0917 -------------------------------------------------
            d_toCheck = ESar(a,res);
            for checktimes = ESar(a,res):nD
                flagToBreakOutOfNestedLoop2_count = 0;
                for d_delta = 0 : duration(a,res,1) - 1
                    d = d_toCheck + d_delta;
                    if Uard_sumA(res,d) + 1 > Qrd(res,d)  % if not enough res availibility
                        d_toCheck = d_toCheck + 1;  % if not enough res, then check the next day
                        earliestDate = d_toCheck;

                    else  % if there is enough res availability
                        flagToBreakOutOfNestedLoop2_count = ...
                            flagToBreakOutOfNestedLoop2_count + 1; % count how many days checked have enough res
                        earliestDate = d_toCheck;  % no effect here, but to prevent isempty(earliestDate)                           
                    end
                    % if enough res for all d_delta, then break out of this nested for loop
                    if (flagToBreakOutOfNestedLoop2_count == duration(a,res,1))
                        break
                    end
                end
            end         
         
            % ES_ar = max{pred_EF_plusBuffer, earliestDate}
            ESar(a, res) = max(pred_EF_plusBuffer + 1, earliestDate);
            % EF_ar = ES_ar + duration - 1
            EFar(a,res) = ESar(a,res) + duration(a,res,1) - 1;
            % update Uard, Uard_sumA, based on ES_ar, EF_ar
            for d = ESar(a,res) : EFar(a,res)
                Uard(a,res,d) = Uard(a,res,d) + 1;
                Uard_sumA(res,d) = sum(Uard(:,res,d), 'all'); 
            end
            % update ESa, EFa
            ESa(a) = min(UR_ar(a,:).*ESar(a,:));
            EFa(a) = max(URp_ar(a,:).*EFar(a,:));
        end
    end
    
    
    % (newly added, to resolve unrealistic assumption 1) ===========================================
    % ==============================================================================================
    % ==============================================================================================
    % check if there are act which are successors of act a but have smaller indices
    % if so, need to move those act to later
    toPush = zeros(nA, 1);  % bool, to record all act to push, =1 if need to push
    allSuccActIdx = seq_pred_x0 == a;
    if sum(allSuccActIdx, 'all') > 0  % if a does have successors
        ii = allSuccActIdx == 1 & seq_succ_x0 < a;  % compare the idx of successors with idx of a
        allSuccActIdxWSmallerIdx = seq_succ_x0(ii);
        
        % update the list toPush, recording all successors of smaller indices plus their successors
        flagToBreak = false;
        if ~isempty(allSuccActIdxWSmallerIdx)
            while flagToBreak == false
                % record those indices
                toPush(allSuccActIdxWSmallerIdx) = 1;
                %temp = allSuccActIdxWSmallerIdx;
                for loop = 1:nA
                    %temp = allSuccActIdxWSmallerIdx;   % so can update and check elements in new allSuccActIdxWSmallerIdx each time
                    for act = 1:length(allSuccActIdxWSmallerIdx)  % for each of those successors 
                        allSuccActIdx_2 = seq_pred_x0 == allSuccActIdxWSmallerIdx(act); % find their successors
                        if sum(allSuccActIdx_2, 'all') > 0  % if they do have successors
                            % no need to check the indices of their successors, but record all
                            toPush(seq_succ_x0(allSuccActIdx_2)) = 1;
                            allSuccActIdxWSmallerIdx_toAdd = seq_succ_x0(allSuccActIdx_2);
                            % if they do not have successors, then check the next num in allSuccActIdxWSmallerIdx

                            % now check if all the new successors identified have been included
                            % in allSuccActIdxWSmallerIdx already
                            if ismember(allSuccActIdxWSmallerIdx_toAdd, allSuccActIdxWSmallerIdx) ...
                                    == length(allSuccActIdxWSmallerIdx_toAdd)
                                flagToBreak = true;
                                allSuccActIdxWSmallerIdx = unique(allSuccActIdxWSmallerIdx);  % delete duplicates
                            else 
                                allSuccActIdxWSmallerIdx = [allSuccActIdxWSmallerIdx, allSuccActIdxWSmallerIdx_toAdd]; % inefficient
                                allSuccActIdxWSmallerIdx = unique(allSuccActIdxWSmallerIdx);  % delete duplicates
                            end
                        end
                    end
                end
            end
        end
        
        for loop = 1:nA-1  % not sure how many levels of successors
            if ~isempty(allSuccActIdxWSmallerIdx)  % if there are successors with smaller indices than a -> to push
                % record those indices
                toPush(allSuccActIdxWSmallerIdx) = 1;
                for act = 1:length(allSuccActIdxWSmallerIdx)  % for each of those successors          
                    allSuccActIdx_2 = seq_pred_x0 == allSuccActIdxWSmallerIdx(act); % find their successors
                    if sum(allSuccActIdx_2, 'all') > 0  % if they do have successors
                        % no need to check the indices of their successors, but record all
                        toPush(seq_succ_x0(allSuccActIdx_2)) = 1;
                        % allSuccActIdxWSmallerIdx = [allSuccActIdxWSmallerIdx, seq_succ_x0(allSuccActIdx_2)];  % inefficient
                    else
                        break  % if they do not have successors, then check the next num in allSuccActIdxWSmallerIdx
                    end
                end
                allSuccActIdxWSmallerIdx = seq_succ_x0(allSuccActIdx_2);
                
                
            end     
        end
%         % update the list toPush, recording all successors of smaller indices plus their successors
%         for loop = 1:nA-1  % not sure how many levels of successors
%             if ~isempty(allSuccActIdxWSmallerIdx)  % if there are successors with smaller indices than a -> to push
%                 % record those indices
%                 toPush(allSuccActIdxWSmallerIdx) = 1;
%                 for act = 1:length(allSuccActIdxWSmallerIdx)  % for each of those successors          
%                     allSuccActIdx_2 = seq_pred_x0 == allSuccActIdxWSmallerIdx(act); % find their successors
%                     if sum(allSuccActIdx_2, 'all') > 0  % if they do have successors
%                         % no need to check the indices of their successors, but record all
%                         toPush(seq_succ_x0(allSuccActIdx_2)) = 1;
%                         % allSuccActIdxWSmallerIdx = [allSuccActIdxWSmallerIdx, seq_succ_x0(allSuccActIdx_2)];  % inefficient
%                     else
%                         break  % if they do not have successors, then check the next num in allSuccActIdxWSmallerIdx
%                     end
%                 end
%                 allSuccActIdxWSmallerIdx = seq_succ_x0(allSuccActIdx_2);
%             end     
%         end
        
        
        
        
        % now, push all the act in toPush, to: max{original ESar(actToPush), EFa + 1}
        % i.e. push by: max{original ESar(actToPush) - original ESar(actToPush), EFa + 1 - original ESar(actToPush)}
        % if no act in toPush, then no effect
        for actToPush = 1:length(toPush)
            if toPush(actToPush) == 1 && actToPush < a % act to push  & UPDATED1026-----------------------------------------=============
                for res = 1:nR
                    % first reset Uard and Uard_sumA
                    % before the res avaialbility is checked for the pushed dates
                    for d = ESar(actToPush,res) : EFar(actToPush,res)
                        Uard(actToPush,res,d) = Uard(actToPush,res,d) - 1;  % reset
                        Uard_sumA(res,d) = sum(Uard(:,res,d), 'all');  % reset
                    end
                    
                    % push ES_ar, EF_ar
                    ESar_orig = ESar(actToPush, res);
                    ESar(actToPush, res) = ESar(actToPush, res) + max(0, EFar(a, res)+1 - ESar_orig);  % should + buffer!
                    EFar(actToPush, res) = EFar(actToPush, res) + max(0, EFar(a, res)+1 - ESar_orig);
                           
                    
                    
                    if ~isempty(find(seq_succ_x0 == actToPush, 1))  % if inside the successor list ================
                        % find all its predecessors
                        pred_list = find(seq_succ_x0 == actToPush);
                        % find the max (EF + buffer) date of all predecessors
                        pred_EF_plusBuffer = max(EFa(seq_pred_x0(pred_list)) + buffer(pred_list)');

                        % ES_ar should at least > pred_EF_plusBuffer + 1
                        % EF_ar = ES_ar + duration - 1
                        ESar(actToPush,res) = max(ESar(actToPush, res), pred_EF_plusBuffer + 1);
                        EFar(actToPush,res) = ESar(actToPush,res) + duration(actToPush,res,1) - 1;
                    end    
                                        
                    
                    % after the reset, check if the pushed dates have enough resources available
                    % check if there is enough resource available during the span of the activity
                    % for each r and d
                    % updated res checking 0917 -------------------------------------------------
                    d_toCheck = ESar(actToPush,res);
                    for checktimes = ESar(actToPush,res):nD
                        flagToBreakOutOfNestedLoop2_count = 0;
                        for d_delta = 0 : duration(actToPush,res,1) - 1
                            d = d_toCheck + d_delta;
                            if Uard_sumA(res,d) + 1 > Qrd(res,d)  % if not enough res availibility
                                d_toCheck = d_toCheck + 1;  % if not enough res, then check the next day
                                earliestDate = d_toCheck;  
                            else  % if there is enough res availability
                                flagToBreakOutOfNestedLoop2_count = ...
                                    flagToBreakOutOfNestedLoop2_count + 1; % count how many days checked have enough res
                                earliestDate = d_toCheck;  % no effect here, but to prevent isempty(earliestDate)                           
                            end
                            % if enough res for all d_delta, then break out of this nested for loop
                            if (flagToBreakOutOfNestedLoop2_count == duration(actToPush,res,1))
                                break
                            end
                        end
                    end

                    % ES_ar = max{pred_EF_plusBuffer, earliestDate}
                    ESar(actToPush,res) = max(ESar(actToPush,res), earliestDate);
                    % EF_ar = ES_ar + duration - 1
                    EFar(actToPush,res) = ESar(actToPush,res) + duration(actToPush,res,1) - 1;
                    % update Uard, Uard_sumA, based on ES_ar, EF_ar
                    for d = ESar(actToPush,res) : EFar(actToPush,res)
                        Uard(actToPush,res,d) = Uard(actToPush,res,d) + 1;
                        Uard_sumA(res,d) = sum(Uard(:,res,d), 'all'); 
                    end
                    % update ESa, EFa
                    ESa(actToPush) = min(UR_ar(actToPush,:).*ESar(actToPush,:));
                    EFa(actToPush) = max(URp_ar(actToPush,:).*EFar(actToPush,:));
                end
            
                
            
                % second level loop ============================================================================
                % ==============================================================================================

                % check if there are act which are successors of act a but have smaller indices
                % if so, need to move those act to later
                toPush2 = zeros(nA, 1);  % bool, to record all act to push, =1 if need to push
                allSuccActIdx2 = seq_pred_x0 == actToPush;
                if sum(allSuccActIdx2, 'all') > 0  % if a does have successors
                    
                    % newly modified: all successors affected by actToPush should be pushed
                    toPush2(seq_succ_x0(allSuccActIdx2)) = 1;
                    ii2 = allSuccActIdx2 == 1 & seq_succ_x0 < actToPush;  % compare the idx of successors with idx of a
                    allSuccActIdxWSmallerIdx2 = seq_succ_x0(ii2);
                    for loop2 = 1:nA-1  % not sure how many levels of successors
                        if ~isempty(allSuccActIdxWSmallerIdx2)  % if there are successors with smaller indices than a -> to push
                            % record those indices
                            toPush2(allSuccActIdxWSmallerIdx2) = 1;
                            for act2 = 1:length(allSuccActIdxWSmallerIdx2)  % for each of those successors          
                                allSuccActIdx_2 = seq_pred_x0 == allSuccActIdxWSmallerIdx2(act2); % find their sucessors
                                if sum(allSuccActIdx_2, 'all') > 0  % if they do have successors
                                    % no need to check the indices of their successors, but record all
                                    toPush2(seq_succ_x0(allSuccActIdx_2)) = 1;
                                else
                                    break
                                end
                            end
                            allSuccActIdxWSmallerIdx2 = seq_succ_x0(allSuccActIdx_2);
                        end     
                    end
                

                    % now, push all the act in toPush, to: max{original ESar(actToPush), EFa + 1}
                    % i.e. push by: max{original ESar(actToPush) - original ESar(actToPush), EFa + 1 - original ESar(actToPush)}
                    % if no act in toPush, then no effect
                    for actToPush2 = 1:length(toPush2)
                        if toPush2(actToPush2) == 1  && actToPush2 < actToPush % act to push  & UPDATED1026---------------------------=============
                            for res = 1:nR
                                % first reset Uard and Uard_sumA
                                % before the res avaialbility is checked for the pushed dates
                                for d = ESar(actToPush2,res) : EFar(actToPush2,res)
                                    Uard(actToPush2,res,d) = Uard(actToPush2,res,d) - 1;  % reset
                                    Uard_sumA(res,d) = sum(Uard(:,res,d), 'all');  % reset
                                end

                                % push ES_ar, EF_ar
                                ESar_orig = ESar(actToPush2, res);
                                ESar(actToPush2, res) = ESar(actToPush2, res) + max(0, EFar(actToPush, res)+1 - ESar_orig);  % should + buffer!
                                EFar(actToPush2, res) = EFar(actToPush2, res) + max(0, EFar(actToPush, res)+1 - ESar_orig);


                                % after the reset, check if the pushed dates have enough resources available
                                % check if there is enough resource available during the span of the activity
                                % for each r and d

                                % newly added:
                                % if res not used, then break out of loop
                                if ESar(actToPush2,res) - 1 ~= EFar(actToPush2,res)  % res r is used

                                    % updated res checking 0917 -------------------------------------------------
                                    d_toCheck = ESar(actToPush2,res);
                                    for checktimes = ESar(actToPush2,res):nD
                                        flagToBreakOutOfNestedLoop2_count = 0;
                                        for d_delta = 0 : duration(actToPush2,res,1) - 1
                                            d = d_toCheck + d_delta;
                                            if Uard_sumA(res,d) + 1 > Qrd(res,d)  % if not enough res availibility
                                                d_toCheck = d_toCheck + 1;  % if not enough res, then check the next day
                                                earliestDate2 = d_toCheck;
                                            else  % if there is enough res availability
                                                flagToBreakOutOfNestedLoop2_count = ...
                                                    flagToBreakOutOfNestedLoop2_count + 1; % count how many days checked have enough res
                                                earliestDate2 = d_toCheck;  % no effect here, but to prevent isempty(earliestDate)                           
                                            end
                                            % if enough res for all d_delta, then break out of this nested for loop
                                            if (flagToBreakOutOfNestedLoop2_count == duration(actToPush2,res,1))
                                                break
                                            end
                                        end
                                    end
 

                                    % ES_ar = max{pred_EF_plusBuffer, earliestDate}
                                    ESar(actToPush2, res) = max(ESar(actToPush2,res), earliestDate2);
                                    % EF_ar = ES_ar + duration - 1
                                    EFar(actToPush2,res) = ESar(actToPush2,res) + duration(actToPush2,res,1) - 1;
                                    % update Uard, Uard_sumA, based on ES_ar, EF_ar
                                    for d = ESar(actToPush2,res) : EFar(actToPush2,res)
                                        Uard(actToPush2,res,d) = Uard(actToPush2,res,d) + 1;
                                        Uard_sumA(res,d) = sum(Uard(:,res,d), 'all'); 
                                    end
                                    % update ESa, EFa
                                    ESa(actToPush2) = min(UR_ar(actToPush2,:).*ESar(actToPush2,:));
                                    EFa(actToPush2) = max(URp_ar(actToPush2,:).*EFar(actToPush2,:));
                                end
                            end
                        end
                    end
                end 
            end          
        end       
    end  
end


ESEFar = [ESar, EFar];
ESEFa = [ESa, EFa];

%% push ES and EF to the earliest possiple, without affecting other activities

for instance = 1:10
    [ESa, EFa, ESar, EFar, Uard_sumA, Uard] = func_generateInitialSolution_pushAct...
            (nA, nR, seq_pred_x0, seq_succ_x0, duration, Qrd, UR_ar, URp_ar, buffer, ...
            ESa, EFa, ESar, EFar, Uard_sumA, Uard);
end

for instance = 1:2
    [ESa, EFa, ESar, EFar, Uard_sumA, Uard] = func_generateInitialSolution_pushAct_reversed...
            (nA, nR, seq_pred_x0, seq_succ_x0, duration, Qrd, UR_ar, URp_ar, buffer, ...
            ESa, EFa, ESar, EFar, Uard_sumA, Uard);
end

for instance = 1:10
    [ESa, EFa, ESar, EFar, Uard_sumA, Uard] = func_generateInitialSolution_pushAct...
            (nA, nR, seq_pred_x0, seq_succ_x0, duration, Qrd, UR_ar, URp_ar, buffer, ...
            ESa, EFa, ESar, EFar, Uard_sumA, Uard);
end







%%
% update x0

% modify ESar(a,res) and EFar(a,res) for the resource unused
% to avoid constraint violation in inequality matrix A * x0
for a = 1:nA
    for res = 1:nR  
        if ESar(a,res) - 1 == EFar(a,res)  % res r is not used
            for res2 = 1:nR  % UPDATED1011 -----------
                if ESar(a,res2) - 1 ~= EFar(a,res2)
                    ESar(a,res) = ESar(a,res2);
                    EFar(a,res) = ESar(a,res) - 1;
                end
            end
        end
    end
end

for a = 1:nA
    % update ES_a & EF_a
    x0((a-1)*n1Act + 1) = ESa(a);
    x0((a-1)*n1Act + 2) = EFa(a);
    for res = 1:nR
        % update ES_ar & EF_ar
        x0((a-1)*n1Act + 2 + (res-1)*n1Res + 1) = ESar(a,res);
        x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2) = EFar(a,res);
    end
end


for a = 1:nA
    for res = 1:nR
        for d = 1:nD
            % U_ard, Z_ard, Zp_ard
            if d < ESar(a,res)
                x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + d) = 0;  % U_ard
                x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + nD + d) = 0;  % Z_ard
                x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + 2*nD + d) = 1;  % Zp_ard
            elseif d >= ESar(a,res) && d <= EFar(a,res)
                x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + d) = 1;  % U_ard
                x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + nD + d) = 1;  % Z_ard
                x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + 2*nD + d) = 1;  % Zp_ard
            else 
                x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + d) = 0;  % U_ard
                x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + nD + d) = 1;  % Z_ard
                x0((a-1)*n1Act + 2 + (res-1)*n1Res + 2 + nM + 2*nD + d) = 0;  % Zp_ard
            end
        end
    end
end




x0_reshaped_after = reshape(x0, n1Act, nA)';  % to check



%{
important assumptions:

assumption 1 should have been dealt with in this version

1.  The act idx in seq_prec is smaller than the act idx in seq_succ
    otherwise, some precedence may not be satisfied, coz in max{EF of pred + buffer, earliest date with available res},
    EF of pred may be the default value 0.
2.  Assume Qrd remains the same for all days
    earliestDate = find(Uard_sumA(res,:) == Qrd(res,d)-qrd, 1) is inaccurate,
    as the earliest date found may have a different Qrd than the Qrd(res,d) in Day d.
%}










