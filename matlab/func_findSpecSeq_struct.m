function [tableCompo_struct, SpecSeqName, SpecSeqName_class, SpecSeqName_countNonUndefined, tableActivity_struct] ...
    = func_findSpecSeq_struct(tableCompo_struct, tableActivity_struct, nLevel, floorElevation, ...
    classToSeq_S1, lowerEnd_lb_S1, lowerEnd_ub_S1, ...
    upperEnd_lb_S1, upperEnd_ub_S1)

% add three columns to record some code, for special custom seq later
tableCompo_struct.SpecSeqName1 = repmat(categorical(" "), height(tableCompo_struct), 1);
tableCompo_struct.SpecSeqName2 = repmat(categorical(" "), height(tableCompo_struct), 1);
tableCompo_struct.SpecSeqName3 = repmat(categorical(" "), height(tableCompo_struct), 1);
tableActivity_struct.SpecSeqName1 = repmat(categorical(" "), height(tableActivity_struct), 1);
tableActivity_struct.SpecSeqName2 = repmat(categorical(" "), height(tableActivity_struct), 1);
tableActivity_struct.SpecSeqName3 = repmat(categorical(" "), height(tableActivity_struct), 1);

% Judge the level - special
% Judge the level: load bearing walls

isInClass = tableCompo_struct{:, 'Class'} == categorical(string(classToSeq_S1));
toSelect2 = tableCompo_struct{:, 'Z_min'} >= lowerEnd_lb_S1;
toSelect3 = tableCompo_struct{:, 'Z_min'} <= lowerEnd_ub_S1;
toSelect4 = tableCompo_struct{:, 'Z_max'} >= upperEnd_lb_S1;
toSelect5 = tableCompo_struct{:, 'Z_max'} <= upperEnd_ub_S1;
selectedRow = isInClass & toSelect2 & toSelect3 & toSelect4 & toSelect5;

tableCompo_struct{selectedRow, 'SpecSeqName1'} = categorical("load bearing wall");
tableActivity_struct{selectedRow, 'SpecSeqName1'} = categorical("load bearing wall");

% also record the SpecSeqName in an array
SpecSeqName = categorical("load bearing wall");
SpecSeqName_class = categorical("Wall");
SpecSeqName_countNonUndefined = 0;
SpecSeqName_countNonUndefined = SpecSeqName_countNonUndefined + 1;  % for now, only 1 specSeq



% Judge the level - special
% Judge the level: some walls (above doors so they start in the middle of a level)
isInClass = tableCompo_struct{:,'Class'} == 'Wall';
selectedRow = isInClass & tableCompo_struct{:,'BaseLevel'} == "";
for lev = 1:nLevel
    isWithinLevelTol = tableCompo_struct{:,"Z_min"} < floorElevation(lev);
    tableCompo_struct{selectedRow, 'BaseLevel'} = strcat("0",num2str(lev-1-1));
end
