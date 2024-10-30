function packageInfo = getPackageInfo(packageName, options)
% getPackageInfo - Retrieve information about an installed Python package
%
% Syntax:
%   packageInfo = getPackageInfo(packageName)
%   packageInfo = getPackageInfo(packageName, 'Field', fieldName)
%
% Description:
%   This function uses the `pip show` command to retrieve metadata about an
%   installed Python package, such as version, location, and dependencies.
%   It returns this information as a structure. An optional argument allows
%   extraction of a specific field from the package information.
%
% Input:
%   packageName - (string) The name of the Python package to query.
%
%   options:
%     Field - (string, optional) The name of a specific field to retrieve
%             from the package info. If provided, only the specified field
%             value is returned.
%
% Output:
%   packageInfo - (struct or string) A structure containing package information.
%                 If the 'Field' option is specified, a string with the
%                 specific field’s value is returned.
%
% Exceptions:
%   Throws an error with ID 'MatBox:PackageNotFound' if the specified package
%   is not installed.
%
% Example:
%   % Get all information about the 'numpy' package
%   packageInfo = matbox.py.getPackageInfo("numpy")
%
%   % Get only the 'Location' field of the 'numpy' package info
%   packageLocation = matbox.py.getPackageInfo("numpy", 'Field', 'Location')
%
% Requirements:
%   Python must be installed and accessible from MATLAB with `pip`.
%
% See also:
%   matbox.py.getPythonExecutable

    arguments
        packageName (1,1) string
        options.Field (1,1) string = missing
    end

    pythonExecutable = matbox.py.getPythonExecutable();

    sysCommand = sprintf("%s -m pip show %s", pythonExecutable, packageName);
    [status, cmdout]  = system(sysCommand);

    if status ~= 0
        error('MatBox:PackageNotFound', 'The package "%s" was not found', packageName)
    end

    % Parse output:
    splitOutput = string( splitlines(cmdout) );
    splitOutput(splitOutput=="") = [];

    packageInfo = struct;
    currentField = "";
    currentValue = "";

    % Loop over each line to build the structure, handling multi-line values
    for i = 1:numel(splitOutput)
        line = splitOutput{i};

        if ~startsWith(line, " ") && contains(line, ': ') % New field detected
            if currentField ~= "" % Save previous field
                packageInfo.(currentField) = strtrim(currentValue);
            end

            % Extract new field name and value
            splitLine = split(line, ': ');
            currentField = matlab.lang.makeValidName(strtrim(splitLine{1}));
            if numel(splitLine) > 2
                currentValue = string( strtrim(join(splitLine(2:end), ': ')) );
            else
                currentValue = string( strtrim(splitLine{2}) );
            end

        else % Continuation of the previous field (multi-line)
            currentValue = currentValue + newline + strtrim(line);
        end
    end

    % Save the last field
    if currentField ~= ""
        packageInfo.(currentField) = strtrim(currentValue);
    end

    % Postprocess Requires, Required_by
    packageInfo.Requires = split(packageInfo.Requires, ', ');
    packageInfo.Required_by = split(packageInfo.Required_by, ', ');
    
    if ~ismissing( options.Field )
        packageInfo = packageInfo.(options.Field);        
    end
end
