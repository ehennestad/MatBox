function migrationPlan = migrateToMatBoxRepo(repoRoot, options)
% migrateToMatBoxRepo - Migrate a MATLAB repository to MatBox layout
%
%   PLAN = matbox.repo.migrateToMatBoxRepo(REPOROOT) creates a dry-run
%   migration plan for moving a repository to the src/tests/tools layout
%   used by MatBox-compatible toolbox repositories.
%
%   matbox.repo.migrateToMatBoxRepo(..., "DryRun", false) applies the plan.
%
%   Calling without inputs opens a small dialog for collecting metadata.

    arguments
        repoRoot (1,1) string = ""
        options.SourceFolder (1,1) string = missing
        options.Namespace (1,1) string = missing
        options.ToolboxName (1,1) string = missing
        options.AuthorName (1,1) string = ""
        options.AuthorEmail (1,1) string = ""
        options.AuthorCompany (1,1) string = ""
        options.Summary (1,1) string = ""
        options.Description (1,1) string = ""
        options.MinimumMatlabRelease (1,1) string = "R2019b"
        options.TemplateRepo (1,1) string = defaultTemplateRepo()
        options.DryRun (1,1) logical = true
        options.AllowDirty (1,1) logical = false
        options.Overwrite (1,1) logical = false
        options.CreateNamespaceUtilities (1,1) logical = false
        options.ValidateToolboxOptions (1,1) logical = false
    end

    if nargin == 0
        userOptions = collectMigrationOptions();
        if isempty(userOptions)
            migrationPlan = [];
            return
        end
        migrationPlan = matbox.repo.migrateToMatBoxRepo(userOptions.RepoRoot, ...
            "SourceFolder", userOptions.SourceFolder, ...
            "Namespace", userOptions.Namespace, ...
            "ToolboxName", userOptions.ToolboxName, ...
            "AuthorName", userOptions.AuthorName, ...
            "AuthorEmail", userOptions.AuthorEmail, ...
            "AuthorCompany", userOptions.AuthorCompany, ...
            "Summary", userOptions.Summary, ...
            "Description", userOptions.Description, ...
            "MinimumMatlabRelease", userOptions.MinimumMatlabRelease, ...
            "TemplateRepo", userOptions.TemplateRepo, ...
            "DryRun", userOptions.DryRun);
        return
    end

    if ~isfolder(repoRoot)
        error("MatBox:RepoMigration:RepoRootNotFound", ...
            "Repository root was not found: %s", repoRoot)
    end

    repoRoot = string(char(java.io.File(char(repoRoot)).getCanonicalPath()));
    if ~isfolder(options.TemplateRepo)
        error("MatBox:RepoMigration:TemplateRepoNotFound", ...
            "The Matlab-Toolbox template repository was not found: %s", options.TemplateRepo)
    end

    if ~options.AllowDirty
        assertCleanGitState(repoRoot)
    end

    repoName = string(getFolderName(repoRoot));
    if ismissing(options.ToolboxName) || strlength(options.ToolboxName) == 0
        options.ToolboxName = repoName;
    end
    if ismissing(options.Namespace) || strlength(options.Namespace) == 0
        options.Namespace = makeNamespace(repoName);
    end
    if ismissing(options.SourceFolder) || strlength(options.SourceFolder) == 0
        options.SourceFolder = detectSourceFolder(repoRoot);
    end

    operations = buildMigrationOperations(repoRoot, options);
    migrationPlan = struct( ...
        "RepoRoot", repoRoot, ...
        "SourceFolder", options.SourceFolder, ...
        "Namespace", options.Namespace, ...
        "ToolboxName", options.ToolboxName, ...
        "DryRun", options.DryRun, ...
        "Operations", operations);

    displayMigrationPlan(migrationPlan)

    if ~options.DryRun
        applyMigrationOperations(repoRoot, operations, options.Overwrite)
        validateMigration(repoRoot, options.ValidateToolboxOptions)
    end

    if nargout == 0
        clear migrationPlan
    end
end

