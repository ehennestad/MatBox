function [owner, repositoryName, gitRef] = parseRepositoryURL(repoUrl)
% parseRepositoryURL - Extract owner, repository name and git reference from URL
%
%   [owner, repositoryName, gitRef] = parseRepositoryURL(repoUrl) splits a
%   GitHub repository URL of the form https://github.com/<owner>/<repo>[@ref]
%   into its parts. gitRef is the branch name, tag name, or commit SHA
%   following "@", or a missing string when the URL has no "@" suffix.

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

    gitRef = string(missing);
    if contains(repositoryName, '@')
        splitName = split(repositoryName, '@');
        repositoryName = splitName(1);
        gitRef = splitName(2);
    end

    if nargout < 3
        clear gitRef
    end
end
