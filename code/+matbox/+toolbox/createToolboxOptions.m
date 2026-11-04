function toolboxOptions = createToolboxOptions(projectRootDirectory, versionNumber, options)
% createToolboxOptions - Create the ToolboxOptions for packaging a project
%
%   toolboxOptions = matbox.toolbox.createToolboxOptions(projectRootDirectory, versionNumber)
%   returns a matlab.addons.toolbox.ToolboxOptions object for the given
%   version, built from the project's MLToolboxInfo.json and
%   requirements.txt.
%
%   Example:
%       toolboxOptions = matbox.toolbox.createToolboxOptions(pwd, "0.9.2", "SourceFolderName", "code")

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
    toolboxFolder = fullfile(projectRootDirectory, options.SourceFolderName);

    % ToolboxOptions has the Readme and PackageName properties from R2026b,
    % and earlier releases reject them as unknown name-value arguments. They
    % are therefore taken out before the constructor and set afterwards on
    % the releases that have them.
    [toolboxInfo, readme] = takeOptionalField(toolboxInfo, "Readme");
    if readme ~= ""
        readmeFile = resolveReadmeFile(toolboxFolder, readme);
    end
    [toolboxInfo, packageName] = takeOptionalField(toolboxInfo, "PackageName");
    if packageName ~= ""
        mustBeValidPackageName(packageName)
    end

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
    opts = matlab.addons.toolbox.ToolboxOptions(toolboxFolder, identifier, toolboxInfo);

    if readme ~= "" && isprop(opts, "Readme")
        opts.Readme = readmeFile;
    end
    if packageName ~= "" && isprop(opts, "PackageName")
        opts.PackageName = packageName;
    end

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

function [toolboxInfo, value] = takeOptionalField(toolboxInfo, fieldName)
% takeOptionalField - Remove a field from the toolbox info and return its value
%
%   The value is "" when the field is absent or empty.

    value = "";
    if isfield(toolboxInfo, fieldName)
        if ~isempty(toolboxInfo.(fieldName))
            value = string(toolboxInfo.(fieldName));
        end
        toolboxInfo = rmfield(toolboxInfo, fieldName);
    end
    if ~isscalar(value)
        error("MatBox:Package:InvalidToolboxInfoField", ...
            '"%s" in MLToolboxInfo.json must be a single text value.', fieldName)
    end
end

function readmeFile = resolveReadmeFile(toolboxFolder, readme)
% resolveReadmeFile - Get the full path of the readme named in MLToolboxInfo.json
%
%   The package contains only the files below the source folder, so the
%   readme is given relative to that folder. A project root file such as
%   README.md is copied there by listing it in RootFilesToPackage.

    isInsideSourceFolder = ~any(split(readme, ["/", "\"]) == "..");
    readmeFile = fullfile(toolboxFolder, readme);
    if ~isInsideSourceFolder || ~isfile(readmeFile)
        error("MatBox:Package:ReadmeNotFound", ...
            ['The file "%s" given as "Readme" in MLToolboxInfo.json is not in ', ...
            'the source folder "%s". Give its path relative to the source ', ...
            'folder, or list a project root file in "RootFilesToPackage" to ', ...
            'copy it there.'], readme, toolboxFolder)
    end
end

function mustBeValidPackageName(packageName)
% mustBeValidPackageName - Check the package name, which must be a MATLAB identifier
    if ~isvarname(packageName)
        error("MatBox:Package:InvalidPackageName", ...
            ['"PackageName" in MLToolboxInfo.json is "%s", which is not a ', ...
            'valid MATLAB identifier. Use a letter followed by letters, ', ...
            'digits or underscores, at most %d characters.'], ...
            packageName, namelengthmax)
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