function operations = buildMigrationOperations(repoRoot, options)
    operations = table( ...
        strings(0,1), strings(0,1), strings(0,1), strings(0,1), strings(0,1), ...
        'VariableNames', ["Action", "Source", "Destination", "Content", "Description"]);

    sourceFolder = fullfile(repoRoot, options.SourceFolder);
    destinationFolder = fullfile(repoRoot, "src", options.SourceFolder);
    if ~isfolder(sourceFolder) && ~isfolder(destinationFolder)
        error("MatBox:RepoMigration:SourceFolderNotFound", ...
            "Source folder was not found: %s", sourceFolder)
    end

    if isfolder(sourceFolder)
        operations = addOperation(operations, "move", sourceFolder, destinationFolder, "", ...
            "Move existing MATLAB source folder into src");
    end

    operations = addOperation(operations, "mkdir", "", fullfile(repoRoot, "tests"), "", ...
        "Create tests folder");
    operations = addOperation(operations, "mkdir", "", fullfile(repoRoot, "tools"), "", ...
        "Create tools folder");

    toolsPackageName = "+" + options.Namespace + "tools";
    operations = addOperation(operations, "mkdir", "", fullfile(repoRoot, "tools", toolsPackageName), "", ...
        "Create tools package folder");
    operations = addOperation(operations, "write", "", fullfile(repoRoot, "tools", "MLToolboxInfo.json"), ...
        createToolboxInfoJson(options), "Create MatBox toolbox metadata");

    operations = addOperation(operations, "copy", templateFile(options.TemplateRepo, ...
        "cookiecutter_templates", "main_template", "{{cookiecutter.repo_name}}", ...
        "tools", "+{{cookiecutter.namespace_name}}tools", "projectdir.m"), ...
        fullfile(repoRoot, "tools", toolsPackageName, "projectdir.m"), "", ...
        "Create projectdir helper");

    operations = addOperation(operations, "copy", templateFile(options.TemplateRepo, ...
        "cookiecutter_templates", "main_template", "{{cookiecutter.repo_name}}", ...
        "tools", "+{{cookiecutter.namespace_name}}tools", "installMatBox.m"), ...
        fullfile(repoRoot, "tools", toolsPackageName, "installMatBox.m"), "", ...
        "Create MatBox installer helper");

    if options.CreateNamespaceUtilities
        namespacePackageFolder = fullfile(repoRoot, "src", options.SourceFolder, "+" + options.Namespace);
        operations = addOperation(operations, "mkdir", "", namespacePackageFolder, "", ...
            "Create source namespace utilities folder");
        operations = addOperation(operations, "copy-render", templateFile(options.TemplateRepo, ...
            "cookiecutter_templates", "main_template", "{{cookiecutter.repo_name}}", ...
            "src", "{{cookiecutter.namespace_name}}", "+{{cookiecutter.namespace_name}}", "toolboxdir.m"), ...
            fullfile(namespacePackageFolder, "toolboxdir.m"), "", ...
            "Create toolboxdir utility");
        operations = addOperation(operations, "copy-render", templateFile(options.TemplateRepo, ...
            "cookiecutter_templates", "main_template", "{{cookiecutter.repo_name}}", ...
            "src", "{{cookiecutter.namespace_name}}", "+{{cookiecutter.namespace_name}}", "toolboxversion.m"), ...
            fullfile(namespacePackageFolder, "toolboxversion.m"), "", ...
            "Create toolboxversion utility");
    end

    workflowNames = ["test-code.yml", "run-codespell.yml", "prepare-release.yml"];
    for workflowName = workflowNames
        operations = addOperation(operations, "copy", ...
            fullfile(options.TemplateRepo, ".github", "workflows", workflowName), ...
            fullfile(repoRoot, ".github", "workflows", workflowName), "", ...
            "Copy GitHub workflow from Matlab-Toolbox");
    end

    operations = addOperation(operations, "copy-if-missing", templateFile(options.TemplateRepo, ...
        "cookiecutter_templates", "main_template", "{{cookiecutter.repo_name}}", "requirements.txt"), ...
        fullfile(repoRoot, "requirements.txt"), "", ...
        "Create requirements file if missing");

    gitignoreTemplate = fileread(templateFile(options.TemplateRepo, ...
        "cookiecutter_templates", "main_template", "{{cookiecutter.repo_name}}", ".gitignore"));
    operations = addOperation(operations, "merge-gitignore", "", fullfile(repoRoot, ".gitignore"), ...
        string(gitignoreTemplate), "Merge MatBox gitignore entries");
