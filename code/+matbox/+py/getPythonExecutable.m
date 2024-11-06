function pythonExecutable = getPythonExecutable()
% getPythonExecutable - Get the path to the Python executable configured in MATLAB
%
% Syntax:
%   pythonExecutable = matbox.py.getPythonExecutable()
%
% Description:
%   This function returns the file path to the Python executable currently
%   configured in MATLAB. It checks if Python is set up in MATLAB through
%   the pyenv function and throws an error if Python is not installed or
%   configured.
%
% Output:
%   pythonExecutable - (char) The path to the Python executable.
%
% Exceptions:
%   Throws an error with ID 'MatBox:PythonNotInstalled' if Python is not
%   installed or configured in MATLAB.
%
% Notes:
%   This function uses the `pyenv` function introduced in MATLAB R2019b.
%   In earlier releases, this function will not work.
%
% Example:
%   % Retrieve the path to the configured Python executable
%   pythonExecutable = matbox.py.getPythonExecutable()
%
% Requirements:
%   Python must be installed and configured in MATLAB.
%
% See also:
%   pyenv

    % Todo: What if MATLAB release is older than R2019b when pyenv was
    % introduced?
    
    pythonInfo = pyenv;
    
    if pythonInfo.Version == ""
        error("MatBox:PythonNotInstalled", "Python not installed.")
    end

    pythonExecutable = pythonInfo.Executable;
end
