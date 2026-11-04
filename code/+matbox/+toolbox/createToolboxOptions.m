function toolboxOptions = createToolboxOptions(projectRootDirectory, versionNumber, options)
% Script for setting up toolbox (mltbx) options for openMINDS_MATLAB
%
%   Example:
%       toolboxOptions = getToolboxOptions('0.9.2')

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
        versionNumber (1,1) string {mustBeValidVersionNumber(versionNumber)}
        options.ToolboxShortName (1,1) string = missing
        options.SourceFolderName (1,1) string = "src"
        options.IgnorePatterns (1,:) string = string.empty
        options.PathFolders (1,:) string = string.empty
    end

    % Read the toolbox info from MLToolboxInfo.json
    [toolboxInfo, identifier, toolboxInfoFileContent] = ...
        matbox.toolbox.readToolboxInfo(projectRootDirectory);

    % Resolve folders to add to path for toolbox. This needs to be done
    % before creating the ToolboxOptions object due to a bug in that class
    % (See matbox.toolbox.internal.resolvePathFolders for more info)
    [toolboxPathFolders, cleanupObj] = matbox.toolbox.internal.resolvePathFolders(...
        projectRootDirectory, ...
        "PathFolders", options.PathFolders, ...
        "SourceFolderName", options.SourceFolderName); %#ok<ASGLU>

    if ismissing(options.ToolboxShortName)
        MLTBX_NAME = toolboxInfo.ToolboxName;
    else
        MLTBX_NAME = options.ToolboxShortName;
    end

    % Initialize the ToolboxOptions from the code folder and initial metadata
    toolboxFolder = fullfile(projectRootDirectory, options.SourceFolderName);
    opts = matlab.addons.toolbox.ToolboxOptions(toolboxFolder, identifier, toolboxInfo);

    % Set the toolbox version
    opts.ToolboxVersion = formatToolboxVersion(versionNumber);

    % Ignore some files if specified
    toIgnore = false(size( opts.ToolboxFiles ));
    for i = 1:numel(options.IgnorePatterns)
        toIgnore = toIgnore | contains(opts.ToolboxFiles, options.IgnorePatterns(i));
    end
    if any(toIgnore)
        opts.ToolboxFiles = opts.ToolboxFiles(~toIgnore);
    end

    opts.ToolboxMatlabPath = toolboxPathFolders;

    opts.SupportedPlatforms.Win64 = true;
    opts.SupportedPlatforms.Maci64 = true;
    opts.SupportedPlatforms.Glnxa64 = true;
    opts.SupportedPlatforms.MatlabOnline = true;

    % Populate required addons from requirements file
    try
        requirements = matbox.setup.internal.getRequirements(projectRootDirectory);
        if ~isempty(requirements)
            opts = addRequirementsToToolboxOptions(opts, requirements);
        end
    catch ME
        if strcmp(ME.identifier, "MatBox:Setup:RequirementsFileNotFound")
            % Pass, no requirements
        else
            rethrow(ME)
        end
    end

    outputFileName = resolveOutputFileName(toolboxInfoFileContent, ...
        MLTBX_NAME, opts.ToolboxVersion);
    opts.OutputFile = fullfile(projectRootDirectory, "releases", outputFileName);

    toolboxOptions = opts;
end

function outputFileName = resolveOutputFileName(toolboxInfoFileContent, mltbxName, toolboxVersion)
% resolveOutputFileName - Get the file name of the packaged .mltbx file
%
%   A non-empty top-level "MltbxFileName" field in MLToolboxInfo.json is used
%   as the file name, with ".mltbx" appended if it is missing. Otherwise the
%   name is <mltbxName>_v<version>.mltbx, where every version separator,
%   including the "+" before a build number, becomes an underscore.

    if isfield(toolboxInfoFileContent, 'MltbxFileName') ...
            && ~isempty(toolboxInfoFileContent.MltbxFileName)
        outputFileName = string(toolboxInfoFileContent.MltbxFileName);
        if ~isscalar(outputFileName) || contains(outputFileName, ["/", "\"])
            error('MatBox:Package:InvalidMltbxFileName', ...
                ['The "MltbxFileName" field in MLToolboxInfo.json must be a ', ...
                'single file name without folders. The packaged toolbox is ', ...
                'always saved in the "releases" folder.'])
        end
        if ~endsWith(outputFileName, ".mltbx", "IgnoreCase", true)
            outputFileName = outputFileName + ".mltbx";
        end
    else
        versionNumber = replace(toolboxVersion, [".", "+"], "_");
        outputFileName = sprintf("%s_v%s.mltbx", mltbxName, versionNumber);
    end
end

function toolboxVersion = formatToolboxVersion(versionNumber)
% formatToolboxVersion - Write a version number in the form ToolboxOptions accepts
%
%   From R2026b, ToolboxVersion must be a semantic version, which writes a
%   build number as <major>.<minor>.<patch>+<build>. Earlier releases accept
%   only <major>.<minor>.<patch>.<build>.

    versionParts = split(versionNumber, ".");
    if numel(versionParts) == 4 && ~isMATLABReleaseOlderThan("R2026b")
        toolboxVersion = join(versionParts(1:3), ".") + "+" + versionParts(4);
    else
        toolboxVersion = versionNumber;
    end
end

function opts = addRequirementsToToolboxOptions(opts, requirements)
    % Add GitHub repository requirements as Additional Software
    isGithubRequirement = strcmp({requirements.Type}, 'GitHub');
    opts.RequiredAdditionalSoftware = ...
        matbox.setup.internal.github.getRequiredAdditionalSoftwareStructForToolboxOptions( {requirements(isGithubRequirement).URI} );

    % Add FileExchange requirements as Addons
    isFexRequirement = strcmp({requirements.Type}, 'FileExchange');
    opts.RequiredAddons = ...
        matbox.setup.internal.fex.getToolboxRequiredAddonStruct( {requirements(isFexRequirement).URI} );
end
