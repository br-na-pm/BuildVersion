# BuildVersion

[BuildVersion](https://github.com/br-na-pm/BuildVersion#readme) is a software package for Automation Studio projects.  
The package includes a powershell script to automatically capture version information during a build.  
The script is intended for use with the version control system [git](https://git-scm.com/).  
The information captured is automatically initialized to local and/or global variables in the project.  
**NOTE:** This is not an official package. BuildVersion is provided as-is under the GNU GPL v3.0 license agreement.  

## Installation

1. Add package to project
    - [Download](https://github.com/br-na-pm/BuildVersion/releases/latest/download/BuildVersion.zip) and unarchive the BuildVersion package
    - Use the Existing Package object from the Automation Studio toolbox to import BuildVersion into logical view
2. Create pre-build event
    - Under the active configuration, right-click the CPU directory and select properties
    - Find the build events tab and populate the pre-build field with the following text

#### Existing Package

![Existing pacakge 2022-03-24_14 54 37](https://user-images.githubusercontent.com/33841634/160433934-09ac6e5c-f2cb-4907-9e5b-5cae5273824e.png)

#### CPU Properties

![CPU properties 2022-03-28_09 50 15](https://user-images.githubusercontent.com/33841634/160433980-0cf65aee-bd4e-4716-bc30-3c3e61983f6b.png)

#### Pre-build Field

![Pre-build field 2022-03-28_10 11 12](https://user-images.githubusercontent.com/33841634/160434011-19c77175-6574-4029-ae85-57cbb81b393f.png)

```powershell
PowerShell -ExecutionPolicy ByPass -File $(WIN32_AS_PROJECT_PATH)\Logical\BuildVersion\BuildVersion.ps1 "$(WIN32_AS_PROJECT_PATH)" "$(AS_VERSION)" "$(AS_USER_NAME)" "$(AS_PROJECT_NAME)" "$(AS_CONFIGURATION)" "$(AS_BUILD_MODE)"
```

## Features

- Local Variable Initialization
    - Following the [installation](#installation) instructions above, the local variable `BuildVersion` in the BuildVer program is automatically initialized with version information on any build. 
    - The entire variable declaration file is overwritten and automatically ignored by git to avoid frequent differences.
- Global Variable Initialization
    - Delare a varable with type `BuildVersionType` in the Global.var file at the root of the Logical directory. 
    - The BuildVersion package will find the first variable match and initialize with the version information on any build. 
    - A confirmation message is written to the console regarding which variable was initialized.
    - Aside from the variable of type `BuildVersionType`, the global variable declaration file's contents remain unchanged.
- Configuration Version
    - Experimental.
- mappView Widgets
    - Coming soon.

## Example

<p align="center">
<img style="width:634px; height:auto;"  src="https://user-images.githubusercontent.com/33841634/159568733-46de9fce-ffc2-41d3-8f3b-b9ccec9153e3.png" alt="2022-03-22_15 17 40" >
</p>

## Errors

> The argument "C:\projects\MyProject\Logical\BuildVersion\BuildVersion.ps1" to the -File parameter does not exist.

- Possible cause: The pre-build event was created but the BuildVersion package was not added to the project. 
  - *Remedy*: Follow the [installation](#installation) to add existing package to the project.
- Possible cause: The pre-build event created but does not point to the BuildVersion package. 
  - *Remedy*: Update the [pre-build field's](#pre-build-field) script path `$(WIN32_AS_PROJECT_PATH)\Logical\BuildVersion\BuildVersion.ps1` to match the path in the project

> Object "C:\projects\MyProject\Logical\BuildVersion\BuildVer\Variable.var" doesn't exist.

- Possible cause: The package was added to the project, but the pre-build event was not created.
  - *Remedy*: Follow the [installation](#installation) to add package to the project.
- Possible cause: The local task was renamed and the powershell script cannot find it.
  - *Remedy*: Update the powershell script's `$ProgramName` variable under Parameters (default `"BuildVer"`) to match the task name in the project

## Build 

Building a project with this package may result in console warnings for files not referenced in the project.  

In Automation Studio 4.11+, it is possible to add specific filters to warnings 9232 and 9233.  Navigate to Configuration View, right-click the PLC object and select properties, chose the Build tab, and add the follow text to the "Objects ignored for build warnings 9232 and 9233" field. The filters are case sensitive.

```
*README*;*LICENSE*;.git;.gitignore;.github
```

Prior to Automation Studio 4.11, it is possible to suppress *all* build warnings regarding unreferenced files by adding `-W 9232 9233` to the "Additional build options" field.
