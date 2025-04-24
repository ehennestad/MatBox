function repoTargetFolder = installGithubRepository(repositoryUrl, branchName, options)
% INSTALLGITHUBREPOSITORY Install or update a GitHub repository
%   repoTargetFolder = installGithubRepository(repositoryUrl, branchName, options)
%   installs or updates a GitHub repository and returns the target folder path.
%
%   Parameters:
%       repositoryUrl - URL of the GitHub repository
%       branchName - Branch to install (default: "main")
%       options - Structure with the following fields:
%           Update - Whether to update if repository exists (default: false)
%           InstallationLocation - Where to install (default: default addon folder)
%           AddToPath - Whether to add to MATLAB path (default: true)
%           AddToPathWithSubfolders - Whether to add subfolders (default: true)
%           Verbose - Whether to display verbose output (default: true)

    arguments
        repositoryUrl (1,1) string
        branchName (1,1) string = "main"
        options.Update (1,1) logical = false
        options.InstallationLocation (1,1) string = matbox.setup.internal.getDefaultAddonFolder()
        options.AddToPath (1,1) logical = true
        options.AddToPathWithSubfolders (1,1) logical = true
        options.Verbose (1,1) logical = true
    end

    % Branch name might be set to missing from upstream callers
    % Todo: Should default to "default" and use git api to resolve name of
    % default branch
    if ismissing(branchName); branchName = "main"; end

    [ownerName, repositoryName] = matbox.setup.internal.github.parseRepositoryURL(repositoryUrl);
    
    [repoExists, repoFolderLocation] = ...
        matbox.setup.internal.pathtool.lookForRepository(repositoryName, branchName);

    if repoExists
        isUpdateNeeded = options.Update;
        repoTargetFolder = repoFolderLocation;
        
        if options.Update % Handle repository update
            if isGitRepository(repoFolderLocation)
                wasSuccess = gitPull(repoFolderLocation);
                if wasSuccess
                    if options.Verbose
                        fprintf('Used git pull to update repository "%s"\n', repositoryUrl)
                    end
                    isUpdateNeeded = false;
                end
            else
                isUpdateNeeded = checkCommitHash(repoFolderLocation, repositoryName, ...
                    ownerName, branchName, repositoryUrl, "Verbose", options.Verbose);
            end
        end

        if ~isUpdateNeeded
            if options.Verbose
                fprintf('Requirement "%s" already exists, skipping.\n', repositoryUrl)
            end
            if ~nargout
                clear repoTargetFolder
            end
            return
        end
    end

    if repoExists
        if contains(repoFolderLocation, options.InstallationLocation)
            rmpath(genpath(repoFolderLocation));
            rmdir(repoFolderLocation, 's');
            if options.Verbose
                fprintf('Removed "%s".\n', repoFolderLocation)
            end
        else
            warning("Found repository in another location (%s) than the " + ...
                "specified installation location. Please update manually.", repoFolderLocation)
            return
        end
    end

    targetFolder = options.InstallationLocation;
    repoTargetFolder = fullfile(targetFolder);

    if ~isfolder(repoTargetFolder); mkdir(repoTargetFolder); end

    % Download repository
    downloadUrl = sprintf( '%s/archive/refs/heads/%s.zip', repositoryUrl, branchName );
    repoTargetFolder = matbox.setup.internal.downloadZippedGithubRepo(downloadUrl, repoTargetFolder, true, true);

    matbox.setup.internal.github.writeCommitHash(...
        repoTargetFolder, repositoryName, ownerName, branchName)

    if options.Verbose
        fprintf('Installed "%s".\n', repositoryUrl)
    end

    % Run setup.m if present.
    setupFile = matbox.setup.internal.findSetupFile(repoTargetFolder);
    if isfile( setupFile )
        run( setupFile )
    else
        if options.AddToPath
            if options.AddToPathWithSubfolders
                addpath(genpath(repoTargetFolder))
            else
                addpath(repoTargetFolder)
            end
        end
    end

    if ~nargout
        clear repoTargetFolder
    end
end

function tf = isGitRepository(folderPath)
    tf = isfolder(fullfile(folderPath, '.git'));
end

function wasSuccess = gitPull(folderPath)
% gitPull - Try to do a repository pull using git
    wasSuccess = false;
    
    % Try to use git commands to update the repository
    try
        if exist("gitrepo", "file")
            repo = gitrepo(folderPath);
            repo.pull()
            wasSuccess = true;
        else
            currentDir = pwd;
            cd(folderPath);
            workDirCleanup = onCleanup(@() cd(currentDir));
            
            % Try to use git pull to update the repository
            [status, cmdout] = system('git pull');
            
            % Return to original directory
            clear workDirCleanup
            
            if status == 0
                wasSuccess = true;
            else
                warning('Git pull failed with message: %s.', cmdout);
            end
        end
    catch ME
        warning(ME.identifier, 'Git pull failed with message: %s.', ME.message);
    end
    
    if wasSuccess
        % Run setup if present after update
        setupFile = matbox.setup.internal.findSetupFile(folderPath);
        if isfile(setupFile)
            run(setupFile);
        end
    end
end

function needsUpdate = checkCommitHash(repoFolderLocation, repoName, ...
        ownerName, branchName, repositoryUrl, options)
% checkCommitHash - Check if the local commit hash matches remote commit hash
    
    arguments
        repoFolderLocation (1,1) string
        repoName (1,1) string
        ownerName (1,1) string
        branchName (1,1) string
        repositoryUrl (1,1) string
        options.Verbose (1,1) logical = true
    end
    
    needsUpdate = false;

    % Check if commit hash has changed before updating
    try
        % Read the stored commit hash
        storedCommitHash = matbox.setup.internal.github.readCommitHash(repoFolderLocation);
        
        % Get the current commit hash from GitHub API
        currentCommitHash = ...
            matbox.setup.internal.github.api.getCurrentCommitID(...
            repoName, ...
            'Owner', ownerName, ...
            'BranchName', branchName);
        
        % Only update if commit hashes are different
        if strcmp(storedCommitHash, currentCommitHash)
            if options.Verbose
                fprintf('Repository "%s" is already up to date (commit: %s).\n', ...
                    repositoryUrl, storedCommitHash);
            end
        else
            needsUpdate = true;
            if options.Verbose
                fprintf('Updating "%s" from commit %s to %s.\n', ...
                    repositoryUrl, storedCommitHash, currentCommitHash);
            end
        end
    catch ME
        needsUpdate = true;
        if options.Verbose
            fprintf('Could not verify commit hash: %s\nForcing update.\n', ME.message);
        end
    end
end
