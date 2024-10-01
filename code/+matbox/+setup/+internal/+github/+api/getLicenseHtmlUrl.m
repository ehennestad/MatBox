function htmlUrl = getLicenseHtmlUrl(repositoryName, repositoryOwner)
    arguments
        repositoryName (1,1) string
        repositoryOwner (1,1) string
    end
    apiUrl = sprintf("https://api.github.com/repos/%s/%s/license", repositoryOwner, repositoryName);
    data = webread(apiUrl);
    htmlUrl = data.download_url;
end