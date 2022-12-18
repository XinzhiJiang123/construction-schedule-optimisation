function [sol_re, sol_re2] = func_writeSol...
    (sol, pjStart, NumberHolidays, nR, nA, tableZoned_struct, tableZoned_mep_splitted, seq_pred, seq_succ, nAllEleGuid)
% write the schedule result (one row for one activity including all resources)
% integrate different rows for one activity with different resources into one row
varTypes = ["double", "string", repmat("double", 1, 1), "datetime", "datetime", "string", "string"];
varNames = ["No.", "Task Name", "Duration", "Start (ES_Act)", "Finish (EF_Act)", "Resources", "Predecessor"];
sz = [nA-1, length(varNames)];  % without dummy finish  % UPDATED1003 ----------------------
sol_re = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
for a = 1:nA-1  % without dummy finish  % UPDATED1003 ----------------------
    sol_re{a,4} = datewrkdy(pjStart, round(sol{(a-1)*nR+1,"ES_Act"}), NumberHolidays); % need to round
    sol_re{a,5} = datewrkdy(pjStart, round(sol{(a-1)*nR+1,"EF_Act"}), NumberHolidays);
    sol_re{a,"Duration"} = round(sol{(a-1)*nR+1,"EF_Act"}) - round(sol{(a-1)*nR+1,"ES_Act"}) +1;
    sol_re{a,1} = a;
end
sol_re{:,"Task Name"} = [string(tableZoned_struct{:,"ActName"}); string(tableZoned_mep_splitted{:,"ActName"})];
% write the predecessors to the table
sol_re{:,"Predecessor"} = repmat("0", nA-1, 1);  % without dummy finish  % UPDATED1003 -----------------
for i = 1:length(seq_pred)
    if seq_succ(i) <= nA-1  % without dummy finish  % UPDATED1003 -----------------
    if sol_re{seq_succ(i),"Predecessor"} == "0"
        sol_re{seq_succ(i),"Predecessor"} = seq_pred(i);
    else
        sol_re{seq_succ(i),"Predecessor"} = strcat(sol_re{seq_succ(i),"Predecessor"},",", int2str(seq_pred(i)));
    end
    end
end
for a = 1:nA-1  % without dummy finish  % UPDATED1003 ----------------------
    if sol_re{a,"Predecessor"} == "0"
        sol_re{a,"Predecessor"} = " ";
    end
end


% with a dummy activity as predecessor for all activities
% insert a dummy row as the first activity
% and later increase all activity indices by one
%{
'Note: the ProjectStart date should be set at the actual date
'Then together with 1-day dummy activity as predecessor for all activities
'can the activities starting at the actual starting date have the correct length
'in the gantt chart
%}
% dummydate = datewrkdy(pjStart, -2, NumberHolidays);
dummydate = pjStart;
dummyAct = {1,"Project start",1, dummydate, dummydate, "", ""};
sol_re2 = [dummyAct; sol_re];
sol_re2{:,"Predecessor"} = repmat("0", nA, 1); % without dummy finish  % UPDATED1003 ----------------------
for nGuid = 1:nAllEleGuid
    sol_re2{:, ['AllEleGuid',num2str(nGuid)]} = repmat(" ", nA, 1);  % without dummy finish  % UPDATED1003 -----
end

for i = 1:length(seq_pred)
    if seq_succ(i) <= nA-1  % without dummy finish  % UPDATED1003 -----------------
    if sol_re2{seq_succ(i)+1,"Predecessor"} == "0"
        sol_re2{seq_succ(i)+1,"Predecessor"} = seq_pred(i)+1;  % +1 for the dummy "project start" activity
    else
        sol_re2{seq_succ(i)+1,"Predecessor"} = strcat(sol_re2{seq_succ(i)+1,"Predecessor"},",", int2str(seq_pred(i)+1));
    end
    end
end
% add the dummy "project start" activity as predecessor for all other activities
for a = 1:nA-1  % without dummy finish  % UPDATED1003 ----------------------
    if sol_re2{a+1,"Predecessor"} == "0"
        sol_re2{a+1,"Predecessor"} = "1";
    else
        sol_re2{a+1,"Predecessor"} = strcat(sol_re2{a+1,"Predecessor"},",","1");
    end
end
for a = 1:nA  % without dummy finish  % UPDATED1003 ----------------------
    if sol_re2{a,"Predecessor"} == "0"
        sol_re2{a,"Predecessor"} = " ";
    end
    sol_re{a,1} = a;
end
for nGuid = 1:nAllEleGuid
    sol_re2{2:end, ['AllEleGuid',num2str(nGuid)]} = ...
        [tableZoned_struct{:, ['AllEleGuid',num2str(nGuid)]}; tableZoned_mep_splitted{:, ['AllEleGuid',num2str(nGuid)]}];
end