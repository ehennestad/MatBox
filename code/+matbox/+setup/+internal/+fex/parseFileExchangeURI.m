function [packageUuid, version] = parseFileExchangeURI(uri)
% parseFileExchangeURI - Get UUID and version for package
%
%   NB: This function relies on an undocumented api, and might break in the
%   future.
    
    arguments
        uri (1,:) string
    end        
    
    FEX_API_URL = "https://addons.mathworks.com/registry/v1/";
    
    packageUuid = repmat("", 1, numel(uri));
    version = repmat("latest", 1, numel(uri)); % Initialize default value

    for i = 1:numel(uri)
    
        splitUri = strsplit(uri(i), '/');
    
        packageNumber = regexp(splitUri{2}, '\d*(?=-)', 'match', 'once');
        try
            packageInfo = webread(FEX_API_URL + num2str(packageNumber));
            packageUuid(i) = packageInfo.uuid;
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

    if nargout < 2
        clear version
    end
end
