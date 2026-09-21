function vendorInfo = vendorPackageFromFolder(repositoryFolder, sourceFolder, targetFolder, options)
%vendorPackageFromFolder - Copy a folder of a downloaded repository into a project
%   vendorInfo = matbox.tasks.internal.vendorPackageFromFolder(repositoryFolder,sourceFolder,targetFolder)
%   copies the folder sourceFolder of the repository in repositoryFolder to
%   targetFolder and returns the information written to vendorinfo.json.
%   sourceFolder is relative to repositoryFolder. targetFolder is a full
%   path. matbox.tasks.vendorPackage describes the copy; this function is
%   the part of it that needs no network access.
%
%   [...] = matbox.tasks.internal.vendorPackageFromFolder(...,Name=Value)
%   sets ExcludeFiles and LicenseFile as in matbox.tasks.vendorPackage, and
%   RepositoryUrl, Reference and CommitID, which are recorded in
%   vendorinfo.json as they are given.
%
%   See also matbox.tasks.vendorPackage

    arguments
        repositoryFolder (1,1) string {mustBeFolder}
        sourceFolder (1,1) string
        targetFolder (1,1) string {mustBeNonzeroLengthText}
        options.ExcludeFiles (1,:) string = string.empty
        options.LicenseFile (1,1) string = "LICENSE"
        options.RepositoryUrl (1,1) string = ""
        options.Reference (1,1) string = ""
        options.CommitID (1,1) string = ""
    end

    VENDOR_INFO_FILE_NAME = "vendorinfo.json";

    sourcePath = fullfile(repositoryFolder, sourceFolder);
    if ~isfolder(sourcePath)
        error("MatBox:VendorPackage:SourceFolderNotFound", ...
            "The repository has no folder ""%s"". Give the folder " + ...
            "relative to the root of the repository.", sourceFolder)
    end

    licensePath = fullfile(repositoryFolder, options.LicenseFile);
    if ~isfile(licensePath)
        error("MatBox:VendorPackage:LicenseFileNotFound", ...
            "The repository has no file ""%s"". Name its license file " + ...
            "with the LicenseFile option.", options.LicenseFile)
    end

    sourceNamespace = matbox.tasks.internal.getNamespaceName(sourceFolder);
    targetNamespace = matbox.tasks.internal.getNamespaceName(targetFolder);
    isRenameNeeded = sourceNamespace ~= targetNamespace;
    if isRenameNeeded && (sourceNamespace == "" || targetNamespace == "")
        error("MatBox:VendorPackage:NamespaceMismatch", ...
            "Cannot copy ""%s"" to ""%s"" because only one of them is a " + ...
            "namespace folder, and calls to functions without a namespace " + ...
            "cannot be renamed. Make both or neither a namespace folder.", ...
            sourceFolder, targetFolder)
    end

    % Only a folder that this function created is replaced, so that a wrong
    % target path cannot delete other source code of the project.
    if isfolder(targetFolder) && ~isfile(fullfile(targetFolder, VENDOR_INFO_FILE_NAME))
        error("MatBox:VendorPackage:TargetFolderNotVendored", ...
            "The folder ""%s"" exists but has no %s file, so it was not " + ...
            "created by this function and is not replaced. Remove the " + ...
            "folder or choose another target folder.", ...
            targetFolder, VENDOR_INFO_FILE_NAME)
    end

    % The copy is prepared in a temporary folder and replaces the target
    % folder as the last step, so that an error leaves the target unchanged.
    stagingFolder = string(tempname());
    copyfile(sourcePath, stagingFolder)
    stagingFolderCleanup = onCleanup(@() removeFolderIfPresent(stagingFolder));

    removeExcludedFiles(stagingFolder, options.ExcludeFiles)

    if isRenameNeeded
        renameNamespaceInFolder(stagingFolder, sourceNamespace, targetNamespace)
    end

    [~, licenseName, licenseExtension] = fileparts(options.LicenseFile);
    copyfile(licensePath, fullfile(stagingFolder, licenseName + licenseExtension))

    vendorInfo = struct( ...
        "Source", options.RepositoryUrl, ...
        "Reference", options.Reference, ...
        "CommitID", options.CommitID, ...
        "SourceFolder", replace(sourceFolder, "\", "/"), ...
        "SourceNamespace", sourceNamespace, ...
        "TargetNamespace", targetNamespace, ...
        "ExcludedFiles", options.ExcludeFiles);
    writeVendorInfo(fullfile(stagingFolder, VENDOR_INFO_FILE_NAME), vendorInfo)

    % Replacing the whole folder also removes the files that the source no
    % longer has, which copying over the existing folder would leave behind.
    if isfolder(targetFolder)
        rmdir(targetFolder, "s")
    end
    parentFolder = fileparts(targetFolder);
    if strlength(parentFolder) > 0 && ~isfolder(parentFolder)
        mkdir(parentFolder)
    end
    movefile(stagingFolder, targetFolder)

    if nargout < 1
        clear vendorInfo
    end
end

function removeExcludedFiles(folderPath, excludeFiles)
%removeExcludedFiles - Delete the excluded files from the copied folder
    excludedPaths = fullfile(folderPath, excludeFiles);

    % A name that matches nothing is an error, because it no longer leaves
    % out the file it was meant for: the source has renamed or removed it.
    isMissing = ~isfile(excludedPaths);
    if any(isMissing)
        error("MatBox:VendorPackage:ExcludedFileNotFound", ...
            "The source folder has no file ""%s"". Update the ExcludeFiles " + ...
            "option to match the files of the source folder.", ...
            strjoin(excludeFiles(isMissing), """, """))
    end

    for i = 1:numel(excludedPaths)
        delete(excludedPaths(i))
    end
end

function renameNamespaceInFolder(folderPath, sourceNamespace, targetNamespace)
%renameNamespaceInFolder - Rename a namespace in all .m files below a folder
    fileListing = dir(fullfile(folderPath, "**", "*.m"));
    filePaths = string(fullfile({fileListing.folder}, {fileListing.name}));

    for i = 1:numel(filePaths)
        % The file is handled as bytes, one character per byte, so that
        % everything but the renamed references is written back unchanged
        % whatever the encoding of the file is. The namespace names are
        % ASCII, which every common encoding stores as single bytes.
        originalText = char(readBytes(filePaths(i)));
        renamedText = matbox.tasks.internal.renameNamespaceInText( ...
            originalText, sourceNamespace, targetNamespace);

        if ~strcmp(renamedText, originalText)
            writeBytes(filePaths(i), uint8(renamedText))
        end
    end
end

function bytes = readBytes(filePath)
%readBytes - Read a file as a row vector of bytes
    fileId = fopen(filePath, "r");
    fileCleanup = onCleanup(@() fclose(fileId));
    bytes = fread(fileId, [1, Inf], "*uint8");
end

function writeBytes(filePath, bytes)
%writeBytes - Replace the content of a file with a vector of bytes
    fileId = fopen(filePath, "w");
    fileCleanup = onCleanup(@() fclose(fileId));
    fwrite(fileId, bytes, "uint8");
end

function writeVendorInfo(filePath, vendorInfo)
%writeVendorInfo - Save the vendor information as a JSON file
    % A cell array is encoded as a JSON array whatever its length, while a
    % string array with one element would be encoded as a JSON string.
    vendorInfo.ExcludedFiles = cellstr(vendorInfo.ExcludedFiles);
    writeBytes(filePath, unicode2native(jsonencode(vendorInfo, PrettyPrint=true), "UTF-8"))
end

function removeFolderIfPresent(folderPath)
%removeFolderIfPresent - Remove a folder and its content if the folder exists
    if isfolder(folderPath)
        rmdir(folderPath, "s")
    end
end
