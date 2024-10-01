function [toolboxOptions, identifier, toolboxInfo] = readToolboxInfo(projectRootDir)
% readToolboxInfo - Read toolbox info from MLToolboxInfo.json
%
%   Assumes an MLToolboxInfo.json file is present in <projectRootDir> or subfolders

    arguments
        projectRootDir (1,1) string {mustBeFolder} = pwd()
    end

    fileListing = dir( fullfile(projectRootDir, "**", "MLToolboxInfo.json") );

    if isempty(fileListing)
        error('MatBox:ToolboxInfoFileNotFound', ...
              'The file "MLToolboxInfo.json" could not be found in the specified project root directory.');
        
    elseif numel(fileListing) > 1
        error('MatBox:MultipleToolboxInfoFilesFound', ...
              'Multiple instances of "MLToolboxInfo.json" were found in the project root directory. Please ensure there is only one file.');
    end

    toolboxInfoFilePath = fullfile(fileListing.folder, fileListing.name);
    toolboxInfo = jsondecode(fileread(toolboxInfoFilePath));
    toolboxOptions = toolboxInfo.ToolboxOptions;
    
    if nargout >= 2
        % Get toolbox identifier and remove it from toolbox info
        identifier = toolboxOptions.Identifier; 
        toolboxOptions = rmfield(toolboxOptions, 'Identifier');
    end
    if nargout < 3
        clear toolboxInfo
    end
end
