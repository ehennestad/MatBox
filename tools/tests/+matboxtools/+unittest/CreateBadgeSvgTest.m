classdef CreateBadgeSvgTest < matlab.unittest.TestCase
%CreateBadgeSvgTest Unit tests for matbox.utility.createBadgeSvg.

    properties (Constant)
        OutputFolder = fullfile(tempdir, "matbox_badge_test")
    end

    methods (TestClassSetup)
        function setupClass(testCase) %#ok<MANU>
            if ~isfolder(CreateBadgeSvgTest.OutputFolder)
                mkdir(CreateBadgeSvgTest.OutputFolder)
            end
        end
    end

    methods (TestClassTeardown)
        function tearDownClass(testCase) %#ok<MANU>
            if isfolder(CreateBadgeSvgTest.OutputFolder)
                rmdir(CreateBadgeSvgTest.OutputFolder, 's')
            end
        end
    end

    methods (Test)

        function testBadgeFileIsCreated(testCase)
            matbox.utility.createBadgeSvg("tests", "21 passed", "green", ...
                "OutputFolder", testCase.OutputFolder);
            filePath = fullfile(testCase.OutputFolder, "tests.svg");
            testCase.verifyTrue(isfile(filePath), ...
                "Expected SVG file was not created.")
        end

        function testBadgeFileHasSvgContent(testCase)
            matbox.utility.createBadgeSvg("build", "passing", "blue", ...
                "OutputFolder", testCase.OutputFolder);
            filePath = fullfile(testCase.OutputFolder, "build.svg");
            content = fileread(filePath);
            testCase.verifySubstring(content, "<svg ", ...
                "File does not contain SVG markup.")
            testCase.verifySubstring(content, "build", ...
                "Label text not found in SVG.")
            testCase.verifySubstring(content, "passing", ...
                "Message text not found in SVG.")
        end

        function testAllColorsProduceSvg(testCase)
            colors = ["red", "green", "blue", "orange", "yellow"];
            for k = 1:numel(colors)
                matbox.utility.createBadgeSvg("label", "value", colors(k), ...
                    "OutputFolder", testCase.OutputFolder, ...
                    "FileName", "color_test_" + colors(k));
                filePath = fullfile(testCase.OutputFolder, ...
                    "color_test_" + colors(k) + ".svg");
                testCase.verifyTrue(isfile(filePath), ...
                    "SVG not created for color: " + colors(k))
            end
        end

        function testCustomFileName(testCase)
            matbox.utility.createBadgeSvg("code quality", "A+", "green", ...
                "OutputFolder", testCase.OutputFolder, ...
                "FileName", "quality_badge");
            filePath = fullfile(testCase.OutputFolder, "quality_badge.svg");
            testCase.verifyTrue(isfile(filePath), ...
                "Custom filename was not used.")
        end

        function testLabelSpacesReplacedByUnderscores(testCase)
            matbox.utility.createBadgeSvg("my badge", "ok", "green", ...
                "OutputFolder", testCase.OutputFolder);
            filePath = fullfile(testCase.OutputFolder, "my_badge.svg");
            testCase.verifyTrue(isfile(filePath), ...
                "Spaces in label were not replaced by underscores in filename.")
        end

        function testSvgContainsColorHex(testCase)
            % Color-to-hex mapping mirrors the implementation in createBadgeSvg.
            colorHexMap = containers.Map( ...
                ["red",     "green",   "blue",    "orange",   "yellow"], ...
                ["#e05d44", "#97CA00", "#007ec6", "#fe7d37",  "#dfb317"]);
            colors = keys(colorHexMap);
            for k = 1:numel(colors)
                color = string(colors{k});
                matbox.utility.createBadgeSvg("x", "y", color, ...
                    "OutputFolder", testCase.OutputFolder, ...
                    "FileName", "hex_test_" + color);
                filePath = fullfile(testCase.OutputFolder, ...
                    "hex_test_" + color + ".svg");
                content = fileread(filePath);
                testCase.verifySubstring(content, colorHexMap(char(color)), ...
                    "Color hex not found in SVG for: " + color)
            end
        end

        function testXmlSpecialCharactersAreEscaped(testCase)
            matbox.utility.createBadgeSvg("a & b", "x < y", "red", ...
                "OutputFolder", testCase.OutputFolder, ...
                "FileName", "escape_test");
            content = fileread(fullfile(testCase.OutputFolder, "escape_test.svg"));
            testCase.verifySubstring(content, "&amp;", ...
                "Ampersand was not XML-escaped.")
            testCase.verifySubstring(content, "&lt;", ...
                "Less-than was not XML-escaped.")
        end

        function testMissingOutputPathThrowsError(testCase)
            testCase.verifyError( ...
                @() matbox.utility.createBadgeSvg("x", "y", "red"), ...
                "MatBox:createBadgeSvg:MissingOutputPath")
        end

    end
end
