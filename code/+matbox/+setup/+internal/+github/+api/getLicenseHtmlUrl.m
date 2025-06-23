function htmlUrl = getLicenseHtmlUrl(repositoryName, repositoryOwner)
    arguments
        repositoryName (1,1) string
        repositoryOwner (1,1) string
    end
    apiUrl = sprintf("https://api.github.com/repos/%s/%s/license", repositoryOwner, repositoryName);
    
    % Get web options with GitHub authentication if available
    options =  matbox.setup.internal.github.api.getGithubWebOptions();
    
    try
        data = webread(apiUrl, options);
        htmlUrl = data.download_url;
    catch ME
        if contains(ME.message, 'rate limit')
            error('GitHub API rate limit exceeded. Consider using a GITHUB_TOKEN environment variable.');
        else
            rethrow(ME);
        end
    end
end
