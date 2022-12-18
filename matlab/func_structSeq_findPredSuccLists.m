function [seq_pred_struct, seq_succ_struct, buffer_struct] = func_structSeq_findPredSuccLists( ...
    tableZoned_struct, ...
    classEssential_struct, classNonEssential_struct, classSeq_struct, ...
    nZ, SpecSeqName, SpecSeqName_countNonUndefined, ...
    classToSeq_S1_2, beforeAfter_bool, levelToSeq_S1_1, levelToSeq_S1_2)

seq_pred_struct = zeros(height(tableZoned_struct)*(height(tableZoned_struct)-1), 1);
seq_succ_struct = zeros(height(tableZoned_struct)*(height(tableZoned_struct)-1), 1);
% columns, beams, slabs: should wait for both the columns and beams in the floor below are completed
% walls: wait for the walls in the floor below are completed
%             classEssential_struct = categorical(["Foundation", "Column", "Beam", "Slab"]);  % UPDATED0912 ------------
%             classNonEssential_struct = categorical("Wall");

for i = 1:height(tableZoned_struct)
    for j = i+1:height(tableZoned_struct)
        % Same floor, different zone: no seq constraints for now
        if tableZoned_struct{i,'Zone'} == tableZoned_struct{j,'Zone'}


            if i > height(tableZoned_struct) - nZ*SpecSeqName_countNonUndefined ...
                || j > height(tableZoned_struct) - nZ*SpecSeqName_countNonUndefined
                % deal with the special cases first
                % then move to the next iteration without executing the rest
                % for now, only one SpecSeqName
                if contains(tableZoned_struct{i,'ActName'}, string(SpecSeqName(1)), 'IgnoreCase',true)
                    if tableZoned_struct{i,'Floor'} == levelToSeq_S1_1 ...
                            && tableZoned_struct{j,'Floor'} == levelToSeq_S1_2
                        if tableZoned_struct{j,'Class'} == categorical(string(classToSeq_S1_2))
                            if beforeAfter_bool == 1  % i is before j
                                seq_pred_struct((i-1)*height(tableZoned_struct)+j) = i;
                                seq_succ_struct((i-1)*height(tableZoned_struct)+j) = j;
                            else  % j is before i
                                seq_pred_struct((i-1)*height(tableZoned_struct)+j) = j;
                                seq_succ_struct((i-1)*height(tableZoned_struct)+j) = i;
                            end
                            continue  % jump to the next j
                        end
                    end
                elseif contains(tableZoned_struct{j,'ActName'}, string(SpecSeqName(1)), 'IgnoreCase',true)
                    if tableZoned_struct{i,'Floor'} == levelToSeq_S1_2 ...
                            && tableZoned_struct{j,'Floor'} == levelToSeq_S1_1
                        if tableZoned_struct{i,'Class'} == categorical(string(classToSeq_S1_2))
                            if beforeAfter_bool == 1  % j is before i
                                seq_pred_struct((i-1)*height(tableZoned_struct)+j) = j;
                                seq_succ_struct((i-1)*height(tableZoned_struct)+j) = i;
                            else  % i is before j
                                seq_pred_struct((i-1)*height(tableZoned_struct)+j) = i;
                                seq_succ_struct((i-1)*height(tableZoned_struct)+j) = j;
                            end
                            continue  % jump to the next j
                        end
                    end
                end




            else
                % ==== CASE 1.1: Same zone, different floors, both in Essential structure classes:
                % if sum(tableZoned{i,'Class'} == classEssential) > 0 % if the class is found in classEssential array
                %     if sum(tableZoned{j,'Class'} == classEssential) > 0 % if the class is found in classEssential array
                if sum(tableZoned_struct{i,'Class'} == classEssential_struct) * ...
                        sum(tableZoned_struct{j,'Class'} == classEssential_struct) > 0
                    % if both classes are found in classEssential array
                    if tableZoned_struct{i,'Floor'} +1 == tableZoned_struct{j,'Floor'}  % UPDATED0912 ----------
                        seq_pred_struct((i-1)*height(tableZoned_struct)+j) = i;
                        seq_succ_struct((i-1)*height(tableZoned_struct)+j) = j;
                    elseif tableZoned_struct{i,'Floor'} -1 == tableZoned_struct{j,'Floor'}  % UPDATED0912 ----------
                        seq_pred_struct((i-1)*height(tableZoned_struct)+j) = j;
                        seq_succ_struct((i-1)*height(tableZoned_struct)+j) = i;
                    end
                end

                % ==== CASE 1.2: Same zone, different floors, both in Non-essential structure classes:
                if sum(tableZoned_struct{i,'Class'} == classNonEssential_struct) * ...
                        sum(tableZoned_struct{j,'Class'} == classNonEssential_struct) > 0
                    % if both classes are found in classNonEssential array
                    if tableZoned_struct{i,'Floor'} +1 == tableZoned_struct{j,'Floor'}  % UPDATED0912 ----------
                        seq_pred_struct((i-1)*height(tableZoned_struct)+j) = i;
                        seq_succ_struct((i-1)*height(tableZoned_struct)+j) = j;
                    elseif tableZoned_struct{i,'Floor'} -1 == tableZoned_struct{j,'Floor'}  % UPDATED0912 ----------
                        seq_pred_struct((i-1)*height(tableZoned_struct)+j) = j;
                        seq_succ_struct((i-1)*height(tableZoned_struct)+j) = i;
                    end
                end

                % ==== CASE 2.1: Same zone, same floor, different activity types:
                % classSeq_struct = categorical(["Column", "Beam", "Slab", "Wall"]); % in general execution sequence
                if tableZoned_struct{i,'Floor'} == tableZoned_struct{j,'Floor'} 
                    for class = 1:length(classSeq_struct)-1
                        if tableZoned_struct{i,'Class'} == classSeq_struct(class)
                            if sum(tableZoned_struct{j,'Class'} == classSeq_struct(class+1:end)) > 0 % if row j is found to the right of i's class
                                seq_pred_struct((i-1)*height(tableZoned_struct)+j) = i;
                                seq_succ_struct((i-1)*height(tableZoned_struct)+j) = j;
                            elseif sum(tableZoned_struct{j,'Class'} == classSeq_struct(1:class)) > 0 % if row j is found to the left of i's class
                                seq_pred_struct((i-1)*height(tableZoned_struct)+j) = j;
                                seq_succ_struct((i-1)*height(tableZoned_struct)+j) = i;
                            end
                        end
                    end
                end
            end
            else   % different zones
            % ==== CASE 3.1: Different zone, same floor, same activity types:
            if tableZoned_struct{i,'Floor'} == tableZoned_struct{j,'Floor'} && ...
                tableZoned_struct{i,'Class'} == tableZoned_struct{j,'Class'}
                if tableZoned_struct{i,'Zone'} < tableZoned_struct{j,'Zone'} 
                    seq_pred_struct((i-1)*height(tableZoned_struct)+j) = i;
                    seq_succ_struct((i-1)*height(tableZoned_struct)+j) = j;
                elseif tableZoned_struct{i,'Zone'} > tableZoned_struct{j,'Zone'} 
                    seq_pred_struct((i-1)*height(tableZoned_struct)+j) = j;
                    seq_succ_struct((i-1)*height(tableZoned_struct)+j) = i;
                end
            end      
        end
    end
end
seq_pred_struct = seq_pred_struct(~all(seq_pred_struct == 0, 2),:)';  % delete the empty elements
seq_succ_struct = seq_succ_struct(~all(seq_succ_struct == 0, 2),:)';
buffer_struct = zeros(1,length(seq_pred_struct));