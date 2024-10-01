function installFexPackage(toolboxIdentifier, installLocation, options)
% installFexPackage - Install a FileExchange package
%
%   This function installs a package from FileExchange. If the package is
%   already present, it is added to the path, otherwise it is downloaded.
%
%   installFexPackage(toolboxIdentifier, installLocation)

%   Todo:
%   [ ] Separate method for downloading
%   [ ] Unclear if downloaded zip is added to path. Is this the
%       responsibility of this function or upstream?

    arguments
        toolboxIdentifier
        installLocation
        options.Name (1,1) string = missing
        options.Version (1,1) string = missing
    end

    % Check if toolbox is installed
    [isInstalled, version] = matbox.setup.internal.fex.isToolboxInstalled(toolboxIdentifier, options.Version);

    if isInstalled
        matlab.addons.enableAddon(toolboxIdentifier, version)

    else % Download toolbox
        fex = matlab.addons.repositories.FileExchangeRepository();

        if ismissing(options.Version)
            versionStr = "latest";
        else
            versionStr = options.Version;
        end
    
        % Get download url for addon / package
        addonUrl = fex.getAddonURL(toolboxIdentifier, versionStr);
        
        if endsWith(addonUrl, '.xml')
            % Todo: Install in MATLAB's Addon folder

            % Sometimes the URL is for an xml, in which case we need to
            % parse the xml and retrieve the download url from the xml.
            [filepath, C] = matbox.setup.internal.utility.tempsave(addonUrl);
            S = readstruct(filepath); delete(C) % Read XML
            toolboxName = S.name;

            addonUrl = S.downloadUrl;
            addonUrl = extractBefore(addonUrl, '?');
        else
            toolboxName = string(missing);
        end

        if ismissing(toolboxName)
            if ismissing(options.Name)
                toolboxName = retrieveToolboxName(toolboxIdentifier);
            else
                toolboxName = options.Name;
            end
        end
    
        if ismissing(toolboxName)
            fprintf('Please wait, installing "<missing name>"...')
        else
            fprintf('Please wait, installing "%s"...', toolboxName)
        end

        if endsWith(addonUrl, '/zip')
            [tempFilepath, C] = matbox.setup.internal.utility.tempsave(addonUrl, [toolboxIdentifier, '_temp.zip']);

            installLocation = fullfile(installLocation, toolboxName);
            if ~isfolder(installLocation); mkdir(installLocation); end
            unzip(tempFilepath, installLocation);

        elseif endsWith(addonUrl, '/mltbx')
            [tempFilepath, C] = matbox.setup.internal.utility.tempsave(addonUrl, [toolboxIdentifier, '_temp.mltbx']);
            matlab.addons.install(tempFilepath);
        end

        delete(C)
        fprintf('Done\n')
    end
end

function toolboxName = retrieveToolboxName(toolboxIdentifier)
    fex = matlab.addons.repositories.FileExchangeRepository();

    additionalInfoUrl = fex.getAddonDetailsURL(toolboxIdentifier);
    addonHtmlInfo = webread(additionalInfoUrl);
    pattern = '<span id="titleText">(.*?)</span>';
    title = regexp(addonHtmlInfo, pattern, 'tokens', 'once');
    if ~isempty(title)
        toolboxName = title{1};
    else
        toolboxName = string(missing);
    end
end
