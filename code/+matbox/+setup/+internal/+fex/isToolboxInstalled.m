function [tf, versionString, toolboxFolder] = isToolboxInstalled(toolboxIdentifier, versionString)
    
    arguments
        toolboxIdentifier (1,1) string
        versionString (1,1) string = missing
    end
    
    import matlab.internal.addons.util.retrieveInstallationFolderForAddOn

    tf = false;
    toolboxFolder = "";

    addonsTable = matlab.addons.installedAddons();
    matchedAddons = addonsTable(addonsTable.Identifier == toolboxIdentifier, :);

    if height(matchedAddons) > 0
        addonName = matchedAddons.Name(1);

        if ~ismissing(versionString) && versionString ~= "latest"
            hasCorrectVersion = matchedAddons.Version == versionString;

            if ~any(hasCorrectVersion)
                warning('Addon with name "%s" is installed, but the version number does not match.', addonName)
                return
            end
        else
            if height(matchedAddons) == 1
                versionString = matchedAddons.Version;
            else % More than 1 match
                versionString = matchedAddons.Version(1);
                warning('Multiple versions installed for addon with name "%s", returning version %s', addonName, versionString)
            end
        end

        tf = true;
        toolboxFolder = retrieveInstallationFolderForAddOn(toolboxIdentifier, versionString);
    end

    if nargout < 2
        clear versionString toolboxFolder
    elseif nargout < 3
        clear toolboxFolder
    end
end
