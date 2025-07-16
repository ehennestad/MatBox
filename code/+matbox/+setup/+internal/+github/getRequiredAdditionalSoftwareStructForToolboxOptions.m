function S = getRequiredAdditionalSoftwareStructForToolboxOptions(githubRepo)
% getToolboxRequiredAddonStruct - Get a struct representing a toolbox addon
%
%   Input Arguments
%       githubRepo : specification for a github repository
%
%   Output Arguments:
%   S : (1,:) struct with following fields (from matlab.addons.toolbox.ToolboxOptions):
%       - Name	        Name of software package, specified as a string scalar or character vector
%       - Platform	    Platform to download the additional software package for, specified as "win64", "maci64", or "glnxa64"
%       - DownloadURL	URL to download the additional software package, specified as a string scalar or character vector
%       - LicenseURL	URL for the software package license file, specified as a string scalar or character vector
    
    arguments
        githubRepo (1,:) string
    end

    numAddons = numel(githubRepo);

    fieldNames = ["Name", "Platform", "DownloadURL", "LicenseURL"];
    platformNames = ["maci64", "win64", "glnxa64"];

    S = cell2struct( repmat({""}, 1, numel(fieldNames)), cellstr(fieldNames), 2 );
    S = repmat(S, 1, numAddons);

    for iAddon = 1:numAddons
        [owner, name, branchName] = matbox.setup.internal.github.parseRepositoryURL(githubRepo(iAddon));

        if ismissing(branchName) % - Get default branchname
            branchName = matbox.setup.internal.github.api.getDefaultBranch(...
                ownerName, repositoryName);
        end

        S(iAddon).Name = name;
        S(iAddon).Platform = platformNames(1);

        S(iAddon).DownloadURL = sprintf( "%s/archive/refs/heads/%s.zip", githubRepo(iAddon), branchName );

        licenseUrl = matbox.setup.internal.github.api.getLicenseHtmlUrl(name, owner);
        S(iAddon).LicenseURL = string(licenseUrl);
    end

    S = repmat(S, numel(platformNames), 1);
    for i = 2:numel(platformNames)
        [S(i,:).Platform] = deal(platformNames(i));
    end

    S = S(:);
end
