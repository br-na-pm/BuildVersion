# Default paths:
# - Logical
# |  - BuildVersion
#    |  - BuildVersion
#    |  |  - Main.st
#    |  |  - Types.typ
#    |  |  - Variables.var
#    |  - BuildVersion.ps1
$DefaultOutput = $args[0] + "\Logical\BuildVersion\BuildVersion\Variables.var" 
$GlobalVariableFile = $args[0] + "\Logical\Global.var" # Location to check for declaration of $StructureIdentifier type
$StructureIdentifier = "BuildVersionType" # Structure found in BuildVersion.typ with two structure members "Git" and "Project"

# Truncate strings to match size of type declaration
function TruncateString {
    param (
        [String]$Str,
        [Int]$Len
    )
    if($Str.Length -gt $Len) {$Str.Substring(0,$Len)}
    else {$Str}
}

$ScriptName = $MyInvocation.MyCommand.Name
Write-Host "Running $ScriptName powershell script"

################################################################################
################################################################################
################################################################################
# Git Commands
################################################################################
################################################################################
################################################################################

# Is git command available? Use `git version`
git version *> $Null 
if($LASTEXITCODE -ne 0) {
    Write-Host "BuildVersion: Git in not installed or is not available in PATH environment. Please install Git (https://git-scm.com/) will recommended option for PATH"
    return
}

# Is the project in a repository? Use `git config --list --local`
git -C $args[0] config --list --local *> $Null 
if($LASTEXITCODE -ne 0) {
    Write-Host "BuildVersion: No local repository has been found in the project root. Please initialize a repository with Git"
    return
}

############
# Remote URL
############
# References:
# https://reactgo.com/git-remote-url/

$Url = git -C $args[0] config --get remote.origin.url 2> $Null
if($LASTEXITCODE -ne 0) {
    Write-Host "BuildVersion: This git repository has no remote defined or the name differs from ""origin"""
    $Url = "Unknown"
}
$Url = TruncateString -Str $Url -Len 255

########
# Branch
########
# References:
# https://stackoverflow.com/a/12142066 

$Branch = git -C $args[0] branch --show-current 2> $Null
if($LASTEXITCODE -ne 0) {
    Write-Host "BuildVersion: The local repository appears to be in a headless state. Please checkout a branch"
    $Branch = "Unknown"
}
$Branch = TruncateString -Str $Branch -Len 80

###################################
# Tag, Additional Commits, Describe
###################################
# References:
# "Most recent tag" https://stackoverflow.com/a/7261049
# "Catching exceptions" https://stackoverflow.com/a/32287181
# "Suppressing outputs" https://stackoverflow.com/a/57548278

$Tag = git -C $args[0] describe --tags --abbrev=0 2> $Null
if($LASTEXITCODE -ne 0) {
    Write-Host "BuildVersion: No tags have been created on this branch"
    $Tag = "None"
    $Describe = "None"
    $AdditionalCommits = 0
}
else {
    $Describe = git -C $args[0] describe --tags 2> $Null
    if($Describe.Replace($Tag,"").Split("-").Length -ne 3) {
        Write-Host "BuildVersion: Git describe is unable to determine the number of additional commits"
        $AdditionalCommits = 0
    }
    else {$AdditionalCommits = $Describe.Replace($Tag,"").Split("-")[1]}
}
$Tag = TruncateString -Str $Tag -Len 80
$Describe = TruncateString -Str $Describe -Len 80

######
# Sha1
######
# References:
# https://www.systutorials.com/how-to-get-the-latest-git-commit-sha-1-in-a-repository/

$Sha1 = git -C $args[0] rev-parse HEAD 2> $Null
if($LASTEXITCODE -ne 0) {
    Write-Host "BuildVersion: Unable to determine latest secure hash"
    $Sha1 = "Unknown"
}
$Sha1 = TruncateString -Str $Sha1 -Len 80

#####################
# Uncommitted Changes
#####################

$UncommittedChanges = git -C $args[0] diff --shortstat 2> $Null
if($UncommittedChanges.Length -eq 0) {$UncommittedChanges = "None"}
$UncommittedChanges = TruncateString -Str $UncommittedChanges -Len 80

