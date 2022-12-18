function database = func_importDatabaseFile(workbookFile, sheetName)       
    % If no sheet is specified, read first sheet
    if nargin == 1 || isempty(sheetName)
        sheetName = 1;
    end
    % If row start and end points are not specified, define defaults
%     if nargin <= 2
%         dataLines = [2, 7];
%     end
    % Set up the Import Options and import the data
    opts = spreadsheetImportOptions("NumVariables", 24);
    % Specify sheet and range
    opts.Sheet = sheetName;
%     opts.DataRange = "A" + dataLines(1, 1) + ":Q" + dataLines(1, 2);
    opts.DataRange = 'A:X';
    % Specify column names and types
    opts.VariableNames = ["Code", "System", "Class", "Type", "Material", "Level", "MaxSize_1", "MaxSize_2", "MaxSize_3",...
        "SizeCategory", "Resource_1", "Res1Mode1", "Cost_r1m1", "Eff_r1m1", "Res1Mode2", "Cost_r1m2", "Eff_r1m2", ...
        "Resource_2", "Res2Mode1", "Cost_r2m1", "Eff_r2m1", "Res2Mode2", "Cost_r2m2", "Eff_r2m2"];
    opts.VariableTypes = ["string", "categorical", "categorical", "categorical", "string", "string", "double", "double", "double",...
        "categorical", "string", "string", "double", "double", "string", "double", "double", ...
        "string", "string", "double", "double", "string", "double", "double"];
    % Specify variable properties
%     opts = setvaropts(opts, ["Material", "R2"], "WhitespaceRule", "preserve");
%     opts = setvaropts(opts, ["System", "Class", "Type", "Material", "MaxSize_2", "MaxSize_3", "SizeCategory"], "EmptyFieldRule", "auto");
    % Import the data
    database = readtable(workbookFile, opts, "UseExcel", false);
%     for idx = 2:size(dataLines, 1)
%         opts.DataRange = "A" + dataLines(idx, 1) + ":Q" + dataLines(idx, 2);
%         tb = readtable(workbookFile, opts, "UseExcel", false);
%         database = [database; tb]; %#ok<AGROW>
%     end 

% delete the first row (column names)
toDelete = database{:,'System'} == 'System';
database(toDelete,:) = [];