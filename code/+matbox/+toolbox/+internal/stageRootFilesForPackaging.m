function cleanupObj = stageRootFilesForPackaging(projectRootDirectory, sourceFolderPath)
% stageRootFilesForPackaging - Temporarily copy project root files into the source folder
%
%   cleanupObj = stageRootFilesForPackaging(projectRootDirectory, sourceFolderPath)
%   copies selected files from the project root directory into the toolbox
%   source folder so that they are included in the packaged toolbox.
%   ToolboxOptions only packages files located below the source folder, so
%   files like LICENSE that conventionally live in the project root must be
%   staged before packaging. The returned onCleanup object deletes the
%   staged copies when it goes out of scope.
%
%   The files to stage are read from the top-level "RootFilesToPackage"
%   field of MLToolboxInfo.json. If the field is not present, the default
%   is "LICENSE"; a missing default file is skipped silently, whereas a
%   missing explicitly listed file triggers a warning.

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
        sourceFolderPath (1,1) string {mustBeFolder}
    end

    [~, ~, toolboxInfo] = matbox.toolbox.readToolboxInfo(projectRootDirectory);

    if isfield(toolboxInfo, 'RootFilesToPackage')
        fileNames = reshape(string(toolboxInfo.RootFilesToPackage), 1, []);
        warnIfMissing = true;
    else
        fileNames = "LICENSE";
        warnIfMissing = false;
    end

    stagedFiles = string.empty;
    for fileName = fileNames
        sourceFile = fullfile(projectRootDirectory, fileName);
        targetFile = fullfile(sourceFolderPath, fileName);
        if ~isfile(sourceFile)
            if warnIfMissing
                warning("MatBox:Package:RootFileNotFound", ...
                    'The file "%s" is listed in "RootFilesToPackage" in MLToolboxInfo.json, but was not found in the project root directory.', ...
                    fileName)
            end
        elseif isfile(targetFile)
            warning("MatBox:Package:RootFileShadowed", ...
                'The source folder already contains a file named "%s". The existing file will be packaged instead of the project root file.', ...
                fileName)
        else
            copyfile(sourceFile, targetFile)
            stagedFiles(end+1) = targetFile; %#ok<AGROW>
        end
    end

    cleanupObj = onCleanup(@() deleteStagedFiles(stagedFiles));
end

function deleteStagedFiles(filePaths)
    for filePath = filePaths
        if isfile(filePath)
            delete(filePath)
        end
    end
end
