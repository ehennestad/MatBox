<a href="https://github.com/user-attachments/assets/2d53e2fa-9b07-41b5-b20f-e086d126102d">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/2d53e2fa-9b07-41b5-b20f-e086d126102d">
    <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/2d53e2fa-9b07-41b5-b20f-e086d126102d">
    <img alt="Dropbox-API-Client-logo" src="[/resources/images/toolbox_image.png](https://github.com/user-attachments/assets/2d53e2fa-9b07-41b5-b20f-e086d126102d)" title="MatBox" align="right" height="70"​>
  </picture>
</a>

# MatBox: Efficient MATLAB Toolbox Development
[![Version Number](https://img.shields.io/github/v/release/ehennestad/MatBox?label=version)](https://github.com/ehennestad/MatBox/releases/latest)
[![View MatBox on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://se.mathworks.com/matlabcentral/fileexchange/180185-matbox)
[![MATLAB Tests](.github/badges/tests.svg)](https://github.com/ehennestad/MatBox/actions/workflows/update.yml)
[![codecov](https://codecov.io/gh/ehennestad/MatBox/graph/badge.svg?token=6D7STF19X0)](https://codecov.io/gh/ehennestad/MatBox)
[![MATLAB Code Issues](.github/badges/code_issues.svg)](https://github.com/ehennestad/MatBox/security/code-scanning)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://gitHub.com/ehennestad/MatBox/graphs/commit-activity)

Matbox is a streamlined solution for managing MATLAB toolbox development, designed to simplify the entire lifecycle—from code checks and dependency management to cleaning, packaging, and continuous integration. With Matbox, you can automate tedious tasks like verifying code quality, handling external dependencies, ensuring compatibility, and bundling your toolbox for distribution.

To get started, use the [template repository](https://github.com/ehennestad/Matlab-Toolbox)

## Key Features:

- **Automated Dependency Management**: Streamline your project setup with automatic installation and configuration of required packages using a `requirements.txt` file.
- **Code Quality Assurance**: Perform code checks and maintain clean, consistent codebases with linting and format enforcement.
- **Continuous Integration**: Seamlessly integrate CI/CD pipelines to ensure code stability and easy deployment using GitHub actions and workflow templates.
- **Effortless Packaging**: Package your MATLAB toolbox for easy distribution with minimal configuration using a `MLToolbox.json` file.

Whether you are building your first toolbox or maintaining a complex library, Matbox helps you stay organized, efficient, and focused on writing great code.

## How to use:

1. Create a new repository using [template repository](https://github.com/ehennestad/Matlab-Toolbox). It is also possible to use MatBox with an existing repository, but this option is currently not documented. Check the example repositories for hints on how to set things up.

2. If your project have dependencies, add a `requirements.txt` in the root of your repository:
<details>
<summary>Example of requirements.txt from openMINDS_MATLAB_UI</summary>

### requirements.txt
```
https://github.com/openMetadataInitiative/openMINDS_MATLAB
https://github.com/ehennestad/StructEditor
https://github.com/VervaekeLab/NANSEN
fex://66235-widgets-toolbox-compatibility-support/1.3.330
fex://83328-widgets-toolbox-matlab-app-designer-components
fex://160058-recursively-list-files-and-folders
fex://167901-iconbutton-app-component
```
</details>

3. Add a `setup.m` based on the [setup template](https://github.com/ehennestad/MatBox/blob/main/code/templates/setup.m)

4. Make necessary adjustments to workflow definitions in `.github/workflows`. Todo: document and/or improve template repo initialization.

5. Customize functions in the `tools/` if necessary.


## Example repositories
- https://github.com/ehennestad/dropbox-sdk-matlab
- https://github.com/ehennestad/openMINDS-MATLAB-UI


## Requirements
It is recommended to use MATLAB R2023a or later. Toolbox packaging will only work with R2023 or later, other functionality of the toolbox should work with older releases as well.

