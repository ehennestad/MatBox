<p align="right">
  <img alt="MatBox logo" src="https://github.com/user-attachments/assets/2d53e2fa-9b07-41b5-b20f-e086d126102d" height="70">
</p>

# MatBox

[![Version Number](https://img.shields.io/github/v/release/ehennestad/MatBox?label=version)](https://github.com/ehennestad/MatBox/releases/latest)
[![View MatBox on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://se.mathworks.com/matlabcentral/fileexchange/180185-matbox)
[![MATLAB Tests](.github/badges/tests.svg)](https://github.com/ehennestad/MatBox/actions/workflows/update.yml)
[![codecov](https://codecov.io/gh/ehennestad/MatBox/graph/badge.svg?token=6D7STF19X0)](https://codecov.io/gh/ehennestad/MatBox)
[![MATLAB Code Issues](.github/badges/code_issues.svg)](https://github.com/ehennestad/MatBox/security/code-scanning)
[![MATLAB](https://img.shields.io/badge/MATLAB-%3E%3DR2023a-blue)](https://www.mathworks.com/products/matlab.html)

MatBox provides reusable MATLAB utilities for maintaining MATLAB toolbox repositories. It installs toolbox dependencies, runs tests with coverage reports, runs MATLAB code analysis, and packages `.mltbx` releases from repository metadata.

MatBox is intended for MATLAB toolbox projects that follow a small set of conventions: source code in a source folder, tests in a test folder, dependency declarations in `requirements.txt`, and toolbox metadata in `MLToolboxInfo.json`.

## What MatBox Does

- Install MATLAB toolbox dependencies from `requirements.txt`
- Install dependencies from GitHub repositories and MATLAB File Exchange packages
- Run MATLAB unit tests and write JUnit and Cobertura coverage reports
- Run MATLAB Code Analyzer and optionally export reports
- Create README badges for test results and code analysis results
- Package `.mltbx` releases using `MLToolboxInfo.json`

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

- [dropbox-sdk-matlab](https://github.com/ehennestad/dropbox-sdk-matlab)
- [openMINDS-MATLAB-UI](https://github.com/ehennestad/openMINDS-MATLAB-UI)

## Related Projects

- [MatBox Actions](https://github.com/ehennestad/matbox-actions)
- [MATLAB Toolbox Template](https://github.com/ehennestad/matlab-toolbox-template)

## License

This project is available under the MIT License. See [LICENSE](LICENSE).
