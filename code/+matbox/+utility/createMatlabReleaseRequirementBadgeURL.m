function logoUrl = createMatlabReleaseRequirementBadgeURL(minRelease, options)
% createMatlabReleaseRequirementBadgeURL - Creates a URL for a MATLAB 
% release requirement badge with customizable colors.
%
% Syntax:
%   logoUrl = matbox.utility.createMatlabReleaseRequirementBadgeURL(minRelease, options) 
%
% Input Arguments:
%   minRelease (1,1) string - The minimum MATLAB release version required.
%   options (struct) - Structure containing optional parameters:
%       LogoColor (1,1) string - Custom color for the logo (must be a 
%           hex code or CSS color name). Default is missing.
%       Color (1,1) string - Badge color in hex format. Default is "2A5F98".
%       LabelColor (1,1) string - Color for the label background in hex 
%           format. Default is "C95C2E".
%
% Output Arguments:
%   logoUrl (string) - The generated URL for the badge that can be used
%       in markdown or as an image source.

    arguments
        minRelease (1,1) string
        options.LogoColor (1,1) string = missing % mustBeHex or mustBeCssColorName
        options.Color (1,1) string = "2A5F98" % blue
        options.LabelColor (1,1) string = "C95C2E" % "orange" % 
    end

    logoPath = fullfile(matbox.toolboxdir(), 'resources', 'matlab-logo.svg');
    svgLogoStr = fileread(logoPath);

    if ~ismissing(options.LogoColor)
        svgLogoStr = strrep(svgLogoStr, 'fill="#ffffff"', ...
            sprintf('fill="%s"', options.LogoColor));
    end
    
    logoRaw = matlab.net.base64encode(svgLogoStr);
    
    logoUrl = sprintf([...
        'https://img.shields.io/badge/', ...
        'MATLAB-%%3E%%3D%s-blue', ...
        '?logo=data:image/svg%%2bxml;base64,%s', ...
        '&label=MATLAB&labelColor=%s&color=%s'], ...
        minRelease, logoRaw, options.LabelColor, options.Color);

    if ~nargout
        clipboard("copy", logoUrl)
        clear logoUrl
    end
end
