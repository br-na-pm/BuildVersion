################################################################################
 # File: BuildVersion.ps1
 # Created: 2022-03-21
 # 
 # Contributors: 
 # - Wesley Buchanan
 # - Tyler Matijevich
 # - Connor Trostel
 # 
 # License:
 #  This file BuildVersion.ps1 is part of the BuildVersion project released 
 #  under the MIT License agreement.  For more information, please visit 
 #  https://github.com/br-na-pm/BuildVersion/blob/main/LICENSE.
################################################################################

# Parameters
param (
    # If the project path is not provided
    # Intentionally set the default value to "Invalid path" to fail the directory existence test
    [Parameter(Position = 0)][String]$ProjectPath = "Invalid path",

    [Parameter(Position = 1)][String]$StudioVersion = "Unknown",
    [Parameter(Position = 2)][String]$UserName = "Unknown",
    [Parameter(Position = 3)][String]$ProjectName = "Unknown",
    [Parameter(Position = 4)][String]$Configuration = "Unknown",
    [Parameter(Position = 5)][String]$BuildMode = "Unknown",

    # Project task to search for under Logical/ and update local Variables.var
    [String]$ProgramName = "BuildVer",
    # Global variable declaration file to search for under Logical/
    [String]$GlobalFilename = "Global.var",
    # Structure type identifier for git and project information
    [String]$TypeName = "BuildVersionType",

    # Create build error if git is not installed or no git repository is found in project root
    [switch]$ErrorOnRepository,
    # Create build error if uncommitted changes are found in git repository
    [switch]$ErrorOnChange,
    # Create build error if neither a local or global variable is initialized with version information
    [switch]$ErrorOnInitialization,

    # Print input parameters, results, and additional debug messages
    [switch]$PrintDebug
)

# Local functions
# Log information, warning, and eror
$LogDefault = "No message provided"
$LogPrefix = "BuildVersion:"

function LogInfo {
    param (
        [String]$Message = $LogDefault
    )

    # Could also use Write-Output cmdlet
    Write-Host "$LogPrefix $Message"

    # Write-Debug, Write-Information, Write-Process, and Write-Verbose
    # have no effect in the Automation Studio output results
}

function LogWarning {
    param (
        [String]$Message = $LogDefault
    )

    # Write-Warning cmdlet is limited to 110 characters in the Automation Studio output resutls
    # If a message exceeds 110 characters from Write-Warning
    # it is wrapped to the next line and written in a different color
    # Use Write-Host cmdlet instead and prefix with "WARNING: " to register with Automation Studio
    # Use foreground color for terminal testing external to Automation Studio
    Write-Host -ForegroundColor Yellow "WARNING: $LogPrefix $Message"
}

function ThrowError {
    param (
        [String]$Message = $LogDefault
    )

    # PowerShell's Write-Error outputs additional attributes Category and FullyQualifiedErrorId
    # The foreground color is in black
    # I think this is confusing to the user

    # Use "ERROR: " to register with Automation Studio
    # This will cause the Automation Studio build procedure to abort
    # A dialog window will appear
    # There will be no build summary message in the output results
    # The red foreground color helps when testing in other terminals and has no effect on Automation Studio
    Write-Host -ForegroundColor Red "ERROR: $LogPrefix $Message"
    
    # This provides an addition message in Automation Studio "Pre-build step was executed with errors"
    # For this reason, name the function ThrowError instead of LogError
    exit 1
}

function LogError {
    param (
        [Parameter(Position = 0)][String]$Message = $LogDefault,
        [switch]$Condition
    )
    if($Condition) {
        ThrowError $Message
    }
    else {
        LogWarning $Message
    }
}

function LogDebug {
    param (
        [Parameter(Position = 0)][String]$Message = "Debug message"
    )
    if($PrintDebug.IsPresent) {
        LogInfo ("(Debug) " + $Message)
    }
}

