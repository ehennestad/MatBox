function codecheckToolbox(projectRootDir)
    arguments
        projectRootDir (1,1) string {mustBeFolder}
        % Assumes this function is located in <rootDir>/dev
    end

    toolboxFileInfo = dir(fullfile(projectRootDir, "**", "*.m"));
    filesToCheck = fullfile(string({toolboxFileInfo.folder}'),string({toolboxFileInfo.name}'));
    
    if isempty(filesToCheck)
        error("MatBox:CodeIssues", "No files to check.")
    end

    if verLessThan('matlab','9.13') %#ok<VERLESSMATLAB>
        % Use the old check code before R2022b
        issues = checkcode(filesToCheck);
        issues = cat(1, issues{:});
        issueCount = size(issues,1);
        infoCount = issueCount;
        [warningCount, errorCount] = deal(0);
    else
        % Use the new code analyzer in R2022b and later
        issues = codeIssues(filesToCheck);
        issueCount = size(issues.Issues,1);
        infoCount = sum(issues.Issues.Severity == "info");
        warningCount = sum(issues.Issues.Severity == "warning");
        errorCount = sum(issues.Issues.Severity == "error");
    end

    fprintf("Checked %d files with %d issue(s).\n", numel(filesToCheck), issueCount)

    % Generate the JSON files for the shields in the readme.md
    color = "green";

    if warningCount > 0
        color = "yellow";
    end

    if errorCount > 0
        color = "red";
    end
    matbox.utility.writeBadgeJSONFile("code issues", string(issueCount), color, projectRootDir)
    
    if issueCount ~= 0
        if verLessThan('matlab','9.13') %#ok<VERLESSMATLAB>
            % pre R2022b, run checkcode without a RHS argument to display issues
            checkcode(filesToCheck)
        else
            % R2022b and later, just display issues
            disp(issues)
        end
        %error("MatBox:CodeIssues", "MatBox requires all code check issues be resolved.")
    end
end
