classdef RepoMigrationTest < matlab.unittest.TestCase
% RepoMigrationTest - Tests for repository migration helpers.

    properties
        RepoRoot
        TemplateRepo
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);

            testCase.RepoRoot = fullfile(pwd, "WidgetTable");
            testCase.TemplateRepo = fullfile(pwd, "Matlab-Toolbox");
            createWidgetTableLikeRepo(testCase.RepoRoot)
            createMinimalTemplateRepo(testCase.TemplateRepo)
        end
    end

    methods (Test)
        function testDryRunDoesNotModifyRepository(testCase)
            plan = matbox.repo.migrateToMatBoxRepo(testCase.RepoRoot, ...
                "SourceFolder", "widget_table", ...
                "Namespace", "widgettable", ...
                "ToolboxName", "WidgetTable", ...
                "TemplateRepo", testCase.TemplateRepo);

            testCase.verifyTrue(istable(plan.Operations))
            testCase.verifyTrue(isfolder(fullfile(testCase.RepoRoot, "widget_table")))
            testCase.verifyFalse(isfolder(fullfile(testCase.RepoRoot, "src")))
            testCase.verifyFalse(isfile(fullfile(testCase.RepoRoot, "tools", "MLToolboxInfo.json")))
        end

        function testMigrationCreatesMatBoxRepositoryLayout(testCase)
            matbox.repo.migrateToMatBoxRepo(testCase.RepoRoot, ...
                "SourceFolder", "widget_table", ...
                "Namespace", "widgettable", ...
                "ToolboxName", "WidgetTable", ...
                "AuthorName", "Eivind Hennestad", ...
                "Summary", "A widget table component", ...
                "Description", "A MATLAB UI component", ...
                "TemplateRepo", testCase.TemplateRepo, ...
                "DryRun", false);

            testCase.verifyFalse(isfolder(fullfile(testCase.RepoRoot, "widget_table")))
            testCase.verifyTrue(isfile(fullfile(testCase.RepoRoot, "src", "widget_table", "WidgetTable.m")))
            testCase.verifyTrue(isfolder(fullfile(testCase.RepoRoot, "tests")))
            testCase.verifyTrue(isfile(fullfile(testCase.RepoRoot, "tools", "MLToolboxInfo.json")))
            testCase.verifyTrue(isfile(fullfile(testCase.RepoRoot, "tools", "+widgettabletools", "projectdir.m")))
            testCase.verifyTrue(isfile(fullfile(testCase.RepoRoot, ".github", "workflows", "test-code.yml")))
            testCase.verifyTrue(isfile(fullfile(testCase.RepoRoot, "requirements.txt")))
            testCase.verifyFalse(isfile(fullfile(testCase.RepoRoot, "src", "widget_table", "Contents.m")))
            testCase.verifyFalse(isfolder(fullfile(testCase.RepoRoot, "src", "widget_table", "+widgettable")))

            gitignoreText = string(fileread(fullfile(testCase.RepoRoot, ".gitignore")));
            testCase.verifyTrue(contains(gitignoreText, ...
                "# Ignore releases" + newline + "releases/" + newline + newline + ...
                "# Packaged toolboxes"))

            [~, ~, toolboxInfo] = matbox.toolbox.readToolboxInfo(testCase.RepoRoot);
            testCase.verifyEqual(string(toolboxInfo.Namespace), "widgettable")
            testCase.verifyEqual(string(toolboxInfo.ToolboxOptions.ToolboxName), "WidgetTable")
        end

        function testExistingDestinationIsProtected(testCase)
            mkdir(fullfile(testCase.RepoRoot, "tools"))
            writeTextFile(fullfile(testCase.RepoRoot, "tools", "MLToolboxInfo.json"), "{}")

            testCase.verifyError(@() matbox.repo.migrateToMatBoxRepo(testCase.RepoRoot, ...
                "SourceFolder", "widget_table", ...
                "Namespace", "widgettable", ...
                "ToolboxName", "WidgetTable", ...
                "TemplateRepo", testCase.TemplateRepo, ...
                "DryRun", false), ...
                "MatBox:RepoMigration:DestinationExists")
        end

        function testExistingRequirementsFileIsPreserved(testCase)
            expectedText = "https://github.com/example/dependency";
            writeTextFile(fullfile(testCase.RepoRoot, "requirements.txt"), expectedText)

            matbox.repo.migrateToMatBoxRepo(testCase.RepoRoot, ...
                "SourceFolder", "widget_table", ...
                "Namespace", "widgettable", ...
                "ToolboxName", "WidgetTable", ...
                "TemplateRepo", testCase.TemplateRepo, ...
                "DryRun", false);

            actualText = string(fileread(fullfile(testCase.RepoRoot, "requirements.txt")));
            testCase.verifyEqual(strtrim(actualText), expectedText)
        end

        function testGitRepositoryUsesGitMove(testCase)
            initializeGitRepository(testCase.RepoRoot)

            matbox.repo.migrateToMatBoxRepo(testCase.RepoRoot, ...
                "SourceFolder", "widget_table", ...
                "Namespace", "widgettable", ...
                "ToolboxName", "WidgetTable", ...
                "TemplateRepo", testCase.TemplateRepo, ...
                "DryRun", false);

            [~, statusText] = system(sprintf('git -C "%s" status --short', testCase.RepoRoot));
            testCase.verifyTrue(contains(string(statusText), ...
                "widget_table/WidgetTable.m -> src/widget_table/WidgetTable.m"))
        end
    end
