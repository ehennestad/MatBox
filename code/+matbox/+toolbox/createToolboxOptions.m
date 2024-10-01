function toolboxOptions = createToolboxOptions(projectRootDirectory, versionNumber, options)
% Script for setting up toolbox (mltbx) options for openMINDS_MATLAB
%
%   Example:
%       toolboxOptions = getToolboxOptions('0.9.2')

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
        versionNumber (1,1) string {mustBeValidVersionNumber(versionNumber)}
        options.ToolboxShortName (1,1) string = missing
        options.SourceFolderName (1,1) string = "code"
        options.IgnorePatterns (1,:) string = string.empty
        options.PathFolders (1,:) string = string.empty
    end

    % Read the toolbox info from MLToolboxInfo.json
    [toolboxInfo, identifier] = matbox.toolbox.readToolboxInfo(projectRootDirectory);
        
    if ismissing(options.ToolboxShortName)
        MLTBX_NAME = toolboxInfo.ToolboxName;
    else
        MLTBX_NAME = options.ToolboxShortName;
    end

    % Initialize the ToolboxOptions from the code folder and initial metadata
    toolboxFolder = fullfile(projectRootDirectory, "code");
    opts = matlab.addons.toolbox.ToolboxOptions(toolboxFolder, identifier, toolboxInfo);
    
    % Set the toolbox version
    opts.ToolboxVersion = versionNumber;

    % Ignore some file
    toIgnore = false(size( opts.ToolboxFiles ));
    for i = 1:numel(options.IgnorePatterns)
        toIgnore = toIgnore | contains(opts.ToolboxFiles, options.IgnorePatterns(i));
    end
    opts.ToolboxFiles = opts.ToolboxFiles(~toIgnore);

    %opts.ToolboxImageFile = fullfile(projectRootDirectory, "img", "light_openMINDS-MATLAB-logo_toolbox.png");
    %opts.ToolboxGettingStartedGuide = fullfile(projectRootDirectory, "code", "gettingStarted.mlx");

    % Specify toolbox path TODO: empty folders
    toolboxPathFolders = fullfile(projectRootDirectory, options.SourceFolderName);

    if isempty(options.PathFolders)
        toolboxPathFolders = string( strsplit(genpath(toolboxPathFolders), pathsep));
        toolboxPathFolders = toolboxPathFolders(1:end-1); % Last element is empty
    else
        for i = 1:numel(options.PathFolders)
            toolboxPathFolders(end+1) = fullfile(projectRootDirectory, options.PathFolders(i)); %#ok<AGROW>
        end
    end

    opts.ToolboxMatlabPath = toolboxPathFolders;
    
    opts.SupportedPlatforms.Win64 = true;
    opts.SupportedPlatforms.Maci64 = true;
    opts.SupportedPlatforms.Glnxa64 = true;
    opts.SupportedPlatforms.MatlabOnline = true;
    
    % Populate required addons from requirements file
    try
        requirements = matbox.setup.internal.getRequirements(projectRootDirectory);
    
        isGithubRequirement = strcmp({requirements.Type}, 'GitHub');
        opts.RequiredAdditionalSoftware = ...
            matbox.setup.internal.github.getRequiredAdditionalSoftwareStructForToolboxOptions( {requirements(isGithubRequirement).URI} );
    
        isFexRequirement = strcmp({requirements.Type}, 'FileExchange');
        opts.RequiredAddons = ...
            matbox.setup.internal.fex.getToolboxRequiredAddonStruct( {requirements(isFexRequirement).URI} );
    catch
        % Pass, no requirements
    end
    
    % Specify name for output .mltbx file.
    versionNumber = strrep(opts.ToolboxVersion, '.', '_');
    outputFileName = sprintf('%s_v%s.mltbx', MLTBX_NAME, versionNumber);
    opts.OutputFile = fullfile(projectRootDirectory, "releases", outputFileName);

    toolboxOptions = opts;
end
