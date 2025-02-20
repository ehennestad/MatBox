function addStartupToMainStartup(toolboxFolder)
% addStartupToMainStartup - Add startup from toolbox folder to main startup file
%
% Syntax:
%   matbox.addStartupToMainStartup(toolboxFolder) adds a toolbox' startup.m in 
%   a run statement to the user's main startup file.
%
% Details:
%   This function locates the toolbox’s startup file and then adds a run 
%   statement to the user's main startup file. For a startup file that is a 
%   function, the run statement is inserted into the function body (before the 
%   final end). For a script file (which may include local functions), the run 
%   statement is inserted before the first local function definition.
%
% Caveats:
%   Cases not explicitly handled include files that do not follow the 
%   conventional structure (for example, files that are empty or contain 
%   misleading comments) or if the run statement appears in a commented‐out form.
    
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

    % Only update if the startupFilePath is not already mentioned.
    if ~contains(fileContent, startupFilePath)
        
        lines = splitlines(fileContent);
        % Determine insertion point for the run statement.
        % Find the first non-empty, non-comment line.
        firstCodeLine = find(~cellfun(@(s) isempty(s) || startsWith(strtrim(s), '%'), lines), 1);
        if ~isempty(firstCodeLine) && startsWith(strtrim(lines{firstCodeLine}), 'function')
            % Case 1: The main startup file is a function file.
            % Look for the first local function definition after the header.
            % (If present, the run statement should be inside the main function,
            % i.e. before the first local function.)
            if numel(lines) > firstCodeLine
                localFuncIdx = find(cellfun(@(s) startsWith(strtrim(s), 'function'), lines(firstCodeLine+1:end)), 1);
                if ~isempty(localFuncIdx)
                    % adjust index relative to the full lines
                    insertIdx = firstCodeLine + localFuncIdx - 1;
                else
                    % No local functions: try to find the last "end"
                    endIndices = find(cellfun(@(s) strcmp(strtrim(s), 'end'), lines));
                    if ~isempty(endIndices)
                        insertIdx = endIndices(end);
                    else
                        insertIdx = numel(lines) + 1;
                    end
                end
            else
                insertIdx = numel(lines) + 1;
            end
        else
            % Case 2: The main startup file is a script (with or without local functions).
            % In this case the main executable code is at the top, so if local
            % functions exist, insert before the first local function.
            localFuncIdx = find(cellfun(@(s) startsWith(strtrim(s), 'function'), lines), 1);
            if ~isempty(localFuncIdx)
                insertIdx = localFuncIdx;
            else
                insertIdx = numel(lines) + 1;
            end
        end

        % Prepare the run statement.
        runStatement = sprintf("run('%s')", startupFilePath);
        
        % If the file does not already end with a newline, prepend one.
        if insertIdx == numel(lines)
            if ~endsWith(fileContent, newline)
                runStatement = newline + runStatement;
            end
            runStatement = runStatement + newline;
        end

        % Insert the run statement at the determined index.
        newLines = [lines(1:insertIdx-1); runStatement; lines(insertIdx:end)];

        % Write the new file content.
        newFileContent = join(newLines, newline);
        fid = fopen(mainStartupFilepath, "w"); % Open for writing (overwrite)
        if fid == -1
            error("Unable to open file %s for writing", mainStartupFilepath);
        end
        fileCleanup = onCleanup(@() fclose(fid));
        fprintf(fid, "%s", newFileContent);
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
