function S = getToolboxRequiredAddonStruct(fexURI)
% getToolboxRequiredAddonStruct - Get a struct representing a toolbox addon
%
%   Input Arguments
%       packageId : (number) ID of package from FileExchange (not uuid)
%
%   Output Arguments:
%   S : (1,:) struct with following fields (from matlab.addons.toolbox.ToolboxOptions):
%    -  Name	        Name of required add-on, specified as a string scalar or character vector
%    -  Identifier	    Unique identifier of the add-on, specified as a string scalar or character vector
%    -  EarliestVersion	Earliest add-on version that the toolbox is compatible with, specified as a string scalar or character vector
%    -  LatestVersion	Latest add-on version that the toolbox is compatible with, specified as string scalar or character vector
%    -  DownloadURL 	URL to download the add-on, specified as

    arguments
        fexURI (1,:) string
    end

    numAddons = numel(fexURI);

    fieldNames = ["Name", "Identifier", "EarliestVersion", "LatestVersion", "DownloadURL"];
    
    S = cell2struct( repmat({""}, 1, numel(fieldNames)), cellstr(fieldNames), 2 );
    S = repmat(S, 1, numAddons);

    for iAddon = 1:numAddons
        [addonUuid, version] = matbox.setup.internal.fex.parseFileExchangeURI(fexURI(iAddon));
        
        addonMetadata = matbox.setup.internal.fex.getAddonMetadata(addonUuid);

        S(iAddon).Name = addonMetadata.name;
        S(iAddon).Identifier = addonUuid;
        if version ~= "latest"
            S(iAddon).EarliestVersion = version;
            S(iAddon).LatestVersion = version;
        else
            S(iAddon).EarliestVersion = "earliest";
            S(iAddon).LatestVersion = "latest";
        end
        S(iAddon).DownloadURL = ""; %addonMetadata.downloadUrl;
    end
end