function CleanPath {
    param (
        [String]$Path
    )
    $EndsWithSlash = $False
    $LastCharacter = $Path[$Path.Length - 1]
    if (($LastCharacter -eq "/") -or ($LastCharacter -eq "\")) {
        $EndsWithSlash = $True
    }
    $Path = ($Path.Split("/\") | Where-Object {$_ -ne ""}) -Join "\"
    if ($EndsWithSlash) {
        $Path = $Path + "\"
    }
    return $Path
}

function StringTruncate {
    param (
        [Ref]$Text,
        # Truncate to a default length of 80 characters
        [Int]$Length = 80
    )
    $Copy = $($Text).Value
    # Verify reference parameter is of type string
    if ($Copy.GetType().Name -ne "String") {
        return
    }
    $($Text).Value = $Copy.SubString(0, [System.Math]::Min($Length, $Copy.Length))
}

# Initialize
$ScriptName = $MyInvocation.MyCommand.Name
LogInfo "Running $ScriptName PowerShell script"

# Print arguments
LogDebug "Parameter ProjectPath = `"$ProjectPath`""
LogDebug "Parameter StudioVersion = `"$StudioVersion`""
LogDebug "Parameter UserName = `"$UserName`""
LogDebug "Parameter ProjectName = `"$ProjectName`""
LogDebug "Parameter Configuration = `"$Configuration`""
LogDebug "Parameter BuildMode = `"$BuildMode`""
LogDebug "Parameter ProgramName = `"$ProgramName`""
LogDebug "Parameter GlobalFilename = `"$GlobalFilename`""
LogDebug "Parameter TypeName = `"$TypeName`""

# Verify logical path
$LogicalPath = CleanPath($ProjectPath + "\Logical\")
if([System.IO.Directory]::Exists($LogicalPath)) {
    LogInfo "Located Logical directory at $LogicalPath"
}
else {
    ThrowError "Unable to locate Logical directory in project path $ProjectPath"
}

# Locate program (task)
# Search for directories named $ProgramName
$Search = Get-ChildItem -Path $LogicalPath -Filter $ProgramName -Recurse -Directory -Name
$ProgramFound = $False
# Loop through zero or more directories named $ProgramName
foreach($SearchItem in $Search) {
    LogDebug "Search result in logical path for program name = `"$SearchItem`""
    $ProgramPath = CleanPath($LogicalPath + $SearchItem + "\")
    # Search for any file in this directory with extension .prg
    $SubSearch = Get-ChildItem -Path $ProgramPath -Filter "*.prg" -Name
    LogDebug "Search result in program path for program file = `"$SubSearch`""
    # If there is at least one *.prg file assume Automation Studio program
    if($SubSearch.Count -eq 1) {
        $ProgramFound = $True
        $PackageFile = $ProgramPath + $SubSearch
        LogInfo "Located `"$ProgramName`" program at $ProgramPath"
        break
    }
}
if(-NOT $ProgramFound) {
    LogWarning "Unable to locate `"$ProgramName`" program in $LogicalPath"
}

# Search for global variable declaration file
$Search = Get-ChildItem -Path $LogicalPath -Filter $GlobalFilename -Recurse -File -Name 
$GlobalFileFound = $False
foreach($SearchItem in $Search) {
    $GlobalFile = CleanPath($LogicalPath + $SearchItem)
    $GlobalFileFound = $True
    LogInfo "Located `"$GlobalFilename`" declaration file at $GlobalFile"
    # Only take the first Global.var found
    break
}
if(-not $GlobalFileFound) {
    # This is only informational because a global variable declaration is optional
    LogInfo "Unable to locate `"$GlobalFilename`" declaration file in $LogicalPath"
}

################################################################################
# Git information
################################################################################

# Is git command available? Use `git version`
try {
    git version *> $Null
} 
catch {
    LogError "Git in not installed or unavailable in PATH environment - re-launch Automation Studio after updating PATH" -Condition:$ErrorOnRepository
}

# Is the project in a repository? Use `git config --list --local`
try { 
    git -C $ProjectPath config --list --local *> $Null
    $BuiltWithGit = 1
    if($LASTEXITCODE -ne 0) {
        LogError "No local git repository is located at the project path $ProjectPath" -Condition:$ErrorOnRepository
        $BuiltWithGit = 0
    }
}
catch {
    $BuiltWithGit = 0
}

# Remote URL
# References:
# https://reactgo.com/git-remote-url/
try {
    $Url = git -C $ProjectPath config --get remote.origin.url 2> $Null
    if($LASTEXITCODE -ne 0) {
        LogWarning "Git repository has no remote or differs from `"origin`""
        $Url = "Unknown"
    }
}
catch {
    $Url = "Unknown"
}
StringTruncate ([Ref]$Url) 255

# Branch
# References:
# https://stackoverflow.com/a/12142066 
try {
    $Branch = git -C $ProjectPath branch --show-current 2> $Null
    if($LASTEXITCODE -ne 0 -or $null -eq $Branch) {
        LogWarning "Local repository is in a headless state"
        $Branch = "Unknown"
    }
}
catch {
    $Branch = "Unknown"
}
StringTruncate ([Ref]$Branch)

# Tag, additional commits, describe
# References:
# "Most recent tag" https://stackoverflow.com/a/7261049
# "Catching exceptions" https://stackoverflow.com/a/32287181
# "Suppressing outputs" https://stackoverflow.com/a/57548278
try {
    $Tag = git -C $ProjectPath describe --tags --abbrev=0 2> $Null
    if($LASTEXITCODE -ne 0) {
        LogWarning "No tags have been created on this branch"
        $Tag = "None"
        $Describe = "None"
        $AdditionalCommits = 0
        $Version = "None"
    }
    else {
        $Describe = git -C $ProjectPath describe --tags --long 2> $Null
        if($Describe.Replace($Tag,"").Split("-").Length -ne 3) {
            LogWarning "Unable to determine # of additional commits"
            $AdditionalCommits = 0
            $Version = $Tag
        }
        else {
            $AdditionalCommits = $Describe.Replace($Tag,"").Split("-")[1]
            $Version = $Tag + "-" + $AdditionalCommits
        }
    }
}
catch {
    $Tag = "None"
    $Describe = "None"
    $AdditionalCommits = 0
    $Version = "None"
}
StringTruncate ([Ref]$Tag)
StringTruncate ([Ref]$Describe)
StringTruncate ([Ref]$Version)

# Sha1
# References:
# https://www.systutorials.com/how-to-get-the-latest-git-commit-sha-1-in-a-repository/
try {
    $Sha1 = git -C $ProjectPath rev-parse HEAD 2> $Null
    if($LASTEXITCODE -ne 0) {
        LogWarning "Unable to determine latest secure hash"
        $Sha1 = "Unknown"
    }
}
catch {
    $Sha1 = "Unknown"
}
StringTruncate ([Ref]$Sha1)

# Uncommitted changes
try {
    $UncommittedChanges = git -C $ProjectPath diff --shortstat --merge-base HEAD 2> $Null
    if($LASTEXITCODE -ne 0) {
        $UncommittedChanges = "Unknown"
        $ChangeWarning = 0
    }
    elseif($UncommittedChanges.Length -eq 0) {
        $UncommittedChanges = "None"
        $ChangeWarning = 0
    }
    else {
        LogError "Uncommitted changes detected" -Condition:$ErrorOnChange
        $ChangeWarning = 1
    }
}
catch {
    $UncommittedChanges = "Unknown"
    $ChangeWarning = 0
}
StringTruncate ([Ref]$UncommittedChanges)

# Date
try {
    $GitDate = git -C $ProjectPath log -1 --format=%cd --date=iso 2> $Null
    if($LASTEXITCODE -ne 0) {
        LogWarning "Unable to determine latest commit date"
        $CommitDate = "2000-01-01-00:00:00"
    }
    else {
        $CommitDate = Get-Date $GitDate -Format "yyyy-MM-dd-HH:mm:ss"
    }
}
catch {
    $CommitDate = "2000-01-01-00:00:00"
}

# Commit author name and email
# References:
# https://stackoverflow.com/a/41548774
try {
    $CommitAuthorName = git -C $ProjectPath log -1 --pretty=format:'%an' 2> $Null
    $CommitAuthorEmail = git -C $ProjectPath log -1 --pretty=format:'%ae' 2> $Null
    if($LASTEXITCODE -ne 0) {
        LogWarning "Unable to determine latest commit author"
        $CommitAuthorName = "Unknown"
        $CommitAuthorEmail = "Unknown"
    }
}
catch {
    $CommitAuthorName = "Unknown"
    $CommitAuthorEmail = "Unknown"
}
StringTruncate ([Ref]$CommitAuthorName)
StringTruncate ([Ref]$CommitAuthorEmail)

################################################################################
# Project information
################################################################################
$BuildDate = Get-Date -Format "yyyy-MM-dd-HH:mm:ss"

StringTruncate ([Ref]$StudioVersion)
StringTruncate ([Ref]$UserName)
StringTruncate ([Ref]$ProjectName)
StringTruncate ([Ref]$Configuration)
StringTruncate ([Ref]$BuildMode)

$BuildVariables = [Ref]$StudioVersion, [Ref]$UserName, [Ref]$ProjectName, [Ref]$Configuration, [Ref]$BuildMode 
for($i = 0; $i -lt $BuildVariables.Length; $i++) {
    # Automation Studio build variables are resolved using the currency character '$'
    # However, '$' is also the escape character for IEC 61131-3 languages
    # This can cause confusing results
    # Check for any leading currency characters from unresolved macros
    if($BuildVariables[$i].Value[0] -eq "$") {
        $BuildVariables[$i].Value = "Unknown"
    }
}

################################################################################
# Initialization
################################################################################
$ScriptInitialization = "BuiltWithGit:=$BuiltWithGit"

$GitInitialization = "URL:='$Url',Branch:='$Branch',Tag:='$Tag',AdditionalCommits:=$AdditionalCommits,Version:='$Version',Sha1:='$Sha1',Describe:='$Describe',UncommittedChanges:='$UncommittedChanges',ChangeWarning:=$ChangeWarning,CommitDate:=DT#$CommitDate,CommitAuthorName:='$CommitAuthorName',CommitAuthorEmail:='$CommitAuthorEmail'"

$ProjectInitialization = "ASVersion:='$StudioVersion',UserName:='$UserName',ProjectName:='$ProjectName',Configuration:='$Configuration',BuildMode:='$BuildMode',BuildDate:=DT#$BuildDate"

################################################################################
# Global declaration
################################################################################
$GlobalDeclarationFound = $False
if([System.IO.File]::Exists($GlobalFile)) {
    $Content = Get-Content -Raw $GlobalFile
    # Protect empty file
    if($Content.Length -eq 0) {$Content = " "}
    # Match global declaration
    $MatchDeclaration = [regex]::Match($Content, "(?x) (\w+) \s* : \s* $TypeName \s* (:= \s* \( (.+) \) \s*)? ;")
    if($MatchDeclaration.Success) {
        $Name = $MatchDeclaration.Groups[1].Value
        # Match build version initialization
        $Regex = @"
(?x)
Script \s* := \s* \( ( .+ ) \)
\s* , \s*
Git \s* := \s* \( ( .+ ) \)
\s* , \s*
Project \s* := \s* \( ( .+ ) \)
"@
        $MatchInitialization = [regex]::Match($MatchDeclaration.Groups[3].Value, $Regex)
        if($MatchInitialization.Success) {
            # Debug
            # for($i = 0; $i -lt $MatchInitialization.Groups.Count; $i++) {
            #     $Value = $MatchInitialization.Groups[$i].Value
            #     Write-Host "Debug BuildVersion: MatchInitialization $i = $Value"
            # }
            $Content = $Content.Replace($MatchInitialization.Groups[1].Value, $ScriptInitialization)
            if($BuiltWithGit) { $Content = $Content.Replace($MatchInitialization.Groups[2].Value, $GitInitialization) }
            $Content = $Content.Replace($MatchInitialization.Groups[3].Value, $ProjectInitialization)
            Set-Content -Path $GlobalFile $Content
            LogInfo "`"$Name`" variable initialization updated with build version information at $GlobalFile"
        }
        else {
            $Content = $Content.Replace($MatchDeclaration.Value, "$Name : $TypeName := (Script:=($ScriptInitialization),Git:=($GitInitialization),Project:=($ProjectInitialization));")
            Set-Content -Path $GlobalFile $Content
            LogInfo "`"$Name`" variable initialization overwritten with build version information at $GlobalFile"
        }
        $GlobalDeclarationFound = $True
    }
    else {
        LogInfo "No variable of type `"$TypeName`" found in $GlobalFile"
    }
}

################################################################################
# Local Declaration
################################################################################
# Read and search text in Variables.var in $ProgramName
if($ProgramFound) {
    # Read
    $File = CleanPath($ProgramPath + "\Variables.var")
    if([System.IO.File]::Exists($File)) {
        $Content = Get-Content -Raw $File
        # Protect empty string
        if($Content.Length -eq 0) {$Content = " "}
    }
    else {
        # Force empty read
        $Content = " "
    }
    # Search
    $Regex = @"
(?x)
\(\*This \s file \s was \s automatically \s generated \s by \s ([\w\d\.]+) \s on \s ([\d-:]+)\.\*\) 
(?:.|\n)*
BuildVersion \s* : \s* $TypeName \s*
:= \s* \( \s*
Script \s* := \s* \( ( .+ ) \)
\s* , \s*
Git \s* := \s* \( ( .+ ) \)
\s* , \s*
Project \s* := \s* \( ( .+ ) \)
\s* \) \s* ;
"@
    $Match = [regex]::Match($Content, $Regex)
    if($Match.Success) {
        # Debug
        # for($i = 0; $i -lt $Match.Groups.Count; $i++) {
        #     $Value = $Match.Groups[$i].Value
        #     Write-Host "Debug BuildVersion: Match $i = $Value"
        # }
        $Content = $Content.Replace($Match.Groups[1].Value, $ScriptName)
        $Content = $Content.Replace($Match.Groups[3].Value, $ScriptInitialization)
        if($BuiltWithGit) { $Content = $Content.Replace($Match.Groups[4].Value, $GitInitialization) }
        $Content = $Content.Replace($Match.Groups[5].Value, $ProjectInitialization)
        # Run this after replacing project information which also includes the build date
        $Content = $Content.Replace($Match.Groups[2].Value, $BuildDate)
        Set-Content -Path $File $Content
        LogInfo "Local declaration file updated with build version information at $File"
    }
    else {
        $Content = @"
(*This file was automatically generated by $ScriptName on $BuildDate.*)
(*Do not modify the contents of this file.*)
VAR
    BuildVersion : BuildVersionType := (Script:=($ScriptInitialization),Git:=($GitInitialization),Project:=($ProjectInitialization)); (* Build version information *)
END_VAR
"@
        Set-Content -Path $File $Content
        LogInfo "Local declaration file overwritten with build version information at $File"
    }

    # Register Variables.var in package definition
    if([System.IO.File]::Exists($PackageFile)) {
        $Content = Get-Content -Raw $PackageFile
        $Regex = ">\s*Variables\.var\s*<"
        $Match = [regex]::Match($Content, $Regex)
        if(-not $Match.Success) {
            $Regex = "(?x) <Files> ((?:.|\n)*) </Files>"
            $Match = [regex]::Match($Content, $Regex)
            if($Match.Success) {
                $Append = "`  <File Description=""Local variables"" Private=""true"">Variables.var</File>`r`n  "
                $Content = $Content.Replace($Match.Groups[1].Value, $Match.Groups[1].Value + $Append)
                Set-Content -Path $PackageFile -Encoding utf8 -NoNewLine $Content
                LogInfo "`"$ProgramName`" program's `"Variables.var`" declaration file registered with package file at $PackageFile"
            }
        }
    }
}

################################################################################
# Complete
################################################################################
LogDebug "Result Git URL = `"$Url`""
LogDebug "Result Git Branch = `"$Branch`""
LogDebug "Result Git Tag = `"$Tag`""
LogDebug "Result Git Additional Commits = `"$AdditionalCommits`""
LogDebug "Result Git Version = `"$Version`""
LogDebug "Result Git SHA1 = `"$Sha1`""
LogDebug "Result Git Describe = `"$Describe`""
LogDebug "Result Git Uncommitted Changes = `"$UncommittedChanges`""
LogDebug "Result Git Commit Author = `"$CommitAuthorName`""
LogDebug "Result Git Commit Author Email = `"$CommitAuthorEmail`""

if((-not $GlobalDeclarationFound) -and (-not $ProgramFound)) {
    LogError "No local or global build version information has been initialized" -Condition:$ErrorOnInitialization
}
else {
    LogInfo "Completed $ScriptName powershell script"
}
