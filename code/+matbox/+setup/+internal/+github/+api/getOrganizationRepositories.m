function reposStruct = getOrganizationRepositories(organizationName)
    % getOrgRepositories Retrieves all repositories for a given organization.
    %
    % Inputs:
    %   organizationName - Name of the GitHub organization
    %
    % Outputs:
    %   reposStruct - A struct array with fields 'name' and 'visibility'.
    
    arguments
        organizationName (1,1) string
    end

    % Get GITHUB_TOKEN from environment variables
    token = getenv('GITHUB_TOKEN');
    
    if isempty(token)
        warning('GITHUB_TOKEN environment variable is not set. Retrieving public repositories');
    end
    
    organizationName = char(organizationName);

    % GitHub API endpoint for organization repositories
    url = ['https://api.github.com/orgs/' organizationName '/repos'];
    
    % Create the web options with the authorization header
    options = weboptions('HeaderFields', {'Authorization', ['token ' token]}, ...
                         'ContentType', 'json', ...
                         'UserAgent', 'MATLAB WebClient', ...
                         'Timeout', 15);

    if isempty(token)
        options.HeaderFields = [];
    end
    
    % Fetch repositories information from GitHub
    data = webread(url, options);
    
    % Initialize an empty struct
    reposStruct = struct('name', {}, 'visibility', {});
    
    % Parse the data
    for i = 1:numel(data)
        reposStruct(i).name = data(i).name;  % Repository name
        if data(i).private
            reposStruct(i).visibility = 'private';
        else
            reposStruct(i).visibility = 'public';
        end
    end
end
