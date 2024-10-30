function pipUninstall(packageName)
    arguments
        packageName (1,1) string
    end

    pythonExecutable = matbox.py.getPythonExecutable();

    systemCommand = sprintf("%s -m pip uninstall --yes %s", pythonExecutable, packageName);
    [status, ~]  = system(systemCommand);

    if status ~= 0
        error("MatBox:UnableToUninstallPythonPackage", ...
            "Could not use pip to uninstall %s", packageName)
    end
end
