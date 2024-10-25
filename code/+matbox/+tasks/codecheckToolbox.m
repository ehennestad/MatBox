function issues = codecheckToolbox(projectRootDir, options)
    arguments
        projectRootDir (1,1) string {mustBeFolder}
        % Assumes this function is located in <rootDir>/dev
        options.CreateBadge (1,1) logical = true
        options.RequireIssuesResolved (1,1) logical = false
        options.SeverityThreshold (1,1) string ...
            {mustBeMember(options.SeverityThreshold, ["info", "warning", "error"])} = "warning"
        options.SaveReport (1,1) logical = true
    end

    toolboxFileInfo = dir(fullfile(projectRootDir, "**", "*.m"));
    filesToCheck = fullfile(string({toolboxFileInfo.folder}'),string({toolboxFileInfo.name}'));
    
    if isempty(filesToCheck)
        error("MatBox:CodeIssues", "No files to check.")
    end

    issueCount = struct;
    
    if verLessThan('matlab','9.13') %#ok<VERLESSMATLAB>
        % Use the old check code before R2022b
        issues = checkcode(filesToCheck);
        issues = cat(1, issues{:});
        issueCount.Total = size(issues,1);
        issueCount.Info = issueCount;
        [issueCount.Warning, issueCount.Error] = deal(0);
    else
        % Use the new code analyzer in R2022b and later
        issues = codeIssues(filesToCheck);
        issueCount.Total = size(issues.Issues,1);
        issueCount.Info = sum(issues.Issues.Severity == "info");
        issueCount.Warning = sum(issues.Issues.Severity == "warning");
        issueCount.Error = sum(issues.Issues.Severity == "error");

        if options.SaveReport
            reportDirectory = fullfile(projectRootDir, 'docs', 'reports');
            if ~isfolder(reportDirectory)
                mkdir(reportDirectory)
            end
            export(issues, fullfile(reportDirectory, 'code_issues'));
        end
    end
    fprintf("Checked %d files with %d issue(s).\n", ...
        numel(filesToCheck), issueCount.Total)

    if options.CreateBadge
        createCodeIssuesBadge(issueCount, projectRootDir) % Local function
    end

    if issueCount.Total > 0
        if verLessThan('matlab','9.13') %#ok<VERLESSMATLAB>
            % pre R2022b, run checkcode without a RHS argument to display issues
            checkcode(filesToCheck)
        else
            % R2022b and later, just display issues
            if ~nargout
                disp(issues)
            end
        end

        % Throw error if unresolved issues are present at specified severity
        if options.RequireIssuesResolved
            if options.SeverityThreshold == "info" && issueCount.Total > 0
                throwUnresolvedCodeIssuesException()
            elseif options.SeverityThreshold == "warning" && (issueCount.Warning > 0 || issueCount.Error > 0)
                throwUnresolvedCodeIssuesException()
            elseif options.SeverityThreshold == "error" && issueCount.Error > 0
                throwUnresolvedCodeIssuesException()
            end
        end

        if ~nargout
            clear issues
        end
    end
end

function createCodeIssuesBadge(issueCount, projectRootDir)
 % Generate the JSON files for the shields in the readme.md
    color = "green";

    if issueCount.Warning > 0
        color = "yellow";
    end
    if issueCount.Error > 0
        color = "red";
    end
    matbox.utility.writeBadgeJSONFile("code issues", ...
        string(issueCount.Total), color, projectRootDir)
end

function ME = throwUnresolvedCodeIssuesException()
    ME = MException(...
        "MatBox:CodeIssues:UnresolvedIssues", ...
        "MatBox requires all code check issues to be resolved." ...
        );

    throw(ME)
end
