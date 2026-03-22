function [newVersion, mltbxPath] = packageToolbox(releaseType, versionString, varargin)
    arguments
        releaseType {mustBeTextScalar,mustBeMember(releaseType,["build","major","minor","patch","specific"])} = "build"
        versionString {mustBeTextScalar} = "";
    end
    arguments (Repeating)
        varargin
    end

    if ~(exist('+matbox/installRequirements', 'file') == 2)
        installMatBox()
    end

    projectRootDir = matboxtools.projectdir();
    addpath(genpath(projectRootDir))

    [newVersion, mltbxPath] = matbox.tasks.packageToolbox(...
        projectRootDir, releaseType, versionString, ...
        varargin{:}, ...
        "SourceFolderName", "code");
end
