function repoTargetFolder = installGithubRepository(repositoryUrl, gitRef, options)
% INSTALLGITHUBREPOSITORY Install or update a GitHub repository
%   repoTargetFolder = installGithubRepository(repositoryUrl, gitRef, options)
%   installs or updates a GitHub repository and returns the target folder path.
%
%   Parameters:
%       repositoryUrl - URL of the GitHub repository
%       gitRef - Git reference to install: a branch name, tag name, or
%           commit SHA (default: "main"). Pass a missing string to use the
%           repository's default branch.
%       options - Structure with the following fields:
%           Update - Whether to update if repository exists (default: false)
%           InstallationLocation - Where to install (default: default addon folder)
%           AddToPath - Whether to add to MATLAB path (default: true)
%           AddToPathWithSubfolders - Whether to add subfolders (default: true)
%           Verbose - Whether to display verbose output (default: true)

    arguments
        repositoryUrl (1,1) string
        gitRef (1,1) string = "main"
        options.Update (1,1) logical = false
        options.UseGit (1,1) logical = false
        options.InstallationLocation (1,1) string = matbox.setup.internal.getDefaultAddonFolder()
        options.AddToPath (1,1) logical = true
        options.AddToPathWithSubfolders (1,1) logical = true
        options.Verbose (1,1) logical = true
    end

    [ownerName, repositoryName] = ...
        matbox.setup.internal.github.parseRepositoryURL(repositoryUrl);

    if ismissing(gitRef) % - Use the repository's default branch
        gitRef = matbox.setup.internal.github.api.getDefaultBranch(...
            ownerName, repositoryName);
    end

    [repoExists, repoFolderLocation] = ...
        matbox.setup.internal.pathtool.lookForRepository(repositoryName, gitRef);

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
                    ownerName, gitRef, repositoryUrl, "Verbose", options.Verbose);
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
    if options.Verbose
        fprintf('Please wait, downloading "%s"...', repositoryUrl)
    end

    % The "archive/<ref>.zip" form resolves branch names, tag names and
    % commit SHAs alike, unlike "archive/refs/heads/<branch>.zip".
    downloadUrl = sprintf('%s/archive/%s.zip', repositoryUrl, gitRef);
    repoTargetFolder = matbox.setup.internal.downloadZippedGithubRepo(downloadUrl, repoTargetFolder, true, true);
    repoTargetFolder = renameToReferenceFolderName(repoTargetFolder, repositoryName, gitRef);

    matbox.setup.internal.github.writeCommitHash(...
        repoTargetFolder, repositoryName, ownerName, gitRef)

    if options.Verbose
        fprintf('Done.\n')
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

function repoFolder = renameToReferenceFolderName(repoFolder, repositoryName, gitRef)
% renameToReferenceFolderName - Rename an unzipped archive folder to <repo>-<ref>
%
%   GitHub names the top-level folder of a zip archive after the requested
%   reference, but not always verbatim. GitHub does not document the naming
%   scheme; as observed on github.com, a leading "v" is dropped from tag
%   names (v1.0.0 unpacks to <repo>-1.0.0) and an abbreviated commit SHA is
%   expanded to the full hash, while branch archives unpack to
%   <repo>-<branch>. Renaming to the reference exactly as written in the
%   requirement makes the folder name predictable regardless of how GitHub
%   names the archive, so that lookForRepository recognises the
%   installation on later runs instead of downloading again.

    [parentFolder, folderName, folderNameSuffix] = fileparts(repoFolder);
    actualName = strcat(folderName, folderNameSuffix); % fileparts splits names like "repo-1.0.0" at the last dot
    expectedName = sprintf('%s-%s', repositoryName, gitRef);

    % Compare case-insensitively: the archive uses the repository's canonical
    % casing, which may differ from the casing in the requirement URL.
    if strcmpi(actualName, expectedName)
        return
    end

    expectedFolder = fullfile(parentFolder, expectedName);
    if isfolder(expectedFolder)
        % A stale copy that is not on the search path (otherwise it would
        % have been found and removed before downloading). Replace it, as
        % movefile would otherwise move the new folder inside it.
        rmdir(expectedFolder, 's')
    end
    movefile(repoFolder, expectedFolder)
    repoFolder = expectedFolder;
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
        ownerName, gitRef, repositoryUrl, options)
% checkCommitHash - Check if the local commit hash matches remote commit hash

    arguments
        repoFolderLocation (1,1) string
        repoName (1,1) string
        ownerName (1,1) string
        gitRef (1,1) string
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
            'BranchName', gitRef);

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
