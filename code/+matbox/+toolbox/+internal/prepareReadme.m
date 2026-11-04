function text = prepareReadme(text, options)
% prepareReadme - Prepare Markdown README text for display outside the repository
%
%   text = matbox.toolbox.internal.prepareReadme(text, Name=Value) returns
%   the README text with two changes, both made outside fenced code blocks:
%
%   - Badge lines are removed. A badge line is a line made only of Markdown
%     images, linked or not, in the leading block of the README: the lines
%     before the first line of prose. Blank lines, headings and lines of
%     HTML tags do not end the leading block. Runs of blank lines are then
%     collapsed to one, and leading blank lines are removed.
%
%   - Relative destinations become absolute URLs in the repository at Ref.
%     This applies to inline links and images, reference definitions, and
%     the HTML attributes href, src and srcset:
%       image   https://raw.githubusercontent.com/<owner>/<repo>/<Ref>/<path>
%               for a repository on github.com, else
%               <RepositoryURL>/raw/<Ref>/<path>
%       folder  <RepositoryURL>/tree/<Ref>/<path>
%       file    <RepositoryURL>/blob/<Ref>/<path>
%     An image is the destination of a Markdown image, of src or srcset, or
%     of a reference definition that names an image file. A folder is a
%     path that ends with "/" or is a folder under ProjectRoot. A leading
%     "./" or "/" is removed, and a query or fragment is kept. Destinations
%     that are empty, have a scheme (https:, mailto:), or start with "#",
%     "//" or "../" are left unchanged.
%
%   Name-Value Arguments:
%     RepositoryURL - Web URL of the repository, e.g.
%                     "https://github.com/<owner>/<repo>". Without it,
%                     links are left unchanged.
%     Ref           - Branch, tag or commit the links point to, e.g.
%                     "v1.2.3". Without it, links are left unchanged.
%     ProjectRoot   - Folder of the repository on disk, used to tell
%                     folders from files.

    arguments
        text (1,1) string
        options.RepositoryURL (1,1) string = ""
        options.Ref (1,1) string = ""
        options.ProjectRoot (1,1) string = ""
    end

    hasFinalNewline = endsWith(text, newline);
    lines = splitlines(text);
    if hasFinalNewline
        lines(end) = [];
    end

    isCode = findCodeBlockLines(lines);
    isBadge = findBadgeLines(lines, isCode);

    if options.RepositoryURL ~= "" && options.Ref ~= ""
        for iLine = find(~isCode & ~isBadge)'
            lines(iLine) = makeDestinationsAbsolute(lines(iLine), options);
        end
    end

    lines(isBadge) = [];
    isCode(isBadge) = [];
    lines = collapseBlankLines(lines, isCode);
    if isempty(lines)
        text = "";
        return
    end

    text = join(lines, newline);
    if hasFinalNewline
        text = text + newline;
    end
end

function isCode = findCodeBlockLines(lines)
% findCodeBlockLines - Find the lines of fenced code blocks, fences included
%
%   A fence is three or more backticks or tildes, indented by at most three
%   spaces. A block is closed by a fence of the same character that is at
%   least as long as the opening fence.

    isCode = false(size(lines));
    openingFence = "";
    for iLine = 1:numel(lines)
        if openingFence == ""
            fence = regexp(lines(iLine), '^ {0,3}(?<fence>`{3,}|~{3,})', 'names', 'once');
            if ~isempty(fence)
                openingFence = fence.fence;
                isCode(iLine) = true;
            end
        else
            isCode(iLine) = true;
            fenceCharacter = regexptranslate("escape", extractBefore(openingFence, 2));
            closingPattern = "^ {0,3}" + fenceCharacter + "{" + strlength(openingFence) + ",}\s*$";
            if ~isempty(regexp(lines(iLine), closingPattern, 'once'))
                openingFence = "";
            end
        end
    end
end

function isBadge = findBadgeLines(lines, isCode)
% findBadgeLines - Find the image-only lines of the leading block

    markdownImage = '\[!\[[^\]]*\]\([^)]*\)\]\([^)]*\)|!\[[^\]]*\]\([^)]*\)';
    heading = '^ {0,3}#{1,6}(\s|$)';
    htmlTags = '^\s*<.*>\s*$';

    isBadge = false(size(lines));
    for iLine = 1:numel(lines)
        line = lines(iLine);
        isImageOnly = strip(line) ~= "" && strip(regexprep(line, markdownImage, "")) == "";
        isLeadingBlockLine = strip(line) == "" || isImageOnly ...
            || ~isempty(regexp(line, heading, 'once')) ...
            || ~isempty(regexp(line, htmlTags, 'once'));
        if isCode(iLine) || ~isLeadingBlockLine
            break
        end
        isBadge(iLine) = isImageOnly;
    end
end

