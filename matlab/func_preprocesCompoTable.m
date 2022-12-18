% To round numbers to integers (mm), and caluclate the min & max coord of each component  % rounding omitted
function tableCompo = func_preprocesCompoTable(tableCompo)


% % to round the numbers to integer (in mm)  % commented here, to avoid rounding data in metre
% toRound = ["CentroidX","CentroidY","CentroidZ","Size_X","Size_Y","Size_Z"];
% for i = 1:length(toRound)
%     tableCompo{:,toRound(i)} = round(tableCompo{:,toRound(i)});
% end

if any(strcmp("X_min", tableCompo.Properties.VariableNames)) == false
    % Caluclate the min & max coordinates of each component
    tableCompo.X_min = tableCompo{:,"CentroidX"} - tableCompo{:,"Size_X"}/2;
    tableCompo.X_max = tableCompo{:,"CentroidX"} + tableCompo{:,"Size_X"}/2;
    tableCompo.Y_min = tableCompo{:,"CentroidY"} - tableCompo{:,"Size_Y"}/2;
    tableCompo.Y_max = tableCompo{:,"CentroidY"} + tableCompo{:,"Size_Y"}/2;
    tableCompo.Z_min = tableCompo{:,"CentroidZ"} - tableCompo{:,"Size_Z"}/2;
    tableCompo.Z_max = tableCompo{:,"CentroidZ"} + tableCompo{:,"Size_Z"}/2;
    % tableCompo.Inclined = repmat(categorical("N"),height(tableCompo),1);  % Initialise
end