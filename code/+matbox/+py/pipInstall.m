function pipInstall(packageName)
    arguments
        packageName (1,1) string
    end

    args = py.list({py.sys.executable, "-m", "pip", "install", packageName});
    py.subprocess.check_call(args);
end
