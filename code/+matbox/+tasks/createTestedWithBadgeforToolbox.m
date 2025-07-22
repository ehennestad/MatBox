function createTestedWithBadgeforToolbox(versionNumber, projectRootDirectory)
%createTestedWithBadgesforToolbox - Take the test reports from the runs against
% multiple MATLAB releases, and generate the "Tested with" badge
%
%   Adapted from: https://github.com/mathworks/climatedatastore/tree/main/buildUtilities
    
    arguments
        versionNumber (1,1) string
        projectRootDirectory (1,1) string {mustBeFolder}
    end
    
    releasesTestedWith = "";
    releasesFailed = 0;

    % Go through the R2* directories and extract the failed test info
    testResultsListing = dir(fullfile(projectRootDirectory, ...
        "docs", "reports", "**", "test-results.xml"));

    assert( ~isempty(testResultsListing), ...
        'MATBOX:BadgeCreation:NoTestResultsFound', ...
        'No test results were found\n' )
    
    testResultFolders = string({testResultsListing.folder});
    releaseNames = getReleaseNamesFromFolderPaths(testResultFolders);

    assert(all(startsWith(releaseNames, "R2")), ...
        'MATBOX:BadgeCreation:ReleaseDetectionFailed', ...
        'Failed to detect release names for one or more test results.')

    % Sort releases newest to oldest
    [~, sortedIndices] = sort(releaseNames);
    testResultsListing = testResultsListing(sortedIndices);

    testResultFiles = string(...
        fullfile({testResultsListing.folder}, {testResultsListing.name}) ...
        );
    
    % Go through the directories and check if tests passed
    for i = 1:numel(testResultFiles)
        releaseName = releaseNames(i);
        currentFile = testResultFiles(i);
        
        % Read the test results file
        testResults = readstruct(currentFile);
        
        % If no tests failed, errors, or were skipped, then add it to the list
        if sum([testResults.testsuite.errorsAttribute]) == 0 ...
           && sum([testResults.testsuite.failuresAttribute]) == 0 ...
           && sum([testResults.testsuite.skippedAttribute]) == 0
            if releasesTestedWith ~= ""
                % Insert the separator between released after the first one
                releasesTestedWith = releasesTestedWith + " | ";
            end
            releasesTestedWith = releasesTestedWith + releaseName;
        else
            releasesFailed = releasesFailed + 1;
        end
    end
    if releasesTestedWith ~= ""
        switch releasesFailed
            case 0
                badgecolor = "green";
            case 1
                badgecolor = "orange";
            case 2
                badgecolor = "yellow";
            otherwise
                badgecolor = "red";
        end

        outputDirectory = fullfile(projectRootDirectory, '.github', 'badges', versionNumber);
        matbox.utility.writeBadgeJSONFile("tested with", releasesTestedWith, badgecolor,...
            "OutputFolder", outputDirectory)
    end
end

function result = getReleaseNamesFromFolderPaths(folderPaths)
    [~, folderNames] = fileparts( folderPaths );
    releaseNames = regexp(folderNames, 'R\d{4}[ab]', 'match');
    result = [releaseNames{:}];
end