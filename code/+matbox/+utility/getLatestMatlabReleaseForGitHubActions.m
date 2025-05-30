function versionStr = getLatestMatlabReleaseForGitHubActions(includePrerelease)
% getLatestMatlabReleaseForGitHubActions - Retrieve the latest MATLAB release string
%
% Syntax:
%   versionStr = matbox.utility.getLatestMatlabReleaseForGitHubActions()
%
% Input Arguments:
%   includePrerelease - A boolean flag indicating whether to include 
%                       pre-release versions in the result.
%
% Output Arguments:
%   versionStr - A string containing the latest MATLAB version number.

    arguments
        includePrerelease (1,1) logical = false
    end
    
    apiUrl = "https://ssd.mathworks.com/supportfiles/ci/matlab-release/v0/latest";
    
    if includePrerelease
        apiUrl = apiUrl + "-including-prerelease";
    end
    versionStr = webread(apiUrl);
end
