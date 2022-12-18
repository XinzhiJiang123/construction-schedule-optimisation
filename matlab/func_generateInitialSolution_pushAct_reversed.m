function [ESa, EFa, ESar, EFar, Uard_sumA, Uard] = func_generateInitialSolution_pushAct_reversed...
        (nA, nR, seq_pred_x0, seq_succ_x0, duration, Qrd, UR_ar, URp_ar, buffer, ...
        ESa, EFa, ESar, EFar, Uard_sumA, Uard)
for a = nA:-1:1
    if ~isempty(find(seq_succ_x0 == a, 1))  % if inside the successor list
        % find all its predecessors
        pred_list = find(seq_succ_x0 == a);
        % find the max (EF + buffer) date of all predecessors
        pred_EF_plusBuffer = max(EFa(seq_pred_x0(pred_list)) + buffer(pred_list)');
    else  % if not inside the successor list
        pred_EF_plusBuffer = 1;
    end
    % check if there is enough resource available during the span of the activity
    % for each r and d
    for res = 1:nR
        % res checking
        d_toCheck = pred_EF_plusBuffer + 1;
        for checktimes = pred_EF_plusBuffer : ESar(a,res)
            flagToBreakOutOfNestedLoop2_count = 0;
            if duration(a,res,1) ~= 0
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
            else
                earliestDate = d_toCheck;
            end
        end  
        
        if ESar(a, res) > earliestDate  % if an earlier date is really possible and checked for res availability
            % reset Uard and Uard_sumA
            for d = ESar(a,res) : EFar(a,res)
                Uard(a,res,d) = Uard(a,res,d) - 1;  % reset
                Uard_sumA(res,d) = sum(Uard(:,res,d), 'all');  % reset
            end
            % ES_ar = max{pred_EF_plusBuffer, earliestDate}
            ESar(a, res) = earliestDate;
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
    end
end
ESEFar = [ESar, EFar];
ESEFa = [ESa, EFa];
end