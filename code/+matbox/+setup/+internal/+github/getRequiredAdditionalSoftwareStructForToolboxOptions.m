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
    
    S = cell2struct( repmat({""}, 1, numel(fieldNames)), cellstr(fieldNames), 2 );
    S = repmat(S, 1, numAddons);

    for iAddon = 1:numAddons
        [owner, name, branchName] = matbox.setup.internal.github.parseRepositoryURL(githubRepo(iAddon));
        if ismissing(branchName); branchName = "main"; end
        S(iAddon).Name = name;
        S(iAddon).Platform = 'maci64';

        S(iAddon).DownloadURL = sprintf( '%s/archive/refs/heads/%s.zip', githubRepo(iAddon), branchName );

        licenseUrl = matbox.setup.internal.github.api.getLicenseHtmlUrl(name, owner);
        S(iAddon).LicenseURL = licenseUrl;
    end
end
