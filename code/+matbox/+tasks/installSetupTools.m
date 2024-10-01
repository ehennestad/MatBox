function installSetupTools()

    % Check for presence of setuptools on MATLAB's search path
    if exist('+setuptools/installRequirements.m', 'file') == 2
        return
    end
    
    % Download setuptools
    url = "https://github.com/ehennestad/setuptools-matlab/archive/refs/heads/main.zip";
    tempZipPath = websave(tempname, url);
    cleanupObj = onCleanup(@(fp) delete(tempZipPath));
    
    % Add setuptools to MATLAB's search path
    installDirectory = fullfile(userpath, 'MATLAB-AddOns');
    if ~isfolder(installDirectory);mkdir(installDirectory); end
    
    unzippedFiles = unzip(tempZipPath, installDirectory);
    addpath(genpath(unzippedFiles{1}))
end
