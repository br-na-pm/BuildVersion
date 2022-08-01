PROGRAM _INIT
	REPEAT
		GetLogIdent.Name := '$$arlogusr';
		GetLogIdent.Execute := TRUE;
		GetLogIdent();
		
		UNTIL GetLogIdent.Done OR GetLogIdent.Error
	END_REPEAT
	
	REPEAT
		WriteToLog.Ident := GetLogIdent.Ident;
		Message := 'Project BuildVersion=';
		brsstrcat(ADR(Message), ADR(BuildVersion.Git.Version));
		brsstrcat(ADR(Message), ADR(' Branch='));
		brsstrcat(ADR(Message), ADR(BuildVersion.Git.Branch));
		IF BuildVersion.Git.ChangeWarning THEN
			WriteToLog.EventID := ArEventLogMakeEventID(arEVENTLOG_SEVERITY_WARNING, 10, 100);
			brsstrcat(ADR(Message), ADR(' Changes=TRUE'));
		ELSE
			WriteToLog.EventID := ArEventLogMakeEventID(arEVENTLOG_SEVERITY_INFO, 10, 100);
			brsstrcat(ADR(Message), ADR(' Changes=TRUE'));
		END_IF
		WriteToLog.AddDataFormat := arEVENTLOG_ADDFORMAT_TEXT;
		WriteToLog.AddDataSize := brsstrlen(ADR(Message)) + 1;
		WriteToLog.AddData := ADR(Message);
		WriteToLog.ObjectID := 'BuildVersion';
		WriteToLog.Execute := TRUE;
		WriteToLog();
	
		UNTIL WriteToLog.Done OR WriteToLog.Error 
	END_REPEAT;
	
	GetLogIdent(Execute := FALSE);
	WriteToLog(Execute := FALSE);
	
	BuildVersion;
END_PROGRAM
