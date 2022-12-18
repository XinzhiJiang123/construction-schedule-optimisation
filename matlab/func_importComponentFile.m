function component = func_importComponentFile(workbookFile, sheetName)

% If no sheet is specified, read first sheet
if nargin == 1 || isempty(sheetName)
    sheetName = 1;
end
% Set up the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 18);
% Specify sheet and range
opts.Sheet = sheetName;
opts.DataRange = 'B:S';
% Specify column names and types
opts.VariableNames = ["GlobalID", "System", "Class", "Type", ...
    "BaseLevel", "Level", "C_BaseLevel", "C_Material", "CentroidX", "CentroidY", "CentroidZ", ...
    "Size_X", "Size_Y", "Size_Z", "BaseOffset", "TopOffset", "Name", "Length"];
opts.VariableTypes = ["string", "categorical", "categorical", "categorical", ...
    "string", "categorical", "categorical", "categorical", "double", "double", "double", ...
    "double", "double", "double", "double", "double", "string", "double"];
% Specify variable properties
% opts = setvaropts(opts, ["GlobalID"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["GlobalID", "System", "Class", "Type", "BaseLevel", "Level", ...
    "C_BaseLevel", "C_Material", "BaseOffset", "TopOffset", "Length"], "EmptyFieldRule", "auto");
% Import the data
component = readtable(workbookFile, opts, "UseExcel", false);

% delete the first row (column names)
toDelete = component{:,'Class'} == 'Class';
component(toDelete,:) = [];


