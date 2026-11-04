function [newVersion, mltbxPath] = packageToolbox(projectRootDirectory, releaseType, versionString, options)
% packageToolbox Package a new version of a toolbox. Package a new version
% of the toolbox based on the toolbox packaging (.prj) file in current
% working directory. MLTBX file is put in ./release directory.
%
% packageToolbox() Build is automatically incremented.
%
% packageTookbox(releaseType) RELEASETYPE  can be "major", "minor", or "patch"
% to update semantic version number appropriately.  Build (fourth element in
% semantic versioning) is always updated automatically.
%
% packageTookbox('specific', versionString) VERSIONSTRING is a string containing
% the specific 3 part semantic version (i.e. "2.3.4") to use.
%
% By default, a LICENSE file in the project root directory is included in
% the packaged toolbox. To control which project root files are included,
% specify a top-level "RootFilesToPackage" list in MLToolboxInfo.json,
% e.g. "RootFilesToPackage": ["LICENSE", "THIRD_PARTY_NOTICES.md"].
%
% From R2026b, "Readme" and "PackageName" in the "ToolboxOptions" of
% MLToolboxInfo.json set the readme file and the package name. "Readme" is
% a path relative to the source folder; list "README.md" in
% "RootFilesToPackage" to package the project README. Earlier releases
% package the readme as an ordinary file and have no package name. Both
% fields are checked on every release.
%
% A readme copied from the project root is processed before packaging, on
% every release: badge lines at the top are removed and relative links
% point to the tag v<major>.<minor>.<patch> of the new version (see
% matbox.toolbox.internal.prepareReadme).
%
% The MLTBX file is named <ToolboxName>_v<version>.mltbx. To use a fixed
% file name for every release, specify a top-level "MltbxFileName" in
% MLToolboxInfo.json, e.g. "MltbxFileName": "MatBox".
%
% Adapted from: https://github.com/mathworks/climatedatastore/blob/main/buildUtilities/packageToolbox.m
% See the THIRD_PARTY_NOTICES.md file distributed with MatBox for license terms.

% Todo:
%  [ ] Create a matlab script that fills in toolbox options for path
%  [ ] and requirements

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
        releaseType {mustBeTextScalar,mustBeMember(releaseType,["build","major","minor","patch","specific"])} = "build"
        versionString {mustBeTextScalar} = "";
        options.ToolboxShortName (1,1) string = missing
        options.SourceFolderName = "src"
        options.IgnorePatterns (1,:) string = string.empty
        options.PathFolders (1,:) string = string.empty
    end

    includeBuildNumer = strcmp(releaseType, 'build');

    % Get updated version number
    sourceFolderPath = fullfile(projectRootDirectory, options.SourceFolderName);

    % Temporarily copy project root files (e.g. LICENSE) into the source
    % folder so they are included in the packaged toolbox.
    [stagedFilesCleanupObj, stagedFiles] = matbox.toolbox.internal.stageRootFilesForPackaging(...
        projectRootDirectory, sourceFolderPath); %#ok<ASGLU>

    try
        previousVersion = matbox.utility.getVersionFromContents(sourceFolderPath);
    catch
        previousVersion = "0.1.0"; % Initialize version number
    end
    newVersion = matbox.utility.updateVersionNumber(previousVersion, releaseType, ...
        versionString, "IncludeBuildNumber", includeBuildNumer);

    prepareStagedReadme(projectRootDirectory, sourceFolderPath, stagedFiles, newVersion)

    % Create/retrieve options for packaging toolbox
    nvPairs = namedargs2cell(options);
    toolboxOptions = matbox.toolbox.createToolboxOptions(projectRootDirectory, newVersion, nvPairs{:});

    % Update Contents.m header based on toolbox options and new version number
    if isempty(char(toolboxOptions.AuthorCompany))
        owner = toolboxOptions.AuthorName;
    else
        owner = toolboxOptions.AuthorCompany;
    end
    contentHeader = matbox.utility.createContentsHeader(...
        "Name", toolboxOptions.ToolboxName, ...
        "VersionNumber", newVersion, ...
        "MinimumMatlabRelease", toolboxOptions.MinimumMatlabRelease, ...
        "Owner", owner);

    % Write contents header
    matbox.utility.updateContentsHeader(sourceFolderPath, contentHeader);

    % Due to a "bug" in MATLAB, if a folder does not contain any m-files,
    % the packaging fails. To work around this we temporarily create empty
    % m-files in any affected folder, and add these file(s) to the
    % ToolboxFiles. The files are deleted before the actual packaging and
    % that causes a warning, which we therefore ignore here:
    warnState = warning('off', 'MATLAB:toolbox_packaging:packaging:FilesDoNotExistWarning');
    cleanupObj = onCleanup(@(ws) warning(warnState));

    % Generate initial MLTBX with additional software specified
    finalOutputFile = toolboxOptions.OutputFile;
    initialOutputFile = strrep(finalOutputFile, '.mltbx', '_initial.mltbx');
    toolboxOptions.OutputFile = initialOutputFile;
    if ~isfolder( fileparts(toolboxOptions.OutputFile) )
        mkdir( fileparts(toolboxOptions.OutputFile) );
    end
    matlab.addons.toolbox.packageToolbox(toolboxOptions);
    mltbxCleanupObj = onCleanup(@() delete(initialOutputFile));

    % Generate final MLTBX without additional software
    toolboxOptions.RequiredAdditionalSoftware = [];
    toolboxOptions.OutputFile = finalOutputFile;
    if ~isfolder( fileparts(toolboxOptions.OutputFile) )
        mkdir( fileparts(toolboxOptions.OutputFile) );
    end

    matlab.addons.toolbox.packageToolbox(toolboxOptions);

    % Hopefully temporary fix for MATLAB bug. See issue #21
    % https://github.com/ehennestad/MatBox/issues/21
    matbox.toolbox.internal.fixRequiredAdditionalSoftware(initialOutputFile, finalOutputFile)

    fprintf('Exported MLTBX to %s\n', finalOutputFile)

    % Return the MLTBX path
    mltbxPath = finalOutputFile;

    if ~nargout
        clear newVersion
    end
end

function prepareStagedReadme(projectRootDirectory, sourceFolderPath, stagedFiles, versionNumber)
% prepareStagedReadme - Prepare the readme for the package if it is a staged copy
%
%   The readme named by "Readme" in MLToolboxInfo.json is processed with
%   matbox.toolbox.internal.prepareReadmeFile only when it was copied from
%   the project root for packaging. A readme committed in the source folder
%   is left as it is.

    toolboxInfo = matbox.toolbox.readToolboxInfo(projectRootDirectory);
    if ~isfield(toolboxInfo, "Readme") || isempty(toolboxInfo.Readme)
        return
    end

    readmeFile = fullfile(sourceFolderPath, string(toolboxInfo.Readme));
    if ismember(readmeFile, stagedFiles)
        matbox.toolbox.internal.prepareReadmeFile(readmeFile, projectRootDirectory, versionNumber)
    end
end
