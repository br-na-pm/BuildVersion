# BuildVersion [![Made For B&R](https://github.com/hilch/BandR-badges/blob/main/Made-For-BrAutomation.svg)](https://www.br-automation.com)

[BuildVersion](https://github.com/br-na-pm/BuildVersion#readme) is a software package for Automation Studio projects.  
The package includes a PowerShell script to automatically capture version information during a build.  
The script is intended for use with the version control system [git](https://git-scm.com/).  
The information captured is automatically initialized to a local and/or global variable in the project.  
**NOTE:** This is not an official package. BuildVersion is provided as-is under the GNU GPL v3.0 license agreement.  

![Initialize build version 2022-03-31_12 27 13](https://user-images.githubusercontent.com/33841634/161134786-7ea1422b-55c4-4f49-a427-3e261ded259d.png)

## Features

- Read git information (only if git repository is detected)
  - Branch, tag, hash, date, etc.
  - Git initialization values remain unmodified if no repository is detected
- Read project information
  - Configuration, build, date, etc.
- Update local and/or global variable initialization
  - `BuildVersion` variable in the BuildVer program is automatically initialized
  - The first variable of type `BuildVersionType` in Global.var is automatically initialized
- mappView widget integration
  - See [BuildVersion Widget Library](https://github.com/br-na-pm/BuildVersionWidget#readme)

## Installation

#### 1. Add Package to Project

- [Download](https://github.com/br-na-pm/BuildVersion/releases/latest/download/BuildVersion.zip) and extract the BuildVersion package
- Select Existing Package from the Automation Studio toolbox to import BuildVersion into logical view

![Step 1 2022-04-10_13-37-35](https://user-images.githubusercontent.com/33841634/162637472-ddf53ad9-52b9-4f34-935c-5416d5bc9a55.gif)

#### 2. Create Pre-Build Event

- Under the active configuration, right-click the CPU object and select properties
- Find the build events tab and populate the pre-build field with the following prompt
- The pre-build event must be set for each configuration seeking version information

```powershell
PowerShell -ExecutionPolicy ByPass -File $(WIN32_AS_PROJECT_PATH)\Logical\BuildVersion\BuildVersion.ps1 $(WIN32_AS_PROJECT_PATH) "$(AS_VERSION)" "$(AS_USER_NAME)" "$(AS_PROJECT_NAME)" "$(AS_CONFIGURATION)" "$(AS_BUILD_MODE)"
```

**NOTE**: The first variable argument after the file path, `$(WIN32_AS_PROJECT_PATH)`, is without quotes because it will resolve with quotes.  *For paths with spaces* (e.g. "C:\My Projects\WireBender") this call will fail when expicitely including quotes on the `$(WIN32_AS_PROJECT_PATH)` argument.

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
