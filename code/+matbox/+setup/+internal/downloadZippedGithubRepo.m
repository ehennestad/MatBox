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
        %pass
    end

    movefile(unzippedFolder, targetFolder);
    
    % Delete the temp zip file
    clear fileCleanupObj

    repoFolder = targetFolder;

    % Fix github unzipped directory...
    %repoFolder = restructureUnzippedGithubRepo(targetFolder);
end

function folderPath = restructureUnzippedGithubRepo(folderPath)
%restructureUnzippedGithubRepo Move the folder of a github addon.
%

% Github packages unzips to a new folder within the created
% folder. Move it up one level. Also, remove the '-master' from
% foldername.
    
    rootDir = fileparts(folderPath);

    % Find the repository folder
    L = dir(folderPath);
    L = L(~strncmp({L.name}, '.', 1));
    
    if numel(L) > 1
        % This is unexpected, there should only be one folder.
        return
    end

    % Move folder up one level
    oldDir = fullfile(folderPath, L.name);
    newDir = fullfile(rootDir, L.name);
    movefile(oldDir, newDir)
    rmdir(folderPath)
        
    % Remove the master postfix from foldername
    if contains(L.name, '-master')
        newName = strrep(L.name, '-master', '');
    elseif contains(L.name, '-main')
        newName = strrep(L.name, '-main', '');
    else
        folderPath = fullfile(rootDir, L.name);
        return
    end
    
    % Rename folder to remove main/master tag
    renamedDir = fullfile(rootDir, newName);
    movefile(newDir, renamedDir)
    folderPath = renamedDir;
end
