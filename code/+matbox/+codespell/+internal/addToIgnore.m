function addToIgnore(word, ignoreFilePath)
    
    if isfile(ignoreFilePath)
        fileContent = fileread(ignoreFilePath);
        fileContent = [fileContent, word, newline];
    else
        fileContent = '';
    end
    fid = fopen(ignoreFilePath, 'wt');
    fwrite(fid, fileContent);
    fclose(fid);

    fprintf('Added "%s" to ignore file\n', word)
end