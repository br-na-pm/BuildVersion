
TYPE
	BuildVersionType : 	STRUCT 
		Git : BuildVersionGitType;
		Project : BuildVersionProjectType;
	END_STRUCT;
	BuildVersionGitType : 	STRUCT 
		Url : STRING[255];
		Branch : STRING[80];
		Tag : STRING[80];
		AdditionalCommits : UINT;
		Sha1 : STRING[80];
		Describe : STRING[80];
		UncommittedChanges : STRING[80];
		CommitDate : DATE_AND_TIME;
		CommitAuthorName : STRING[80];
		CommitAuthorEmail : STRING[80];
	END_STRUCT;
	BuildVersionProjectType : 	STRUCT 
		ASVersion : STRING[80];
		UserName : STRING[80];
		ProjectName : STRING[80];
		Configuration : STRING[80];
		BuildMode : STRING[80];
		BuildDate : DT;
	END_STRUCT;
END_TYPE
