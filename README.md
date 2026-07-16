<p align="right">
  <img alt="MatBox logo" src="https://github.com/user-attachments/assets/2d53e2fa-9b07-41b5-b20f-e086d126102d" title="MatBox" align="right" height="70">
</p>

# MatBox - Tools for MATLAB Toolbox Development

[![Version Number](https://img.shields.io/github/v/release/ehennestad/MatBox?label=version)](https://github.com/ehennestad/MatBox/releases/latest)
[![View MatBox on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://se.mathworks.com/matlabcentral/fileexchange/180185-matbox)
[![MATLAB Tests](.github/badges/tests.svg)](https://github.com/ehennestad/MatBox/actions/workflows/update.yml)
[![codecov](https://codecov.io/gh/ehennestad/MatBox/graph/badge.svg?token=6D7STF19X0)](https://codecov.io/gh/ehennestad/MatBox)
[![MATLAB Code Issues](.github/badges/code_issues.svg)](https://github.com/ehennestad/MatBox/security/code-scanning)
[![MATLAB](https://img.shields.io/badge/MATLAB-%3E%3DR2023a-blue?logo=data:image/svg%2bxml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjxzdmcKICAgd2lkdGg9IjEyIgogICBoZWlnaHQ9IjEwLjcyNSIKICAgdmlld0JveD0iMCAwIDEyIDEwLjcyNSIKICAgZmlsbD0ibm9uZSIKICAgdmVyc2lvbj0iMS4xIgogICBpZD0ic3ZnNCIKICAgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIgogICB4bWxuczpzdmc9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8ZwogICAgIGNsaXAtcGF0aD0idXJsKCNjbGlwMF8zMTRfMTY2KSIKICAgICBpZD0iZzIiCiAgICAgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTQsLTQuMDc1MjAwMSkiPgogICAgPHBhdGgKICAgICAgIGQ9Im0gNi4xNzUsMTEuNTc1MiBjIC0wLjYsLTAuNDUgLTEuMzUsLTAuOTc1IC0yLjE3NSwtMS41NzUgMC45NzUsLTAuMzc1IDEuOTUsLTAuNzUgMi45MjUsLTEuMTI1IGwgMS4yLDAuOSBjIC0wLjksMS4wNSAtMS41LDEuNDI1IC0xLjk1LDEuOCB6IG0gOC4wMjUsLTMuMTUgYyAtMC4yMjUsLTAuNiAtMC4zNzUsLTEuMiAtMC42LC0xLjggLTAuMjI1LC0wLjY3NSAtMC40NSwtMS4yNzUgLTAuODI1LC0xLjggLTAuMTUsLTAuMjI1IC0wLjQ1LC0wLjc1IC0wLjgyNSwtMC43NSAtMC4wNzUsMCAtMC4xNSwwLjA3NSAtMC4yMjUsMC4wNzUgLTAuMjI1LDAuMDc1IC0wLjUyNSwwLjUyNSAtMC42LDAuODI1IC0wLjIyNSwwLjM3NSAtMC42NzUsMC45NzUgLTAuOTc1LDEuMzUgLTAuMDc1LDAuMTUgLTAuMjI1LDAuMyAtMC4zLDAuMzc1IC0wLjIyNSwwLjE1IC0wLjQ1LDAuMzc1IC0wLjc1LDAuNTI1IC0wLjA3NSwwIC0wLjE1LDAuMDc1IC0wLjIyNSwwLjA3NSAtMC4yMjUsMCAtMC4zNzUsMC4xNSAtMC41MjUsMC4yMjUgLTAuMjI1LDAuMjI1IC0wLjQ1LDAuNTI1IC0wLjY3NSwwLjc1IDAsMC4wNzUgLTAuMDc1LDAuMTUgLTAuMTUsMC4yMjUgbCAxLjEyNSwwLjgyNSBjIDAuODI1LC0wLjk3NSAxLjgsLTEuOTUgMi40NzUsLTMuODI1IDAsMCAtMC4yMjUsMi4wMjUgLTIuMDI1LDQuMiAtMS4xMjUsMS4yNzUgLTIuMDI1LDEuOTUgLTIuMTc1LDIuMSAwLDAgMC4zLC0wLjA3NSAwLjYsMC4wNzUgMC42LDAuMjI1IDAuOSwxLjA1IDEuMTI1LDEuNjUgMC4xNSwwLjQ1IDAuMzc1LDAuODI1IDAuNTI1LDEuMjc1IDAuNiwtMC4xNSAwLjk3NSwtMC4zNzUgMS4zNSwtMC43NSAwLjM3NSwtMC4zNzUgMC43NSwtMC44MjUgMS4xMjUsLTEuMiAwLjY3NSwtMC44MjUgMS41LC0xLjg3NSAyLjU1LC0xLjM1IDAuMTUsMC4wNzUgMC4zNzUsMC4yMjUgMC40NSwwLjMgMC4yMjUsMC4xNSAwLjM3NSwwLjMgMC42LDAuNTI1IDAuMzc1LDAuMyAwLjUyNSwwLjUyNSAwLjgyNSwwLjY3NSAtMC43NSwtMS41IC0xLjI3NSwtMyAtMS44NzUsLTQuNTc1IHoiCiAgICAgICBmaWxsPSIjZmZmZmZmIgogICAgICAgaWQ9InBhdGgyIiAvPgogIDwvZz4KICA8ZGVmcwogICAgIGlkPSJkZWZzNCI+CiAgICA8Y2xpcFBhdGgKICAgICAgIGlkPSJjbGlwMF8zMTRfMTY2Ij4KICAgICAgPHJlY3QKICAgICAgICAgd2lkdGg9IjEyIgogICAgICAgICBoZWlnaHQ9IjEyIgogICAgICAgICBmaWxsPSIjZmZmZmZmIgogICAgICAgICB0cmFuc2Zvcm09InRyYW5zbGF0ZSg0LDQpIgogICAgICAgICBpZD0icmVjdDQiCiAgICAgICAgIHg9IjAiCiAgICAgICAgIHk9IjAiIC8+CiAgICA8L2NsaXBQYXRoPgogIDwvZGVmcz4KPC9zdmc+Cg==&label=MATLAB&labelColor=C95C2E&color=2A5F98)](https://se.mathworks.com/products/matlab.html)

MatBox provides the repository infrastructure that MATLAB doesn't: dependency installation, test and coverage reporting, code analysis, and release packaging — implemented once, reused across all your toolbox repositories.

Maintaining a MATLAB toolbox as a Git repository means solving the same problems in every project: MATLAB has no package manager for installing dependencies, no standard way to produce the test and coverage reports CI services expect, and packaging an `.mltbx` release is a manual, error-prone process. MatBox solves each of these with a single function call:

- **Install dependencies** — declare GitHub and File Exchange dependencies in `requirements.txt`; `matbox.installRequirements(pwd)` installs them on your machine and on CI runners alike.
- **Run tests with real reports** — `matbox.tasks.testToolbox(pwd)` runs your test suite and writes JUnit results, Cobertura coverage, and an HTML report to `docs/reports` — the formats GitHub checks and Codecov consume directly.
- **Check code quality** — `matbox.tasks.codecheckToolbox(pwd)` runs the MATLAB Code Analyzer and exports SARIF, so issues show up on GitHub's code-scanning tab; optionally fail CI when warnings are present.
- **Release with one command** — `matbox.tasks.packageToolbox(pwd, "patch")` bumps the version, builds `ToolboxOptions` from `MLToolboxInfo.json`, and packages the `.mltbx`.
- **Generate badges** — test-result and code-issue badges rendered in MATLAB, committed to the repo, no external badge service.

Because every MatBox project follows the same small set of conventions, the companion [matbox-actions](https://github.com/ehennestad/matbox-actions) give any toolbox repository full CI — tests, analysis, coverage, badges, releases — from a few short workflow files.

To see this in practice, browse [dropbox-sdk-matlab](https://github.com/ehennestad/dropbox-sdk-matlab) or [openMINDS-MATLAB-UI](https://github.com/ehennestad/openMINDS-MATLAB-UI): the badges, test and code-analysis runs, and packaged releases in those repositories are produced by MatBox.

The conventions are minimal: source code in a source folder, tests in a test folder, dependency declarations in `requirements.txt`, and toolbox metadata in `MLToolboxInfo.json`.

## Requirements

- MATLAB R2023a or later is the supported baseline for MatBox itself.
- Some functionality may work in older MATLAB releases, but the current package metadata and tests target R2023a or later.
- Dependency installation requires network access when packages are fetched from GitHub or MATLAB File Exchange.

## Installation

Install MatBox from one of the released `.mltbx` files:

- [Latest GitHub release](https://github.com/ehennestad/MatBox/releases/latest)
- [MATLAB File Exchange](https://se.mathworks.com/matlabcentral/fileexchange/180185-matbox)

For GitHub Actions workflows, use the companion action:

- [matbox-actions/install-matbox](https://github.com/ehennestad/matbox-actions/tree/main/install-matbox)

## Quick Start

Install dependencies for a toolbox repository:

```matlab
matbox.installRequirements(pwd)
```

Run tests:

```matlab
matbox.tasks.testToolbox(pwd)
```

Run MATLAB Code Analyzer:

```matlab
matbox.tasks.codecheckToolbox(pwd)
```

Package a toolbox release:

```matlab
[newVersion, mltbxPath] = matbox.tasks.packageToolbox(pwd, "patch")
```

Use `"build"`, `"major"`, `"minor"`, `"patch"`, or `"specific"` as the release type.

## Repository Conventions

MatBox expects toolbox projects to provide a few files and folders.

```text
my-toolbox/
  requirements.txt
  tools/
    MLToolboxInfo.json
  src/
    Contents.m
  tests/
```

The default source folder is `src`, and the default test folder is `tests`. If your project uses different folder names, pass them explicitly:

```matlab
matbox.tasks.testToolbox( ...
    pwd, ...
    "SourceFolderName", "code", ...
    "TestsFolderName", fullfile("tools", "tests"))
```

Packaging uses `MLToolboxInfo.json` to create MATLAB `ToolboxOptions`. MatBox looks for exactly one `MLToolboxInfo.json` file in a direct subfolder of the project root.

Generated outputs are written to conventional locations:

- `docs/reports` for test, coverage, and code-analysis reports
- `.github/badges` for generated SVG badges
- `releases` for packaged `.mltbx` files

## Dependency Files

Dependencies are declared in `requirements.txt`, one requirement per line. Empty lines and lines beginning with `#` are ignored.

Supported formats:

```text
https://github.com/<owner>/<repo>
https://github.com/<owner>/<repo>@<branch>
fex://<file-exchange-id-title>
fex://<file-exchange-id-title>/<version>
```

Example:

```text
https://github.com/openMetadataInitiative/openMINDS_MATLAB
https://github.com/ehennestad/StructEditor
fex://66235-widgets-toolbox-compatibility-support/1.3.330
fex://83328-widgets-toolbox-matlab-app-designer-components
```

Install or update dependencies:

```matlab
matbox.installRequirements(pwd)
matbox.installRequirements(pwd, "update")
```

By default, installed dependencies are added to the MATLAB path and the path is saved. These behaviors can be controlled with name-value arguments:

```matlab
matbox.installRequirements( ...
    pwd, ...
    "InstallationLocation", fullfile(userpath, "MATLAB-AddOns"), ...
    "UpdateSearchPath", true, ...
    "SaveSearchPath", true)
```

## Common Tasks

Run all tests and create reports:

```matlab
matbox.tasks.testToolbox( ...
    pwd, ...
    "HtmlReports", true, ...
    "CreateBadge", true)
```

Run tests with tag filtering:

```matlab
matbox.tasks.testToolbox(pwd, "HasTag", "Unit")
matbox.tasks.testToolbox(pwd, "ExcludeTags", ["Graphical", "Slow"])
```

Run code analysis and fail when warnings or errors are present:

```matlab
matbox.tasks.codecheckToolbox( ...
    pwd, ...
    "RequireIssuesResolved", true, ...
    "SeverityThreshold", "warning")
```

Package a build release without changing the three-part semantic version:

```matlab
matbox.tasks.packageToolbox(pwd, "build")
```

Package a specific version:

```matlab
matbox.tasks.packageToolbox(pwd, "specific", "1.2.3")
```

## Project-Specific Task Wrappers

Projects can keep their own CI entry points in `tools/tasks`. These wrapper functions are useful when a project needs non-default source folders, test folders, tag filters, report settings, or packaging options.

Example:

```matlab
function testToolbox()
    taskFile = mfilename('fullpath');
    projectRoot = fileparts(fileparts(fileparts(taskFile)));

    matbox.tasks.testToolbox( ...
        projectRoot, ...
        "SourceFolderName", "code", ...
        "TestsFolderName", fullfile("tools", "tests"), ...
        "HtmlReports", true);
end
```

This keeps project-specific policy in the project repository while reusing the core MatBox task implementation.

## Continuous Integration

MatBox is designed to run in GitHub Actions. The companion repository [matbox-actions](https://github.com/ehennestad/matbox-actions) provides composite actions and reusable workflows that install MatBox on a runner and invoke the MatBox tasks, so a toolbox repository only needs a few small workflow files.

A minimal test workflow (`.github/workflows/test-code.yml`):

```yaml
name: Test code

on:
  push:
    branches: main
  pull_request:
    branches: main

jobs:
  test:
    name: Analyse and test code
    uses: ehennestad/matbox-actions/.github/workflows/test-code-workflow.yml@v1
    with:
      source_directory: src
      tests_directory: tests
      tools_directory: tools
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

This runs code analysis and the test suites, publishes test results, uploads coverage to Codecov (if the token is set), commits updated badges, and uploads all reports as a build artifact. A corresponding release workflow packages the toolbox and creates a draft GitHub release when a version tag is pushed.

If a project defines its own task wrappers in `tools/tasks` (see above), the CI actions find and call them instead of the built-in `matbox.tasks.*` functions.

See the [CI documentation](docs/ci.md) for the full setup, including the release pipeline, badge behavior, code coverage, and all workflow inputs.

## New Projects

For new toolbox repositories, start from the MATLAB toolbox template:

- [MATLAB Toolbox Template](https://github.com/ehennestad/matlab-toolbox-template)

Then configure:

- `requirements.txt` for dependencies
- `setup.m` for local setup
- `MLToolboxInfo.json` for toolbox metadata
- `.github/workflows` for CI
- optional `tools/tasks` wrappers for project-specific task settings

## Example Repositories

These repositories use MatBox for testing, code analysis, badges, and releases:

- [dropbox-sdk-matlab](https://github.com/ehennestad/dropbox-sdk-matlab) — a class-based Dropbox API client
- [openMINDS-MATLAB-UI](https://github.com/ehennestad/openMINDS-MATLAB-UI) — a graphical interface for openMINDS metadata

## Related Projects

- [MatBox Actions](https://github.com/ehennestad/matbox-actions)
- [MATLAB Toolbox Template](https://github.com/ehennestad/matlab-toolbox-template)

## License

This project is available under the MIT License. See [LICENSE](LICENSE).
