function repositoryUrl = getRepositoryUrl(projectRootDirectory)
% getRepositoryUrl - Get the web URL of a project's git repository
%
%   repositoryUrl = matbox.toolbox.internal.getRepositoryUrl(projectRootDirectory)
%   returns the URL in the form https://<host>/<owner>/<repo>.
%
%   On GitHub Actions the URL is GITHUB_SERVER_URL/GITHUB_REPOSITORY.
%   Elsewhere it is the URL of the "origin" remote of the repository in
%   projectRootDirectory, with credentials and a trailing ".git" removed,
%   and an SSH address (git@<host>:<owner>/<repo> or ssh://...) written as
%   https://<host>/<owner>/<repo>. The result is "" when there is no such
%   remote or its URL is not a web or SSH address.

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
    end

    serverUrl = string(getenv("GITHUB_SERVER_URL"));
    repository = string(getenv("GITHUB_REPOSITORY"));
    if serverUrl ~= "" && repository ~= ""
        repositoryUrl = serverUrl + "/" + repository;
        return
    end

    [status, commandOutput] = system(sprintf('git -C "%s" remote get-url origin', projectRootDirectory));
    outputLines = splitlines(strip(string(commandOutput)));
    if status ~= 0 || outputLines(end) == ""
        repositoryUrl = "";
        return
    end
    repositoryUrl = remoteUrlToWebUrl(outputLines(end));
end

function webUrl = remoteUrlToWebUrl(remoteUrl)
% remoteUrlToWebUrl - Write a git remote URL as the web URL of the repository

    remoteUrl = regexprep(remoteUrl, '(\.git)?/?$', '');

    scpAddress = regexp(remoteUrl, '^[^@/:]+@(?<host>[^:/]+):(?<path>.+)$', 'names', 'once');
    sshUrl = regexp(remoteUrl, '^ssh://(?:[^@/]+@)?(?<host>[^/:]+)(?::\d+)?/(?<path>.+)$', 'names', 'once');
    if ~isempty(scpAddress)
        webUrl = "https://" + scpAddress.host + "/" + scpAddress.path;
    elseif ~isempty(sshUrl)
        webUrl = "https://" + sshUrl.host + "/" + sshUrl.path;
    elseif startsWith(remoteUrl, ["https://", "http://"])
        webUrl = regexprep(remoteUrl, '^(https?://)[^@/]+@', '$1');
    else
        webUrl = "";
    end
end
