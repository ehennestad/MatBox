function addStartupToMainStartup(toolboxFolder)
% addStartupToMainStartup - Add startup from toolbox folder to main startup file
    
    arguments
        toolboxFolder (1,1) string {mustBeFolder}
    end
    
    startupFilePath = matbox.setup.internal.findStartupFile(toolboxFolder);
    if isempty(startupFilePath)
        warning('No startup file was found in the given directory:\n%s', toolboxFolder)
        return
    end

    startupListing = string( which('startup', '-all') );

    if numel(startupListing) > 1
        mainStartupFilepath = selectStartupFile(startupListing);
    else
        mainStartupFilepath = fullfile(startupListing.folder, startupListing.name);
    end
    
    fileContent = fileread(mainStartupFilepath);

    % Update startup file if the startupFilePath is not already in the
    % main startup.m
    if ~contains(fileContent, startupFilePath)
        lines = splitlines(fileContent);
        for i = 1:numel(lines)
            if startsWith(lines{i}, "%") || isempty(strtrim(lines{i}))
                continue
            end
        end
    end
end

function mainStartupFilepath = selectStartupFile(startupListing)
    
    fileIndex = arrayfun(@(x) sprintf("[%d]", x), 1:numel(startupListing));
    
    fileIndex = ensureColumn(fileIndex);
    startupListing = ensureColumn(startupListing);

    promptList = "  " + fileIndex + " " + startupListing;

    promptMessage = newline + strjoin([...
        "The following startup files were found on your search path:"
        promptList; ...
        "Please select your main startup file: "], newline);

    answer = input(promptMessage, 's');
    answer = str2double(answer);
    if not( answer >= 1 && answer <= numel(startupListing) )
        error("Please select a number between 1 and %d", numel(startupListing))
    end

    mainStartupFilepath = startupListing(answer);
end

function x = ensureColumn(x)
    if ~iscolumn(x)
        x = transpose(x);
    end
end
