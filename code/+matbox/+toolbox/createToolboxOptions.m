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
    [toolboxInfo, identifier] = matbox.toolbox.readToolboxInfo(projectRootDirectory);
    
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
    opts.ToolboxVersion = versionNumber;

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
        opts = addRequirementsToToolboxOptions(opts, requirements);
    catch ME
        if strcmp(ME.identifier, "MatBox:Setup:RequirementsFileNotFound")
            % Pass, no requirements
        else
            rethrow(ME)
        end
    end

    % Specify name for output .mltbx file.
    versionNumber = strrep(opts.ToolboxVersion, '.', '_');
    outputFileName = sprintf('%s_v%s.mltbx', MLTBX_NAME, versionNumber);
    opts.OutputFile = fullfile(projectRootDirectory, "releases", outputFileName);

    toolboxOptions = opts;
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