end

function operations = addOperation(operations, action, source, destination, content, description)
    operations(end+1,:) = {string(action), string(source), string(destination), ...
        string(content), string(description)};
end

function applyMigrationOperations(repoRoot, operations, overwrite)
    for i = 1:height(operations)
        action = operations.Action(i);
        source = operations.Source(i);
        destination = operations.Destination(i);

        switch action
            case "move"
                ensureDestinationAvailable(destination, overwrite)
                ensureParentFolder(destination)
                moveRepositoryPath(repoRoot, source, destination)
            case "mkdir"
                if ~isfolder(destination)
                    mkdir(destination)
                end
            case "write"
                ensureDestinationAvailable(destination, overwrite)
                ensureParentFolder(destination)
                writeTextFile(destination, operations.Content(i))
            case "copy"
                ensureTemplateFileExists(source)
                ensureDestinationAvailable(destination, overwrite)
                ensureParentFolder(destination)
                copyfile(source, destination)
            case "copy-if-missing"
                ensureTemplateFileExists(source)
                if ~isfile(destination) && ~isfolder(destination)
                    ensureParentFolder(destination)
                    copyfile(source, destination)
                end
            case "copy-render"
                ensureTemplateFileExists(source)
                ensureDestinationAvailable(destination, overwrite)
                ensureParentFolder(destination)
                text = renderTemplate(fileread(source), operations, i);
                writeTextFile(destination, text)
            case "merge-gitignore"
                mergeGitignore(destination, operations.Content(i))
            otherwise
                error("MatBox:RepoMigration:UnknownOperation", ...
                    "Unknown migration operation: %s", action)
        end
    end
end

function moveRepositoryPath(repoRoot, source, destination)
    if isfolder(fullfile(repoRoot, ".git"))
        runSystemCommand("git", ["-C", repoRoot, "mv", source, destination])
    else
        movefile(source, destination)
    end
end

function runSystemCommand(commandName, commandArguments)
    commandParts = [commandName, quoteCommandArguments(commandArguments)];
    commandString = strjoin(commandParts, " ");
    [status, output] = system(commandString);
    if status ~= 0
        error("MatBox:RepoMigration:SystemCommandFailed", ...
            "Command failed: %s\n%s", commandString, output)
    end
end

function quotedArguments = quoteCommandArguments(commandArguments)
    commandArguments = string(commandArguments);
    commandArguments = replace(commandArguments, '"', '\"');
    quotedArguments = """" + commandArguments + """";
end

function ensureDestinationAvailable(destination, overwrite)
    if isfile(destination) || isfolder(destination)
        if ~overwrite
            error("MatBox:RepoMigration:DestinationExists", ...
                "Destination already exists. Use Overwrite=true to replace it: %s", destination)
        end
        if isfolder(destination)
            rmdir(destination, "s")
        else
            delete(destination)
        end
    end
end

function ensureParentFolder(filePath)
    parentFolder = fileparts(filePath);
    if parentFolder ~= "" && ~isfolder(parentFolder)
        mkdir(parentFolder)
    end
end

function ensureTemplateFileExists(filePath)
    if ~isfile(filePath)
        error("MatBox:RepoMigration:TemplateFileNotFound", ...
            "Template file was not found: %s", filePath)
    end
end

function mergeGitignore(destination, templateText)
    if ~isfile(destination)
        writeTextFile(destination, ensureTrailingNewline(templateText))
        return
    end

    existingText = string(fileread(destination));
    existingLines = splitlines(existingText);
    templateLines = splitlines(templateText);

    isBlankTemplateLine = templateLines == "";
    isMissingTemplateLine = ~isBlankTemplateLine & ~ismember(templateLines, existingLines);
    if ~any(isMissingTemplateLine)
        return
    end

    linesToAppend = templateLines(isBlankTemplateLine | isMissingTemplateLine);
    linesToAppend = trimBlankBoundaryLines(linesToAppend);

    newText = ensureTrailingNewline(existingText) + newline + ...
        strjoin(linesToAppend, newline) + newline;
    writeTextFile(destination, newText)
end

function text = ensureTrailingNewline(text)
    text = string(text);
    if ~endsWith(text, newline)
        text = text + newline;
    end
