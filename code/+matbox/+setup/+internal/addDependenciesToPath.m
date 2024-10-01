function addDependenciesToPath(options)

    arguments
        options.InstallationLocation (1,1) string = matbox.setup.internal.getDefaultAddonFolder()
    end
    
    reqs = matbox.setup.internal.getRequirements();

    for i = 1:numel(reqs)
        switch reqs(i).Type
            case 'GitHub'
                % Todo.
                %[repoUrl, branchName] = parseGitHubUrl(reqs(i).URI);
                %matbox.setup.internal.installGithubRepository( repoUrl, branchName )
            
            case 'FileExchange'
                [packageUuid, version] = matbox.setup.internal.fex.parseFileExchangeURI( reqs(i).URI );
                [isInstalled, version] = matbox.setup.internal.fex.isToolboxInstalled(packageUuid, version);
                if isInstalled
                    matlab.addons.enableAddon(packageUuid, version)
                end
            case 'Unknown'
                continue
        end
    end
    
    % Add all addons in the package's addon folder to path
    addonLocation = options.InstallationLocation;
    addonListing = dir(addonLocation);

    for i = 1:numel(addonListing)
        if startsWith(addonListing(i).name, '.')
            continue
        end
        if ~addonListing(i).isdir
            continue
        end

        folderPath = fullfile(addonListing(i).folder, addonListing(i).name);
        startupFile = matbox.setup.internal.findStartupFile(folderPath);
        
        if ~isempty(startupFile)
            run( startupFile )
        else
            addpath(genpath(folderPath))
        end
    end
end
