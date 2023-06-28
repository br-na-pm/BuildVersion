################################################################################
# File: 
#   BuildVersion.ps1
# Authors:
#   Wesley Buchanan
#   Tyler Matijevich
#   Connor Trostel
# Date: 
#   2022-03-21
################################################################################

$ScriptName = $MyInvocation.MyCommand.Name
Write-Host "BuildVersion: Running $ScriptName powershell script"

################################################################################
# Note
################################################################################
# Please edit the "Parameters" section just below as you see fit
# Pre-build event field (also in README):
# PowerShell -ExecutionPolicy ByPass -File $(WIN32_AS_PROJECT_PATH)\Logical\BuildVersion\BuildVersion.ps1 $(WIN32_AS_PROJECT_PATH) "$(AS_VERSION)" "$(AS_USER_NAME)" "$(AS_PROJECT_NAME)" "$(AS_CONFIGURATION)" "$(AS_BUILD_MODE)"

################################################################################
# Parameters
################################################################################
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

################################################################################
# Check project
################################################################################
# Debug
# for($i = 0; $i -lt $args.Length; $i++) {
#     $Value = $args[$i]
#     Write-Host "Debug BuildVersion: Argument $i = $Value"
# }

if($args.Length -lt 1) {
    # Write-Warning output to the Automation Studio console is limited to 110 characters (AS 4.11.5.46 SP)
    Write-Warning "BuildVersion: Missing project path argument `$(WIN32_AS_PROJECT_PATH)"
    if($OptionErrorOnArguments) { exit 1 } 
    exit 0
}

$LogicalPath = $args[0] + "\Logical\"
if(-not [System.IO.Directory]::Exists($LogicalPath)) {
    $Path = $args[0]
    Write-Warning "BuildVersion: Cannot find Logical folder in $Path"
    if($OptionErrorOnArguments) { exit 1 } 
    exit 0
}

