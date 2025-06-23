function options = getGithubWebOptions(customHeaders)
    % getGithubWebOptions Returns weboptions with GitHub authentication if available
    %
    % Inputs:
    %   customHeaders - Optional cell array of custom header fields to include
    %
    % Outputs:
    %   options - weboptions object with authentication headers if token is available
    
    arguments
        customHeaders = {}
    end
    
    % Get GITHUB_TOKEN from environment variables
    token = getenv('GITHUB_TOKEN');
    
    % Initialize options
    options = weboptions('UserAgent', 'MATLAB WebClient');
    
    % Add custom headers if provided
    if ~isempty(customHeaders)
        options.HeaderFields = customHeaders;
    end
    
    % Add authentication header if token is available
    if ~isempty(token)
        if isempty(options.HeaderFields)
            options.HeaderFields = {'Authorization', ['token ' token]};
        else
            options.HeaderFields = [options.HeaderFields; {'Authorization', ['token ' token]}];
        end
    end
end
