function installMatBox(mode)
% installMatBox - Install MatBox from latest release or latest commit

    arguments
        mode (1,1) string {mustBeMember(mode, ["release", "commit"])} = "release"
    end
    
    if mode == "release"
        installFromRelease() % local function
    elseif mode == "commit"
        installFromCommit() % local function
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

function installFromCommit()
    
    scriptPath = mfilename('fullpath');
    projectFolder = extractBefore(scriptPath, fullfile('.github', 'actions'));
    codeDirectory = fullfile(projectFolder, 'code');
    
    addpath(genpath(codeDirectory))
    savepath()
end
