function writeCommitHash(repositoryFolderPath, repositoryName, organizationName, branchName)
    commitId = matbox.setup.internal.github.api.getCurrentCommitID(repositoryName, ...
        'Organization', organizationName, "BranchName", branchName);
    filePath = fullfile(repositoryFolderPath, '.commit_hash');
    matbox.setup.internal.utility.filewrite(filePath, commitId)
end
