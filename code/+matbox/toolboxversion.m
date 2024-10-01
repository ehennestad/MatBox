function versionStr = toolboxversion()
% toolboxversion - Get the version identifier for the openMINDS toolbox

    rootPath = matbox.toolboxdir();
    contentsFile = fullfile(rootPath, 'Contents.m');

    if ~isfile(contentsFile)
        error("Toolbox does not have a Contents.m file")
    end
    
    fileStr = fileread(contentsFile);
   
    % First try to get a version with a sub-patch version number
    matchedStr = regexp(fileStr, 'Version \d*\.\d*\.\d*.\d*(?= )', 'match');

    % If not found, get major-minor-patch
    if isempty(matchedStr)
        matchedStr = regexp(fileStr, 'Version \d*\.\d*\.\d*(?= )', 'match');
    end

    if isempty(matchedStr)
        error('MatBox:Version:VersionNotFound', ...
            'No version was detected for this matbox installation.')
    end
    versionStr = matchedStr{1};
end
