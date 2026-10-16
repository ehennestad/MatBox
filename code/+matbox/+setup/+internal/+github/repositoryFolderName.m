function folderName = repositoryFolderName(repositoryName, gitRef)
% repositoryFolderName - Name of the folder holding a repository at a git reference
%
%   folderName = repositoryFolderName(repositoryName, gitRef) returns
%   "<repositoryName>-<gitRef>" with each "/" in gitRef replaced by "-".
%   A git reference may contain "/" (as in "release/1.0"), which would
%   otherwise make the name a nested path. As observed on github.com, a
%   branch archive unpacks to a folder named by the same rule.
%
%   Different references can map to the same name, for example
%   "release/1.0" and "release-1.0".

    arguments
        repositoryName (1,1) string
        gitRef (1,1) string
    end

    folderName = repositoryName + "-" + replace(gitRef, "/", "-");
end
