function testToolbox(projectRootDirectory, options)
    %RUNTESTWITHCODECOVERAGE Summary of this function goes here
    %   Detailed explanation goes here

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
        options.HtmlReports (1,1) logical = false
        options.ReportSubdirectory (1,1) string = ""
        options.SourceFolderName (1,1) string = "code"
        options.TestsFolderName (1,1) string = missing
        options.CoverageRootFolder (1,1) string = missing
        options.CoverageFileList (1,:) string = string.empty
        options.CreateBadge (1,1) logical = true
        options.Verbosity (1,1) matlab.unittest.Verbosity = "Terse"
    end
    
    import matlab.unittest.TestSuite;
    import matlab.unittest.TestRunner;
    import matlab.unittest.plugins.CodeCoveragePlugin;
    import matlab.unittest.plugins.XMLPlugin;
    import matlab.unittest.plugins.codecoverage.CoverageReport;
    import matlab.unittest.plugins.codecoverage.CoberturaFormat;
    import matlab.unittest.selectors.HasTag;
    
    if ~ismissing(options.TestsFolderName)
        testFolder = fullfile(projectRootDirectory, options.TestsFolderName);
    else
        testFolder = fullfile(projectRootDirectory, "tools", "tests"); % Backwards compatibility - todo: remove
    end
    codeFolder = fullfile(projectRootDirectory, options.SourceFolderName);
    oldpath = addpath(genpath(testFolder), genpath(codeFolder));
    finalize = onCleanup(@()(path(oldpath)));
    
    % Run startup function if it exists
    if isfile( fullfile(codeFolder, 'startup.m') )
        run( fullfile(codeFolder, 'startup.m') )
    end

    outputDirectory = fullfile(projectRootDirectory, "docs", "reports", options.ReportSubdirectory);
    if ~isfolder(outputDirectory)
        mkdir(outputDirectory)
    end

    suite = TestSuite.fromFolder( testFolder, "IncludingSubfolders", true );
    
    if isMATLABReleaseOlderThan('R2022a') % fromFolder did not include packages
        % List packages and add suites by package names
        packageListing = dir(fullfile(testFolder, '+*'));
        for i = 1:numel(packageListing)
            if packageListing(i).isdir
                packageName = packageListing(i).name(2:end);
                suite = [suite, TestSuite.fromPackage( packageName, ...
                    "IncludingSubpackages", true )]; %#ok<AGROW>
            end
        end
    end

    if exist("isenv", "file") == 2 % isenv was introduced in R2022b
        if isenv('GITHUB_ACTIONS') && strcmp(getenv('GITHUB_ACTIONS'), 'true')
            % Remove graphical tests if running on a github runner
            suite = suite.selectIf(~HasTag("Graphical"));
        end
    end
    
    runner = TestRunner.withTextOutput('Verbosity', options.Verbosity);

    codecoverageFileName = fullfile(outputDirectory, "codecoverage.xml");
        
    if ~isempty(options.CoverageFileList)
        codecoverageFileList = options.CoverageFileList;
        if ~ismissing(options.CoverageRootFolder)
            warning('Matbox:TestToolbox:IgnoredCoverageRootFolder', ...
                'The value in CoverageRootFolder is ignored because CoverageFileList is provided.');
        end
    else
        if ~ismissing(options.CoverageRootFolder)
            mfileListing = dir(fullfile(options.CoverageRootFolder, '**', '*.m'));
        else
            mfileListing = dir(fullfile(codeFolder, '**', '*.m'));
        end
        codecoverageFileList = fullfile({mfileListing.folder}, {mfileListing.name});
    end
    
    if options.HtmlReports
        htmlReport = CoverageReport(outputDirectory, 'MainFile', "codecoverage.html");
        p = CodeCoveragePlugin.forFile(codecoverageFileList, "Producing", htmlReport);
        runner.addPlugin(p)
    else
        runner.addPlugin(XMLPlugin.producingJUnitFormat(fullfile(outputDirectory,'test-results.xml')));
        runner.addPlugin(CodeCoveragePlugin.forFile(codecoverageFileList, 'Producing', CoberturaFormat(codecoverageFileName)));
    end
    
    results = runner.run(suite);

    if ~verLessThan('matlab','9.9') && ~isMATLABReleaseOlderThan("R2022a") %#ok<VERLESSMATLAB>
        % This report is only available in R2022a and later.  isMATLABReleaseOlderThan wasn't added until MATLAB 2020b / version 9.9
        results.generateHTMLReport(outputDirectory,'MainFile',"testreport.html");
    end

    if options.CreateBadge
        createTestResultBadge(results, projectRootDirectory) % local function
    end
    
    displayTestResultSummary(results)

    results.assertSuccess();
end

function createTestResultBadge(results, projectRootDirectory)
    numTests = numel(results);
    numPassedTests = sum([results.Passed]);
    numFailedTests = sum([results.Failed]);
    
    % Generate the JSON files for the shields in the readme.md
    if numFailedTests == 0
        color = "green";
        message = sprintf("%d passed", numPassedTests);
    elseif numFailedTests/numTests < 0.05
        color = "yellow";
        message = sprintf("%d/%d passed", numPassedTests, numTests);
    else
        color = "red";
        message = sprintf("%d/%d passed", numPassedTests, numTests);
    end
    matbox.utility.createBadgeSvg("tests", message, color, projectRootDirectory)
end

function displayTestResultSummary(testResults)
    fprintf(['Test result summary:\n', ...
        '   %d Passed, %d Failed, %d Incomplete.\n', ...
        '   %.04f seconds testing time.\n'], ...
        sum([testResults.Passed]), ...
        sum([testResults.Failed]), ...
        sum([testResults.Incomplete]), ...
        sum([testResults.Duration]) ...
        )
end
