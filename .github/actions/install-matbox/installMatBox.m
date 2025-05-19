function installMatBox(mode, options)
% installMatBox - Install MatBox from latest release or latest commit

    arguments
        mode (1,1) string {mustBeMember(mode, ["release", "commit"])} = "release"
        options.InstallationLocation = userpath
    end
    
    if mode == "release"
        installFromRelease() % local function
    elseif mode == "commit"
        installFromCommit(options.InstallationLocation) % local function
    end
end

function installFromRelease()
    addonsTable = matlab.addons.installedAddons();
    isMatchedAddon = addonsTable.Name == "MatBox";
    
    if ~isempty(isMatchedAddon) && any(isMatchedAddon)
        matlab.addons.enableAddon('MatBox')
    else
        info = webread('https://api.github.com/repos/ehennestad/MatBox/releases/latest');
        assetNames = {info.assets.name};
        isMltbx = startsWith(assetNames, 'MatBox');
    
        mltbx_URL = info.assets(isMltbx).browser_download_url;
        
        % Download matbox
        tempFilePath = websave(tempname, mltbx_URL);
        cleanupObj = onCleanup(@(fp) delete(tempFilePath));
        
        % Install toolbox
        matlab.addons.install(tempFilePath);
    end
end


function installFromCommit(installationLocation)
    
    scriptPath = mfilename('fullpath');
    projectFolder = extractBefore(scriptPath, fullfile('.github', 'actions'));
    codeDirectory = fullfile(projectFolder, 'code');
    
    addpath(genpath(codeDirectory))
    savepath()
    
    return
    
    % Download latest zipped version of repo
    url = "https://github.com/ehennestad/MatBox/archive/refs/heads/main.zip";
    tempFilePath = websave(tempname, url);
    cleanupObj = onCleanup(@(fp) delete(tempFilePath));
    
    % Unzip in temporary location
    unzippedFiles = unzip(tempFilePath, tempdir);
    unzippedFolder = unzippedFiles{1};
    if endsWith(unzippedFolder, filesep)
        unzippedFolder = unzippedFolder(1:end-1);
    end
    
    % Move to installation location
    [~, repoFolderName] = fileparts(unzippedFolder);
    targetFolder = fullfile(installationLocation, "MATLAB Add-Ons", "Toolboxesss");
    targetFolder = fullfile(targetFolder, repoFolderName);
    if isfolder(targetFolder); rmdir(targetFolder, "s"); end
    movefile(unzippedFolder, targetFolder);

    % Add to MATLAB's search path
    addpath(genpath(targetFolder))
    savepath()
end