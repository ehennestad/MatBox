classdef GithubReferenceTest < matlab.unittest.TestCase
% GithubReferenceTest - Tests for GitHub requirements pinned to a git reference
%
%   A GitHub requirement may pin a branch name, tag name, or commit SHA
%   using the "<url>@<ref>" form. These tests cover parsing the reference,
%   naming the installation folder, locating an installed copy on the
%   search path, and installing from GitHub. The install tests require
%   network access.

    properties (Constant)
        RepositoryUrl = "https://github.com/ehennestad/StructEditor"
        RepositoryName = "StructEditor"
        % A published tag and its commit in the test repository. As observed
        % on github.com, the archive folders are named "StructEditor-0.1.0"
        % (leading "v" dropped) and "StructEditor-<full sha>", so both
        % exercise the rename to "<repo>-<ref>" done by installGithubRepository.
        TagName = "v0.1.0"
        CommitSha = "4e8eaa6"
        % A branch name in the hierarchical form and the folder name it
        % maps to. Used only by tests that need no network access, so the
        % branch need not exist in the test repository.
        HierarchicalBranchName = "release/1.0"
        HierarchicalBranchFolderName = "StructEditor-release-1.0"
        % A branch in the test repository whose name contains "/". As
        % observed on github.com, its archive folder is named
        % "StructEditor-codex-nansen-compatibility-contract".
        ExistingHierarchicalBranchName = "codex/nansen-compatibility-contract"
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            import matlab.unittest.fixtures.WorkingFolderFixture
            testCase.applyFixture(WorkingFolderFixture)
            % Installing adds folders to the search path; restore it after.
            testCase.addTeardown(@restoreSearchPath, path)
        end
    end

    methods (Test)
        function testParseUrlWithoutReference(testCase)
            [owner, repositoryName, gitRef] = ...
                matbox.setup.internal.github.parseRepositoryURL(testCase.RepositoryUrl);
            testCase.verifyEqual(owner, "ehennestad")
            testCase.verifyEqual(repositoryName, testCase.RepositoryName)
            testCase.verifyTrue(ismissing(gitRef))
        end

        function testParseUrlWithTagReference(testCase)
            [~, repositoryName, gitRef] = matbox.setup.internal.github.parseRepositoryURL( ...
                testCase.RepositoryUrl + "@" + testCase.TagName);
            testCase.verifyEqual(repositoryName, testCase.RepositoryName)
            testCase.verifyEqual(gitRef, testCase.TagName)
        end

        function testParseUrlWithCommitReference(testCase)
            [~, repositoryName, gitRef] = matbox.setup.internal.github.parseRepositoryURL( ...
                testCase.RepositoryUrl + "@" + testCase.CommitSha);
            testCase.verifyEqual(repositoryName, testCase.RepositoryName)
            testCase.verifyEqual(gitRef, testCase.CommitSha)
        end

        function testRepositoryFolderNameReplacesSlashes(testCase)
            folderName = matbox.setup.internal.github.repositoryFolderName( ...
                testCase.RepositoryName, testCase.HierarchicalBranchName);
            testCase.verifyEqual(folderName, testCase.HierarchicalBranchFolderName)
        end

        function testLookForRepositoryFindsHierarchicalBranchFolder(testCase)
            folderPath = testCase.createRepositoryFolder(testCase.HierarchicalBranchFolderName);
            [exists, repositoryPath] = matbox.setup.internal.pathtool.lookForRepository( ...
                testCase.RepositoryName, testCase.HierarchicalBranchName);
            testCase.verifyTrue(exists)
            testCase.verifyEqual(repositoryPath, folderPath)
        end
        
        function testParseUrlWithSlashInReference(testCase)
            [~, repositoryName, gitRef] = matbox.setup.internal.github.parseRepositoryURL( ...
                testCase.RepositoryUrl + "@" + testCase.HierarchicalBranchName);
            testCase.verifyEqual(repositoryName, testCase.RepositoryName)
            testCase.verifyEqual(gitRef, testCase.HierarchicalBranchName)
        end

        function testParseUrlWithTrailingSlashAfterReference(testCase)
            [~, ~, gitRef] = matbox.setup.internal.github.parseRepositoryURL( ...
                testCase.RepositoryUrl + "@" + testCase.HierarchicalBranchName + "/");
            testCase.verifyEqual(gitRef, testCase.HierarchicalBranchName)
        end

        function testParseUrlWithAtSignInReference(testCase)
            % Only the first "@" separates the repository name from the
            % reference; git allows "@" inside a reference name.
            [~, repositoryName, gitRef] = matbox.setup.internal.github.parseRepositoryURL( ...
                testCase.RepositoryUrl + "@fix@2");
            testCase.verifyEqual(repositoryName, testCase.RepositoryName)
            testCase.verifyEqual(gitRef, "fix@2")
        end

        function testParseUrlWithPathAfterRepositoryNameErrors(testCase)
            testCase.verifyError(@() matbox.setup.internal.github.parseRepositoryURL( ...
                testCase.RepositoryUrl + "/tree/main"), "MATBOX:GitHub:InvalidRepositoryURL")
        end

        function testInstallWithPathAfterRepositoryNameErrors(testCase)
            % The URI is parsed before any request to GitHub, so this test
            % needs no network access.
            testCase.verifyError(@() matbox.setup.installFromSourceUri( ...
                testCase.RepositoryUrl + "/tree/main", "InstallationLocation", pwd), ...
                "MATBOX:GitHub:InvalidRepositoryURL")
        end

        function testLookForRepositoryFindsTagFolder(testCase)
            folderPath = testCase.createRepositoryFolder( ...
                testCase.RepositoryName + "-" + testCase.TagName);
            [exists, repositoryPath] = matbox.setup.internal.pathtool.lookForRepository( ...
                testCase.RepositoryName, testCase.TagName);
            testCase.verifyTrue(exists)
            testCase.verifyEqual(repositoryPath, folderPath)
        end

        function testLookForRepositoryMatchesDotsLiterally(testCase)
            % The dots in "v0.1.0" must match literally. An unescaped "."
            % matches any character, so a decoy folder named "-v0x1x0"
            % would wrongly be found.
            testCase.createRepositoryFolder(testCase.RepositoryName + "-v0x1x0");
            exists = matbox.setup.internal.pathtool.lookForRepository( ...
                testCase.RepositoryName, testCase.TagName);
            testCase.verifyFalse(exists)
        end

        function testInstallTagPinnedRequirement(testCase)
            testCase.verifyInstallAndReinstall(testCase.TagName)
        end

        function testInstallCommitPinnedRequirement(testCase)
            testCase.verifyInstallAndReinstall(testCase.CommitSha)
        end

        function testInstallHierarchicalBranchPinnedRequirement(testCase)
            testCase.verifyInstallAndReinstall(testCase.ExistingHierarchicalBranchName)
        end
    end

    methods (Access = private)
        function folderPath = createRepositoryFolder(~, folderName)
            % Create a folder that lookForRepository accepts as a repository
            % (it must hold a README and a LICENSE) and put it on the path.
            folderPath = string(fullfile(pwd, folderName));
            mkdir(folderPath)
            writelines("", fullfile(folderPath, "README.md"))
            writelines("", fullfile(folderPath, "LICENSE"))
            addpath(folderPath)
        end

        function verifyInstallAndReinstall(testCase, gitRef)
            sourceUri = testCase.RepositoryUrl + "@" + gitRef;
            % The installation folder sits directly in the installation
            % location, with each "/" of the reference replaced by "-".
            expectedFolder = string(fullfile(pwd, ...
                testCase.RepositoryName + "-" + replace(gitRef, "/", "-")));

            installResult = matbox.setup.installFromSourceUri(sourceUri, ...
                "InstallationLocation", pwd, "Verbose", false);

            testCase.verifyEqual(string(installResult.FilePath), expectedFolder)
            testCase.verifyTrue(isfolder(expectedFolder))
            testCase.verifyTrue(isfile(fullfile(expectedFolder, ".commit_hash")))

            % A second install must recognise the existing folder and skip
            % downloading, which it reports in its verbose output.
            output = evalc( ...
                "matbox.setup.installFromSourceUri(sourceUri, InstallationLocation=pwd)");
            testCase.verifySubstring(output, "already exists, skipping")
        end
    end
end

function restoreSearchPath(originalPath)
    path(originalPath);
end
