function files = listMatFiles(rootDirectory)
    arguments
        rootDirectory (1,1) string {mustBeFolder}
    end

    fileListing = dir(fullfile(rootDirectory, "**", "*.m"));
    files = fullfile(string({fileListing.folder}'),string({fileListing.name}'));
end
