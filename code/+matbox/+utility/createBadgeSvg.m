function createBadgeSvg(label, message, color, projectRootDirectory, options)
%createBadgeSvg Create an SVG badge and save it to a file.
%
%   createBadgeSvg(label, message, color) creates a flat-style SVG badge
%   file with the given label on the left section and the message on the
%   right section. The badge is written to the ".github/badges" folder of
%   the current project root directory.
%
%   Arguments:
%       label   (string) - The label text on the left side of the badge.
%
%       message (string) - The message text on the right side of the badge.
%
%       color   (string) - Background color of the right (message) section.
%                          Must be one of: "red", "green", "blue",
%                          "orange", or "yellow".
%
%   Optional arguments:
%       projectRootDirectory (string) - Root directory of the project. Used
%           to derive the default output folder (".github/badges"). Required
%           when OutputFolder is not specified.
%
%   Optional name/value arguments:
%       OutputFolder (string) - Path to the folder where the SVG will be
%           saved. Overrides the default derived from projectRootDirectory.
%
%       FileName (string) - Base file name (without extension) for the
%           output SVG. Defaults to the label with spaces replaced by
%           underscores.
%
%   Example:
%
%       createBadgeSvg("tests", "21 passed", "green", "/path/to/project")
%
%   creates "tests.svg" in "/path/to/project/.github/badges/".

    arguments
        label (1,1) string
        message (1,1) string
        color (1,1) string {mustBeMember(color, ["red","green","blue","orange","yellow"])}
        projectRootDirectory (1,1) string = missing
        options.OutputFolder (1,1) string = missing
        options.FileName (1,1) string = missing
    end

    badgeSvg = generateBadgeSvg(label, message, color);

    if ismissing(options.OutputFolder)
        if ismissing(projectRootDirectory)
            error("MatBox:createBadgeSvg:MissingOutputPath", ...
                "Please specify project root directory or output folder")
        end
        options.OutputFolder = fullfile(projectRootDirectory, ".github", "badges");
    end

    if ~isfolder(options.OutputFolder)
        mkdir(options.OutputFolder)
    end

    if ismissing(options.FileName)
        name = strrep(label, " ", "_");
    else
        name = options.FileName;
    end

    filePath = fullfile(options.OutputFolder, name + ".svg");
    fid = fopen(filePath, "wt");
    fileCleanup = onCleanup(@() fclose(fid));

    fwrite(fid, char(badgeSvg));
    fprintf('Saved badge to %s\n', filePath)
end

% -------------------------------------------------------------------------

