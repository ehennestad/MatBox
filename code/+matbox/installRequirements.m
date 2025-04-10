function installRequirements(toolboxFolder, mode, options)

    arguments
        toolboxFolder (1,1) string {mustBeFolder}
    end
    arguments (Repeating)
        mode string {mustBeMember(mode, ["force", "f", "update", "u"])}
    end
    
    arguments
        % Tentative, not implemented yet!
        options.UseDefaultInstallationLocation (1,1) logical = true
        options.UpdateSearchPath (1,1) logical = true
        options.SaveSearchPath (1,1) logical = true
        options.InstallationLocation (1,1) string = matbox.setup.internal.getDefaultAddonFolder()
        options.Verbose (1,1) logical = true
    end
    
    % Parse mode/flags
    mode = string(mode);
    doUpdate = any(strcmp(mode, 'update')) || any( strcmp(mode, 'u') );
    
    installationLocation = options.InstallationLocation;
    if ~isfolder(installationLocation); mkdir(installationLocation); end
        
    reqs = matbox.setup.internal.getRequirements(toolboxFolder);
    for i = 1:numel(reqs)
        switch reqs(i).Type
            
            case 'GitHub'
                [repoUrl, branchName] = parseGitHubUrl(reqs(i).URI);
                matbox.setup.internal.installGithubRepository( ...
                    repoUrl, ...
                    branchName, ...
                    "AddToPath", options.UpdateSearchPath, ...
                    "Update", doUpdate, ...
                    "Verbose", options.Verbose)

            case 'FileExchange'
                [packageUuid, version] = getFEXPackageSpecification( reqs(i).URI );
                matbox.setup.internal.installFexPackage(...
                    packageUuid, ...
                    installationLocation, ...
                    'Version', version, ...
                    "AddToPath", options.UpdateSearchPath, ...
                    "Verbose", options.Verbose);

            case 'Unknown'
                continue
        end
    end
    if options.UpdateSearchPath && options.SaveSearchPath
        savepath()
    end
end

function [packageUuid, version] = getFEXPackageSpecification(uri)
% getFEXPackageSpecification - Get UUID and version for package
%
%   NB: This function relies on an undocumented api, and might break in the
%   future.

    version = "latest"; % Initialize default value

    FEX_API_URL = "https://addons.mathworks.com/registry/v1/";
    
    splitUri = strsplit(uri, '/');

    packageNumber = regexp(splitUri{2}, '\d*(?=-)', 'match', 'once');
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

function [repoUrl, branchName] = parseGitHubUrl(repoUrl)
% parseGitHubUrl - Extract branchname if present
    branchName = string(missing);
    if contains(repoUrl, '@')
        splitUrl = strsplit(repoUrl, '@');
        repoUrl = splitUrl{1};
        branchName = splitUrl{2};
    end
end