######
# Date
######

$GitDate = git -C $args[0] log -1 --format=%cd --date=iso 2> $Null
if($LASTEXITCODE -ne 0) {
    Write-Host "BuildVersion: Unable to determine latest commit date"
    $CommitDate = "2000-01-01-00:00:00"
}
else {$CommitDate = Get-Date $GitDate -Format "yyyy-MM-dd-HH:mm:ss"}

##############################
# Commit Author Name and Email
##############################
# References:
# https://stackoverflow.com/a/41548774

$CommitAuthorName = git -C $Args[0] log -1 --pretty=format:'%an' 2> $Null
$CommitAuthorEmail = git -C $Args[0] log -1 --pretty=format:'%ae' 2> $Null
if($LASTEXITCODE -ne 0) {
    Write-Host "BuildVersion: Unable to determine latest commit author"
    $CommitAuthorName = "Unknown"
    $CommitAuthorEmail = "Unknown"
}
$CommitAuthorName = TruncateString -Str $CommitAuthorName -Len 80
$CommitAuthorEmail = TruncateString -Str $CommitAuthorEmail -Len 80

################################################################################
################################################################################
################################################################################
# Project References
################################################################################
################################################################################
################################################################################
$ASVersion = $args[1]
$ASVersion = TruncateString -Str $ASVersion -Len 80
$UserName = $args[2]
$UserName = TruncateString -Str $UserName -Len 80
$ProjectName = $args[3]
$ProjectName = TruncateString -Str $ProjectName -Len 80
$Configuration = $args[4]
$Configuration = TruncateString -Str $Configuration -Len 80
$BuildMode = $args[5]
$BuildMode = TruncateString -Str $BuildMode -Len 80
$BuildDate = Get-Date -Format "yyyy-MM-dd-HH:mm:ss"

################################################################################
################################################################################
################################################################################
# Output
################################################################################
################################################################################
################################################################################

################
# Initialization
################
$GitInit = "(Url:='$Url',Branch:='$Branch',Tag:='$Tag',AdditionalCommits:=$AdditionalCommits,Sha1:='$Sha1',Describe:='$Describe',UncommittedChanges:='$UncommittedChanges',CommitDate:=DT#$CommitDate,CommitAuthorName:='$CommitAuthorName',CommitAuthorEmail:='$CommitAuthorEmail')"
$ProjectInit = "(ASVersion:='$ASVersion',UserName:='$UserName',ProjectName:='$ProjectName',Configuration:='$Configuration',BuildMode:='$BuildMode',BuildDate:=DT#$BuildDate)"
$BuildVersionInit = "(Git:=$GitInit,Project:=$ProjectInit)"

###################################
# Check global variable declaration
###################################
$GlobalOption = $False
if([System.IO.File]::Exists($GlobalVariableFile)) {
    $GlobalVariableContent = Get-Content $GlobalVariableFile
    $GlobalVariableMatch = [regex]::Match($GlobalVariableContent, "([a-zA-Z_][a-zA-Z_0-9]+)\s*:\s*$StructureIdentifier\s*(:=)?\s*[!;]*\s*;")
    if($GlobalVariableMatch.Success) {
        $GlobalVariableIdentifier = $GlobalVariableMatch.Groups[1]
        Write-Host "BuildVersion: Writing version information to $GlobalVariableIdentifier of type $StructureIdentifier in file $GlobalVariableFile"
        Set-Content -Path $GlobalVariableFile $GlobalVariableContent.Replace($GlobalVariableMatch.Value, "$GlobalVariableIdentifier : $StructureIdentifier := $BuildVersionInit;")
        $GlobalOption = $True 
    }
}

####################################
# Generate Variable Declaration File
####################################

$FileContent = @"
(*This file was automatically generated by $ScriptName.*)
(*Do not modify the contents of this file.*)
VAR
    BuildVersion : BuildVersionType := $BuildVersionInit;
END_VAR
"@

Set-Content -Path $DefaultOutput $FileContent