function svgStr = generateBadgeSvg(label, message, color)
%generateBadgeSvg Build the SVG markup string for a flat-style badge.

    colorHexMap = containers.Map( ...
        ["red",     "green",   "blue",    "orange",   "yellow"], ...
        ["#e05d44", "#97CA00", "#007ec6", "#fe7d37",  "#dfb317"]);
    colorHex = colorHexMap(color);

    labelTextLength  = computeTextWidth(label);
    messageTextLength = computeTextWidth(message);

    % Section widths in px (5 px padding each side)
    labelWidth   = labelTextLength  / 10 + 10;
    messageWidth = messageTextLength / 10 + 10;
    totalWidth   = labelWidth + messageWidth;

    % Text x-positions in scale(0.1) coordinate space
    labelTextX   = labelTextLength / 2 + 60;
    messageTextX = labelTextLength + messageTextLength / 2 + 140;

    labelEsc   = xmlEscape(label);
    messageEsc = xmlEscape(message);

    svgStr = sprintf( ...
        ['<svg xmlns="http://www.w3.org/2000/svg" ' ...
         'xmlns:xlink="http://www.w3.org/1999/xlink" ' ...
         'width="%.1f" height="20">' ...
         '<linearGradient id="smooth" x2="0" y2="100%%">' ...
         '<stop offset="0" stop-color="#bbb" stop-opacity=".1"/>' ...
         '<stop offset="1" stop-opacity=".1"/>' ...
         '</linearGradient>' ...
         '<clipPath id="round">' ...
         '<rect width="%.1f" height="20" rx="3" fill="#fff"/>' ...
         '</clipPath>' ...
         '<g clip-path="url(#round)">' ...
         '<rect width="%.1f" height="20" fill="#555"/>' ...
         '<rect x="%.1f" width="%.1f" height="20" fill="%s"/>' ...
         '<rect width="%.1f" height="20" fill="url(#smooth)"/>' ...
         '</g>' ...
         '<g fill="#fff" text-anchor="middle" ' ...
         'font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="110">' ...
         '<text x="%.1f" y="150" fill="#010101" fill-opacity=".3" ' ...
         'transform="scale(0.1)" textLength="%.1f" ' ...
         'lengthAdjust="spacing">%s</text>' ...
         '<text x="%.1f" y="140" ' ...
         'transform="scale(0.1)" textLength="%.1f" ' ...
         'lengthAdjust="spacing">%s</text>' ...
         '<text x="%.1f" y="150" fill="#010101" fill-opacity=".3" ' ...
         'transform="scale(0.1)" textLength="%.1f" ' ...
         'lengthAdjust="spacing">%s</text>' ...
         '<text x="%.1f" y="140" ' ...
         'transform="scale(0.1)" textLength="%.1f" ' ...
         'lengthAdjust="spacing">%s</text>' ...
         '</g></svg>'], ...
        totalWidth, ...                 % svg width
        totalWidth, ...                 % clipPath rect width
        labelWidth, ...                 % left rect width
        labelWidth, messageWidth, ...   % right rect x + width
        colorHex, ...                   % right rect color
        totalWidth, ...                 % gradient rect width
        labelTextX,  labelTextLength,  labelEsc, ...  % label shadow text
        labelTextX,  labelTextLength,  labelEsc, ...  % label text
        messageTextX, messageTextLength, messageEsc, ... % message shadow text
        messageTextX, messageTextLength, messageEsc);    % message text
end

% -------------------------------------------------------------------------

function width = computeTextWidth(text)
%computeTextWidth Compute total text width in SVG textLength units.
%
%   Width values are based on Verdana 11 px font metrics, scaled so that
%   dividing by 10 gives the rendered pixel width at the badge font size.

    charWidths = getCharWidths();
    chars = double(char(text));
    width = 0;
    for k = 1:numel(chars)
        idx = chars(k) - 31;  % Maps ASCII 32 (space) -> index 1, ..., ASCII 126 (~) -> index 95
        if idx >= 1 && idx <= numel(charWidths)
            width = width + charWidths(idx);
        else
            width = width + 70;  % Fallback width; approximates the mean Verdana 11 px glyph width
        end
    end
end

% -------------------------------------------------------------------------

