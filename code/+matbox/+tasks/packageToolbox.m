function newVersion = packageToolbox(projectRootDirectory, releaseType, versionString, options)
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
% Adapted from: https://github.com/mathworks/climatedatastore/blob/main/buildUtilities/packageToolbox.m

% Todo:
%  [ ] Create a matlab script that fills in toolbox options for path
%  [ ] and requirements

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
        releaseType {mustBeTextScalar,mustBeMember(releaseType,["build","major","minor","patch","specific"])} = "build"
        versionString {mustBeTextScalar} = "";
        options.ToolboxShortName (1,1) string = missing
        options.SourceFolderName = "code"
        options.IgnorePatterns (1,:) string = string.empty
        options.PathFolders (1,:) string = string.empty
    end

    includeBuildNumer = strcmp(releaseType, 'build');

    % Get updated version number
    sourceFolderPath = fullfile(projectRootDirectory, options.SourceFolderName);
    try
        previousVersion = matbox.utility.getVersionFromContents(sourceFolderPath);
    catch
        previousVersion = "0.1.0"; % Initialize version number
    end
    newVersion = matbox.utility.updateVersionNumber(previousVersion, releaseType, ...
        versionString, "IncludeBuildNumber", includeBuildNumer);

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

    % Generate initial MLTBX with additional software specified
    finalOutputFile = toolboxOptions.OutputFile;
    initialOutputFile = strrep(finalOutputFile, '.mltbx', '_initial.mltbx');
    toolboxOptions.OutputFile = initialOutputFile;
    matlab.addons.toolbox.packageToolbox(toolboxOptions);
    mltbxCleanupObj = onCleanup(@() delete(initialOutputFile));

    % Generate final MLTBX without additional software
    toolboxOptions.RequiredAdditionalSoftware = [];
    toolboxOptions.OutputFile = finalOutputFile;
    if ~isfolder( fileparts(toolboxOptions.OutputFile) )
        mkdir( fileparts(toolboxOptions.OutputFile) );
    end

    warnState = warning('off', 'MATLAB:toolbox_packaging:packaging:FilesDoNotExistWarning');
    cleanupObj = onCleanup(@(ws) warning(warnState));

    matlab.addons.toolbox.packageToolbox(toolboxOptions);

    % Hopefully temporary fix for MATLAB bug. See issue #21
    % https://github.com/ehennestad/MatBox/issues/21
    matbox.toolbox.internal.fixRequiredAdditionalSoftware(initialOutputFile, finalOutputFile)

    if ~nargout
        clear newVersion
    end
end
