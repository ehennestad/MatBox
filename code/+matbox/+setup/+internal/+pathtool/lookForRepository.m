function [exists, repositoryPath] = lookForRepository(repositoryName, gitRef)
% lookForRepository - Look for an installed repository on the MATLAB search path
%
%   [exists, repositoryPath] = lookForRepository(repositoryName, gitRef)
%   searches the MATLAB search path for a folder holding the repository at
%   the given git reference (branch name, tag name, or commit SHA).

    exists = false;
    repositoryPath = "";

    % Get the full MATLAB search path:
    pathList = strsplit(path, pathsep);

    % Candidate folder names, most specific first:
    %   {repositoryName}-{gitRef} is the folder name of a repository that
    %   was downloaded as a zip archive (see installGithubRepository).
    %   {repositoryName} is the folder name of a repository cloned with git.
    % Each candidate is matched both as the last folder of a path entry
    % ("$") and as a parent folder of a path entry (filesep).
    candidateFolderNames = [ ...
        sprintf("%s-%s", repositoryName, gitRef), ...
        sprintf("%s-%s", repositoryName, gitRef), ...
        string(repositoryName), ...
        string(repositoryName)];
    candidateSuffixes = ["$", filesep, "$", filesep];

    for i = 1:numel(candidateFolderNames)
        folderName = candidateFolderNames(i);
        suffix = candidateSuffixes(i);

        % Escape regexp metacharacters: tag names commonly contain "."
        % (v1.0.0) and may contain "+" (build metadata).
        pattern = regexptranslate('escape', folderName) + suffix;

        % Check if this repo is already on path:
        matchingFolderName = regexp(pathList, pattern, 'match');

        isEmpty = cellfun('isempty', matchingFolderName);
        matchedFolderIndex = find(~isEmpty);

        if suffix == filesep
            matchedFolderNames = string(pathList(matchedFolderIndex));
            matchedFolderNames = unique( extractBefore(matchedFolderNames, folderName + suffix));
            matchedFolderNames = fullfile(matchedFolderNames, folderName + suffix);
        else
            matchedFolderNames = unique( string( pathList(matchedFolderIndex) ) );
        end

        if numel(matchedFolderNames) == 1 %#ok<ISCL>
            exists = true;
            repositoryPath = matchedFolderNames;
            break

        elseif numel(matchedFolderIndex) > 1
            warning('Multiple folders matching the repository name was found on path')
            exists = true;
            repositoryPath = matchedFolderNames(1);
            break
        end
    end
    repositoryPath = string(repositoryPath);

    % Make sure folder exists
    if ~isempty(char(repositoryPath)) && ~isfolder(repositoryPath)
        warning("Repository was found on MATLAB's search path, but folder does not exist")
        exists = false;
        repositoryPath = "";
    end

    if repositoryPath == ""; return; end

    % Check if folder contains expected files...
    L = dir( repositoryPath );
    assert(contains('README.md', {L.name}, 'IgnoreCase', true) && ...
        contains('LICENSE', {L.name}, 'IgnoreCase', true), ...
        "Expected repository to contain a Readme and LICENSE file")
end
