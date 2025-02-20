function startupFilePath = findStartupFile(folderPath)
% findSetupFile - Find a startup.m file in the provided folder
%
%   This function is meant to look for a startup.m file in a matlab
%   repository or package. It will look for the file in the root directory
%   and one folder level down.

    if ~isfolder(folderPath)
        error('Provided folder does not exist')
    end
    
    L = [ dir(fullfile(folderPath, 'startup.m')), ...
          dir(fullfile(folderPath, '*', 'startup.m')) ];

    if isempty(L)
        startupFilePath = string.empty;
    else
        startupFilePath = string(fullfile(L(1).folder, L(1).name));
        if numel(L) > 1
            % Consider displaying a warning?
        end
    end
end
