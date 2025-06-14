function requirements = getRequirements(packageRootDirectory)
% getRequirements - Get toolbox requirements / dependencies
%
%   requirements = matbox.setup.internal.getRequirements(packageRootDirectory)
%       returns a struct array where each element represents a
%       requirement/dependency. This function assumes a requirements.txt
%       file is present in the provided packageRootDirectorys
    
    arguments
        packageRootDirectory (1,1) string
    end

    requirementsFilePath = fullfile(packageRootDirectory, 'requirements.txt');
    
    if ~isfile(requirementsFilePath)
        error("SetupTools:RequirementsFileNotFound", ...
            'No requirements file was found in the given toolbox folder')
    end

    requirementsStr = fileread(requirementsFilePath);
    requirements = splitlines(requirementsStr);

    isEmpty = cellfun('isempty', requirements);
    requirements(isEmpty) = [];
    
    isComment = cellfun(@(str) startsWith(str, "#"), requirements);
    requirements(isComment) = [];

    requirements = parseRequirements(requirements);
end

function parsedRequirements = parseRequirements(requirements) % Needed?

    parsedRequirements = struct;

    for i = 1:numel(requirements)
        
        if startsWith(requirements{i}, "fex://")
            type = 'FileExchange';
        elseif startsWith(requirements{i}, "https://github.com")
            type = 'GitHub';
        else
            type = 'Unknown';
            warning('Unsupported requirement specification: %s', requirements{i})
        end
        
        parsedRequirements(i).Type = type;
        parsedRequirements(i).URI = string(requirements{i});
    end

    parsedRequirements = parsedRequirements( ~cellfun('isempty', requirements) );
end
