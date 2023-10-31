# BuildVersion [![Made For B&R](https://raw.githubusercontent.com/hilch/BandR-badges/main/Made-For-BrAutomation.svg)](https://www.br-automation.com)

[BuildVersion](https://github.com/br-na-pm/BuildVersion#readme) is a software package for [Automation Studio](https://www.br-automation.com/en/products/software/automation-software/automation-studio/) projects.  
The package includes a [PowerShell](https://learn.microsoft.com/en/powershell/) script to automatically capture version information during a build.  
The script is intended for use with the version control system [git](https://git-scm.com/).  
**NOTE:** This is not an official package. BuildVersion is provided as-is under the GNU GPL v3.0 license agreement.  

![Initialize build version 2022-03-31_12 27 13](https://user-images.githubusercontent.com/33841634/161134786-7ea1422b-55c4-4f49-a427-3e261ded259d.png)

## Features

- Capture git repository information and Automation Studio project information
- Use with and without git
  - The git info is only updated if a repository is detected, otherwise unmodified
- Initialize local variable
  - **Variables.var** in **BuildVer** task located anywhere in **Logical** folder
- Initialize global variable
  - First variable of **BuildVersionType** in **Global.var** located anywhere in **Logical** folder
- PowerShell script will not error project compilation after successful [installation](#installation)
- mappView widget integration
  - See [BuildVersion Widget Library](https://github.com/br-na-pm/BuildVersionWidget#readme)

## Installation

#### 1. Add Package to Project

- [Download](https://github.com/br-na-pm/BuildVersion/releases/latest/download/BuildVersion.zip) and extract
- Logical View -> select project folder -> Toolbox -> Existing Package -> import BuildVersion

![Step 1 2022-04-10_13-37-35](https://user-images.githubusercontent.com/33841634/162637472-ddf53ad9-52b9-4f34-935c-5416d5bc9a55.gif)

#### 2. Create Pre-Build Event

- Configuration View -> active configuration -> right-click CPU object -> Properties
- Build Events -> Configuration Pre-Build Step -> Insert the following

```powershell
PowerShell -ExecutionPolicy ByPass -File $(WIN32_AS_PROJECT_PATH)\Logical\BuildVersion\BuildVersion.ps1 $(WIN32_AS_PROJECT_PATH) "$(AS_VERSION)" "$(AS_USER_NAME)" "$(AS_PROJECT_NAME)" "$(AS_CONFIGURATION)" "$(AS_BUILD_MODE)"
```

The first argument `$(WIN32_AS_PROJECT_PATH)` omits surrounding quotes because it will resolve with quotes.  If extra quotes are added to this argument, project paths with spaces will fail to be read ("C:\My Projects\CoffeeMachine").

The Pre-Build Step will have to be set for all desired configurations.

![Step 2 2022-04-10_13-49-32](https://user-images.githubusercontent.com/33841634/162637534-a7b174c9-fff3-4a81-9096-b1335f0e7f23.gif)

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

The PowerShell script provides several options for naming, error severity, and build reaction.  
By default, the PowerShell script will not generate a build error (if installed correctly).  
However, developers may wish to enable more severe build reactions given the git version information. The options are detailed below and can be enabled by setting the `$True` constant in BuildVersion.ps1.

```powershell
############
# Parameters
############
# The script will search under Logical to find this program (e.g. .\Logical\BuildVersion\BuildVer)
$ProgramName = "BuildVer"
# The script will search under Logical to find this variable file (e.g. .\Logical\Global.var)
$GlobalDeclarationName = "Global.var"
# The script will search for variables of this type
$TypeIdentifier = "BuildVersionType"

# Use $True or $False to select options
# Create build error if the script fails to due missing arguments
$OptionErrorOnArguments = $False
# Create build error if git is not installed or no git repository is found in project root
$OptionErrorOnRepositoryCheck = $False 
# Create build error if uncommitted changes are found in git repository
$OptionErrorOnUncommittedChanges = $False
# Create build error if neither a local or global variable is initialized with version information
$OptionErrorIfNoInitialization = $False
```

To run multiple commands in the pre-build event, use the follow syntax.

```powershell
<command_1> & <command_2>
```

For example, users can test the build script without building the whole project with the following example.  An error is forced at the end of the pre-build step.

```powershell
PowerShell -ExecutionPolicy ByPass -File $(WIN32_AS_PROJECT_PATH)\Logical\BuildVersion\BuildVersion.ps1 $(WIN32_AS_PROJECT_PATH) "$(AS_VERSION)" "$(AS_USER_NAME)" "$(AS_PROJECT_NAME)" "$(AS_CONFIGURATION)" "$(AS_BUILD_MODE)" & exit 1
```

## Build 

Building a project with this package may result in warnings for additional files.  

![Build warnings 2022-03-31_12 34 35](https://user-images.githubusercontent.com/33841634/161134955-5e71050f-bd1b-49cf-b07c-6408ae3c24ca.png)

In Automation Studio 4.11+, it is possible to add specific filters to warnings 9232 and 9233.  Navigate to Configuration View, right-click the PLC object and select properties, chose the Build tab, and add the follow text to the "Objects ignored for build warnings 9232 and 9233" field. The filters are case sensitive.

```
*README*;*LICENSE*;.git;.gitignore;.github
```

Prior to Automation Studio 4.11, it is possible to suppress *all* build warnings regarding additional files by using `-W 9232 9233` in the "Additional build options" field.
