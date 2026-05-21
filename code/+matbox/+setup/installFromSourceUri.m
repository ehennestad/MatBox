function installResult = installFromSourceUri(sourceUri, options)
%installFromSourceUri Install dependency from a supported source URI.
%
%   installResult = matbox.setup.installFromSourceUri(sourceUri)
%   installs from a supported URI and returns a normalized install result.
%
%   Input Arguments:
%       sourceUri (string) - URI for package installation
%       Supported URI schemes:
%           - fex://<id-title>[/version]
%           - https://github.com/<owner>/<repo>[@branch]
%
%   Output Arguments:
%       installResult (struct) - Structure with the following fields:
%           - FilePath - Path to location where toolbox is installed
%           - InstallationType - Type of installation (folder or mltbx)
%           - ToolboxIdentifier - UUID for toolbox (FEX only)

    arguments
        sourceUri (1,1) string
        options.InstallationLocation (1,1) string = matbox.setup.internal.getDefaultAddonFolder()
        options.AddToPath (1,1) logical = true
        options.Update (1,1) logical = false
        options.Verbose (1,1) logical = true
        options.AgreeToLicense (1,1) logical = false
    end

    if startsWith(sourceUri, "fex://")
        [packageUuid, title, version] = getFEXPackageSpecification(sourceUri);
        [packageTargetFolder, installationType] = matbox.setup.internal.installFexPackage( ...
            packageUuid, ...
            options.InstallationLocation, ...
            "Title", title, ...
            "Version", version, ...
            "AddToPath", options.AddToPath, ...
            "Verbose", options.Verbose, ...
            "AgreeToLicense", options.AgreeToLicense);

        installResult = struct( ...
            "FilePath", packageTargetFolder, ...
            "InstallationType", installationType, ...
            "ToolboxIdentifier", packageUuid);

    elseif startsWith(sourceUri, "https://github.com/")
        [repoUrl, branchName] = parseGitHubSourceUri(sourceUri);
        repoTargetFolder = matbox.setup.internal.installGithubRepository( ...
            repoUrl, ...
            branchName, ...
            "InstallationLocation", options.InstallationLocation, ...
            "AddToPath", options.AddToPath, ...
            "Update", options.Update, ...
            "Verbose", options.Verbose);

        installResult = struct( ...
            "FilePath", repoTargetFolder, ...
            "InstallationType", "folder", ...
            "ToolboxIdentifier", "");

    else
        error("MatBox:Setup:UnsupportedSourceUri", ...
            'Unsupported source URI: %s', sourceUri)
    end

    if ~nargout
        clear installResult
    end
end

function [packageUuid, title, version] = getFEXPackageSpecification(uri)
% getFEXPackageSpecification - Get UUID and version for package
%
%   NB: This function relies on an undocumented api, and might break in the
%   future.

    version = "latest"; % Initialize default value

    FEX_API_URL = "https://addons.mathworks.com/registry/v1/";

    splitUri = strsplit(uri, '/');

    packageNumber = regexp(splitUri{2}, '\d*(?=-)', 'match', 'once');
    title = extractAfter(splitUri{2}, [packageNumber '-']);
    try
        packageInfo = webread(FEX_API_URL + num2str(packageNumber));
        packageUuid = packageInfo.uuid;
    catch ME
        switch ME.identifier
            case 'MATLAB:webservices:HTTP404StatusCodeError'
                error('FEX package with identifier "%s" was not found', splitUri{2})
            otherwise
                rethrow(ME)
        end
    end

    if numel(splitUri) == 3
        version = string( splitUri{3} );
        assert( any(strcmp(packageInfo.versions, version) ), ...
            'Specified version "%s" is not supported for FEX package "%s"', ...
            version, splitUri{2});
    end
end

function [repoUrl, branchName] = parseGitHubSourceUri(repoUrl)
% parseGitHubSourceUri - Extract branchname if present
    branchName = string(missing);
    if contains(repoUrl, '@')
        splitUrl = strsplit(repoUrl, '@');
        repoUrl = splitUrl{1};
        branchName = splitUrl{2};
    end
end
