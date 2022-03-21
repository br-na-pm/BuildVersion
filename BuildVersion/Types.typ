
TYPE
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
		New_Member : USINT;
	END_STRUCT;
END_TYPE
