function runStartup(toolboxFolder)

    arguments
        toolboxFolder (1,1) string {mustBeFolder}
    end
    
    startupFilePath = matbox.setup.internal.findStartupFile(toolboxFolder);
    if ~isempty(startupFilePath)
        run(startupFilePath)
    end
end
