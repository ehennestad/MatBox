function fixRequiredAdditionalSoftware(toolboxOptions)
% fixRequiredAdditionalSoftware - Fix the specification for Required
% Additional Software

    % Due to a lack of maca64 support for additional software from
    % ToolboxOptions API in MATLAB R2023b and earlier releases, we need to
    % manually add a *_common.xml specification in the .MLTBX file for each
    % of the additional software using an undocumented MATLAB builtin
    % function.

    currentWorkDir = pwd;
    cleanupObj = onCleanup(@(fp) cd(currentWorkDir));

    tempDir = fullfile(tempdir, 'toolbox_repackage');
    if ~isfolder(tempDir)
        mkdir(tempDir)
    end

    cd(tempDir)
    fileCleanupObj = onCleanup(@(fp) rmdir(tempDir, 's'));

    unzip(toolboxOptions.OutputFile, 'temp_toolbox');
    L = dir(fullfile('temp_toolbox', 'metadata', 'InstructionSets', '*_maci64.xml'));

    for i = 1:numel(L)
        filePath = fullfile(L(i).folder, L(i).name);
        targetFilename = strrep(L(i).name, 'maci64', 'common');
        copyfile(filePath, targetFilename);
        
        mlAddonAddInstructionSet(char(toolboxOptions.OutputFile), targetFilename)
    end
end
