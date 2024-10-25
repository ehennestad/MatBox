function codespellToolbox(codeFolder, options)
% codeSpellToolbox - run codespell on a code directory / toolbox
%
%   Note: codespell must be installed (pip install codespell)
%       codespell executable must be provided if it is different from default

    arguments
        codeFolder (1,1) string {mustBeFolder} = pwd
        options.DoAutomaticFix (1,1) logical = false
        options.IgnoreFilePath (1,1) string = ".codespell_ignore"
        options.Skip (1,:) string = string.empty
        options.CodeSpellExecutable (1,1) string = '/opt/homebrew/bin/codespell';
        options.RequireCodespellPassing (1,1) logical = false
        options.SaveResults (1,1) logical = false;
    end
    
    if ~strcmp(codeFolder, pwd)
        currentDir = pwd();
        cleanupObj = onCleanup( @(pathName) cd(currentDir));
        cd(codeFolder)
    end

    options.Skip = [options.Skip, "*words.txt"];
    
    commandStr = options.CodeSpellExecutable;
    
    if options.DoAutomaticFix
        commandStr = sprintf("%s --write-changes", commandStr);
    end

    if ~ismissing(options.IgnoreFilePath)
        commandStr = sprintf("%s --ignore-words %s", commandStr, options.IgnoreFilePath);
        if ~isfile(options.IgnoreFilePath)
            fid = fopen(options.IgnoreFilePath, "w");
            fwrite(fid, '');
            fclose(fid);
        end
    end

    if ~isempty(options.Skip)
        commandStr = sprintf("%s --skip=""%s""", commandStr, join(options.Skip, ','));
    end

    [s, m] = system(commandStr);
    codespellPassing = ~s;
    
    if options.DoAutomaticFix
        return
    end

    if ~codespellPassing % Parse results.

        % Remove color formatting (Term color)
        colorFormatIdentifiers = ["[33m", "[0m", "[31m", "[32m"];
        for colorSpec = colorFormatIdentifiers
            m = strrep(m, colorSpec, '');
        end

        % Remove escape character
        m = strrep(m, char(27), ''); % Remove escape (esc) char

        % Split lines
        lines = string( strsplit(m, newline) );

        % Ignore warnings
        skip = startsWith(lines, "WARNING");
        lines(skip) = [];

        % Skip empty lines:
        lines(lines == "") = [];

        S = struct("File", {}, "Ignore", {}, "Word", {}, "Suggestion", {}, "Auto", {});
        typos = repmat("", numel(lines), 1);

        for i = 1:numel(lines)
            splitLine = split(lines{i}, ':');
            
            % Clean filepath:
            relativeFilePath = splitLine{1}(2:end);
            filePath = fullfile(codeFolder, relativeFilePath);
            
            fullName = omni.matlab.meta.abspath2funcname(strtrim(filePath));
            lineNumber = str2double(splitLine{2});

            S(i).File = omni.matlab.code.utility.createOpenInEditorLink(filePath, fullName, lineNumber);

            splitWords = strsplit(splitLine{3}, ' ==> ');
            S(i).Word = strtrim( string(splitWords{1}));
            S(i).Suggestion = string(splitWords{2});

            typos(i) = splitLine{3};
            S(i).Auto = isscalar( strsplit(S(i).Suggestion, ',') );

            if ~ismissing(options.IgnoreFilePath)
                S(i).Ignore = createIgnoreLink(S(i).Word, options.IgnoreFilePath);
            end
        end
        
        if options.SaveResults
            fid = fopen('words.txt', 'w');
            fwrite(fid, strjoin(typos, newline));
            fclose(fid);
        else
            T = struct2table(S);
            T = sortrows(T, "Auto");
            disp( T )
        end

    
        if options.RequireCodespellPassing
            message = sprintf( "Codespell identified the following potential spelling mistakes:\n%s", ...
                strjoin( "    " + typos, newline));
            assert(codespellPassing, message)
        end
    end
end

function linkStr = createIgnoreLink(word, ignoreFilePath)
    linkStr = sprintf('<a href = "matlab:matbox.codespell.internal.addToIgnore(''%s'', ''%s'')">%s</a>', word, ignoreFilePath, 'Ignore');
    linkStr = string(linkStr);
end
