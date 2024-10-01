function testToolbox(projectRootDirectory, options)
    %RUNTESTWITHCODECOVERAGE Summary of this function goes here
    %   Detailed explanation goes here
    
    % Todo

    arguments
        projectRootDirectory (1,1) string {mustBeFolder}
        options.HtmlReports (1,1) logical = false;
        options.ReportSubdirectory (1,1) string = "";
        options.SourceFolderName (1,1) string = "code";
        options.ToolsFolderName (1,1) string = "tools";
        options.CoverageFileList (1,:) string = string.empty
    end
    
    import matlab.unittest.TestSuite;
    import matlab.unittest.TestRunner;
    import matlab.unittest.Verbosity;
    import matlab.unittest.plugins.CodeCoveragePlugin;
    import matlab.unittest.plugins.XMLPlugin;
    import matlab.unittest.plugins.codecoverage.CoverageReport;
    import matlab.unittest.plugins.codecoverage.CoberturaFormat;
    import matlab.unittest.selectors.HasTag;
    
    testFolder = fullfile(projectRootDirectory, options.ToolsFolderName, "tests");
    codeFolder = fullfile(projectRootDirectory, options.SourceFolderName);
    oldpath  = addpath(genpath(testFolder), codeFolder );
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

    runner = TestRunner.withTextOutput('OutputDetail', Verbosity.Detailed);

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
    matbox.utility.writeBadgeJSONFile("tests", message, color, projectRootDirectory)
    
    results.assertSuccess()
end
