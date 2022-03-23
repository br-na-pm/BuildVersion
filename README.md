# BuildVersion

BuildVersion is a software package for Automation Studio projects.  
The package includes a powershell script to automatically capture version information during a build.  
The script is intended for use with the version control system [git](https://git-scm.com/).  
The information captured is automatically initialized to local and/or global variables in the project.  

## Installation

1. Add package to project
    - Download and unarchive the BuildVersion package
    - Find existing package in the Automation Studio toolbox to import BuildVersion into logical view
2. Create pre-build event
    - Under the active configuration in configuration view, right-click the CPU directory and select properties
    - Find the build events tab and place the following text in the pre-build field

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
    - A confirmation message is written to the console regarding which variable is initialized.
    - Aside from the variable of type `BuildVersionType`, the entire contents of the global variable declaration file remain unchanged.
- Configuration Version
    - Experimental.
- mappView Widgets
    - Coming soon.

## Example

<p align="center">
<img style="width:634px; height:auto;"  src="https://user-images.githubusercontent.com/33841634/159568733-46de9fce-ffc2-41d3-8f3b-b9ccec9153e3.png" alt="2022-03-22_15 17 40" >
</p>


