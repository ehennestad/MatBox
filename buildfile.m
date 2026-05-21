function plan = buildfile
%buildfile - Build configuration for MatBox CI tasks
%
%   Defines tasks for continuous integration using MATLAB's buildtool.
%   Available tasks:
%       buildtool setup  - Install MatBox and set up paths
%       buildtool check  - Identify code issues
%       buildtool test   - Run tests with code coverage
%
%   Requires MATLAB R2023b or later.

    import matlab.buildtool.tasks.CodeIssuesTask
    import matlab.buildtool.tasks.TestTask

    plan = buildplan(localfunctions);

    plan("setup").Description = "Install MatBox and set up paths";

    plan("check") = CodeIssuesTask("code");
    plan("check").Description = ...
        "Identify code issues using MATLAB code analyzer";
    plan("check").Dependencies = "setup";

    plan("test") = TestTask( ...
        Tests="tools/tests", ...
        SourceFiles="code");
    plan("test").Description = "Run tests with code coverage";
    plan("test").Dependencies = "setup";

    plan.DefaultTasks = ["check", "test"];
end

function setupTask(~)
%setupTask - Install MatBox and add tools to MATLAB path
    addpath(genpath("tools"));
    installMatBox();
end
