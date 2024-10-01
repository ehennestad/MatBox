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
            pathStr = matbox.toolboxdir();

            copyfile(pathStr, pwd);
            matbox.tasks.codecheckToolbox(pwd)

            testCase.verifyTrue(isfolder(fullfile(pwd, "docs", "reports")))
        end

        function testTestToolbox(testCase)
            pathStr = matboxtools.projectdir();
            copyfile(pathStr, pwd);

            rmdir(fullfile(pwd, 'releases'), 's')

            matbox.tasks.packageToolbox(pwd, "build", "")
            testCase.verifyTrue(isfolder(fullfile(pwd, "releases")))

            
        end
    end
end
