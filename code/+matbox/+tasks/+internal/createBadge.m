function createBadge(label, message, color, projectRootDirectory)
% createBadge - Write a badge as JSON or as a legacy SVG file
%
%   Writes a badge description as a JSON file (docs/reports/badges) when
%   the MATBOX_BADGE_FORMAT environment variable is set to "json". The
%   matbox-actions workflows set this variable and render the JSON files
%   to SVG badges with badge-maker.
%
%   Otherwise falls back to rendering the SVG in MATLAB via the deprecated
%   pybadges Python package, for callers without a render step: local runs
%   and repositories pinned to older matbox-actions versions. This
%   fallback will be removed in a future major release.

    arguments
        label (1,1) string
        message (1,1) string
        color (1,1) string
        projectRootDirectory (1,1) string {mustBeFolder}
    end

    if strcmpi(getenv("MATBOX_BADGE_FORMAT"), "json")
        matbox.utility.writeBadgeJSONFile(label, message, color, ...
            "OutputFolder", fullfile(projectRootDirectory, "docs", "reports", "badges"))
    else
        matbox.utility.createBadgeSvg(label, message, color, projectRootDirectory)
    end
end
