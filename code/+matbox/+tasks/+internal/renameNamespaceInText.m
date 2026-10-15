function text = renameNamespaceInText(text, sourceNamespace, targetNamespace)
%renameNamespaceInText - Rename the references to a namespace in code
%   text = matbox.tasks.internal.renameNamespaceInText(text,sourceNamespace,targetNamespace)
%   replaces each reference to sourceNamespace in text, such as
%   "webprogress.upload", with the same reference to targetNamespace, such
%   as "mytoolbox.external.webprogress.upload". Code, strings and comments
%   are all renamed. The class of text is kept.
%
%   A reference is the namespace name followed by "." and a letter or "*"
%   (as in "import webprogress.*"). The name is not a reference when a
%   letter, digit, "_", ".", "/" or "\" comes before it, which leaves
%   longer names ("mywebprogress.x"), property access ("obj.webprogress.x")
%   and paths ("src/webprogress.zip") unchanged. Error identifiers
%   ("webprogress:upload:Failed") have no "." after the name and are also
%   unchanged. A variable with the same name as the namespace is
%   indistinguishable from the namespace and is renamed.
%
%   See also matbox.tasks.vendorPackage, regexprep

    arguments
        text {mustBeTextScalar}
        sourceNamespace (1,1) string {mustBeNamespaceName}
        targetNamespace (1,1) string {mustBeNamespaceName}
    end

    % The character classes are spelled out because \w may also match
    % non-ASCII letters, and the text can be the raw bytes of a file.
    notInsideLongerName = "(?<![A-Za-z0-9_.\\/])";
    memberFollows = "\.(?=[A-Za-z*])";

    pattern = notInsideLongerName ...
        + regexptranslate("escape", sourceNamespace) + memberFollows;

    % A namespace name has no "$" or "\", the two characters with a special
    % meaning in a replacement, so the replacement needs no escaping.
    text = regexprep(text, pattern, targetNamespace + ".");
end

function mustBeNamespaceName(name)
%mustBeNamespaceName - Validate that a name is a dot-separated list of identifiers
    isValid = all(arrayfun(@isvarname, split(name, ".")));
    if ~isValid
        error("MatBox:VendorPackage:InvalidNamespaceName", ...
            """%s"" is not a namespace name. A namespace name is one or " + ...
            "more MATLAB identifiers joined with ""."".", name)
    end
end
