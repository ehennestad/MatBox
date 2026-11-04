function prepareReadmeFile(readmeFile, projectRootDirectory, versionNumber)
% prepareReadmeFile - Prepare a README file for display outside the repository
%
%   matbox.toolbox.internal.prepareReadmeFile(readmeFile, projectRootDirectory, versionNumber)
%   rewrites readmeFile with matbox.toolbox.internal.prepareReadme. Relative
%   links point to the tag v<major>.<minor>.<patch> of versionNumber in the
%   repository given by matbox.toolbox.internal.getRepositoryUrl. When that
%   URL is not available, badge lines are still removed, relative links are
%   left unchanged, and a warning is issued.
%
%   The file is read and written as UTF-8.

    arguments
        readmeFile (1,1) string {mustBeFile}
        projectRootDirectory (1,1) string {mustBeFolder}
        versionNumber (1,1) string
    end

    versionParts = split(versionNumber, ".");
    tagName = "v" + join(versionParts(1:min(3, end)), ".");

    repositoryUrl = matbox.toolbox.internal.getRepositoryUrl(projectRootDirectory);
    if repositoryUrl == ""
        warning("MatBox:Package:RepositoryUrlNotFound", ...
            ['The repository URL of "%s" could not be found, so relative links ', ...
            'in "%s" are left unchanged. Add a git remote named "origin".'], ...
            projectRootDirectory, readmeFile)
    end

    text = string(fileread(readmeFile, "Encoding", "UTF-8"));
    text = matbox.toolbox.internal.prepareReadme(text, ...
        "RepositoryURL", repositoryUrl, ...
        "Ref", tagName, ...
        "ProjectRoot", projectRootDirectory);

    fileId = fopen(readmeFile, "w", "n", "UTF-8");
    fileCleanup = onCleanup(@() fclose(fileId));
    fprintf(fileId, "%s", text);
end
