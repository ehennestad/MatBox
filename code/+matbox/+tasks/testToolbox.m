function testToolbox(projectRootDirectory, options)
    %RUNTESTWITHCODECOVERAGE Summary of this function goes here
    %   Detailed explanation goes here

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
        options.HtmlReports (1,1) logical = false
        options.ReportSubdirectory (1,1) string = ""
        options.SourceFolderName (1,1) string = "code"
        options.ToolsFolderName (1,1) string = "tools"
        options.CoverageFileList (1,:) string = string.empty
        options.CreateBadge (1,1) logical = true
        options.Verbosity (1,1) matlab.unittest.Verbosity = "Detailed"
    end
    
    import matlab.unittest.TestSuite;
    import matlab.unittest.TestRunner;
    import matlab.unittest.plugins.CodeCoveragePlugin;
    import matlab.unittest.plugins.XMLPlugin;
    import matlab.unittest.plugins.codecoverage.CoverageReport;
    import matlab.unittest.plugins.codecoverage.CoberturaFormat;
    import matlab.unittest.selectors.HasTag;
    
    testFolder = fullfile(projectRootDirectory, options.ToolsFolderName, "tests");
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

    runner = TestRunner.withTextOutput('OutputDetail', options.Verbosity);

    codecoverageFileName = fullfile(outputDirectory, "codecoverage.xml");

    if isempty(options.CoverageFileList)
        codecoverageFileList = dir(fullfile(codeFolder, '**', '*.m'));
        codecoverageFileList = fullfile({codecoverageFileList.folder}, {codecoverageFileList.name});
    else
        codecoverageFileList = options.CoverageFileList;
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
    
    results.assertSuccess()
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
