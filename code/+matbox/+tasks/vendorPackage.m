function vendorInfo = vendorPackage(projectRootDirectory, sourceUri, sourceFolder, targetFolder, options)
%vendorPackage - Copy a folder from a GitHub repository into a project
%   matbox.tasks.vendorPackage(projectRootDirectory,sourceUri,sourceFolder,targetFolder)
%   downloads the GitHub repository sourceUri and copies its folder
%   sourceFolder to the folder targetFolder of the project, which is
%   replaced if it exists. sourceUri has the form
%   "https://github.com/<owner>/<repo>[@ref]", where ref is a branch name,
%   tag name or commit SHA, and the default branch if left out.
%   sourceFolder is relative to the root of the repository and
%   targetFolder is relative to projectRootDirectory.
%
%   If the two folders are namespace folders with different namespace
%   names, the references to the source namespace in the copied .m files
%   are renamed. For example, copying "src/webprogress/+webprogress" to
%   "src/mytoolbox/+mytoolbox/+external/+webprogress" turns
%   "webprogress.upload" into "mytoolbox.external.webprogress.upload" in
%   code, strings and comments. Error identifiers keep the source name.
%
%   The license file of the repository is copied into targetFolder, and
%   the file vendorinfo.json there records the repository, the reference,
%   the commit that was copied, the two namespace names and the excluded
%   files. Changes made to the copied files are lost on the next call,
%   because the folder is replaced as a whole. A folder without a
%   vendorinfo.json file is never replaced.
%
%   vendorInfo = matbox.tasks.vendorPackage(...) returns the information
%   written to vendorinfo.json as a struct.
%
%   [...] = matbox.tasks.vendorPackage(...,ExcludeFiles=FILES) leaves out
%   the files FILES, given relative to sourceFolder with "/" as separator,
%   for example ["toolboxdir.m","private/helper.m"]. A name that matches
%   no file is an error.
%
%   [...] = matbox.tasks.vendorPackage(...,LicenseFile=FILE) copies FILE,
%   given relative to the root of the repository, as the license file. The
%   default is "LICENSE".
%
%   [...] = matbox.tasks.vendorPackage(...,Verbose=TF) prints a summary of
%   the copy if TF is true, the default.
%
%   Example: Copy a package into the namespace of a toolbox
%       sourceUri = "https://github.com/ehennestad/http-progressbar-matlab@main";
%       sourceFolder = "src/webprogress/+webprogress";
%       targetFolder = "src/mytoolbox/external/+mytoolbox/+external/+webprogress";
%       matbox.tasks.vendorPackage(pwd, sourceUri, sourceFolder, ...
%           targetFolder, ExcludeFiles=["toolboxdir.m","toolboxversion.m"])
%
%   See also matbox.installRequirements, matbox.tasks.packageToolbox

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
        sourceUri (1,1) string
        sourceFolder (1,1) string
        targetFolder (1,1) string {mustBeNonzeroLengthText, mustStayBelowRoot}
        options.ExcludeFiles (1,:) string = string.empty
        options.LicenseFile (1,1) string = "LICENSE"
        options.Verbose (1,1) logical = true
    end

    [ownerName, repositoryName, gitRef] = ...
        matbox.setup.internal.github.parseRepositoryURL(sourceUri);
    repositoryUrl = "https://github.com/" + ownerName + "/" + repositoryName;

    if ismissing(gitRef)
        gitRef = matbox.setup.internal.github.api.getDefaultBranch( ...
            ownerName, repositoryName);
    end

    % The reference is resolved to a commit first and the archive of that
    % commit is downloaded, so that the recorded commit is the one the files
    % come from even if a branch moves between the two requests.
    commitId = string(matbox.setup.internal.github.api.getCurrentCommitID( ...
        repositoryName, Owner=ownerName, BranchName=gitRef));

    downloadFolder = string(tempname());
    mkdir(downloadFolder)
    downloadFolderCleanup = onCleanup(@() rmdir(downloadFolder, "s"));

    % The URL is a character vector because downloadZippedGithubRepo builds
    % a file name from it by concatenation.
    archiveUrl = sprintf('%s/archive/%s.zip', repositoryUrl, commitId);
    isUpdate = false;
    throwErrorIfFails = true;
    repositoryFolder = matbox.setup.internal.downloadZippedGithubRepo( ...
        archiveUrl, downloadFolder, isUpdate, throwErrorIfFails);

    vendorInfo = matbox.tasks.internal.vendorPackageFromFolder( ...
        repositoryFolder, sourceFolder, fullfile(projectRootDirectory, targetFolder), ...
        ExcludeFiles=options.ExcludeFiles, ...
        LicenseFile=options.LicenseFile, ...
        RepositoryUrl=repositoryUrl, ...
        Reference=gitRef, ...
        CommitID=commitId);

    if options.Verbose
        SHORT_COMMIT_LENGTH = 7;
        fprintf("Copied ""%s"" of %s at commit %s to ""%s"".\n", ...
            sourceFolder, repositoryUrl, ...
            extractBefore(commitId, SHORT_COMMIT_LENGTH+1), targetFolder)
    end

    if nargout < 1
        clear vendorInfo
    end
end

function mustStayBelowRoot(folderPath)
%mustStayBelowRoot - Validate that a relative path has no ".." folder
    folderNames = split(replace(folderPath, "\", "/"), "/");
    if any(folderNames == "..")
        error("MatBox:VendorPackage:InvalidTargetFolder", ...
            "The target folder ""%s"" must be below the project root " + ...
            "directory. Give a path without "".."".", folderPath)
    end
end
