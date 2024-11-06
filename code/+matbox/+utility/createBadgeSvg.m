function createBadgeSvg(label, message, color, projectRootDirectory, options)
    
    arguments
        label (1,1) string
        message (1,1) string
        color (1,1) string {mustBeMember(color, ["red","green","blue","orange","yellow"])}
        projectRootDirectory (1,1) string = missing
        options.OutputFolder (1,1) string = missing
        options.FileName (1,1) string = missing
    end

    try
        matbox.py.getPackageInfo('pybadges');
    catch
        matbox.py.pipInstall('pybadges')
    end

    badgeSvg = py.pybadges.badge(left_text=label, right_text=message, right_color=color);

    if ismissing(options.OutputFolder)
        if ismissing(projectRootDirectory)
            error("Please specify project root directory or output folder")
        end
        options.OutputFolder = fullfile(projectRootDirectory, ".github", "badges");
    end

    if ~isfolder(options.OutputFolder)
        mkdir(options.OutputFolder)
    end

    if ismissing(options.FileName)
        name = strrep(label, " ", "_");
    else
        name = options.FileName;
    end

    filePath = fullfile(options.OutputFolder, name + ".svg");
    fid = fopen(filePath, "wt");
    try
        fwrite(fid, char(badgeSvg));
    catch e
        fclose(fid);
        rethrow e
    end
    fclose(fid);
    
    fprintf('Saved badge to %s\n', filePath)
end
