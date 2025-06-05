function result = resolveFiles(rootDir, folderPaths, filePaths)

    arguments
        rootDir (1,1) string
        folderPaths (1,:) string
        filePaths (1,:) string
    end

    folderPaths(folderPaths=="") = []; % Filter out strings with strlength = 0

    if isempty(folderPaths) && isempty(filePaths)
        result = matbox.utility.listMatFiles(rootDir);
    elseif isempty(folderPaths) && ~isempty(filePaths)
        result = filePaths;
    elseif ~isempty(folderPaths) && isempty(filePaths)
        result = matbox.utility.listMatFiles(folderPaths);
    else
        result = unique( ...
            cat(1, ...
                matbox.utility.listMatFiles(folderPaths), ...
                filePaths ...
                ) ...
            );
    end
end
