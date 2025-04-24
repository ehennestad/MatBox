function commitHash = readCommitHash(repositoryFolderPath)
% readCommitHash - Reads the commit hash from a specified repository folder
%
% Syntax:
%   commitHash = readCommitHash(repositoryFolderPath) 
%   This function reads the commit hash from a file named '.commit_hash' 
%   located in the specified repository folder.
%
% Input Arguments:
%   repositoryFolderPath - A string specifying the path to the repository 
%   folder from which the commit hash will be read.
%
% Output Arguments:
%   commitHash - The commit hash retrieved from the '.commit_hash' file.
%
% See also:
%   matbox.setup.internal.github.api.getCurrentCommitID
%   matbox.setup.internal.github.writeCommitHash

    arguments
        repositoryFolderPath
    end

    filePath = fullfile(repositoryFolderPath, '.commit_hash');
    commitHash = fileread(filePath);
end
