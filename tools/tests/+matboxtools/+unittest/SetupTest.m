classdef SetupTest <  matlab.unittest.TestCase
% BasicTest - Unit test for testing the openMINDS tutorials.

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
    end

    methods
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
