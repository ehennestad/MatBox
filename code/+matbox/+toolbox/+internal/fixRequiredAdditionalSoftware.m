function fixRequiredAdditionalSoftware(initialToolboxFilePath, finalToolboxFilePath)
% fixRequiredAdditionalSoftware - Fix the specification for Required
% Additional Software
%
% Due to a lack of maca64 support for additional software from
% ToolboxOptions API in MATLAB R2023b and earlier releases, we need to
% manually add a *_common.xml specification in the .MLTBX file for each
% of the additional software using an undocumented MATLAB builtin
% function.
%
%   Inputs:
%
%     initialToolboxFilePath - Filepath of a mltbx file where the
%       additional required software is specified.
%     finalToolboxFilePath - Filepath of the final mltbx file where the
%       additional required software will be added with a "_common" suffix.
%

    currentWorkDir = pwd;
    cleanupObj = onCleanup(@(fp) cd(currentWorkDir));

    tempDir = fullfile(tempdir, 'toolbox_repackage');
    if ~isfolder(tempDir)
        mkdir(tempDir)
    end

    cd(tempDir)
    fileCleanupObj = onCleanup(@(fp) rmdir(tempDir, 's'));

    unzip(initialToolboxFilePath, 'temp_toolbox');
    L = dir(fullfile('temp_toolbox', 'metadata', 'InstructionSets', '*_maci64.xml'));

    for i = 1:numel(L)
        filePath = fullfile(L(i).folder, L(i).name);
        targetFilename = strrep(L(i).name, 'maci64', 'common');
        copyfile(filePath, targetFilename);
        
        mlAddonAddInstructionSet(char(finalToolboxFilePath), targetFilename)
    end
end
