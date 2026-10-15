function locations = findNamespaceReferences(folderPath, namespaceName)
%findNamespaceReferences - Find the places where the files below a folder name a namespace
%   locations = matbox.tasks.internal.findNamespaceReferences(folderPath,namespaceName)
%   searches the files below folderPath for namespaceName as a whole word
%   and returns a string column vector with one element per place found.
%   For a text file, an element is the path of the file relative to
%   folderPath, with "/" as separator, followed by ":" and the line
%   number, such as "upload.m:12". For a binary file, it is the path
%   alone, such as "examples/demo.mlx".
%
%   The name is not counted when a letter, digit, "_", ".", "/" or "\"
%   comes before it, as in matbox.tasks.internal.renameNamespaceInText, or
%   when a letter, digit, "_" or ":" comes after it. This leaves out longer
%   names, renamed references ("mytoolbox.external.webprogress.upload"),
%   paths and error identifiers ("webprogress:upload:Failed"). Lines of .m
%   files that are comments are not searched.
%
%   .mlx and .mlapp files are zip archives and are searched in the files
%   they hold. A file with a NUL byte is binary and is searched as it is
%   stored, so a name in compressed data, such as a MAT-file saved in the
%   default format, is not found.
%
%   See also matbox.tasks.vendorPackage, matbox.tasks.internal.renameNamespaceInText

    arguments
        folderPath (1,1) string {mustBeFolder}
        namespaceName (1,1) string {mustBeNonzeroLengthText}
    end

    ARCHIVE_EXTENSIONS = [".mlx", ".mlapp"];
    CODE_EXTENSION = ".m";

    % The character classes are spelled out because \w may also match
    % non-ASCII letters, and the text is the raw bytes of a file.
    notInsideLongerName = "(?<![A-Za-z0-9_.\\/])";
    notFollowedByNameOrColon = "(?![A-Za-z0-9_:])";
    pattern = notInsideLongerName ...
        + regexptranslate("escape", namespaceName) + notFollowedByNameOrColon;

    fileListing = dir(fullfile(folderPath, "**", "*"));
    fileListing([fileListing.isdir]) = [];
    filePaths = sort(string(fullfile({fileListing.folder}, {fileListing.name})));

    % dir gives full paths with symbolic links resolved, so the root folder
    % is taken from dir as well for the file paths to start with it.
    rootListing = dir(folderPath);
    rootFolder = string(rootListing(1).folder);
    relativePaths = replace(extractAfter(filePaths, strlength(rootFolder) + 1), "\", "/");

    locationsPerFile = cell(numel(filePaths), 1);
    for i = 1:numel(filePaths)
        relativePath = relativePaths(i);
        [~, ~, fileExtension] = fileparts(filePaths(i));

        if any(strcmpi(fileExtension, ARCHIVE_EXTENSIONS))
            isNamed = isNameInArchive(filePaths(i), pattern);
            locationsPerFile{i} = relativePath(isNamed);
        else
            % The file is handled as bytes, one character per byte, because
            % its encoding is unknown. The namespace name is ASCII, which
            % every common encoding stores as single bytes.
            bytes = readBytes(filePaths(i));
            if any(bytes == 0)
                isNamed = ~isempty(regexp(char(bytes), pattern, "once"));
                locationsPerFile{i} = relativePath(isNamed);
            else
                isCodeFile = strcmpi(fileExtension, CODE_EXTENSION);
                lineNumbers = findLinesWithName(char(bytes), pattern, isCodeFile);
                locationsPerFile{i} = relativePath + ":" + lineNumbers;
            end
        end
    end

    locations = vertcat(strings(0, 1), locationsPerFile{:});
end

function lineNumbers = findLinesWithName(text, pattern, isCodeFile)
%findLinesWithName - Get the numbers of the lines of a text that match a pattern
    % Splitting at the line feed alone also handles Windows line endings,
    % because the carriage return left at the end of a line cannot be part
    % of a match.
    textLines = split(string(text), newline);
    isNamed = contains(textLines, regexpPattern(pattern));

    % A comment line cannot refer to a namespace at run time, and help text
    % often names the package it belongs to.
    if isCodeFile
        isCommentLine = startsWith(strip(textLines, "left"), "%");
        isNamed = isNamed & ~isCommentLine;
    end

    lineNumbers = find(isNamed);
end

function isNamed = isNameInArchive(filePath, pattern)
%isNameInArchive - Check whether a file in a zip archive matches a pattern
    extractionFolder = string(tempname());
    mkdir(extractionFolder)
    extractionFolderCleanup = onCleanup(@() rmdir(extractionFolder, "s"));

    extractedPaths = string(unzip(filePath, extractionFolder));
    extractedPaths = extractedPaths(isfile(extractedPaths));

    isNamed = false;
    for i = 1:numel(extractedPaths)
        bytes = readBytes(extractedPaths(i));
        if ~isempty(regexp(char(bytes), pattern, "once"))
            isNamed = true;
            break
        end
    end
end

function bytes = readBytes(filePath)
%readBytes - Read a file as a row vector of bytes
    fileId = fopen(filePath, "r");
    fileCleanup = onCleanup(@() fclose(fileId));
    bytes = fread(fileId, [1, Inf], "*uint8");
end
