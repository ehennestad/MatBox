function repoFolder = downloadZippedGithubRepo(githubUrl, targetFolder, updateFlag, throwErrorIfFails)
%downloadZippedGithubRepo Download addon to a specified addon folder

    if nargin < 3; updateFlag = false; end
    if nargin < 4; throwErrorIfFails = false; end

    if isa(updateFlag, 'char') && strcmp(updateFlag, 'update')
        updateFlag = true;
    end
    
    % Create a temporary path for storing the downloaded file.
    [~, ~, fileType] = fileparts(githubUrl);
    tempFilepath = [tempname, fileType];
    
    % Download the file containing the addon toolbox
    try
        tempFilepath = websave(tempFilepath, githubUrl);
        fileCleanupObj = onCleanup( @(fname) delete(tempFilepath) );
    catch ME
        if throwErrorIfFails
            rethrow(ME)
        end
    end

    unzippedFiles = unzip(tempFilepath, tempdir);
    unzippedFolder = unzippedFiles{1};
    if endsWith(unzippedFolder, filesep)
        unzippedFolder = unzippedFolder(1:end-1);
    end
    
    [~, repoFolderName] = fileparts(unzippedFolder);
    targetFolder = fullfile(targetFolder, repoFolderName);

    if updateFlag && isfolder(targetFolder)
        
        % Delete current version
        if isfolder(targetFolder)
            if contains(path, fullfile(targetFolder, filesep))
                pathList = strsplit(path, pathsep);
                pathList_ = pathList(startsWith(pathList, fullfile(targetFolder, filesep)));
                rmpath(strjoin(pathList_, pathsep))
            end
            try
                rmdir(targetFolder, 's')
            catch
                warning('Could not remove old installation... Please report')
            end
        end
    else
        % pass
    end

    movefile(unzippedFolder, targetFolder);
    
    % Delete the temp zip file
    clear fileCleanupObj

    repoFolder = targetFolder;
end
