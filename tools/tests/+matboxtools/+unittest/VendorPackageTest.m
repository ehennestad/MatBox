classdef VendorPackageTest < matlab.unittest.TestCase
% VendorPackageTest - Tests for copying a package of another repository into a project
%
%   matbox.tasks.vendorPackage downloads a repository and hands the copy
%   to matbox.tasks.internal.vendorPackageFromFolder. Most tests call the
%   latter with a repository that the test creates on disk, and need no
%   network access. testVendorFromGitHub downloads a tagged release of
%   MatBox itself.

    properties (Constant)
        SourceFolder = "src/webprogress/+webprogress"
        SourceNamespace = "webprogress"
        TargetNamespace = "mytoolbox.external.webprogress"
        ExcludedFile = "toolboxdir.m"
        LicenseText = "License of the source repository"
        % A tagged release of MatBox and the commit the tag points to
        GitHubSourceUri = "https://github.com/ehennestad/matbox@v0.11.0"
        GitHubCommitId = "a805e35ea3905d914b41e4001e53a943519eb4d7"
    end

    properties (TestParameter)
        % Text with a reference to SourceNamespace, followed by the text
        % expected after renaming the namespace to TargetNamespace
        referenceCase = struct( ...
            "functionCall", ["x = webprogress.upload(a);", ...
                "x = mytoolbox.external.webprogress.upload(a);"], ...
            "functionHandle", ["f = @(o) webprogress.Monitor(o{:});", ...
                "f = @(o) mytoolbox.external.webprogress.Monitor(o{:});"], ...
            "staticMethod", ["tf = ~webprogress.Monitor.isWebFigure(fig);", ...
                "tf = ~mytoolbox.external.webprogress.Monitor.isWebFigure(fig);"], ...
            "importStatement", ["import webprogress.*", ...
                "import mytoolbox.external.webprogress.*"], ...
            "helpText", ["%   webprogress.upload(FILENAME,URL) uploads", ...
                "%   mytoolbox.external.webprogress.upload(FILENAME,URL) uploads"], ...
            "metaClassQuery", ["?webprogress.Monitor", ...
                "?mytoolbox.external.webprogress.Monitor"])

        % Text in which the name "webprogress" is not a namespace reference
        unchangedText = struct( ...
            "errorIdentifier", "error(""webprogress:upload:Failed"", ""Failed."")", ...
            "longerNamespaceName", "webprogresstools.projectdir()", ...
            "nameWithPrefix", "mywebprogress.upload(a)", ...
            "propertyAccess", "obj.webprogress.upload", ...
            "folderPath", "% see src/webprogress/+webprogress", ...
            "fileName", "% see https://github.com/owner/webprogress.git", ...
            "endOfSentence", "% is in the namespace webprogress. It has", ...
            "alreadyRenamed", "mytoolbox.external.webprogress.upload(a)")

        % A folder path followed by the name of the namespace it defines
        namespaceCase = struct( ...
            "singleFolder", ["src/webprogress/+webprogress", "webprogress"], ...
            "nestedFolders", ["src/tb/+tb/+external/+webprogress", "tb.external.webprogress"], ...
            "backslashSeparators", ["src\tb\+tb\+external", "tb.external"], ...
            "trailingSeparator", ["src/+tb/", "tb"], ...
            "onlyNamespaceFolders", ["+tb/+external", "tb.external"], ...
            "restartedBelowOrdinaryFolder", ["+tb/external/+tb/+external", "tb.external"], ...
            "ordinaryFolder", ["src/webprogress", ""], ...
            "ordinaryFolderInNamespace", ["src/+tb/private", ""])
    end

    methods (TestMethodSetup)
        function setupMethod(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture)
        end
    end

    methods (Test) % renameNamespaceInText
        function testReferenceIsRenamed(testCase, referenceCase)
            renamedText = matbox.tasks.internal.renameNamespaceInText( ...
                referenceCase(1), testCase.SourceNamespace, testCase.TargetNamespace);

            testCase.verifyEqual(renamedText, referenceCase(2))
        end

        function testOtherTextIsUnchanged(testCase, unchangedText)
            renamedText = matbox.tasks.internal.renameNamespaceInText( ...
                unchangedText, testCase.SourceNamespace, testCase.TargetNamespace);

            testCase.verifyEqual(renamedText, unchangedText)
        end

        function testDotsInNamespaceNameMatchLiterally(testCase)
            % An unescaped "." matches any character, so "axb.run" would be
            % taken for a reference to the namespace "a.b".
            renamedText = matbox.tasks.internal.renameNamespaceInText( ...
                "axb.run() + a.b.run()", "a.b", "c.d");

            testCase.verifyEqual(renamedText, "axb.run() + c.d.run()")
        end

        function testClassOfTextIsKept(testCase)
            renamedText = matbox.tasks.internal.renameNamespaceInText( ...
                'webprogress.upload(a)', testCase.SourceNamespace, testCase.TargetNamespace);

            testCase.verifyEqual(renamedText, 'mytoolbox.external.webprogress.upload(a)')
        end

        function testInvalidNamespaceNameErrors(testCase)
            testCase.verifyError( ...
                @() matbox.tasks.internal.renameNamespaceInText("x", "web progress", "a"), ...
                "MatBox:VendorPackage:InvalidNamespaceName")
        end
    end

    methods (Test) % getNamespaceName
        function testNamespaceNameOfFolder(testCase, namespaceCase)
            namespaceName = matbox.tasks.internal.getNamespaceName(namespaceCase(1));

            testCase.verifyEqual(namespaceName, namespaceCase(2))
        end
    end

    methods (Test) % vendorPackageFromFolder
        function testFilesAreCopiedAndRenamed(testCase)
            repositoryFolder = testCase.createRepository();
            targetFolder = testCase.getTargetFolder();

            matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder)

            uploadCode = fileread(fullfile(targetFolder, "upload.m"));
            testCase.verifySubstring(uploadCode, ...
                "@(o) mytoolbox.external.webprogress.Monitor(o{:})")
            testCase.verifySubstring(uploadCode, ...
                "%   mytoolbox.external.webprogress.upload(FILENAME,URL) uploads")
            testCase.verifySubstring(uploadCode, """webprogress:upload:Failed""")
            testCase.verifyTrue(isfile(fullfile(targetFolder, "private", "mustBeValidUrl.m")))
        end

        function testExcludedFilesAreNotCopied(testCase)
            repositoryFolder = testCase.createRepository();
            targetFolder = testCase.getTargetFolder();

            matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder, ...
                ExcludeFiles=[testCase.ExcludedFile, "private/mustBeValidUrl.m"])

            testCase.verifyFalse(isfile(fullfile(targetFolder, testCase.ExcludedFile)))
            testCase.verifyFalse(isfile(fullfile(targetFolder, "private", "mustBeValidUrl.m")))
            testCase.verifyTrue(isfile(fullfile(targetFolder, "upload.m")))
        end

        function testExcludedFileMissingFromSourceErrors(testCase)
            repositoryFolder = testCase.createRepository();
            targetFolder = testCase.getTargetFolder();

            testCase.verifyError( ...
                @() matbox.tasks.internal.vendorPackageFromFolder( ...
                    repositoryFolder, testCase.SourceFolder, targetFolder, ...
                    ExcludeFiles="renamedUpstream.m"), ...
                "MatBox:VendorPackage:ExcludedFileNotFound")
            testCase.verifyFalse(isfolder(targetFolder))
        end

        function testLicenseFileIsCopied(testCase)
            repositoryFolder = testCase.createRepository();
            targetFolder = testCase.getTargetFolder();

            matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder)

            testCase.verifyEqual( ...
                string(fileread(fullfile(targetFolder, "LICENSE"))), testCase.LicenseText)
        end

        function testLicenseFileInSubfolderIsCopiedByName(testCase)
            repositoryFolder = testCase.createRepository();
            writeText(fullfile(repositoryFolder, "licenses", "MIT.txt"), "MIT license text")
            targetFolder = testCase.getTargetFolder();

            matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder, ...
                LicenseFile="licenses/MIT.txt")

            testCase.verifyEqual( ...
                string(fileread(fullfile(targetFolder, "MIT.txt"))), "MIT license text")
        end

        function testVendorInfoIsWritten(testCase)
            repositoryFolder = testCase.createRepository();
            targetFolder = testCase.getTargetFolder();

            returnedInfo = matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder, ...
                ExcludeFiles=testCase.ExcludedFile, ...
                RepositoryUrl="https://github.com/owner/webprogress", ...
                Reference="main", ...
                CommitID="0123abc");

            expectedInfo = struct( ...
                "Source", 'https://github.com/owner/webprogress', ...
                "Reference", 'main', ...
                "CommitID", '0123abc', ...
                "SourceFolder", char(testCase.SourceFolder), ...
                "SourceNamespace", char(testCase.SourceNamespace), ...
                "TargetNamespace", char(testCase.TargetNamespace), ...
                "ExcludedFiles", {{char(testCase.ExcludedFile)}});
            savedInfo = jsondecode(fileread(fullfile(targetFolder, "vendorinfo.json")));
            testCase.verifyEqual(savedInfo, expectedInfo)
            testCase.verifyEqual(returnedInfo.CommitID, "0123abc")
            testCase.verifyEqual(returnedInfo.ExcludedFiles, testCase.ExcludedFile)
        end

        function testSecondCallGivesIdenticalFolder(testCase)
            repositoryFolder = testCase.createRepository();
            targetFolder = testCase.getTargetFolder();

            matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder)
            [firstPaths, firstContents] = readFolder(targetFolder);
            matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder)
            [secondPaths, secondContents] = readFolder(targetFolder);

            testCase.verifyEqual(secondPaths, firstPaths)
            testCase.verifyEqual(secondContents, firstContents)
            testCase.verifyFalse(contains( ...
                fileread(fullfile(targetFolder, "upload.m")), "external.mytoolbox"))
        end

        function testFileRemovedFromSourceIsRemovedFromTarget(testCase)
            repositoryFolder = testCase.createRepository();
            targetFolder = testCase.getTargetFolder();
            matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder)

            delete(fullfile(repositoryFolder, testCase.SourceFolder, "toolboxdir.m"))
            matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder)

            testCase.verifyFalse(isfile(fullfile(targetFolder, "toolboxdir.m")))
            testCase.verifyTrue(isfile(fullfile(targetFolder, "upload.m")))
        end

        function testFolderWithoutVendorInfoIsNotReplaced(testCase)
            repositoryFolder = testCase.createRepository();
            targetFolder = testCase.getTargetFolder();
            ownFile = fullfile(targetFolder, "ownCode.m");
            writeText(ownFile, "x = 1;")

            testCase.verifyError( ...
                @() matbox.tasks.internal.vendorPackageFromFolder( ...
                    repositoryFolder, testCase.SourceFolder, targetFolder), ...
                "MatBox:VendorPackage:TargetFolderNotVendored")
            testCase.verifyTrue(isfile(ownFile))
        end

        function testErrorLeavesExistingCopyUnchanged(testCase)
            repositoryFolder = testCase.createRepository();
            targetFolder = testCase.getTargetFolder();
            matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder)
            [pathsBefore, contentsBefore] = readFolder(targetFolder);

            testCase.verifyError( ...
                @() matbox.tasks.internal.vendorPackageFromFolder( ...
                    repositoryFolder, testCase.SourceFolder, targetFolder, ...
                    ExcludeFiles="renamedUpstream.m"), ...
                "MatBox:VendorPackage:ExcludedFileNotFound")

            [pathsAfter, contentsAfter] = readFolder(targetFolder);
            testCase.verifyEqual(pathsAfter, pathsBefore)
            testCase.verifyEqual(contentsAfter, contentsBefore)
        end

        function testSameNamespaceCopiesFilesUnchanged(testCase)
            repositoryFolder = testCase.createRepository();
            targetFolder = fullfile(pwd, "project", "external", "+webprogress");

            matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder)

            sourceFile = fullfile(repositoryFolder, testCase.SourceFolder, "upload.m");
            testCase.verifyEqual(fileread(fullfile(targetFolder, "upload.m")), ...
                fileread(sourceFile))
        end

        function testOrdinaryTargetFolderErrors(testCase)
            repositoryFolder = testCase.createRepository();
            targetFolder = fullfile(pwd, "project", "external", "webprogress");

            testCase.verifyError( ...
                @() matbox.tasks.internal.vendorPackageFromFolder( ...
                    repositoryFolder, testCase.SourceFolder, targetFolder), ...
                "MatBox:VendorPackage:NamespaceMismatch")
        end

        function testMissingSourceFolderErrors(testCase)
            repositoryFolder = testCase.createRepository();

            testCase.verifyError( ...
                @() matbox.tasks.internal.vendorPackageFromFolder( ...
                    repositoryFolder, "src/+otherName", testCase.getTargetFolder()), ...
                "MatBox:VendorPackage:SourceFolderNotFound")
        end

        function testMissingLicenseFileErrors(testCase)
            repositoryFolder = testCase.createRepository();

            testCase.verifyError( ...
                @() matbox.tasks.internal.vendorPackageFromFolder( ...
                    repositoryFolder, testCase.SourceFolder, testCase.getTargetFolder(), ...
                    LicenseFile="license.txt"), ...
                "MatBox:VendorPackage:LicenseFileNotFound")
        end

        function testBytesOutsideReferencesArePreserved(testCase)
            % The comment holds multi-byte UTF-8 characters and the file has
            % Windows line endings; both must come through byte for byte.
            repositoryFolder = testCase.createRepository();
            sourceText = "% µm – ok" + char([13 10]) + "webprogress.upload(a)" + char([13 10]);
            writeText(fullfile(repositoryFolder, testCase.SourceFolder, "scale.m"), sourceText)
            targetFolder = testCase.getTargetFolder();

            matbox.tasks.internal.vendorPackageFromFolder( ...
                repositoryFolder, testCase.SourceFolder, targetFolder)

            expectedText = replace(sourceText, "webprogress.", testCase.TargetNamespace + ".");
            testCase.verifyEqual(readBytes(fullfile(targetFolder, "scale.m")), ...
                unicode2native(expectedText, "UTF-8"))
        end
    end

    methods (Test) % vendorPackage
        function testTargetFolderOutsideProjectErrors(testCase)
            testCase.verifyError( ...
                @() matbox.tasks.vendorPackage(pwd, testCase.GitHubSourceUri, ...
                    "code/+matbox/+utility", "../+mytoolbox/+utility"), ...
                "MatBox:VendorPackage:InvalidTargetFolder")
        end

        function testVendorFromGitHub(testCase)
            % Requires network access.
            targetFolder = "src/+mytoolbox/+external/+utility";

            vendorInfo = matbox.tasks.vendorPackage(pwd, testCase.GitHubSourceUri, ...
                "code/+matbox/+utility", targetFolder, ...
                ExcludeFiles="filewrite.m", Verbose=false);

            testCase.verifyEqual(vendorInfo.Source, "https://github.com/ehennestad/matbox")
            testCase.verifyEqual(vendorInfo.Reference, "v0.11.0")
            testCase.verifyEqual(vendorInfo.CommitID, testCase.GitHubCommitId)
            testCase.verifyTrue(isfile(fullfile(pwd, targetFolder, "LICENSE")))
            testCase.verifyTrue(isfile(fullfile(pwd, targetFolder, "vendorinfo.json")))
            testCase.verifyFalse(isfile(fullfile(pwd, targetFolder, "filewrite.m")))
            testCase.verifySubstring( ...
                fileread(fullfile(pwd, targetFolder, "getLatestMatlabReleaseForGitHubActions.m")), ...
                "mytoolbox.external.utility.getLatestMatlabReleaseForGitHubActions()")
        end
    end

    methods (Access = private)
        function repositoryFolder = createRepository(testCase)
            % Create the files of a repository whose package is in the
            % namespace SourceNamespace, as an unzipped download would be.
            repositoryFolder = string(fullfile(pwd, "repository"));
            packageFolder = fullfile(repositoryFolder, testCase.SourceFolder);

            uploadCode = join([
                "function upload(filePath, url)"
                "%upload - Upload a file"
                "%   webprogress.upload(FILENAME,URL) uploads the file."
                "    monitorFcn = @(o) webprogress.Monitor(o{:});"
                "    error(""webprogress:upload:Failed"", ""Upload failed."")"
                "end"
                ], newline);

            writeText(fullfile(repositoryFolder, "LICENSE"), testCase.LicenseText)
            writeText(fullfile(packageFolder, "upload.m"), uploadCode)
            writeText(fullfile(packageFolder, testCase.ExcludedFile), "function toolboxdir(), end")
            writeText(fullfile(packageFolder, "private", "mustBeValidUrl.m"), ...
                "function mustBeValidUrl(~), end")
        end

        function targetFolder = getTargetFolder(~)
            % Full path of a folder that defines the namespace TargetNamespace
            targetFolder = string(fullfile(pwd, "project", "src", ...
                "+mytoolbox", "+external", "+webprogress"));
        end
    end
end

function writeText(filePath, text)
% writeText - Write text to a UTF-8 file, creating its folder if needed
    folderPath = fileparts(filePath);
    if ~isfolder(folderPath)
        mkdir(folderPath)
    end
    fileId = fopen(filePath, "w");
    fileCleanup = onCleanup(@() fclose(fileId));
    fwrite(fileId, unicode2native(text, "UTF-8"), "uint8");
end

function bytes = readBytes(filePath)
% readBytes - Read a file as a row vector of bytes
    fileId = fopen(filePath, "r");
    fileCleanup = onCleanup(@() fclose(fileId));
    bytes = fread(fileId, [1, Inf], "*uint8");
end

function [relativePaths, contents] = readFolder(folderPath)
% readFolder - Get the relative paths and the bytes of all files below a folder
    fileListing = dir(fullfile(folderPath, "**", "*"));
    fileListing([fileListing.isdir]) = [];
    filePaths = sort(string(fullfile({fileListing.folder}, {fileListing.name})));

    relativePaths = erase(filePaths, string(folderPath) + filesep);
    contents = cell(size(filePaths));
    for i = 1:numel(filePaths)
        contents{i} = readBytes(filePaths(i));
    end
end