################################################################################
# Search
################################################################################
# Search for directories named $ProgramName
$Search = Get-ChildItem -Path $LogicalPath -Filter $ProgramName -Recurse -Directory -Name
$ProgramFound = $False
# Loop through zero or more directories named $ProgramName
foreach($SearchItem in $Search) {
    $ProgramPath = $LogicalPath + $SearchItem + "\"
    # Search for any file in this directory with extension .prg
    $SubSearch = Get-ChildItem -Path $ProgramPath -Filter "*.prg" -Name
    # If there is at least one *.prg file assume Automation Studio program
    if($SubSearch.Count -eq 1) {
        $ProgramFound = $True
        $PackageFile = $ProgramPath + $SubSearch
        $RelativeProgramPath = $ProgramPath.Replace($LogicalPath, ".\Logical\")
        Write-Host "BuildVersion: Located $ProgramName program at $RelativeProgramPath"
        break
    }
}
if(-NOT $ProgramFound) {
    Write-Warning "BuildVersion: Unable to locate $ProgramName in $LogicalPath"
}

# Search for global variable declaration file
$Search = Get-ChildItem -Path $LogicalPath -Filter $GlobalDeclarationName -Recurse -File -Name 
$GlobalFileFound = $False
foreach($SearchItem in $Search) {
    $GlobalFile = $LogicalPath + $SearchItem
    $GlobalFileFound = $True
    $RelativeGlobalFile = $GlobalFile.Replace($LogicalPath, ".\Logical\")
    Write-Host "BuildVersion: Located $GlobalDeclarationName at $RelativeGlobalFile"
    # Only take the first Global.var found
    break
}
if(-not $GlobalFileFound) {
    # This is only informational because a global variable declaration is optional
    Write-Host "BuildVersion: Unable to locate $GlobalDeclarationName in $LogicalPath"
}

################################################################################
# Git information
################################################################################
# Truncate strings to match size of type declaration
function TruncateString {
    param ([String]$String,[Int]$Length)
    $String.Substring(0,[System.Math]::Min($Length,$String.Length))
}

# Assume true
$BuiltWithGit = 1

# Is git command available? Use `git version`
try {git version *> $Null} 
catch {
    Write-Warning "BuildVersion: Git in not installed or unavailable in PATH environment"
    if($OptionErrorOnRepositoryCheck) { exit 1 }
    $BuiltWithGit = 0
}

# Is the project in a repository? Use `git config --list --local`
git -C $args[0] config --list --local *> $Null 
if($LASTEXITCODE -ne 0) {
    if($BuiltWithGit) { Write-Warning "BuildVersion: No local repository has been found in the project root" }
    if($OptionErrorOnRepositoryCheck) { exit 1 }
    $BuiltWithGit = 0
}

# Remote URL
# References:
# https://reactgo.com/git-remote-url/
$Url = git -C $args[0] config --get remote.origin.url 2> $Null
if($LASTEXITCODE -ne 0) {
    if($BuiltWithGit) { Write-Warning "BuildVersion: Git repository has no remote or differs from ""origin""" }
    $Url = "Unknown"
}
$Url = TruncateString $Url 255

# Branch
# References:
# https://stackoverflow.com/a/12142066 
$Branch = git -C $args[0] branch --show-current 2> $Null
if($LASTEXITCODE -ne 0) {
    if($BuiltWithGit) { Write-Warning "BuildVersion: Local repository is in a headless state" }
    $Branch = "Unknown"
}
$Branch = TruncateString $Branch 80

# Tag, additional commits, describe
# References:
# "Most recent tag" https://stackoverflow.com/a/7261049
# "Catching exceptions" https://stackoverflow.com/a/32287181
# "Suppressing outputs" https://stackoverflow.com/a/57548278
$Tag = git -C $args[0] describe --tags --abbrev=0 2> $Null
if($LASTEXITCODE -ne 0) {
    if($BuiltWithGit) { Write-Warning "BuildVersion: No tags have been created on this branch" }
    $Tag = "None"
    $Describe = "None"
    $AdditionalCommits = 0
    $Version = "None"
}
else {
    $Describe = git -C $args[0] describe --tags --long 2> $Null
    if($Describe.Replace($Tag,"").Split("-").Length -ne 3) {
        if($BuiltWithGit) { Write-Warning "BuildVersion: Unable to determine # of additional commits" }
        $AdditionalCommits = 0
        $Version = $Tag
    }
    else {
        $AdditionalCommits = $Describe.Replace($Tag,"").Split("-")[1]
        $Version = $Tag + "-" + $AdditionalCommits
    }
}
$Tag = TruncateString $Tag 80
$Describe = TruncateString $Describe 80

# Sha1
# References:
# https://www.systutorials.com/how-to-get-the-latest-git-commit-sha-1-in-a-repository/
$Sha1 = git -C $args[0] rev-parse HEAD 2> $Null
if($LASTEXITCODE -ne 0) {
    if($BuiltWithGit) { Write-Warning "BuildVersion: Unable to determine latest secure hash" }
    $Sha1 = "Unknown"
}
$Sha1 = TruncateString $Sha1 80

# Uncommitted changes
$ChangeWarning = 1
$UncommittedChanges = git -C $args[0] diff --shortstat 2> $Null
if($LASTEXITCODE -ne 0) {
    $UncommittedChanges = "Unknown"
    $ChangeWarning = 0
}
elseif($UncommittedChanges.Length -eq 0) {
    $UncommittedChanges = "None"
    $ChangeWarning = 0
}
elseif($OptionErrorOnUncommittedChanges) {
    Write-Warning "BuildVersion: Uncommitted changes detected"
    exit 1
}
$UncommittedChanges = TruncateString $UncommittedChanges.Trim() 80

# Date
$GitDate = git -C $args[0] log -1 --format=%cd --date=iso 2> $Null
if($LASTEXITCODE -ne 0) {
    if($BuiltWithGit) { Write-Warning "BuildVersion: Unable to determine latest commit date" }
    $CommitDate = "2000-01-01-00:00:00"
}
else {$CommitDate = Get-Date $GitDate -Format "yyyy-MM-dd-HH:mm:ss"}

# Commit author name and email
# References:
# https://stackoverflow.com/a/41548774
$CommitAuthorName = git -C $Args[0] log -1 --pretty=format:'%an' 2> $Null
$CommitAuthorEmail = git -C $Args[0] log -1 --pretty=format:'%ae' 2> $Null
if($LASTEXITCODE -ne 0) {
    if($BuiltWithGit) { Write-Warning "BuildVersion: Unable to determine latest commit author" }
    $CommitAuthorName = "Unknown"
    $CommitAuthorEmail = "Unknown"
}
$CommitAuthorName = TruncateString $CommitAuthorName 80
$CommitAuthorEmail = TruncateString $CommitAuthorEmail 80

################################################################################
# Project information
################################################################################
$BuildDate = Get-Date -Format "yyyy-MM-dd-HH:mm:ss"

# Check arguments
if($args.Length -ne 6) {
    Write-Warning "BuildVersion: Missing or unknown arguments for project information"
    if($OptionErrorOnArguments) { exit 1 } 
    $ASVersion = "Unknown"
    $UserName = "Unknown"
    $ProjectName = "Unknown"
    $Configuration = "Unknown"
    $BuildMode = "Unknown"
}
else {
    $ASVersion = TruncateString $args[1] 80
    $UserName = TruncateString $args[2] 80
    $ProjectName = TruncateString $args[3] 80
    $Configuration = TruncateString $args[4] 80
    $BuildMode = TruncateString $args[5] 80
    $ProjectMarcos = [Ref]$ASVersion, [Ref]$UserName, [Ref]$ProjectName, [Ref]$Configuration, [Ref]$BuildMode 
    for($i = 0; $i -lt $ProjectMarcos.Length; $i++) {
        if($ProjectMarcos[$i].Value[0] -eq "$") { # Catch incomplete macros which cause warnings and confusion
            $ProjectMarcos[$i].Value = "Unknown"
        }
    }
}

################################################################################
# Initialization
################################################################################
$ScriptInitialization = "BuiltWithGit:=$BuiltWithGit"

$GitInitialization = "URL:='$Url',Branch:='$Branch',Tag:='$Tag',AdditionalCommits:=$AdditionalCommits,Version:='$Version',Sha1:='$Sha1',Describe:='$Describe',UncommittedChanges:='$UncommittedChanges',ChangeWarning:=$ChangeWarning,CommitDate:=DT#$CommitDate,CommitAuthorName:='$CommitAuthorName',CommitAuthorEmail:='$CommitAuthorEmail'"

$ProjectInitialization = "ASVersion:='$ASVersion',UserName:='$UserName',ProjectName:='$ProjectName',Configuration:='$Configuration',BuildMode:='$BuildMode',BuildDate:=DT#$BuildDate"

################################################################################
# Global declaration
################################################################################
$GlobalDeclarationFound = $False
if([System.IO.File]::Exists($GlobalFile)) {
    $Content = Get-Content -Raw $GlobalFile
    # Protect empty file
    if($Content.Length -eq 0) {$Content = " "}
    # Match global declaration
    $MatchDeclaration = [regex]::Match($Content, "(?x) (\w+) \s* : \s* $TypeIdentifier \s* (:= \s* \( (.+) \) \s*)? ;")
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
            Write-Host "BuildVersion: $Name's initialization in $RelativeGlobalFile updated with build version information"
        }
        else {
            $Content = $Content.Replace($MatchDeclaration.Value, "$Name : $TypeIdentifier := (Script:=($ScriptInitialization),Git:=($GitInitialization),Project:=($ProjectInitialization));")
            Set-Content -Path $GlobalFile $Content
            Write-Host "BuildVersion: $Name's initialization in $RelativeGlobalFile overwritten with build version information"
        }
        $GlobalDeclarationFound = $True
    }
    else {
        Write-Host "BuildVersion: No variable of type $TypeIdentifier found in $RelativeGlobalFile"
    }
}

