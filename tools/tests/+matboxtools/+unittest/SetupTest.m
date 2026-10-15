classdef SetupTest <  matlab.unittest.TestCase
% BasicTest - Unit test for testing the openMINDS tutorials.

    properties (Constant)
        % A FileExchange package that is distributed as an .mltbx file
        FexMltbxUri = "fex://160058-recursively-list-files-and-folders"
    end

    methods (TestClassSetup)
        function setupClass(testCase) %#ok<*MANU>
            % pass
        end
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)
        end
    end

    methods (Test)
        function testInstallRequirements(testCase)
            testCase.installRequirements()
            rmpath(genpath(fullfile(pwd, 'StructEditor-main')))
        end

        function testUpdateGitRequirement(testCase)
            testCase.installRequirements()

            testCase.installRequirements("Update", true)
            rmpath(genpath(fullfile(pwd, 'StructEditor-main')))
        end

        function testUpdateGitRequirementWithGit(testCase)

            system('git clone "https://github.com/ehennestad/StructEditor"')
            addpath("StructEditor")

            testCase.installRequirements("Update", true)
            rmpath(genpath(fullfile(pwd, "StructEditor")))
        end

        function testExplicitAgreeToLicenseFalseWarns(testCase)
            testCase.assumeFalse(isMATLABReleaseOlderThan("R2026b"), ...
                "MATLAB ignores a declined add-on license only from R2026b.")
            testCase.uninstallFexAddon(testCase.FexMltbxUri)

            testCase.verifyWarning( ...
                @() matbox.setup.installFromSourceUri(testCase.FexMltbxUri, ...
                    "InstallationLocation", pwd, "AgreeToLicense", false), ...
                "MatBox:Setup:AgreeToLicenseIgnored")
        end

        function testOmittedAgreeToLicenseDoesNotWarn(testCase)
            testCase.assumeFalse(isMATLABReleaseOlderThan("R2026b"), ...
                "MATLAB ignores a declined add-on license only from R2026b.")
            testCase.uninstallFexAddon(testCase.FexMltbxUri)

            % No warning follows the license warning in the install path,
            % so the last warning shows whether it was issued.
            lastwarn("", "")
            matbox.setup.installFromSourceUri(testCase.FexMltbxUri, "InstallationLocation", pwd)
            [~, lastWarningId] = lastwarn();
            testCase.verifyNotEqual(lastWarningId, 'MatBox:Setup:AgreeToLicenseIgnored')
        end
    end

    methods
        function uninstallFexAddon(~, sourceUri)
            % installFexPackage skips an add-on that is already installed, so
            % remove every installed version to make the next call install it.
            addonIdentifier = matbox.setup.internal.fex.parseFileExchangeURI(sourceUri);
            addons = matlab.addons.installedAddons();
            addonVersions = addons.Version(addons.Identifier == addonIdentifier);
            for addonVersion = reshape(addonVersions, 1, [])
                matlab.addons.uninstall(addonIdentifier, addonVersion)
            end
        end

        function installRequirements(testCase, options)

            arguments
                testCase
                options.Update (1,1) logical = false
            end

            pathStr = matboxtools.projectdir();
            requirementsPath = fullfile(pathStr, "tools", "tests", "test_resources");

            try
                if options.Update
                    matbox.installRequirements(requirementsPath, "u", "InstallationLocation", pwd)
                else
                    matbox.installRequirements(requirementsPath, "InstallationLocation", pwd)
                end
            catch ME
                testCase.verifyFail(ME.message)
            end
        end
    end
end
