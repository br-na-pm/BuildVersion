# BuildVersion

[![Made for B&R](https://raw.githubusercontent.com/hilch/BandR-badges/dfd5e264d7d2dd369fd37449605673f779db437d/Made-For-BrAutomation.svg)](https://www.br-automation.com)
![GitHub License](https://img.shields.io/github/license/br-na-pm/BuildVersion)
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/br-na-pm/BuildVersion/total)
[![GitHub issues](https://img.shields.io/github/issues-raw/br-na-pm/BuildVersion)](https://github.com/br-na-pm/BuildVersion/issues)

[BuildVersion](https://github.com/br-na-pm/BuildVersion#readme) is a software package for [Automation Studio](https://www.br-automation.com/en/products/software/automation-software/automation-studio/) projects to transfer version information to runtime variables during each build.

The package includes a Windows-native [PowerShell](https://learn.microsoft.com/en/powershell/) script to automatically capture version information during the pre-build event.  
The script is intended for use with the version control system [git](https://git-scm.com/).

**NOTE:** This is not an official package and is supported by the community.  BuildVersion is provided as-in under the [MIT License](https://mit-license.org/) agreement.  Source code, documentation, and issues are managed through [GitHub](https://github.com/br-na-pm/BuildVersion).

![Initialize build version 2022-03-31_12 27 13](https://user-images.githubusercontent.com/33841634/161134786-7ea1422b-55c4-4f49-a427-3e261ded259d.png)

## Features

- :octocat: Capture git repository information
- :arrow_down: Capture Automation Studio project and build information
- :beginner: Use with and without git
- :file_folder: Initialize local variable
- :earth_americas: Initialize global variable
- :warning: PowerShell script will not throw error in project build by default
- :tv: [mappView widget](https://github.com/br-na-pm/BuildVersionWidget#readme) integration

## Installation

#### 1. Add Package to Project

- [Download](https://github.com/br-na-pm/BuildVersion/releases/latest/download/BuildVersion.zip) and extract
- Logical View -> select project folder -> Toolbox -> Existing Package -> import BuildVersion

![Step 1 2022-04-10_13-37-35](https://user-images.githubusercontent.com/33841634/162637472-ddf53ad9-52b9-4f34-935c-5416d5bc9a55.gif)

#### 2. Create Pre-Build Event

- Configuration View -> active configuration -> right-click CPU object -> Properties
- Build Events -> Configuration Pre-Build Step -> Insert the following

```powershell
PowerShell -ExecutionPolicy ByPass -File $(WIN32_AS_PROJECT_PATH)\Logical\BuildVersion\BuildVersion.ps1 -ProjectPath $(WIN32_AS_PROJECT_PATH) -StudioVersion "$(AS_VERSION)" -UserName "$(AS_USER_NAME)" -ProjectName "$(AS_PROJECT_NAME)" -Configuration "$(AS_CONFIGURATION)" -BuildMode "$(AS_BUILD_MODE)"
```

![Step 2 2022-04-10_13-49-32](https://user-images.githubusercontent.com/33841634/162637534-a7b174c9-fff3-4a81-9096-b1335f0e7f23.gif)

If the BuildVersion package is placed in subdirectories of Logical, the pre-build event must be updated to reflect the subdirectories.  
For example, if the BuildVersion package is placed in a `Tools` subdirectory then the `-File` argument must be updated to the following.

```
-File $(WIN32_AS_PROJECT_PATH)\Logical\Tools\BuildVersion\BuildVersion.ps1
```

The Pre-Build Step will have to be set for all desired configurations.  

Upon successful installation, users will see BuildVersion messages in the output results when building.

![BuildVersion output results 2022-04-10_13 48 16](https://user-images.githubusercontent.com/33841634/162637580-277bd6a0-d40b-4da7-bd82-3082ee8f065e.png)

## Errors

> The argument "C:\projects\MyProject\Logical\BuildVersion\BuildVersion.ps1" to the -File parameter does not exist.

- Possible cause: The pre-build event was created but the BuildVersion package was not added to the project. 
  - *Remedy*: Follow the [installation](#installation) instructions to add existing package to the project.
- Possible cause: The pre-build event created but does not point to the BuildVersion package. 
  - *Remedy*: Update the [pre-build field's](#2-create-pre-build-event) script path `$(WIN32_AS_PROJECT_PATH)\Logical\BuildVersion\BuildVersion.ps1` to match the path in the project

> Object "C:\projects\MyProject\Logical\BuildVersion\BuildVer\Variable.var" doesn't exist.

- Possible cause: The BuildVersion package was added to the project, but the pre-build event was not created.
  - *Remedy*: Follow the [installation](#2-create-pre-build-event) instructions to create the pre-build event.
- Possible cause: The local task was renamed and the PowerShell script cannot find it.
  - *Remedy*: Update the PowerShell script's `$ProgramName` parameter (default `"BuildVer"`) to match the task name in the project.

> BuildVersion: Git in not installed or unavailable in PATH environment  
> BuildVersion: Please install git (git-scm.com) with recommended options for PATH  

- Possible cause: Using the git client Sourcetree with the embedded git preference.
  - *Remedy*: Installing Sourcetree before installing git causes Sourcetree to default to its embedded git option. Sourcetree's embedded git is not available in the PATH environment. [Install git separately](https://git-scm.com/) with default installer options to add git to the PATH environment.

## Developers

The [PowerShell script](https://github.com/br-na-pm/BuildVersion/blob/dd9dd64a9b23b1f31e800e7619e68b56a351374e/BuildVersion.ps1#L16) offers several optional [switch parameters](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-7.4#switch-parameters).

`-ErrorOnRepository`

Create a build error if git is not installed of the project path does not exist within a git repository.

`-ErrorOnChange`

Create a build error if the git repository shows uncommited changes.

`-ErrorOnInitialization`

Create a build error if neither the local variable or global variable was updated with build information.

`-PrintDebug`

Print all debug messages to the output results.

To run multiple commands in the pre-build event, use the follow syntax.

```powershell
<command_1> & <command_2>
```

## Build 

Building a project with this package may result in warnings for additional files.  

![Build warnings 2022-03-31_12 34 35](https://user-images.githubusercontent.com/33841634/161134955-5e71050f-bd1b-49cf-b07c-6408ae3c24ca.png)

In Automation Studio 4.11+, it is possible to add specific filters to warnings 9232 and 9233.  Navigate to Configuration View, right-click the PLC object and select properties, chose the Build tab, and add the follow text to the "Objects ignored for build warnings 9232 and 9233" field. The filters are case sensitive.

```
*README*;*LICENSE*;.git;.gitignore;.github
```

Prior to Automation Studio 4.11, it is possible to suppress *all* build warnings regarding additional files by using `-W 9232 9233` in the "Additional build options" field.
