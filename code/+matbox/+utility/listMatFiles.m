function files = listMatFiles(rootDirectory)
    arguments
        rootDirectory (1,:) string {mustBeFolder}
    end

    fileListing = cell(1, numel(rootDirectory));
    for i = 1:numel(rootDirectory)
        fileListing{i} = dir(fullfile(rootDirectory(i), "**", "*.m"));
    end
    fileListing = cat(1, fileListing{:});

    files = string( fullfile({fileListing.folder}', {fileListing.name}') );
end
