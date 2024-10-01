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
%  - Create a matlab script that fills in toolbox options for path
%  - and requirements

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
        releaseType {mustBeTextScalar,mustBeMember(releaseType,["build","major","minor","patch","specific"])} = "build"
        versionString {mustBeTextScalar} = "";
        options.SourceFolderName = "code"
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
    toolboxOptions = matbox.toolbox.createToolboxOptions(projectRootDirectory, newVersion);

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
    
    % Package toolbox
    if ~isfolder( fileparts(toolboxOptions.OutputFile) )
        mkdir( fileparts(toolboxOptions.OutputFile) );
    end
    matlab.addons.toolbox.packageToolbox(toolboxOptions);
end
