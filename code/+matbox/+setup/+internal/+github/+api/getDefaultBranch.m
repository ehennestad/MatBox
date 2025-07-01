function defaultBranch = getDefaultBranch(owner, repoName)
%GETDEFAULTBRANCH Returns the default branch of a GitHub repository.
%   defaultBranch = getDefaultBranch(owner, repoName) queries the GitHub
%   API to get the repository metadata and returns the default branch name.
%
%   Example:
%       branch = getDefaultBranch('octocat', 'Hello-World');

    % Build the API URL
    apiUrl = sprintf('https://api.github.com/repos/%s/%s', owner, repoName);
    
    requestOpts =  matbox.setup.internal.github.api.getGithubWebOptions();
    requestOpts.Timeout = 10;
    requestOpts.ContentType = 'json';

    try
        response = webread(apiUrl, requestOpts);
    catch ME
        error('Failed to fetch repository info: %s', ME.message);
    end

    % Extract the default_branch field
    if isfield(response, 'default_branch')
        defaultBranch = response.default_branch;
    else
        error('default_branch field not found in API response.');
    end
end
