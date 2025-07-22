function [commitID, commitDetails] = getCurrentCommitID(repositoryName, options)
%getCurrentCommitID Get current commit id for a branch of a repository
%
%   commitID = getCurrentCommitID(branchName) returns the commitID for the
%   specified branch as a character vector

    arguments
        repositoryName (1,1) string
        options.Owner (1,1) string = missing
        options.BranchName = "main"
    end

    assert(~ismissing(options.Owner), ...
        'Repository owner (username or organization) must be specified')

    API_BASE_URL = sprintf("https://api.github.com/repos/%s/%s", ...
        options.Owner, repositoryName);
    
    apiURL = strjoin( [API_BASE_URL, "commits", options.BranchName], '/');

    % Get info about latest commit:
    % data = webread(apiURL);
    % commitID = data.sha;

    % More specific api call to only get the sha-1 hash:
    customHeaders = {'Accept', 'application/vnd.github.sha'};
    requestOpts =  matbox.setup.internal.github.api.getGithubWebOptions(customHeaders);

    try
        data = webread(apiURL, requestOpts);
    catch ME
        if contains(ME.message, 'rate limit')
            if isempty(getenv("GITHUB_TOKEN"))
                error(['GitHub API rate limit exceeded. Consider using ', ...
                    'a GITHUB_TOKEN environment variable.']);
            else
                error(['GitHub API rate limit exceeded. The following ', ...
                    'GitHub token was used: %s\n'], getenv("GITHUB_TOKEN"))
            end
        else
            rethrow(ME);
        end
    end
    commitID = char(data');

    if nargout == 2
        commitDetails = struct();
        commitDetails.CommitID = commitID;
        commitDetails.RepositoryName = repositoryName;
        commitDetails.BranchName = options.BranchName;
        commitDetails.Owner = options.Owner;
    end
end
