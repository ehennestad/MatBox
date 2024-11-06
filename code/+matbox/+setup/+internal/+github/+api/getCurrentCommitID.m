function [commitID, commitDetails] = getCurrentCommitID(repositoryName, options)
%getCurrentCommitID Get current commit id for a branch of a repository
%
%   commitID = getCurrentCommitID(branchName) returns the commitID for the
%   specified branch as a character vector

    arguments
        repositoryName (1,1) string
        options.UserName (1,1) string = missing
        options.Organization (1,1) string = missing
        options.BranchName = "main"
    end

    assert(~ismissing(options.UserName) || ~ismissing(options.Organization), 'Owner (UserName or Organization) must be specified')

    if ~ismissing(options.UserName)
        owner = options.UserName;
    else
        owner = options.Organization;
    end

    API_BASE_URL = sprintf("https://api.github.com/repos/%s/%s", owner, repositoryName);
    
    apiURL = strjoin( [API_BASE_URL, "commits", options.BranchName], '/');

    % Get info about latest commit:
    % data = webread(apiURL);
    % commitID = data.sha;

    % More specific api call to only get the sha-1 hash:
    requestOpts = weboptions();
    requestOpts.HeaderFields = {'Accept', 'application/vnd.github.sha'};

    data = webread(apiURL, requestOpts);
    commitID = char(data');

    if nargout == 2
        commitDetails = struct();
        commitDetails.CommitID = commitID;
        commitDetails.RepositoryName = repositoryName;
        commitDetails.BranchName = options.BranchName;
        commitDetails.Organization = options.Organization;
    end
end
