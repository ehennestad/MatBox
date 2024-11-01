function addToIgnore(word, ignoreFilePath)
    
    [~, ~, fileExt] = fileparts(ignoreFilePath);

    if strcmp(fileExt, '.codespell_ignore')
        if isfile(ignoreFilePath)
            fileContent = fileread(ignoreFilePath);
            fileContent = [fileContent, word, newline];
        else
            fileContent = '';
        end
        
    elseif strcmp(fileExt, '.codespellrc')
        if isfile(ignoreFilePath)
            fileContent = fileread(ignoreFilePath);
        else
            error('MatBox:Codespell', 'Codespell config file does not exist')
        end

        fileLines = string( splitlines(fileContent) );
        fileLines(fileLines=="") = [];

        isIgnoreWordsLine = startsWith(fileLines, 'ignore-words-list');
        if ~any(isIgnoreWordsLine)
            ignoreWordsLineIdx = numel(fileLines)+1;
            ignoreWords = string.empty;
        else
            ignoreWordsLineIdx = find(isIgnoreWordsLine);
            ignoreWordsLineSplit = strsplit(fileLines(isIgnoreWordsLine), "=");
            ignoreWords = strtrim( strsplit(ignoreWordsLineSplit(2), ',') );
        end
        ignoreWords(end+1) = word;
        ignoreWords = unique(ignoreWords);

        ignoreWordsStr = sprintf("ignore-words-list = %s", strjoin(ignoreWords, ', '));
        fileLines(ignoreWordsLineIdx) = ignoreWordsStr;
        fileContent = strjoin(fileLines, newline);
        fileContent = fileContent +  newline;
    end

    fid = fopen(ignoreFilePath, 'wt');
    fwrite(fid, fileContent);
    fclose(fid);
    fprintf('Added "%s" to codespell configuration file\n', word)
end