function lines = collapseBlankLines(lines, isCode)
% collapseBlankLines - Keep at most one blank line in a row outside code blocks

    isBlank = strip(lines) == "" & ~isCode;
    isRepeatedBlank = isBlank & [true; isBlank(1:end-1)];
    lines(isRepeatedBlank) = [];
end

function line = makeDestinationsAbsolute(line, options)
% makeDestinationsAbsolute - Make the relative destinations of one line absolute

    % Markdown images come first. The link pattern also matches the "](" of
    % an image, and finds its destination already absolute.
    line = replaceDestinations(line, '!\[[^\]]*\]\(\s*(<[^>]*>|[^)\s]+)', "image", options);
    line = replaceDestinations(line, '\]\(\s*(<[^>]*>|[^)\s]+)', "link", options);
    line = replaceDestinations(line, '^ {0,3}\[[^\]]+\]:\s*(<[^>]*>|\S+)', "reference", options);
    line = replaceDestinations(line, '\shref\s*=\s*"([^"]*)"', "link", options);
    line = replaceDestinations(line, "\shref\s*=\s*'([^']*)'", "link", options);
    line = replaceDestinations(line, '\ssrc\s*=\s*"([^"]*)"', "image", options);
    line = replaceDestinations(line, "\ssrc\s*=\s*'([^']*)'", "image", options);
    line = replaceDestinations(line, '\ssrcset\s*=\s*"([^"]*)"', "srcset", options);
    line = replaceDestinations(line, "\ssrcset\s*=\s*'([^']*)'", "srcset", options);
end

function line = replaceDestinations(line, pattern, kind, options)
% replaceDestinations - Replace the destination captured by the single token of pattern

    tokenExtents = regexp(line, pattern, 'tokenExtents');

    % Replace from the end of the line, so the extents of earlier matches
    % stay valid.
    for iMatch = numel(tokenExtents):-1:1
        extent = tokenExtents{iMatch};
        if extent(2) < extent(1)
            continue % Empty destination
        end
        destination = extractBetween(line, extent(1), extent(2));
        if kind == "srcset"
            newDestination = absoluteSrcset(destination, options);
        else
            newDestination = absoluteDestination(destination, kind, options);
        end
        if newDestination ~= destination
            line = replaceBetween(line, extent(1), extent(2), newDestination);
        end
    end
end

function srcset = absoluteSrcset(srcset, options)
% absoluteSrcset - Make each image candidate of a srcset value absolute
%
%   A candidate is a URL, optionally followed by a width or density
%   descriptor, and candidates are separated by commas.

    candidates = strip(split(srcset, ","));
    for iCandidate = 1:numel(candidates)
        parts = split(candidates(iCandidate));
        parts(1) = absoluteDestination(parts(1), "image", options);
        candidates(iCandidate) = join(parts, " ");
    end
    srcset = join(candidates, ", ");
end

function destination = absoluteDestination(destination, kind, options)
% absoluteDestination - Make one link or image destination absolute

    if startsWith(destination, "<") && endsWith(destination, ">")
        innerDestination = extractBetween(destination, 2, strlength(destination) - 1);
        destination = "<" + absoluteDestination(innerDestination, kind, options) + ">";
        return
    end

    hasScheme = ~isempty(regexp(destination, '^[A-Za-z][A-Za-z0-9+.\-]*:', 'once'));
    if destination == "" || hasScheme || startsWith(destination, ["#", "//", "../"])
        return
    end

    % Keep a query or fragment as it is
    suffixStart = regexp(destination, '[?#]', 'once');
    if isempty(suffixStart)
        repositoryPath = destination;
        suffix = "";
    else
        repositoryPath = extractBefore(destination, suffixStart);
        suffix = extractAfter(destination, suffixStart - 1);
    end
    repositoryPath = regexprep(repositoryPath, '^(\./)+', '');
    repositoryPath = regexprep(repositoryPath, '^/', '');
    if repositoryPath == ""
        return
    end

    if kind == "reference"
        imageExtensions = [".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"];
        if endsWith(lower(repositoryPath), imageExtensions)
            kind = "image";
        else
            kind = "link";
        end
    end

    repositoryUrl = options.RepositoryURL;
    if kind == "image"
        githubPrefix = "https://github.com/";
        if startsWith(repositoryUrl, githubPrefix)
            url = "https://raw.githubusercontent.com/" + extractAfter(repositoryUrl, githubPrefix) ...
                + "/" + options.Ref + "/" + repositoryPath;
        else
            url = repositoryUrl + "/raw/" + options.Ref + "/" + repositoryPath;
        end
    elseif endsWith(repositoryPath, "/") ...
            || (options.ProjectRoot ~= "" && isfolder(fullfile(options.ProjectRoot, repositoryPath)))
        url = repositoryUrl + "/tree/" + options.Ref + "/" + regexprep(repositoryPath, '/+$', '');
    else
        url = repositoryUrl + "/blob/" + options.Ref + "/" + repositoryPath;
    end
    destination = url + suffix;
end
