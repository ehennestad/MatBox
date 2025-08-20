function [toolboxPathFolders, cleanupObj] = resolvePathFolders(projectRootDirectory, options)
% resolvePathFolders Resolves folders to include in the MATLAB path for a toolbox project.
%
% Syntax:
%   [toolboxPathFolders, cleanupObj] = matbox.toolbox.internal.resolvePathFolders(...
%       projectRootDirectory, options) determines the folders within a
%       specified project root directory to include in the MATLAB path for a
%       toolbox. It recursively identifies path folders within a specified
%       source folder or uses a list of custom path folders if provided.
%
% Inputs:
%   projectRootDirectory (string) - The root directory of the project where
%       the toolbox code is located.
%
%   options (struct) - Optional name-value pair arguments:
%       - SourceFolderName (string): The name of the folder containing
%         source code within `projectRootDirectory`. Default is "src".
%       - PathFolders (string array): A custom list of path folders. If
%         empty, folders within `SourceFolderName` are used.
%
% Outputs:
%   toolboxPathFolders (string array) - An array of folder paths to be
%       included in the MATLAB path for a toolbox.
%
%   cleanupObj (onCleanup) - An object that automatically deletes any
%       temporary `Contents.m` files created in empty folders when it goes
%       out of scope.
%
% Note: Due to a bug in matlab.addons.toolbox.ToolboxOptions it is not
% possible to specify folders for the path which does not contain at least
% one file. I.e if a folder that should be added to the path contains only
% subfolders and no files, the ToolboxOptions class throws an error. To work
% around this, if a folder does not contain any immediate files, a
% temporary file is created. This file is deleted when the cleanupObj is
% cleared

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
        options.SourceFolderName (1,1) string = "src"
        options.PathFolders (1,:) string = string.empty
    end
    
    if isempty(options.PathFolders)
        toolboxCodeFolder = fullfile(projectRootDirectory, options.SourceFolderName);
        toolboxPathFolders = string( strsplit(genpath(toolboxCodeFolder), pathsep));
        toolboxPathFolders = toolboxPathFolders(1:end-1); % Last element is empty
    else
        toolboxPathFolders = repmat("", 1, numel(options.PathFolders));
        for i = 1:numel(options.PathFolders)
            if ~startsWith(options.PathFolders, projectRootDirectory)
                toolboxPathFolders(i) = fullfile(projectRootDirectory, options.PathFolders(i));
            else
                toolboxPathFolders(i) = options.PathFolders(i);
            end
        end
    end

    tempFiles = string.empty;
    for i = 1:numel(toolboxPathFolders)
        L = dir(fullfile(toolboxPathFolders(i), '*.m'));
        if isempty(L)
            tempFiles(end+1) = fullfile(toolboxPathFolders(i), 'Contents.m'); %#ok<AGROW>
            fid = fopen(tempFiles(end), 'wt');
            fwrite(fid, '% Temporary placeholder');
            fclose(fid);
        end
    end
    cleanupObj = onCleanup(@(flist) deleteFiles(tempFiles) );
end

function deleteFiles(fileList)
    for i = 1:numel(fileList)
        delete(fileList(i))
    end
end
