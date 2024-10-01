function [filePath, cleanupObj] = tempsave(fileUrl, fileName)
% tempsave - Save file from the web to temporary location
%
%   [filePath, cleanupObj] = tempsave(fileUrl) saves a file from the web to
%   a temporary location. It returns the filePath to the file and a
%   cleanupObject. The file will be automatically deleted when the cleanup
%   object is cleared from memory.
%
%   [filePath, cleanupObj] = tempsave(fileUrl, fileName) optionally saves
%   the file with the name given by fileName. If fileName is not provided,
%   the name of the file from the fileUrl is used.
%
%   File is automatically deleted when the cleanupObj is deleted or cleared
%   from the workspace

    arguments
        fileUrl (1,1) string
        fileName (1,1) string = missing
    end

    if ismissing(fileName)
        fileName = fileUrl;
    end

    [~, fileName, fileExtension] = fileparts( char(fileName) );

    filePath = websave(fullfile(tempdir, [fileName, fileExtension] ), fileUrl );
    cleanupObj = onCleanup(@(filename) deleteTempFile(filePath));
end

function deleteTempFile(filePath)
    if isfile(filePath)
        delete(filePath)
    end
end
