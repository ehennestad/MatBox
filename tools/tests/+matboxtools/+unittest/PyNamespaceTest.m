classdef PyNamespaceTest < matlab.unittest.TestCase
%PyNamespaceTest Unit tests for the matbox.py namespace utilities.

    methods (TestMethodSetup)  % Setup for each test
        function setupMethod(testCase) %#ok<MANU>
        end
    end

    methods (Test)

        function testPipInstallUnknownPackage(testCase)
            testCase.assertError(@(name) matbox.py.pipInstall('pybaldges'), ...
                'MatBox:UnableToInstallPythonPackage')
        end

    end
end
