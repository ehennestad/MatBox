function commitHash = readCommitHash(repositoryFolderPath)
    filePath = fullfile(repositoryFolderPath, '.commit_hash');
    commitHash = fileread(filePath);
end