function widths = getCharWidths()
%getCharWidths Return per-character width table for Verdana 11 px.
%
%   Values are in SVG textLength units (10x the rendered pixel width).
%   Index 1 corresponds to ASCII 32 (space); index 95 to ASCII 126 (~).

    widths = zeros(1, 95);

    % --- Space and basic punctuation (ASCII 32-47) ---
    widths(1)  = 33;   % ' '
    widths(2)  = 38;   % '!'
    widths(3)  = 45;   % '"'
    widths(4)  = 80;   % '#'
    widths(5)  = 62;   % '$'
    widths(6)  = 93;   % '%'
    widths(7)  = 78;   % '&'
    widths(8)  = 25;   % '''
    widths(9)  = 38;   % '('
    widths(10) = 38;   % ')'
    widths(11) = 55;   % '*'
    widths(12) = 80;   % '+'
    widths(13) = 37;   % ','
    widths(14) = 42;   % '-'
    widths(15) = 35;   % '.'
    widths(16) = 40;   % '/'

    % --- Digits (ASCII 48-57) ---
    widths(17) = 73;   % '0'
    widths(18) = 64;   % '1'
    widths(19) = 70;   % '2'
    widths(20) = 70;   % '3'
    widths(21) = 73;   % '4'
    widths(22) = 70;   % '5'
    widths(23) = 73;   % '6'
    widths(24) = 70;   % '7'
    widths(25) = 73;   % '8'
    widths(26) = 73;   % '9'

    % --- Punctuation (ASCII 58-64) ---
    widths(27) = 38;   % ':'
    widths(28) = 38;   % ';'
    widths(29) = 80;   % '<'
    widths(30) = 80;   % '='
    widths(31) = 80;   % '>'
    widths(32) = 63;   % '?'
    widths(33) = 125;  % '@'

    % --- Uppercase letters (ASCII 65-90) ---
    widths(34) = 76;   % 'A'
    widths(35) = 73;   % 'B'
    widths(36) = 73;   % 'C'
    widths(37) = 83;   % 'D'
    widths(38) = 66;   % 'E'
    widths(39) = 62;   % 'F'
    widths(40) = 80;   % 'G'
    widths(41) = 83;   % 'H'
    widths(42) = 28;   % 'I'
    widths(43) = 45;   % 'J'
    widths(44) = 76;   % 'K'
    widths(45) = 62;   % 'L'
    widths(46) = 89;   % 'M'
    widths(47) = 83;   % 'N'
    widths(48) = 86;   % 'O'
    widths(49) = 69;   % 'P'
    widths(50) = 86;   % 'Q'
    widths(51) = 76;   % 'R'
    widths(52) = 65;   % 'S'
    widths(53) = 66;   % 'T'
    widths(54) = 83;   % 'U'
    widths(55) = 76;   % 'V'
    widths(56) = 102;  % 'W'
    widths(57) = 71;   % 'X'
    widths(58) = 71;   % 'Y'
    widths(59) = 68;   % 'Z'

    % --- Punctuation (ASCII 91-96) ---
    widths(60) = 38;   % '['
    widths(61) = 43;   % '\'
    widths(62) = 38;   % ']'
    widths(63) = 80;   % '^'
    widths(64) = 55;   % '_'
    widths(65) = 55;   % '`'

    % --- Lowercase letters (ASCII 97-122) ---
    widths(66) = 73;   % 'a'
    widths(67) = 73;   % 'b'
    widths(68) = 60;   % 'c'
    widths(69) = 73;   % 'd'
    widths(70) = 66;   % 'e'
    widths(71) = 38;   % 'f'
    widths(72) = 73;   % 'g'
    widths(73) = 73;   % 'h'
    widths(74) = 28;   % 'i'
    widths(75) = 28;   % 'j'
    widths(76) = 66;   % 'k'
    widths(77) = 28;   % 'l'
    widths(78) = 103;  % 'm'
    widths(79) = 73;   % 'n'
    widths(80) = 73;   % 'o'
    widths(81) = 73;   % 'p'
    widths(82) = 73;   % 'q'
    widths(83) = 43;   % 'r'
    widths(84) = 56;   % 's'
    widths(85) = 45;   % 't'
    widths(86) = 73;   % 'u'
    widths(87) = 66;   % 'v'
    widths(88) = 93;   % 'w'
    widths(89) = 64;   % 'x'
    widths(90) = 66;   % 'y'
    widths(91) = 58;   % 'z'

    % --- Remaining punctuation (ASCII 123-126) ---
    widths(92) = 42;   % '{'
    widths(93) = 40;   % '|'
    widths(94) = 42;   % '}'
    widths(95) = 80;   % '~'
end

% -------------------------------------------------------------------------

function escaped = xmlEscape(text)
%xmlEscape Replace special XML characters with entity references.
    escaped = char(text);
    escaped = strrep(escaped, '&',  '&amp;');
    escaped = strrep(escaped, '<',  '&lt;');
    escaped = strrep(escaped, '>',  '&gt;');
    escaped = strrep(escaped, '"',  '&quot;');
    escaped = strrep(escaped, '''', '&apos;');
end
