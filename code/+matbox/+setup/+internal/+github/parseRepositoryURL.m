function [owner, repositoryName, gitRef] = parseRepositoryURL(repoUrl)
% parseRepositoryURL - Extract owner, repository name and git reference from URL
%
%   [owner, repositoryName, gitRef] = parseRepositoryURL(repoUrl) splits a
%   GitHub repository URL of the form https://github.com/<owner>/<repo>[@ref]
%   into its parts. gitRef is the branch name, tag name, or commit SHA
%   following the first "@", including any "/" in it (as in
%   "release/1.0"), or a missing string when the URL has no "@" suffix.
%   A URL with path segments after the repository name and no "@", such
%   as https://github.com/<owner>/<repo>/tree/<branch>, is an error.

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

    % A git reference may contain "/" and "@", so the reference is
    % everything after the first "@", up to the end of the path.
    gitRef = string(missing);
    if contains(repositoryName, "@")
        gitRef = strjoin([extractAfter(repositoryName, "@"), pathNames(3:end)], "/");
        repositoryName = extractBefore(repositoryName, "@");
    elseif numel(pathNames) > 2
        error("MATBOX:GitHub:InvalidRepositoryURL", ...
            "The repository URL ""%s"" has path segments after the repository name. " + ...
            "Give a branch, tag or commit as https://github.com/<owner>/<repo>@<ref>.", ...
            string(repoUrl))
    end

    if nargout < 3
        clear gitRef
    end
end
