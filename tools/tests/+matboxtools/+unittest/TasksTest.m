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
    end
end
