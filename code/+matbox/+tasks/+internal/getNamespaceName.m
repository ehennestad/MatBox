function namespaceName = getNamespaceName(folderPath)
%getNamespaceName - Get the name of the namespace that a folder defines
%   namespaceName = matbox.tasks.internal.getNamespaceName(folderPath)
%   returns the namespace name given by the namespace folders at the end
%   of folderPath, joined with ".". Both "/" and "\" are accepted as
%   separators. The result is "" if the last folder is not a namespace
%   folder.
%
%   Example: Namespace of a nested namespace folder
%       folderPath = "src/mytoolbox/+mytoolbox/+external/+webprogress";
%       name = matbox.tasks.internal.getNamespaceName(folderPath)
%       % name = "mytoolbox.external.webprogress"
%
%   See also matbox.tasks.vendorPackage

    arguments
        folderPath (1,1) string
    end

    NAMESPACE_PREFIX = "+";

    folderNames = split(replace(folderPath, "\", "/"), "/");
    folderNames(folderNames == "") = [];

    % Only the unbroken run of namespace folders at the end of the path
    % counts, because a namespace folder below an ordinary folder starts a
    % new namespace.
    isNamespaceFolder = startsWith(folderNames, NAMESPACE_PREFIX);
    lastOrdinaryFolder = find(~isNamespaceFolder, 1, "last");
    if isempty(lastOrdinaryFolder)
        lastOrdinaryFolder = 0;
    end
    namespaceFolders = folderNames(lastOrdinaryFolder+1:end);

    % join returns <missing> for an empty array, so that case is set apart.
    isInNamespace = ~isempty(namespaceFolders);
    if isInNamespace
        namespaceName = join(extractAfter(namespaceFolders, NAMESPACE_PREFIX), ".");
    else
        namespaceName = "";
    end
end
