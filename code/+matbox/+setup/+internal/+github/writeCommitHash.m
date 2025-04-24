function writeCommitHash(repositoryFolderPath, repositoryName, owner, branchName)
% writeCommitHash - Writes the current commit hash of a repository to file. 
%
% Syntax:
%   writeCommitHash(repositoryFolderPath, repositoryName, owner, branchName)
%
% Input Arguments:
%   repositoryFolderPath - The path to the repository folder.
%   repositoryName - The name of the repository.
%   owner - The owner of the repository.
%   branchName - The name of the branch.
%
% See also:
%   matbox.setup.internal.github.api.getCurrentCommitID
%   matbox.setup.internal.github.readCommitHash 

    arguments
        repositoryFolderPath (1,1) string
        repositoryName (1,1) string
        owner (1,1) string
        branchName (1,1) string
    end

    import matbox.setup.internal.github.api.getCurrentCommitID

    commitId = getCurrentCommitID(repositoryName, ...
        "Owner", owner, ...
        "BranchName", branchName);

    filePath = fullfile(repositoryFolderPath, '.commit_hash');
    matbox.setup.internal.utility.filewrite(filePath, commitId)
end
