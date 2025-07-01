<a href="https://github.com/user-attachments/assets/2d53e2fa-9b07-41b5-b20f-e086d126102d">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/2d53e2fa-9b07-41b5-b20f-e086d126102d">
    <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/2d53e2fa-9b07-41b5-b20f-e086d126102d">
    <img alt="Dropbox-API-Client-logo" src="[/resources/images/toolbox_image.png](https://github.com/user-attachments/assets/2d53e2fa-9b07-41b5-b20f-e086d126102d)" title="MatBox" align="right" height="70"​>
  </picture>
</a>

# MatBox: CI Tools for MATLAB Toolbox Development

[![Version Number](https://img.shields.io/github/v/release/ehennestad/MatBox?label=version)](https://github.com/ehennestad/MatBox/releases/latest)
[![View MatBox on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://se.mathworks.com/matlabcentral/fileexchange/180185-matbox)
[![MATLAB Tests](.github/badges/tests.svg)](https://github.com/ehennestad/MatBox/actions/workflows/update.yml)
[![codecov](https://codecov.io/gh/ehennestad/MatBox/graph/badge.svg?token=6D7STF19X0)](https://codecov.io/gh/ehennestad/MatBox)
[![MATLAB Code Issues](.github/badges/code_issues.svg)](https://github.com/ehennestad/MatBox/security/code-scanning)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://gitHub.com/ehennestad/MatBox/graphs/commit-activity)
[![Release](https://img.shields.io/badge/MATLAB-%3E%3DR2023b-blue?logo=data:image/svg%2bxml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjxzdmcKICAgd2lkdGg9IjEyIgogICBoZWlnaHQ9IjEwLjcyNSIKICAgdmlld0JveD0iMCAwIDEyIDEwLjcyNSIKICAgZmlsbD0ibm9uZSIKICAgdmVyc2lvbj0iMS4xIgogICBpZD0ic3ZnNCIKICAgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIgogICB4bWxuczpzdmc9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8ZwogICAgIGNsaXAtcGF0aD0idXJsKCNjbGlwMF8zMTRfMTY2KSIKICAgICBpZD0iZzIiCiAgICAgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoLTQsLTQuMDc1MjAwMSkiPgogICAgPHBhdGgKICAgICAgIGQ9Im0gNi4xNzUsMTEuNTc1MiBjIC0wLjYsLTAuNDUgLTEuMzUsLTAuOTc1IC0yLjE3NSwtMS41NzUgMC45NzUsLTAuMzc1IDEuOTUsLTAuNzUgMi45MjUsLTEuMTI1IGwgMS4yLDAuOSBjIC0wLjksMS4wNSAtMS41LDEuNDI1IC0xLjk1LDEuOCB6IG0gOC4wMjUsLTMuMTUgYyAtMC4yMjUsLTAuNiAtMC4zNzUsLTEuMiAtMC42LC0xLjggLTAuMjI1LC0wLjY3NSAtMC40NSwtMS4yNzUgLTAuODI1LC0xLjggLTAuMTUsLTAuMjI1IC0wLjQ1LC0wLjc1IC0wLjgyNSwtMC43NSAtMC4wNzUsMCAtMC4xNSwwLjA3NSAtMC4yMjUsMC4wNzUgLTAuMjI1LDAuMDc1IC0wLjUyNSwwLjUyNSAtMC42LDAuODI1IC0wLjIyNSwwLjM3NSAtMC42NzUsMC45NzUgLTAuOTc1LDEuMzUgLTAuMDc1LDAuMTUgLTAuMjI1LDAuMyAtMC4zLDAuMzc1IC0wLjIyNSwwLjE1IC0wLjQ1LDAuMzc1IC0wLjc1LDAuNTI1IC0wLjA3NSwwIC0wLjE1LDAuMDc1IC0wLjIyNSwwLjA3NSAtMC4yMjUsMCAtMC4zNzUsMC4xNSAtMC41MjUsMC4yMjUgLTAuMjI1LDAuMjI1IC0wLjQ1LDAuNTI1IC0wLjY3NSwwLjc1IDAsMC4wNzUgLTAuMDc1LDAuMTUgLTAuMTUsMC4yMjUgbCAxLjEyNSwwLjgyNSBjIDAuODI1LC0wLjk3NSAxLjgsLTEuOTUgMi40NzUsLTMuODI1IDAsMCAtMC4yMjUsMi4wMjUgLTIuMDI1LDQuMiAtMS4xMjUsMS4yNzUgLTIuMDI1LDEuOTUgLTIuMTc1LDIuMSAwLDAgMC4zLC0wLjA3NSAwLjYsMC4wNzUgMC42LDAuMjI1IDAuOSwxLjA1IDEuMTI1LDEuNjUgMC4xNSwwLjQ1IDAuMzc1LDAuODI1IDAuNTI1LDEuMjc1IDAuNiwtMC4xNSAwLjk3NSwtMC4zNzUgMS4zNSwtMC43NSAwLjM3NSwtMC4zNzUgMC43NSwtMC44MjUgMS4xMjUsLTEuMiAwLjY3NSwtMC44MjUgMS41LC0xLjg3NSAyLjU1LC0xLjM1IDAuMTUsMC4wNzUgMC4zNzUsMC4yMjUgMC40NSwwLjMgMC4yMjUsMC4xNSAwLjM3NSwwLjMgMC42LDAuNTI1IDAuMzc1LDAuMyAwLjUyNSwwLjUyNSAwLjgyNSwwLjY3NSAtMC43NSwtMS41IC0xLjI3NSwtMyAtMS44NzUsLTQuNTc1IHoiCiAgICAgICBmaWxsPSIjZmZmZmZmIgogICAgICAgaWQ9InBhdGgyIiAvPgogIDwvZz4KICA8ZGVmcwogICAgIGlkPSJkZWZzNCI+CiAgICA8Y2xpcFBhdGgKICAgICAgIGlkPSJjbGlwMF8zMTRfMTY2Ij4KICAgICAgPHJlY3QKICAgICAgICAgd2lkdGg9IjEyIgogICAgICAgICBoZWlnaHQ9IjEyIgogICAgICAgICBmaWxsPSIjZmZmZmZmIgogICAgICAgICB0cmFuc2Zvcm09InRyYW5zbGF0ZSg0LDQpIgogICAgICAgICBpZD0icmVjdDQiCiAgICAgICAgIHg9IjAiCiAgICAgICAgIHk9IjAiIC8+CiAgICA8L2NsaXBQYXRoPgogIDwvZGVmcz4KPC9zdmc+Cg==&label=MATLAB&labelColor=C95C2E&color=2A5F98)](https://se.mathworks.com/products/new_products/release2022b.html)

---

MatBox is a streamlined solution for managing MATLAB toolbox development: automate code checks, dependency management, cleaning, packaging, and continuous integration.

---

## 🚀 Features

- **Automated Dependency Management**: Use a `requirements.txt` for easy installation/configuration.
- **Continuous Integration**: Ready-to-use GitHub Actions and workflow templates for code analysis and unit testing.
- **Effortless Packaging**: Bundle your toolbox with a simple `MLToolbox.json` file.

---

## ⚡ Quickstart

### 1. New Projects

- **Create a repository** using the [MATLAB Toolbox Template](https://github.com/ehennestad/matlab-toolbox-template).
- (Optional) **Add dependencies** in a `requirements.txt` (see below).
- **Customize `setup.m`** ([template here](https://github.com/ehennestad/MatBox/blob/main/code/templates/setup.m)).
- **Adjust workflow files** in `.github/workflows` if needed.
- **Add or override CI functions** in the `tools/` directory.

### 2. Adding to Existing Projects

> **Note:** Direct documentation for retrofitting MatBox to existing repositories is in progress.  
> See [openMINDS-MATLAB-UI](https://github.com/ehennestad/openMINDS-MATLAB-UI) for a practical example.

**Minimal steps:**
- Add MatBox as a dependency (see [matbox-actions/install-matbox](https://github.com/ehennestad/matbox-actions/tree/main/install-matbox)).
- Add/adjust `requirements.txt`, `setup.m`, and `.github/workflows` as above.
- Place custom tasks (optional) in a `tools/` folder.

---

## 📦 Requirements & Installation

- **MATLAB R2023a** or later is recommended for toolbox packaging (other features may work with older versions).
- To install dependencies listed in your `requirements.txt`:
    ```matlab
    matbox.installRequirements(pwd)
    ```
- Example `requirements.txt`:
    ```
    https://github.com/openMetadataInitiative/openMINDS_MATLAB
    https://github.com/ehennestad/StructEditor
    fex://66235-widgets-toolbox-compatibility-support/1.3.330
    fex://83328-widgets-toolbox-matlab-app-designer-components
    ```

---

## 🧑‍💻 Basic Usage

- **Run tests**:
    ```matlab
    matbox.tasks.testToolbox(pwd)
    ```
- **Package your toolbox**:
    ```matlab
    [newVersion, mltbxPath] = matbox.tasks.packageToolbox(pwd, 'build')
    ```

---

## 🏁 Example Repositories

- [dropbox-sdk-matlab](https://github.com/ehennestad/dropbox-sdk-matlab)
- [openMINDS-MATLAB-UI](https://github.com/ehennestad/openMINDS-MATLAB-UI)

---

## 🛠 FAQ / Troubleshooting

**Q: Can I use MatBox with an existing non-template repo?**  
A: Yes, with some manual setup; see the [example repo](https://github.com/ehennestad/openMINDS-MATLAB-UI).

**Q: Where do I put custom CI or utility functions?**  
A: In the `tools/` directory of your project.

**Q: How do I run tests or package my toolbox?**  
A: See "Basic Usage" above.

---

## 🤝 Contributing

Please see [CONTRIBUTING.md](.github/CONTRIBUTING.md).

---

## 📝 License

This project is available under the MIT License. See [LICENSE](LICENSE).

---

**See also:**  
- [MatBox Actions (GitHub Actions)](https://github.com/ehennestad/matbox-actions)
- [MATLAB Toolbox Template](https://github.com/ehennestad/matlab-toolbox-template)