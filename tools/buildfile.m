function plan = buildfile
% BUILDPLAN for MatBox
% Defines buildtool tasks for testing, packaging, and installing requirements.
%
% Usage:
%   buildtool              % Lists tasks
%   buildtool test         % Run tests
%   buildtool package      % Package toolbox
%   buildtool installreqs  % Install requirements

plan = buildplan(localfunctions);
plan.DefaultTasks = "test";
end

%% === TASKS ===

function testTask(~)
    % TEST Run tests for the toolbox
    disp("Running tests with MatBox...");
    if exist('tools/tasks/testToolbox.m', 'file')
        testToolbox();
    else
        % Fallback to default MatBox task
        projectRootDir = pwd;
        matbox.tasks.testToolbox(projectRootDir);
    end
end

function packageTask(~)
    % PACKAGE Package the MATLAB toolbox
    disp("Packaging toolbox with MatBox...");
    if exist('tools/tasks/packageToolbox.m', 'file')
        packageToolbox("build");
    else
        projectRootDir = pwd;
        matbox.tasks.packageToolbox(projectRootDir, "build");
    end
end

function installRequirementsTask(~)
    % INSTALLREQS Install requirements from requirements.txt
    disp("Installing requirements...");
    if exist('code/+matbox/installRequirements.m', 'file')
        matbox.installRequirements(pwd);
    else
        warning("matbox.installRequirements not found. Skipping.");
    end
end
