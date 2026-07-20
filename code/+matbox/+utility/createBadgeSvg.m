function createBadgeSvg(label, message, color, projectRootDirectory, options)
% createBadgeSvg - Create an SVG badge using the pybadges Python package
%
%   Deprecated: when running via current matbox-actions workflows, MatBox
%   tasks write badge descriptions as JSON files instead (see
%   matbox.utility.writeBadgeJSONFile), which CI renders to SVG with
%   badge-maker. This function remains as a fallback for local runs and
%   older matbox-actions versions. It requires Python and the deprecated
%   pybadges package, and will be removed in a future major release.

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
    fileCleanup = onCleanup(@() fclose(fid));

    fwrite(fid, char(badgeSvg));
    fprintf('Saved badge to %s\n', filePath)
end
