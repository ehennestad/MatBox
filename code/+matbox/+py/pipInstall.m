function pipInstall(packageName, options)
% pipInstall - Install a specified Python package using pip from within MATLAB
%
% Syntax:
%   pipInstall(packageName)
%
% Description:
%   This function installs a specified Python package using `pip` from the
%   Python executable configured in MATLAB. If the installation fails, an
%   error is thrown. After installation, it checks if the install location
%   is in the `PYTHONPATH` and adds it if necessary.
%
% Input:
%   packageName - (string) The name of the Python package to install.
%
% Exceptions:
%   Throws an error with ID 'MatBox:UnableToInstallPythonPackage' if the
%   package cannot be installed.
%
% Notes:
%   Python must be set up and configured in MATLAB using `pyenv`, and `pip`
%   must be available in the Python environment.
%
% Example:
%   % Install the 'numpy' package
%   matbox.py.pipInstall("numpy")
%
% See also:
%   matbox.py.getPythonExecutable, matbox.py.getPackageInfo

    arguments
        packageName (1,1) string
        options.Update (1,1) logical = false 
    end

    pythonExecutable = matbox.py.getPythonExecutable();

    systemCommand = sprintf("%s -m pip install %s", pythonExecutable, packageName);
    if options.Update
        systemCommand = systemCommand + " --upgrade";
    end
    [status, m]  = system(systemCommand);

    if status ~= 0
        error("MatBox:UnableToInstallPythonPackage", ...
            "Could not use pip to install %s", packageName)
    end

    % Add install location to PYTHONPATH if it is not already there
    installLocation = matbox.py.getPackageInfo(packageName, "Field", "Location");

    checkAndUpdatePythonPath(installLocation, packageName) % Local function
end

function checkAndUpdatePythonPath(installLocation, packageName)

    pyPath = py.sys.path();
    pyPath = string(pyPath);
    pyPath(pyPath=="") = [];

    if ~any( contains(pyPath, installLocation) )
        fprintf("Adding %s location to pythonpath\n", packageName)
        py.sys.path().append(installLocation)
    end
end
