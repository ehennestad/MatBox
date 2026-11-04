classdef PrepareReadmeTest < matlab.unittest.TestCase
% PrepareReadmeTest - Tests for preparing a README for the packaged toolbox

    properties (Constant)
        RepositoryURL = "https://github.com/owner/repo"
        Ref = "v1.2.3"
        BlobURL = "https://github.com/owner/repo/blob/v1.2.3/"
        TreeURL = "https://github.com/owner/repo/tree/v1.2.3/"
        RawURL = "https://raw.githubusercontent.com/owner/repo/v1.2.3/"
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end

    methods (Test)
        function testBadgeLinesInLeadingBlockAreRemoved(testCase)
            text = joinLines([ ...
                "<p align=""right""><img src=""https://example.com/logo.png""></p>"
                ""
                "# Toolbox"
                ""
                "[![tests](.github/badges/tests.svg)](https://example.com/actions)"
                "![version](https://img.shields.io/badge/v-1-blue) ![b](https://example.com/b.svg)"
                ""
                ""
                "Intro text."]);

            expected = joinLines([ ...
                "<p align=""right""><img src=""https://example.com/logo.png""></p>"
                ""
                "# Toolbox"
                ""
                "Intro text."]);
            testCase.verifyEqual(testCase.prepare(text), expected)
        end

        function testImageLinesAfterProseAreKept(testCase)
            text = joinLines(["# Toolbox", "Intro text.", "", "![Plot](docs/plot.png)"]);

            expected = joinLines(["# Toolbox", "Intro text.", "", ...
                "![Plot](" + testCase.RawURL + "docs/plot.png)"]);
            testCase.verifyEqual(testCase.prepare(text), expected)
        end

        function testLineWithTextAndImageEndsLeadingBlock(testCase)
            text = joinLines(["# Toolbox", "![icon](https://example.com/i.svg) Intro text.", ...
                "[![b](https://example.com/b.svg)](https://example.com)"]);

            testCase.verifyEqual(testCase.prepare(text), text)
        end

        function testHtmlImageLinesAreKept(testCase)
            text = joinLines([ ...
                "<a href=""/img/logo.png"">"
                "  <picture>"
                "    <source srcset=""/img/dark.png 1x, ./img/dark@2x.png 2x"">"
                "    <img src='img/logo.png' height=""70"">"
                "  </picture>"
                "</a>"
                "# Toolbox"]);

            expected = joinLines([ ...
                "<a href=""" + testCase.BlobURL + "img/logo.png"">"
                "  <picture>"
                "    <source srcset=""" + testCase.RawURL + "img/dark.png 1x, " + testCase.RawURL + "img/dark@2x.png 2x"">"
                "    <img src='" + testCase.RawURL + "img/logo.png' height=""70"">"
                "  </picture>"
                "</a>"
                "# Toolbox"]);
            testCase.verifyEqual(testCase.prepare(text), expected)
        end

        function testLinksToFileFolderAndImage(testCase)
            mkdir(fullfile(pwd, "docs"))
            text = "Text [file](LICENSE), [folder](docs), [slash](src/) and ![image](img/a.png).";

            expected = "Text [file](" + testCase.BlobURL + "LICENSE), " ...
                + "[folder](" + testCase.TreeURL + "docs), " ...
                + "[slash](" + testCase.TreeURL + "src) and " ...
                + "![image](" + testCase.RawURL + "img/a.png).";
            testCase.verifyEqual(testCase.prepare(text, pwd), expected)
        end

        function testLinkedImageGetsRawImageAndBlobLink(testCase)
            text = "Text [![logo](img/a.png)](img/a.png).";

            expected = "Text [![logo](" + testCase.RawURL + "img/a.png)](" ...
                + testCase.BlobURL + "img/a.png).";
            testCase.verifyEqual(testCase.prepare(text), expected)
        end

        function testFragmentQueryAndDotSlashAreHandled(testCase)
            text = "See [install](./docs/guide.md#install) and [raw](/img/a.png?raw=true).";

            expected = "See [install](" + testCase.BlobURL + "docs/guide.md#install) and " ...
                + "[raw](" + testCase.BlobURL + "img/a.png?raw=true).";
            testCase.verifyEqual(testCase.prepare(text), expected)
        end

        function testAngleBracketDestinationIsRewritten(testCase)
            text = "See [guide](<docs/my guide.md>).";

            expected = "See [guide](<" + testCase.BlobURL + "docs/my guide.md>).";
            testCase.verifyEqual(testCase.prepare(text), expected)
        end

        function testAbsoluteAndLocalDestinationsAreUnchanged(testCase)
            text = joinLines([ ...
                "[web](https://example.com/a.md) [mail](mailto:a@example.com)"
                "[anchor](#usage) [cdn](//cdn.example.com/a.js) [parent](../other/a.md)"
                "<a href=""https://example.com"">x</a> <a href="""">empty</a>"]);

            testCase.verifyEqual(testCase.prepare(text), text)
        end

        function testFencedCodeIsUnchanged(testCase)
            text = joinLines([ ...
                "```markdown"
                "[![b](b.svg)](c)"
                ""
                ""
                "[file](LICENSE)"
                "```"
                "~~~~"
                "```"
                "[file](LICENSE)"
                "~~~~"
                "[file](LICENSE)"]);

            lines = splitlines(text);
            expected = joinLines([lines(1:end-1); "[file](" + testCase.BlobURL + "LICENSE)"]);
            testCase.verifyEqual(testCase.prepare(text), expected)
        end

        function testReferenceDefinitionsAreRewritten(testCase)
            text = joinLines(["Read the [guide] and see ![logo].", "", ...
                "[guide]: docs/guide.md ""Guide""", "  [logo]: <img/logo.svg>"]);

            expected = joinLines(["Read the [guide] and see ![logo].", "", ...
                "[guide]: " + testCase.BlobURL + "docs/guide.md ""Guide""", ...
                "  [logo]: <" + testCase.RawURL + "img/logo.svg>"]);
            testCase.verifyEqual(testCase.prepare(text), expected)
        end

        function testRepositoryOutsideGithubUsesRawPath(testCase)
            text = "Text ![image](img/a.png) and [file](LICENSE).";

            actual = matbox.toolbox.internal.prepareReadme(text, ...
                "RepositoryURL", "https://gitlab.com/owner/repo", "Ref", testCase.Ref);
            testCase.verifyEqual(actual, "Text ![image](https://gitlab.com/owner/repo/raw/v1.2.3/img/a.png) " ...
                + "and [file](https://gitlab.com/owner/repo/blob/v1.2.3/LICENSE).")
        end

        function testWithoutRepositoryUrlOnlyBadgesAreRemoved(testCase)
            text = joinLines(["# Toolbox", "[![b](b.svg)](c)", "", "See [file](LICENSE)."]);

            actual = matbox.toolbox.internal.prepareReadme(text);
            testCase.verifyEqual(actual, joinLines(["# Toolbox", "", "See [file](LICENSE)."]))
        end

        function testFinalNewlineIsKept(testCase)
            testCase.verifyEqual(testCase.prepare("Text." + newline), "Text." + newline)
            testCase.verifyEqual(testCase.prepare("Text."), "Text.")
        end

        function testRepositoryUrlFromGithubActions(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.EnvironmentVariableFixture( ...
                "GITHUB_SERVER_URL", "https://github.com"));
            testCase.applyFixture(matlab.unittest.fixtures.EnvironmentVariableFixture( ...
                "GITHUB_REPOSITORY", "owner/repo"));

            testCase.verifyEqual(matbox.toolbox.internal.getRepositoryUrl(pwd), ...
                "https://github.com/owner/repo")
        end

        function testRepositoryUrlFromOriginRemote(testCase)
            testCase.clearGithubActionsEnvironment()
            testCase.initializeGitRepository()

            remoteUrls = [ ...
                "git@github.com:owner/repo.git"
                "ssh://git@example.com:2222/owner/repo.git"
                "https://user:token@github.com/owner/repo.git"
                "https://github.com/owner/repo/"];
            expectedUrls = [ ...
                "https://github.com/owner/repo"
                "https://example.com/owner/repo"
                "https://github.com/owner/repo"
                "https://github.com/owner/repo"];
            for iUrl = 1:numel(remoteUrls)
                testCase.setOriginRemote(remoteUrls(iUrl))
                testCase.verifyEqual(matbox.toolbox.internal.getRepositoryUrl(pwd), ...
                    expectedUrls(iUrl), "Remote URL: " + remoteUrls(iUrl))
            end
        end

        function testRepositoryUrlIsEmptyWithoutOrigin(testCase)
            testCase.clearGithubActionsEnvironment()
            testCase.initializeGitRepository()

            testCase.verifyEqual(matbox.toolbox.internal.getRepositoryUrl(pwd), "")
        end
    end

    methods (Access = private)
        function text = prepare(testCase, text, projectRoot)
            arguments
                testCase
                text (1,1) string
                projectRoot (1,1) string = ""
            end
            text = matbox.toolbox.internal.prepareReadme(text, ...
                "RepositoryURL", testCase.RepositoryURL, ...
                "Ref", testCase.Ref, ...
                "ProjectRoot", projectRoot);
        end

        function clearGithubActionsEnvironment(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.EnvironmentVariableFixture( ...
                "GITHUB_SERVER_URL", ""));
            testCase.applyFixture(matlab.unittest.fixtures.EnvironmentVariableFixture( ...
                "GITHUB_REPOSITORY", ""));
        end

        function initializeGitRepository(testCase)
            [status, output] = system(sprintf('git -C "%s" init', pwd));
            testCase.assertEqual(status, 0, output)
        end

        function setOriginRemote(testCase, remoteUrl)
            [~, ~] = system(sprintf('git -C "%s" remote remove origin', pwd)); % Fails when there is no origin yet
            [status, output] = system(sprintf('git -C "%s" remote add origin %s', pwd, remoteUrl));
            testCase.assertEqual(status, 0, output)
        end
    end
end

function text = joinLines(lines)
    text = join(lines(:), newline);
end
