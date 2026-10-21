function [packageTargetFolder, installationMethod] = installFexPackage(toolboxIdentifier, installLocation, options)
% installFexPackage - Install a FileExchange package
%
%   This function installs a package from FileExchange. If the package is
%   already present, it is added to the path, otherwise it is downloaded.
%
%   [folder, method] = installFexPackage(toolboxIdentifier, installLocation)
%
%   Output:
%       packageTargetFolder - Path to the installed package folder, or
%           string(missing) for mltbx packages (managed by MATLAB)
%       installationMethod  - "folder" for zip-extracted packages,
%           "mltbx" for MATLAB toolbox packages

%   Todo:
%   [ ] Separate method for downloading

    arguments
        toolboxIdentifier
        installLocation
        options.Name (1,1) string = missing
        options.Title (1,1) string = missing
        options.Version (1,1) string = missing
        options.AddToPath (1,1) logical = true
        options.AddToPathWithSubfolders (1,1) logical = true
        options.Verbose (1,1) logical = true
        % No default, so an explicit false can be told from an omitted value
        options.AgreeToLicense (1,1) logical
    end

    isLicenseOptionGiven = isfield(options, "AgreeToLicense");
    isLicenseAgreed = isLicenseOptionGiven && options.AgreeToLicense;
    isLicenseDeclined = isLicenseOptionGiven && ~options.AgreeToLicense;

    % Check if toolbox is installed
    [isInstalled, version, toolboxFolder] = matbox.setup.internal.fex.isToolboxInstalled(toolboxIdentifier, options.Version);

    if isInstalled
        matlab.addons.enableAddon(toolboxIdentifier, version)
        packageTargetFolder = toolboxFolder;
        installationMethod = "mltbx";
        if options.Verbose
            fprintf('Requirement "%s" is already installed. Skipping...\n', options.Title)
        end

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
                if ismissing(toolboxName)
                    toolboxName = options.Title;
                end
            else
                toolboxName = options.Name;
            end
        end

        if options.Verbose
            if ismissing(toolboxName)
                fprintf('Please wait, installing "<missing name>"...')
            else
                fprintf('Please wait, installing "%s"...', toolboxName)
            end
        end

        if endsWith(addonUrl, '/zip')
            [tempFilepath, C] = matbox.setup.internal.utility.tempsave(addonUrl, [toolboxIdentifier, '_temp.zip']);

            packageTargetFolder = fullfile(installLocation, toolboxName);
            installationMethod = "folder";
            if ~isfolder(packageTargetFolder); mkdir(packageTargetFolder); end
            unzip(tempFilepath, packageTargetFolder);
            if options.AddToPath
                if options.AddToPathWithSubfolders
                    addpath(genpath(packageTargetFolder))
                else
                    addpath(packageTargetFolder)
                end
            end

        elseif endsWith(addonUrl, '/mltbx')
            isLicenseOptionSupported = isMATLABReleaseOlderThan("R2026b");
            if isLicenseOptionSupported && ~isLicenseAgreed && ~canShowLicenseDialog()
                fprintf(newline)
                error("MatBox:Setup:LicenseDialogUnavailable", ...
                    ['Installing "%s" shows its license agreement in a dialog, and ', ...
                    'this MATLAB session cannot display one. Pass AgreeToLicense=true ', ...
                    '(AgreeToLicenses=true in installRequirements) to accept the ', ...
                    'license without the dialog.'], toolboxName)
            end

            [tempFilepath, C] = matbox.setup.internal.utility.tempsave(addonUrl, [toolboxIdentifier, '_temp.mltbx']);
            if isLicenseOptionSupported
                installedAddon = matlab.addons.install(tempFilepath, isLicenseAgreed);
            else
                % From R2026b, installing accepts the license agreement,
                % and an agreeToLicense argument of false is an error.
                installedAddon = matlab.addons.install(tempFilepath);
            end
            if isempty(installedAddon)
                fprintf(newline)
                error('Failed to install "%s"...', toolboxName)
            end
            if isLicenseDeclined && ~isLicenseOptionSupported
                fprintf(newline)
                warning("MatBox:Setup:AgreeToLicenseIgnored", ...
                    ['AgreeToLicense is false, but from R2026b MATLAB accepts the ', ...
                    'license agreement when it installs an add-on. "%s" was installed ', ...
                    'and its license terms apply.'], toolboxName)
            end
            packageTargetFolder = string(missing);
            installationMethod = "mltbx";
        end

        delete(C)
        if options.Verbose
            fprintf('Done.\n')
        end

        if ~nargout
            clear packageTargetFolder installationMethod
        elseif nargout == 1
            clear installationMethod
        end
    end
end

function tf = canShowLicenseDialog()
% canShowLicenseDialog - Whether this session can display the add-on license dialog
%
%   Before R2026b, matlab.addons.install shows the license agreement of an
%   .mltbx add-on in a Java Swing dialog unless agreeToLicense is true.
%   Java is headless when there is no display, as on a CI runner, and
%   creating the dialog then throws java.awt.HeadlessException.

    tf = usejava("jvm") && ~java.awt.GraphicsEnvironment.isHeadless();
end

function toolboxName = retrieveToolboxName(toolboxIdentifier)
    fex = matlab.addons.repositories.FileExchangeRepository();

    try
        additionalInfoUrl = fex.getAddonDetailsURL(toolboxIdentifier);
        addonHtmlInfo = webread(additionalInfoUrl);
        pattern = '<span id="titleText">(.*?)</span>';
        title = regexp(addonHtmlInfo, pattern, 'tokens', 'once');
        if ~isempty(title)
            toolboxName = title{1};
        else
            toolboxName = string(missing);
        end
    catch
        toolboxName = string(missing);
    end
end
