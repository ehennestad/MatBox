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
        elseif strcmp(ME.identifier, 'MATLAB:webservices:HTTP404StatusCodeError')
            % GitHub returns 404 when it finds no license file in the repository
            error('MatBox:GitHub:LicenseNotFound', ...
                ['GitHub found no license for the repository "%s/%s". ', ...
                'Add a LICENSE file to that repository.'], ...
                repositoryOwner, repositoryName)
        else
            rethrow(ME);
        end
    end
end
