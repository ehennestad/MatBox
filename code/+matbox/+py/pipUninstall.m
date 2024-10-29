function pipUninstall(packageName)
    arguments
        packageName (1,1) string
    end

    args = py.list({py.sys.executable, "-m", "pip", "uninstall", "--yes", packageName});
    status = py.subprocess.check_call(args);

    if double(status) ~= 0
        error('Something went wrong')
    end
end
