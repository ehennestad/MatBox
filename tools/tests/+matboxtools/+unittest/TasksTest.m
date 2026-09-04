classdef TasksTest <  matlab.unittest.TestCase
% BasicTest - Unit test for testing the openMINDS tutorials.

    methods (TestClassSetup)
        function setupClass(testCase) %#ok<*MANU>
            % pass
        end
    end

    methods (TestClassTeardown)
        function tearDownClass(testCase)
            % Pass. No class teardown routines needed
        end
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            % Pass. No method setup routines needed
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testCodecheckToolbox(testCase)
            pathStr = matboxtools.projectdir();

            copyfile(pathStr, pwd);

            matbox.tasks.codecheckToolbox(pwd, ...
                "CreateBadge", false, "SaveReport", false);

            % Todo: Add test for saving badge and report

            testCase.verifyTrue(isfolder(fullfile(pwd, "docs", "reports")))
        end

        function testCodecheckToolboxCreatesBadgeJson(testCase)
            pathStr = matboxtools.projectdir();
            copyfile(pathStr, pwd);

            % The matbox-actions workflows set this environment variable to
            % request badge JSON instead of legacy in-MATLAB SVG rendering.
            previousValue = getenv("MATBOX_BADGE_FORMAT");
            setenv("MATBOX_BADGE_FORMAT", "json")
            testCase.addTeardown(@() setenv("MATBOX_BADGE_FORMAT", previousValue))

            matbox.tasks.codecheckToolbox(pwd, ...
                "CreateBadge", true, "SaveReport", false);

            badgeFile = fullfile(pwd, "docs", "reports", "badges", "code_issues.json");
            testCase.verifyTrue(isfile(badgeFile), ...
                "Expected badge JSON file was not created.")

            badgeInfo = jsondecode(fileread(badgeFile));
            testCase.verifyEqual(badgeInfo.label, 'code issues')
            testCase.verifyTrue(ismember(string(badgeInfo.color), ...
                ["green", "yellow", "red"]))
        end

        function testPackageToolbox(testCase)
            pathStr = matboxtools.projectdir();
            copyfile(pathStr, pwd);
            if isfolder(fullfile(pwd, 'releases'))
                rmdir(fullfile(pwd, 'releases'), 's')
                mkdir(fullfile(pwd, 'releases'))
            end
            [~, toolboxFile] = matbox.tasks.packageToolbox( ...
                pwd, "build", "", "SourceFolderName", "code");
            testCase.verifyTrue(isfolder(fullfile(pwd, "releases")))

            archiveFolder = fullfile(pwd, "toolbox-archive");
            unzip(toolboxFile, archiveFolder)
            packagedLicenseFile = fullfile(archiveFolder, "fsroot", "LICENSE");
            testCase.verifyTrue(isfile(packagedLicenseFile))
            testCase.verifyEqual(fileread(packagedLicenseFile), ...
                fileread(fullfile(pwd, "LICENSE")))

            % Staged copy is removed from the source folder after packaging
            testCase.verifyFalse(isfile(fullfile(pwd, "code", "LICENSE")))
        end

        function testPackageToolboxWithRootFilesToPackage(testCase)
            pathStr = matboxtools.projectdir();
            copyfile(pathStr, pwd);

            % Add a notices file and declare an explicit list of root files
            % to package, including one file that does not exist.
            matbox.utility.filewrite(fullfile(pwd, 'NOTICE.md'), 'Third party notices');

            toolboxInfoFile = fullfile(pwd, 'tools', 'MLToolboxInfo.json');
            toolboxInfo = jsondecode(fileread(toolboxInfoFile));
            toolboxInfo.RootFilesToPackage = {'LICENSE'; 'NOTICE.md'; 'MISSING.md'};
            matbox.utility.filewrite(toolboxInfoFile, ...
                jsonencode(toolboxInfo, "PrettyPrint", true));

            [~, toolboxFile] = testCase.verifyWarning(...
                @() matbox.tasks.packageToolbox(pwd, "build", "", "SourceFolderName", "code"), ...
                "MatBox:Package:RootFileNotFound");

            archiveFolder = fullfile(pwd, "toolbox-archive");
            unzip(toolboxFile, archiveFolder)
            testCase.verifyTrue(isfile(fullfile(archiveFolder, "fsroot", "LICENSE")))
            testCase.verifyTrue(isfile(fullfile(archiveFolder, "fsroot", "NOTICE.md")))
        end

        function testPackageToolboxShadowedRootFile(testCase)
            pathStr = matboxtools.projectdir();
            copyfile(pathStr, pwd);

            % A file with the same name in the source folder shadows the
            % project root file and must not be overwritten or deleted.
            shadowText = 'Shadowing license file';
            matbox.utility.filewrite(fullfile(pwd, 'code', 'LICENSE'), shadowText);

            [~, toolboxFile] = testCase.verifyWarning(...
                @() matbox.tasks.packageToolbox(pwd, "build", "", "SourceFolderName", "code"), ...
                "MatBox:Package:RootFileShadowed");

            archiveFolder = fullfile(pwd, "toolbox-archive");
            unzip(toolboxFile, archiveFolder)
            packagedLicenseFile = fullfile(archiveFolder, "fsroot", "LICENSE");
            testCase.verifyEqual(fileread(packagedLicenseFile), shadowText)
            testCase.verifyTrue(isfile(fullfile(pwd, 'code', 'LICENSE')))
        end

        function testTestedWithBadgeCountsReleaseWithSkippedTests(testCase)
            % Tests filtered by an unmet assumption are reported as skipped
            % rather than failed, so the release is still tested with.
            writeTestResultsReport(pwd, "R2024a", "Skipped", 4);
            writeTestResultsReport(pwd, "R2024b");

            matbox.tasks.createTestedWithBadgeforToolbox("v1.2.3", pwd);

            badgeInfo = readTestedWithBadge(testCase, pwd, "v1.2.3");
            testCase.verifyEqual(string(badgeInfo.message), "R2024a | R2024b")
            testCase.verifyEqual(string(badgeInfo.color), "green")
        end

        function testTestedWithBadgeExcludesFailingRelease(testCase)
            % Errors and failures still disqualify a release, and the badge
            % turns orange once a single release is left out.
            writeTestResultsReport(pwd, "R2024a", "Failures", 1);
            writeTestResultsReport(pwd, "R2024b", "Skipped", 2);

            matbox.tasks.createTestedWithBadgeforToolbox("v1.2.3", pwd);

            badgeInfo = readTestedWithBadge(testCase, pwd, "v1.2.3");
            testCase.verifyEqual(string(badgeInfo.message), "R2024b")
            testCase.verifyEqual(string(badgeInfo.color), "orange")
        end

        function testTestedWithBadgeErrorsWhenNoReleasePassed(testCase)
            % Writing no badge at all would surface much later as a missing
            % file, so the task has to report the problem itself.
            writeTestResultsReport(pwd, "R2024a", "Errors", 1);
            writeTestResultsReport(pwd, "R2024b", "Failures", 1);

            testCase.verifyError( ...
                @() matbox.tasks.createTestedWithBadgeforToolbox("v1.2.3", pwd), ...
                "MATBOX:BadgeCreation:NoReleasePassed")
        end
    end