end

function createWidgetTableLikeRepo(repoRoot)
    mkdir(fullfile(repoRoot, "widget_table"))
    writeTextFile(fullfile(repoRoot, "README.md"), "# WidgetTable" + newline)
    writeTextFile(fullfile(repoRoot, "widget_table", "WidgetTable.m"), ...
        "classdef WidgetTable" + newline + ...
        "end" + newline)
end

function createMinimalTemplateRepo(templateRepo)
    workflowFolder = fullfile(templateRepo, ".github", "workflows");
    mkdir(workflowFolder)
    writeTextFile(fullfile(workflowFolder, "test-code.yml"), "name: Test code" + newline)
    writeTextFile(fullfile(workflowFolder, "run-codespell.yml"), "name: Run Codespell" + newline)
    writeTextFile(fullfile(workflowFolder, "prepare-release.yml"), "name: Prepare toolbox release" + newline)

    templateRoot = fullfile(templateRepo, "cookiecutter_templates", "main_template", "{{cookiecutter.repo_name}}");
    mkdir(fullfile(templateRoot, "tools", "+{{cookiecutter.namespace_name}}tools"))
    writeTextFile(fullfile(templateRoot, "tools", "+{{cookiecutter.namespace_name}}tools", "projectdir.m"), ...
        "function folderPath = projectdir()" + newline + ...
        "folderPath = fileparts(fileparts(fileparts(mfilename('fullpath'))));" + newline + ...
        "end" + newline)
    writeTextFile(fullfile(templateRoot, "tools", "+{{cookiecutter.namespace_name}}tools", "installMatBox.m"), ...
        "function installMatBox()" + newline + ...
        "addpath(genpath(fullfile(projectdir(), 'src')))" + newline + ...
        "end" + newline)
    writeTextFile(fullfile(templateRoot, "requirements.txt"), "# Requirements" + newline)
    writeTextFile(fullfile(templateRoot, ".gitignore"), ...
        "# Ignore releases" + newline + ...
        "releases/" + newline + ...
        newline + ...
        "# Packaged toolboxes" + newline + ...
        "*.mltbx" + newline)
end

function initializeGitRepository(repoRoot)
    runCommand(sprintf('git -C "%s" init', repoRoot))
    runCommand(sprintf('git -C "%s" config user.email "test@example.com"', repoRoot))
    runCommand(sprintf('git -C "%s" config user.name "Test User"', repoRoot))
    runCommand(sprintf('git -C "%s" add README.md widget_table/WidgetTable.m', repoRoot))
    runCommand(sprintf('git -C "%s" commit -m "Initial commit"', repoRoot))
end

function runCommand(command)
    [status, output] = system(command);
    if status ~= 0
        error("RepoMigrationTest:SystemCommandFailed", ...
            "Command failed: %s\n%s", command, output)
    end
end

function writeTextFile(filePath, text)
    fid = fopen(filePath, "w");
    cleanupObj = onCleanup(@() fclose(fid));
    fwrite(fid, char(text));
end
