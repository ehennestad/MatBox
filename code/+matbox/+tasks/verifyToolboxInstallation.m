function verifyToolboxInstallation(mltbxFile)
% verifyToolboxInstallation - Verify installation of MATLAB toolbox

    arguments
        mltbxFile (1,1) string {mustBeFile}
    end

    fprintf('Installing toolbox: %s\n', mltbxFile);
    agreeToLicense = true;
    installedToolbox = matlab.addons.install(mltbxFile, agreeToLicense);
    
    % Verify installation
    fprintf('Toolbox installed successfully:\n');
    fprintf('  Name: %s\n', installedToolbox.Name);
    fprintf('  Version: %s\n', installedToolbox.Version);
    fprintf('  Identifier: %s\n', installedToolbox.Identifier);

    fprintf('Verification completed successfully on %s\n', computer);
end
