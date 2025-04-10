function repoTargetFolder = installGithubRepository(repositoryUrl, branchName, options)

    arguments
        repositoryUrl (1,1) string
        branchName (1,1) string = "main"
        options.Update (1,1) logical = false
        options.InstallationLocation (1,1) string = matbox.setup.internal.getDefaultAddonFolder()
        options.AddToPath (1,1) logical = true
        options.AddToPathWithSubfolders (1,1) logical = true
        options.Verbose (1,1) logical = true
    end

    if ismissing(branchName); branchName = "main"; end

    [organization, repoName] = matbox.setup.internal.github.parseRepositoryURL(repositoryUrl);
    
    [repoExists, repoFolderLocation] = matbox.setup.internal.pathtool.lookForRepository(repoName, branchName);
    if repoExists && ~options.Update
        if options.Verbose
            fprintf('Requirement "%s" already exists, skipping.\n', repositoryUrl)
        end
        return
    end
    
    if repoExists && options.Update
        % Remove old repo from path and delete folder
        rmpath(genpath(repoFolderLocation));
        rmdir(repoFolderLocation, 's')
    end

    targetFolder = options.InstallationLocation;
    repoTargetFolder = fullfile(targetFolder);

    if ~isfolder(repoTargetFolder); mkdir(repoTargetFolder); end

    % Download repository
    downloadUrl = sprintf( '%s/archive/refs/heads/%s.zip', repositoryUrl, branchName );
    repoTargetFolder = matbox.setup.internal.downloadZippedGithubRepo(downloadUrl, repoTargetFolder, true, true);

    commitId = matbox.setup.internal.github.api.getCurrentCommitID(repoName, 'Organization', organization, "BranchName", branchName);
    filePath = fullfile(repoTargetFolder, '.commit_hash');
    matbox.setup.internal.utility.filewrite(filePath, commitId)

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