end

function writeTestResultsReport(projectRootDirectory, releaseName, options)
% writeTestResultsReport - Write a minimal JUnit-style report for one release
%
%   The report holds a single test suite whose error, failure and skip counts
%   are given by the optional arguments. It mirrors the layout that the release
%   workflow produces by downloading one report artifact per MATLAB release.

    arguments
        projectRootDirectory (1,1) string
        releaseName (1,1) string
        options.Errors (1,1) double = 0
        options.Failures (1,1) double = 0
        options.Skipped (1,1) double = 0
    end

    reportFolder = fullfile(projectRootDirectory, "docs", "reports", "reports-" + releaseName);
    if ~isfolder(reportFolder)
        mkdir(reportFolder)
    end

    reportXml = sprintf([...
        '<?xml version="1.0" encoding="UTF-8" standalone="no" ?>\n' ...
        '<testsuites>\n' ...
        '  <testsuite errors="%d" failures="%d" name="ExampleTest" skipped="%d" tests="%d" time="1.0"/>\n' ...
        '</testsuites>\n'], ...
        options.Errors, options.Failures, options.Skipped, ...
        options.Errors + options.Failures + options.Skipped + 1);

    matbox.utility.filewrite(fullfile(reportFolder, "test-results.xml"), reportXml);
end

function badgeInfo = readTestedWithBadge(testCase, projectRootDirectory, versionNumber)
% readTestedWithBadge - Read back the badge written for a given version

    badgeFile = fullfile(projectRootDirectory, ".github", "badges", versionNumber, "tested_with.json");
    testCase.assertTrue(isfile(badgeFile), ...
        "Expected 'tested with' badge file was not created.")
    badgeInfo = jsondecode(fileread(badgeFile));
end
