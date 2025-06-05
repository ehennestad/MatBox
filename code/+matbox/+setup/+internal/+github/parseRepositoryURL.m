function [owner, repositoryName, branchName] = parseRepositoryURL(repoUrl)
% parseRepositoryURL - Extract owner, repository name and branch name from URL
    
    arguments
        repoUrl (1,1) matlab.net.URI
    end
    
    if repoUrl.Host ~= "github.com"
        error("MATBOX:GitHub:InvalidRepositoryURL", ...
            "Please make sure the repository URL's host name is 'github.com'")
    end
    
    pathNames = repoUrl.Path;
    pathNames( cellfun('isempty', pathNames) ) = [];

    owner = pathNames(1);
    repositoryName = pathNames(2);

    branchName = string(missing);
    if contains(repositoryName, '@')
        splitName = split(repositoryName, '@');
        repositoryName = splitName(1);
        branchName = splitName(2);
    end

    if nargout < 3
        clear branchName
    end
end