end

function lines = trimBlankBoundaryLines(lines)
    while ~isempty(lines) && lines(1) == ""
        lines(1) = [];
    end
    while ~isempty(lines) && lines(end) == ""
        lines(end) = [];
    end
end

function validateMigration(repoRoot, validateToolboxOptions)
    matbox.toolbox.readToolboxInfo(repoRoot);
    if validateToolboxOptions
        matbox.toolbox.createToolboxOptions(repoRoot, "0.1.0");
    end
end

function displayMigrationPlan(plan)
    fprintf("MatBox repository migration plan for %s\n", plan.RepoRoot)
    fprintf("  Source folder: %s\n", plan.SourceFolder)
    fprintf("  Namespace: %s\n", plan.Namespace)
    fprintf("  Dry run: %d\n\n", plan.DryRun)
    disp(plan.Operations(:, ["Action", "Source", "Destination", "Description"]))
end

function toolboxInfoJson = createToolboxInfoJson(options)
    toolboxInfo = struct();
    toolboxInfo.Namespace = char(options.Namespace);
    toolboxInfo.ToolboxOptions = struct( ...
        "Identifier", char(java.util.UUID.randomUUID()), ...
        "ToolboxName", char(options.ToolboxName), ...
        "AuthorName", char(options.AuthorName), ...
        "AuthorEmail", char(options.AuthorEmail), ...
        "AuthorCompany", char(options.AuthorCompany), ...
        "Summary", char(options.Summary), ...
        "Description", char(options.Description), ...
        "MinimumMatlabRelease", char(options.MinimumMatlabRelease), ...
        "MaximumMatlabRelease", "");

    toolboxInfoJson = string(jsonencode(toolboxInfo, "PrettyPrint", true));
end

function sourceFolder = detectSourceFolder(repoRoot)
    listing = dir(repoRoot);
    listing = listing([listing.isdir]);
    folderNames = string({listing.name});
    excludedFolders = [".", "..", ".git", ".github", "docs", "releases", ...
        "src", "test", "tests", "tools"];
    folderNames(ismember(folderNames, excludedFolders)) = [];

    candidates = strings(0,1);
    for folderName = folderNames
        if containsMatlabFiles(fullfile(repoRoot, folderName))
            candidates(end+1,1) = folderName; %#ok<AGROW>
        end
    end

    if isempty(candidates)
        error("MatBox:RepoMigration:SourceFolderNotDetected", ...
            "No source folder candidate was detected. Provide SourceFolder explicitly.")
    elseif numel(candidates) > 1
        error("MatBox:RepoMigration:AmbiguousSourceFolder", ...
            "Multiple source folder candidates were detected: %s. Provide SourceFolder explicitly.", ...
            strjoin(candidates, ", "))
    end

    sourceFolder = candidates;
end

function tf = containsMatlabFiles(folderPath)
    tf = ~isempty(dir(fullfile(folderPath, "**", "*.m"))) || ...
        ~isempty(dir(fullfile(folderPath, "**", "*.mlx")));
end

function assertCleanGitState(repoRoot)
    if ~isfolder(fullfile(repoRoot, ".git"))
        return
    end

    command = sprintf('git -C "%s" status --porcelain', repoRoot);
    [status, output] = system(command);
    if status ~= 0
        error("MatBox:RepoMigration:GitStatusFailed", ...
            "Could not inspect git status for %s", repoRoot)
    end
    if strlength(strtrim(string(output))) > 0
        error("MatBox:RepoMigration:DirtyGitState", ...
            "Repository has uncommitted changes. Commit, stash, or use AllowDirty=true.")
    end
end

function templateRepo = defaultTemplateRepo()
    matboxRepo = fileparts(matbox.toolboxdir());
    templateRepo = fullfile(fileparts(matboxRepo), "Matlab-Toolbox");
end

function filePath = templateFile(templateRepo, varargin)
    filePath = fullfile(templateRepo, varargin{:});
end

function namespace = makeNamespace(repoName)
    namespace = lower(regexprep(repoName, "[^A-Za-z0-9]", ""));
    namespace = string(matlab.lang.makeValidName(namespace));
end

function folderName = getFolderName(folderPath)
    [~, folderName] = fileparts(folderPath);
end

