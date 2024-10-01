function S = getAddonMetadata(packageUuid)
% getAddonMetadata - Retrieve metadata from FileExchange for AddOn given uuid
%
%   Input Arguments:
%       packageUuid : (1,1) string
%                     The uuid for a FEX package
%
%   Output Arguments:
%       metadata    : (1,1) struct
%                     A struct with the following fields:
%       - name
%       - author
%       - version
%       - installationFolder
%       - displayType

    fex = matlab.addons.repositories.FileExchangeRepository();
    addonUrl = fex.getAddonURL(packageUuid);

    % Parse the xml if the URL points to an XML document
    if endsWith(addonUrl, '.xml')

        [filepath, C] = matbox.setup.internal.utility.tempsave(addonUrl);
        S = readstruct(filepath); delete(C) % Read XML

        if isdatetime(S.version)
            % Version is wrongly converted to date
            S.Version = sprintf('%d.%d.%d', day(S.version), month(S.version), year(S.version));
        end
        S.downloadUrl = extractBefore(S.downloadUrl, '?'); % Strip query params...

    elseif endsWith(addonUrl, '/mltbx')
        [filepath, C] = matbox.setup.internal.utility.tempsave(addonUrl);
        mdReader = matlab.internal.addons.metadata.MltbxMetadataReader(filepath);

        S.name = mdReader.getName();
        S.author = mdReader.getAuthor();
        S.version = mdReader.getVersion();
        S.displayType = "Toolboxes";
        S.installationFolder = "Toolboxes";
        S.downloadUrl = addonUrl;
        delete(C)
    else
        error('SetupTools:MetadataNotAvailable', ...
            'Metadata for package with id "%s" was not found', packageUuid)
    end
end
