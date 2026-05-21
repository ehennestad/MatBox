function installRequirements(toolboxFolder, mode, options)

    arguments
        toolboxFolder (1,1) string {mustBeFolder}
    end
    arguments (Repeating)
        mode string {mustBeMember(mode, ["force", "f", "update", "u"])}
    end

    arguments
        options.UpdateSearchPath (1,1) logical = true
        options.SaveSearchPath (1,1) logical = true
        options.InstallationLocation (1,1) string = matbox.setup.internal.getDefaultAddonFolder()
        options.Verbose (1,1) logical = true
        options.AgreeToLicenses (1,1) logical = false
    end

    % Parse mode/flags
    mode = string(mode);
    doUpdate = any(strcmp(mode, 'update')) || any(strcmp(mode, 'u'));

    installationLocation = options.InstallationLocation;
    if ~isfolder(installationLocation); mkdir(installationLocation); end

    reqs = matbox.setup.internal.getRequirements(toolboxFolder);
    for i = 1:numel(reqs)
        switch reqs(i).Type
            case {'GitHub', 'FileExchange'}
                matbox.setup.installFromSourceUri( ...
                    reqs(i).URI, ...
                    "InstallationLocation", installationLocation, ...
                    "AddToPath", options.UpdateSearchPath, ...
                    "Update", doUpdate, ...
                    "Verbose", options.Verbose, ...
                    "AgreeToLicense", options.AgreeToLicenses);
            case 'Unknown'
                continue
        end
    end

    if options.UpdateSearchPath && options.SaveSearchPath
        savepath()
    end
end