function text = renderTemplate(text, operations, index)
    [sourceParent, ~] = fileparts(operations.Destination(index));
    [~, packageName] = fileparts(sourceParent);
    namespace = extractAfter(string(packageName), "+");

    text = strrep(text, "{{ cookiecutter.namespace_name }}", "{{cookiecutter.namespace_name}}");
    text = strrep(text, "{{ cookiecutter.toolbox_name }}", "{{cookiecutter.toolbox_name}}");
    text = strrep(text, "{{ cookiecutter.namespace_name | upper}}", "{{cookiecutter.namespace_name | upper}}");
    text = strrep(text, "{{cookiecutter.namespace_name}}", char(namespace));
    text = strrep(text, "{{cookiecutter.namespace_name | upper}}", char(upper(namespace)));
    text = strrep(text, "{{cookiecutter.toolbox_name}}", char(namespace));
end

function writeTextFile(filePath, text)
    fid = fopen(filePath, "w");
    cleanupObj = onCleanup(@() fclose(fid));
    fwrite(fid, char(text));
end

function userOptions = collectMigrationOptions()
    userOptions = [];

    fig = uifigure("Name", "Migrate Repository to MatBox", ...
        "Position", [100 100 560 620], "WindowStyle", "modal");
    cleanupObj = onCleanup(@() closeFigureIfValid(fig));

    grid = uigridlayout(fig, [13 2]);
    grid.RowHeight = repmat({30}, 1, 13);
    grid.ColumnWidth = {150, "1x"};
    grid.Padding = [12 12 12 12];

    repoRootField = addTextField(grid, "Repository root", pwd);
    sourceFolderField = addTextField(grid, "Source folder", "");
    namespaceField = addTextField(grid, "Namespace", "");
    toolboxNameField = addTextField(grid, "Toolbox name", "");
    authorNameField = addTextField(grid, "Author name", "");
    authorEmailField = addTextField(grid, "Author email", "");
    authorCompanyField = addTextField(grid, "Author company", "");
    summaryField = addTextField(grid, "Summary", "");
    descriptionField = addTextField(grid, "Description", "");
    minimumReleaseField = addTextField(grid, "Minimum MATLAB release", "R2019b");
    templateRepoField = addTextField(grid, "Template repo", defaultTemplateRepo());

    uilabel(grid, "Text", "Dry run");
    dryRunField = uicheckbox(grid, "Value", true, "Text", "");

    buttonGrid = uigridlayout(grid, [1 2]);
    buttonGrid.Layout.Row = 13;
    buttonGrid.Layout.Column = [1 2];
    buttonGrid.ColumnWidth = {"1x", "1x"};
    uibutton(buttonGrid, "Text", "Cancel", "ButtonPushedFcn", @(~,~) cancelDialog(fig));
    uibutton(buttonGrid, "Text", "Run", "ButtonPushedFcn", @(~,~) submitDialog(fig));

    uiwait(fig)

    if ~isvalid(fig) || ~isfield(fig.UserData, "Submitted") || ~fig.UserData.Submitted
        return
    end

    userOptions = struct( ...
        "RepoRoot", string(repoRootField.Value), ...
        "SourceFolder", string(sourceFolderField.Value), ...
        "Namespace", string(namespaceField.Value), ...
        "ToolboxName", string(toolboxNameField.Value), ...
        "AuthorName", string(authorNameField.Value), ...
        "AuthorEmail", string(authorEmailField.Value), ...
        "AuthorCompany", string(authorCompanyField.Value), ...
        "Summary", string(summaryField.Value), ...
        "Description", string(descriptionField.Value), ...
        "MinimumMatlabRelease", string(minimumReleaseField.Value), ...
        "TemplateRepo", string(templateRepoField.Value), ...
        "DryRun", dryRunField.Value);
end

function field = addTextField(grid, label, value)
    uilabel(grid, "Text", label);
    field = uieditfield(grid, "text", "Value", char(value));
end

function submitDialog(fig)
    fig.UserData = struct("Submitted", true);
    uiresume(fig)
end

function cancelDialog(fig)
    fig.UserData = struct("Submitted", false);
    uiresume(fig)
end

function closeFigureIfValid(fig)
    if isvalid(fig)
        close(fig)
    end
end
