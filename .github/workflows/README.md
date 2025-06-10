# Reusable GitHub Actions Workflows

This directory contains reusable GitHub Actions workflows for MATLAB toolbox development and release management.

## Overview

The workflows are organized into two levels:

1. **Complete Workflows** (`reusable-workflow_*`): Full end-to-end processes
2. **Job Workflows** (`reusable-job_*`): Individual job components that can be mixed and matched

## Complete Workflows

### `reusable-workflow_release.yml`

A complete release workflow that validates versions, runs tests, packages the toolbox, and verifies installation.

**Usage:**
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    uses: ./.github/workflows/reusable-workflow_release.yml
    with:
      ref_name: ${{ github.ref_name }}
      needs_python: true
    secrets:
      DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
```

## Job Workflows

Individual job workflows that can be used independently or combined in custom workflows:

### `reusable-job_validate-version.yml`

Validates version numbers and checks for required files.

**Inputs:**
- `version` (optional): Version number for manual triggers
- `ref_name` (optional): GitHub ref name for tag triggers
- `tools_directory` (default: 'tools'): Directory containing tools

**Outputs:**
- `version_number`: Validated version number

### `reusable-job_build-matrix.yml`

Builds test matrices for MATLAB and Python versions.

**Inputs:**
- `tools_directory` (default: 'tools'): Directory containing tools
- `matlab_versions` (default: '[]'): JSON array of MATLAB versions
- `python_versions` (default: ''): JSON object mapping MATLAB to Python versions
- `needs_python` (default: false): Whether Python is needed

**Outputs:**
- `matrix`: Test matrix JSON
- `matlab_versions`: MATLAB versions array

### `reusable-job_run-tests.yml`

Runs MATLAB tests across multiple versions.

**Inputs:**
- `code_directory` (default: 'code'): Source code directory
- `tools_directory` (default: 'tools'): Tools directory
- `matlab_products` (default: ''): MATLAB products to install
- `needs_python` (default: false): Whether Python is needed
- `matrix_json` (required): Test matrix from build-matrix job

### `reusable-job_package-toolbox.yml`

Packages the toolbox and creates a GitHub release.

**Inputs:**
- `version_number` (required): Version number for the release
- `code_directory` (default: 'code'): Source code directory
- `tools_directory` (default: 'tools'): Tools directory

**Secrets:**
- `DEPLOY_KEY` (required): SSH deploy key for pushing to protected branches

**Outputs:**
- `toolbox_name`: Name of the packaged toolbox
- `mltbx_path`: Path to the packaged MLTBX file

### `reusable-job_verify-installation.yml`

Verifies toolbox installation across multiple operating systems.

**Inputs:**
- `toolbox_name` (required): Name of the toolbox to verify
- `os_matrix` (default: '["ubuntu-latest", "windows-latest", "macos-latest"]'): OS array

## Customization Examples

### Adding Virtual Display Support

When you need to add custom setup (like virtual displays) to the test job, you can create a custom workflow that uses most of the reusable jobs but implements a custom test job:

```yaml
name: Custom Release with Virtual Display

on:
  push:
    tags:
      - 'v*'

jobs:
  validate_version:
    uses: ./.github/workflows/reusable-job_validate-version.yml
    with:
      ref_name: ${{ github.ref_name }}

  build_matrix:
    uses: ./.github/workflows/reusable-job_build-matrix.yml
    with:
      needs_python: true

  # Custom test job with virtual display
  test:
    name: Run MATLAB tests with virtual display
    needs: [validate_version, build_matrix]
    runs-on: ubuntu-latest
    strategy:
      matrix: ${{ fromJSON(needs.build_matrix.outputs.matrix) }}
    steps:
      - uses: actions/checkout@v4
      
      # Custom virtual display setup
      - name: Setup virtual display
        run: |
          sudo apt-get install -y xvfb
          echo "DISPLAY=:99.0" >> $GITHUB_ENV
          Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &
      
      # Continue with standard test steps...
      - name: Set up MATLAB
        uses: matlab-actions/setup-matlab@v2
        with:
          release: ${{ matrix.MATLABVersion }}
      
      - name: Run tests
        uses: ehennestad/matbox/.github/actions/test-code@make-release-workflow-reusable
        with:
          code_directory: code
          tools_directory: tools

  release:
    needs: [test, validate_version]
    uses: ./.github/workflows/reusable-job_package-toolbox.yml
    with:
      version_number: ${{ needs.validate_version.outputs.version_number }}
    secrets:
      DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}

  verify_installation:
    needs: [release]
    uses: ./.github/workflows/reusable-job_verify-installation.yml
    with:
      toolbox_name: ${{ needs.release.outputs.toolbox_name }}
```

### Adding Custom Secrets

If you need additional secrets for specific jobs, you can pass them through:

```yaml
jobs:
  custom_test:
    name: Custom test with additional secrets
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      # Use custom secret
      - name: Setup custom service
        env:
          API_KEY: ${{ secrets.CUSTOM_API_KEY }}
        run: |
          echo "Setting up custom service with API key"
      
      # Continue with standard steps...
```

## Benefits

1. **Flexibility**: Use individual job workflows for maximum customization
2. **Reusability**: Standard workflows for common use cases
3. **Maintainability**: Changes to core functionality only need to be made in one place
4. **Gradual Migration**: Can adopt job-by-job without breaking existing workflows
