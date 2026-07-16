# Continuous Integration with MatBox

This guide describes how to set up GitHub Actions CI for a MATLAB toolbox
repository using MatBox. It covers running tests, code analysis, spell
checking, and the release pipeline.

## How the Pieces Fit Together

CI support for MatBox projects is split across three repositories:

| Repository | Role |
|---|---|
| [MatBox](https://github.com/ehennestad/MatBox) | MATLAB functions that do the actual work: `matbox.tasks.testToolbox`, `matbox.tasks.codecheckToolbox`, `matbox.tasks.packageToolbox`, and `matbox.installRequirements` |
| [matbox-actions](https://github.com/ehennestad/matbox-actions) | GitHub composite actions and reusable workflows that install MatBox on a runner and invoke the MatBox tasks |
| [matlab-toolbox-template](https://github.com/ehennestad/matlab-toolbox-template) | A repository template with the workflows below already configured |

A downstream toolbox repository does not need to reference MatBox directly in
its workflow files. It calls the reusable workflows in `matbox-actions`, which
install MatBox on the runner and run the tasks.

There are two levels at which a project can consume the CI tooling:

1. **Reusable workflows** (recommended): a single `uses:` line per workflow
   file. This is what the toolbox template does.
2. **Individual composite actions**: for projects that need a custom job
   layout, the building blocks (`install-matbox`, `test-code`, `check-code`,
   `package-toolbox`, and others) can be combined in a custom workflow. See the
   [matbox-actions README](https://github.com/ehennestad/matbox-actions#available-actions)
   for the full list.

## Prerequisites

The reusable workflows assume the
[repository conventions](../README.md#repository-conventions) described in the
README. The defaults expect this layout:

```text
my-toolbox/
  requirements.txt          # Toolbox dependencies (optional)
  src/                      # Source code
  tests/                    # Test suites
  tools/
    MLToolboxInfo.json      # Toolbox metadata (required for packaging)
    tasks/                  # Optional project-specific task wrappers
  .github/
    workflows/              # Workflow files shown below
    badges/                 # Generated badges are committed here
```

If your project uses different folder names, pass them as inputs
(`source_directory`, `tests_directory`, `tools_directory`) to the reusable
workflows.

## Test Workflow

Runs code analysis and the test suites, publishes test results, uploads
coverage, and updates badges. Create `.github/workflows/test-code.yml`:

```yaml
name: Test code

on:
  push:
    branches: main
  pull_request:
    branches: main

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

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

### Inputs

| Input | Default | Description |
|---|---|---|
| `source_directory` | `src` | Directory containing source code. Code coverage and code analysis run on this folder and its subfolders |
| `tests_directory` | `tests` | Directory containing MATLAB test suites |
| `tools_directory` | `tools` | Directory containing CI tools. Used for locating customized MatBox tasks |
| `matlab_release` | `latest` | MATLAB release used for running tests and code analysis |
| `matlab_use_cache` | `false` | Whether to cache the MATLAB installation for faster subsequent setups |
| `matlab_products` | `''` | Optional list of additional MATLAB products to install |
| `needs_virtual_display` | `false` | Whether to start a virtual display (Xvfb) before testing. Required for tests that create figures or apps |
| `update_badges` | `true` | Whether push events and ready pull requests should generate and commit badge updates |

Secrets: `CODECOV_TOKEN` (optional; enables coverage upload to Codecov).
Outputs: `badges_stale` (whether generated badges differ from committed
badges).

The workflow runs these steps: check out the repository, set up MATLAB
(`matlab-actions/setup-matlab`), install MatBox, run code analysis
(`matbox.tasks.codecheckToolbox`), run tests (`matbox.tasks.testToolbox`),
commit updated badges, upload coverage to Codecov, and upload the
`docs/reports` folder as a build artifact.

Products passed via `matlab_products` use underscore-separated names, one per
line:

```yaml
      matlab_products: >
        Image_Processing_Toolbox
        Statistics_and_Machine_Learning_Toolbox
```

## Code Analysis Workflow

For running code analysis on its own (without tests), use
`check-code-workflow.yml`:

```yaml
jobs:
  check:
    uses: ehennestad/matbox-actions/.github/workflows/check-code-workflow.yml@v1
    with:
      source_directory: src
      tools_directory: tools
```

Inputs: `source_directory`, `tools_directory`, `matlab_release`,
`matlab_use_cache`, and `update_badges`, with the same defaults and meanings
as the test workflow. The code-issues report is uploaded in SARIF format and
appears under the repository's Security > Code scanning tab (requires
`security-events: write` permission and MATLAB R2023a or later).

## Spell-Check Workflow

Runs [codespell](https://github.com/codespell-project/codespell) over the
repository:

```yaml
jobs:
  codespell:
    uses: ehennestad/matbox-actions/.github/workflows/codespell-workflow.yml@v1
    with:
      config_file: .codespellrc
```

The single input `config_file` (default `.codespellrc`) points to a codespell
configuration file. Only the `skip` and `ignore-words-list` options are read
from the configuration file.

## Release Workflow

The release pipeline validates a version number, tests against a matrix of
MATLAB releases, packages the toolbox as `.mltbx`, creates a draft GitHub
release, and verifies that the packaged toolbox installs cleanly. Create
`.github/workflows/prepare-release.yml`:

```yaml
name: Prepare toolbox release

on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
  workflow_dispatch:
    inputs:
      version:
        description: 'Version number in major.minor.patch format'
        required: true
        type: string

jobs:
  prepare-release:
    uses: ehennestad/matbox-actions/.github/workflows/prepare-release-workflow.yml@v1
    with:
      version: ${{ inputs.version }}
      ref_name: ${{ github.ref_name }}
      source_directory: src
      tools_directory: tools
    secrets:
      DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
```

A release is triggered either by pushing a tag like `v1.2.3` or by running the
workflow manually with a version number.

### Inputs

| Input | Default | Description |
|---|---|---|
| `version` | — | Version number in `major.minor.patch` format (for manual triggers) |
| `ref_name` | — | GitHub ref name (for tag triggers) |
| `source_directory` | `src` | Directory containing source code |
| `tests_directory` | `tests` | Directory containing MATLAB test suites |
| `tools_directory` | `tools` | Directory containing tools and `MLToolboxInfo.json` |
| `matlab_products` | `''` | Optional list of additional MATLAB products to install |
| `matlab_versions` | `'[]'` | JSON array of MATLAB versions to test, e.g. `'["R2023a", "R2024a"]'`. If empty, versions are determined from `MLToolboxInfo.json` |
| `python_versions` | `''` | JSON object mapping MATLAB versions to Python versions, e.g. `'{"R2024a": "3.10"}'` |
| `needs_python` | `false` | Whether Python is needed for testing |
| `needs_virtual_display` | `false` | Whether to start a virtual display for testing |

Secrets: `DEPLOY_KEY` (required) — an SSH deploy key with write access, used
to push version updates back to protected branches.

### Pipeline Stages

The reusable workflow chains these jobs:

1. **Validate version** — checks the version number format
2. **Configure test matrix** — determines which MATLAB releases to test, from
   `matlab_versions` or from `MLToolboxInfo.json`
3. **Test** — runs the test suites across the MATLAB version matrix
4. **Package and release** — packages the `.mltbx` with
   `matbox.tasks.packageToolbox` and creates a draft GitHub release
5. **Verify installation** — installs the packaged toolbox and confirms it
   loads

## Project-Specific Task Wrappers

The `test-code` and `check-code` actions add the source, tests, and tools
directories to the MATLAB path, then look for functions named `testToolbox`
and `codecheckToolbox`. If found (conventionally in `tools/tasks/`), the
wrapper is called instead of the built-in `matbox.tasks.*` function, with the
same name-value arguments forwarded.

Use a wrapper when a project needs non-default settings that cannot be
expressed through workflow inputs, such as tag filters or report options. See
[Project-Specific Task Wrappers](../README.md#project-specific-task-wrappers)
in the README for an example.

## Badges

The test and code-analysis workflows generate SVG badges in `.github/badges`
(test results and code issues) and commit them back to the branch when they
change:

- Draft pull requests run CI without generating or committing badges.
- Ready pull requests generate badges. With `update_badges: true` (the
  default), updates are committed back to same-repository pull request
  branches. With `update_badges: false`, a `Badges current` job fails if the
  committed badges are stale, so they can be regenerated locally instead.
- Push events generate and commit badge updates when `update_badges` is
  `true`.

Reference the badges in the README:

```markdown
[![MATLAB Tests](.github/badges/tests.svg)](https://github.com/<owner>/<repo>/actions/workflows/test-code.yml)
[![MATLAB Code Issues](.github/badges/code_issues.svg)](https://github.com/<owner>/<repo>/security/code-scanning)
```

## Code Coverage

`matbox.tasks.testToolbox` writes a Cobertura coverage report to
`docs/reports/codecoverage.xml`. If the `CODECOV_TOKEN` secret is set, the
test workflow uploads it to [Codecov](https://codecov.io). To enable:

1. Add the repository on codecov.io and copy the upload token.
2. Add the token as a repository secret named `CODECOV_TOKEN`.
3. Pass the secret to the reusable workflow as shown in the test workflow
   example above.

All generated reports (JUnit test results, coverage, code-issues report, HTML
test report) are also uploaded as a workflow artifact named `reports`.

## Versioning

Pin the reusable workflows and actions to a major version tag (currently
`@v1`), which receives backwards-compatible updates:

```yaml
uses: ehennestad/matbox-actions/.github/workflows/test-code-workflow.yml@v1
```
