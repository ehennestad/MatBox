function version = libVersion(packageName)
    arguments
        packageName (1,1) string
    end

    version = py.importlib.metadata.version(packageName);
end
