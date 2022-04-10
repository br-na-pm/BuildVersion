# BuildVersion

[BuildVersion](https://github.com/br-na-pm/BuildVersion#readme) is a software package for Automation Studio projects.  
The package includes a PowerShell script to automatically capture version information during a build.  
The script is intended for use with the version control system [git](https://git-scm.com/).  
The information captured is automatically initialized to a local and/or global variable in the project.  
**NOTE:** This is not an official package. BuildVersion is provided as-is under the GNU GPL v3.0 license agreement.  

![Initialize build version 2022-03-31_12 27 13](https://user-images.githubusercontent.com/33841634/161134786-7ea1422b-55c4-4f49-a427-3e261ded259d.png)

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
PowerShell -ExecutionPolicy ByPass -File $(WIN32_AS_PROJECT_PATH)\Logical\BuildVersion\BuildVersion.ps1 "$(WIN32_AS_PROJECT_PATH)" "$(AS_VERSION)" "$(AS_USER_NAME)" "$(AS_PROJECT_NAME)" "$(AS_CONFIGURATION)" "$(AS_BUILD_MODE)"
```

![Step 2 2022-04-10_13-49-32](https://user-images.githubusercontent.com/33841634/162637534-a7b174c9-fff3-4a81-9096-b1335f0e7f23.gif)

Upon successful installation, users will see BuildVersion messages in the output results when building.

![BuildVersion output results 2022-04-10_13 48 16](https://user-images.githubusercontent.com/33841634/162637580-277bd6a0-d40b-4da7-bd82-3082ee8f065e.png)

## Features

- Local Variable Initialization
    - Following the [installation](#installation) instructions above, the local variable `BuildVersion` in the BuildVer program is automatically initialized with version information on any build. 
    - The entire variable declaration file is overwritten and automatically ignored by git to avoid frequent differences.
- Global Variable Initialization
    - Declare a variable with type `BuildVersionType` in the Global.var file. 
    - The BuildVersion package will search for any variable of this type and initialize it with the version information on any build. 
    - A confirmation message is written to the console regarding which variable was initialized.
    - Aside from the variable of type `BuildVersionType`, the Global.var file remains unchanged.
- Configuration Version
    - *Experimental*
	- Set the active configuration's version if the tag matches a `<major>.<minor>.<patch>` number format.
- mappView Widgets
    - *Coming soon*

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

## Build 

Building a project with this package may result in warnings for additional files.  

![Build warnings 2022-03-31_12 34 35](https://user-images.githubusercontent.com/33841634/161134955-5e71050f-bd1b-49cf-b07c-6408ae3c24ca.png)

In Automation Studio 4.11+, it is possible to add specific filters to warnings 9232 and 9233.  Navigate to Configuration View, right-click the PLC object and select properties, chose the Build tab, and add the follow text to the "Objects ignored for build warnings 9232 and 9233" field. The filters are case sensitive.

```
*README*;*LICENSE*;.git;.gitignore;.github
```

Prior to Automation Studio 4.11, it is possible to suppress *all* build warnings regarding additional files by using `-W 9232 9233` in the "Additional build options" field.