################################################################################
# Local Declaration
################################################################################
# Read and search text in Variables.var in $ProgramName
if($ProgramFound) {
    # Read
    $File = $ProgramPath + "Variables.var"
    $RelativeFile = $File.Replace($LogicalPath, ".\Logical\")
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
BuildVersion \s* : \s* $TypeIdentifier \s*
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
        Write-Host "BuildVersion: $RelativeFile updated with build version information"
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
        Write-Host "BuildVersion: $RelativeFile overwritten with build version information"
    }

    # Register Variables.var in package definition
    if([System.IO.File]::Exists($PackageFile)) {
        $Content = Get-Content -Raw $PackageFile
        $Regex = "Variables\.var"
        $Match = [regex]::Match($Content, $Regex)
        if(-not $Match.Success) {
            $Regex = "(?x) <Files> ((?:.|\n)*) </Files>"
            $Match = [regex]::Match($Content, $Regex)
            if($Match.Success) {
                $Append = "`  <File Description=""Local variables"" Private=""true"">Variables.var</File>`r`n  "
                $Content = $Content.Replace($Match.Groups[1].Value, $Match.Groups[1].Value + $Append)
                Set-Content -Path $PackageFile -Encoding utf8 -NoNewLine $Content
                Write-Host "BuildVersion: Register $RelativeProgramPath Variable.var with package"
            }
        }
    }
}

################################################################################
# Complete
################################################################################
if((-not $GlobalDeclarationFound) -and (-not $ProgramFound)) {
    Write-Warning "BuildVersion: No local or global build version information has been initialized"
    if($OptionErrorIfNoInitialization) { exit 1 }
}
else {
    Write-Host "BuildVersion: Completed $ScriptName powershell script"
}
