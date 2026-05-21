function plan = buildfile
%buildfile - Build configuration for toolbox CI tasks
%
%   Defines tasks for continuous integration using MATLAB's buildtool.
%   Available tasks:
%       buildtool setup  - Set up paths and install dependencies
%       buildtool check  - Identify code issues
%       buildtool test   - Run tests with code coverage
%
%   Requires MATLAB R2023b or later.
%
%   Note: Adapt the source and test folder paths to match your project
%   structure.

    import matlab.buildtool.tasks.CodeIssuesTask
    import matlab.buildtool.tasks.TestTask

    plan = buildplan(localfunctions);

    plan("setup").Description = "Set up paths and install dependencies";

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
%setupTask - Set up MATLAB path and install dependencies
    addpath(genpath("tools"));
    if exist("installMatBox", "file")
        installMatBox();
    end
end
