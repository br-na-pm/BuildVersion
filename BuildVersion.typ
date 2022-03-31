
TYPE
	BuildVersionType : 	STRUCT  (*BuildVersion structure definition*)
		Git : BuildVersionGitType; (*Git member*)
		Project : BuildVersionProjectType; (*Project member*)
	END_STRUCT;
	BuildVersionGitType : 	STRUCT  (*Git information structure definition*)
		URL : STRING[255]; (*URL of git server referenced by the default remote "origin"*)
		Branch : STRING[80]; (*Current branch checked out by local repository*)
		Tag : STRING[80]; (*Latest tag on current branch*)
		AdditionalCommits : UINT; (*Additional commits since latest tag*)
		Version : STRING[80]; (*<tag>-<addn_commits>*)
		Sha1 : STRING[80]; (*Full hash value from the latest commit*)
		Describe : STRING[80]; (*<tag>-<addn_commits>-g<short_sha1>*)
		UncommittedChanges : STRING[80]; (*Example: 5 files changed, 14 insertions(+), 11 deletions(-)*)
		CommitDate : DATE_AND_TIME; (*Local timestamp of the latest commit*)
		CommitAuthorName : STRING[80]; (*Name of author of latest commit*)
		CommitAuthorEmail : STRING[80]; (*Email of author of latest commit*)
	END_STRUCT;
	BuildVersionProjectType : 	STRUCT  (*Project information structure definition*)
		ASVersion : STRING[80]; (*From $(AS_VERSION), see help for PLC object properties*)
		UserName : STRING[80]; (*From $(AS_USER_NAME)*)
		ProjectName : STRING[80]; (*From $(AS_PROJECT_NAME)*)
		Configuration : STRING[80]; (*From $(AS_CONFIGURATION)*)
		BuildMode : STRING[80]; (*From $(AS_BUILD_MODE), see help for possible values - Build, Rebuild, BuildAndTransfer, ...*)
		BuildDate : DATE_AND_TIME; (*Local timestamp grabbed by powershell on build*)
	END_STRUCT;
END_TYPE
