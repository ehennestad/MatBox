function setupFilePath = findSetupFile(folderPath)
% findSetupFile - Find a setup.m file in the provided folder
%
%   This function is meant to look for a setup.m file in a matlab
%   repository or package. It will look for the file in the root directory
%   and one folder level down.

    if ~isfolder(folderPath)
        error('Provided folder does not exist')
    end
    
    L = [ dir(fullfile(folderPath, 'setup.m')), ...
          dir(fullfile(folderPath, '*', 'setup.m')) ];

    if isempty(L)
        setupFilePath = string.empty;
    else
        setupFilePath = string(fullfile(L(1).folder, L(1).name));
    end
end
