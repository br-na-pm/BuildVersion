
#ifdef _DEFAULT_INCLUDES
	#include <AsDefault.h>
#endif

#include <ArEventLog.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

static void stringCopy(char *destination, char *source, uint32_t size);
static void stringConcat(char *destination, char *source, uint32_t size);

ArEventLogGetIdent_typ getLogIdent;
ArEventLogWrite_typ writeToLog;
char message[121];

/* Program initialization */
void _INIT ProgramInit(void) {
	stringCopy(getLogIdent.Name, "$arlogusr", sizeof(getLogIdent.Name));
	getLogIdent.Execute = true;
	do {
		ArEventLogGetIdent(&getLogIdent);
	} while(!getLogIdent.Done && !getLogIdent.Error);
	
	writeToLog.Ident = getLogIdent.Ident;
	stringCopy(message, "Project BuildVersion=", sizeof(message));
	stringConcat(message, BuildVersion.Git.Version, sizeof(message));
	stringConcat(message, " Branch=", sizeof(message));
	stringConcat(message, BuildVersion.Git.Branch, sizeof(message));
	if(BuildVersion.Git.ChangeWarning) {
		writeToLog.EventID = ArEventLogMakeEventID(arEVENTLOG_SEVERITY_WARNING, 10, 100);
		stringConcat(message, " Changes=TRUE", sizeof(message));
	}
	else {
		writeToLog.EventID = ArEventLogMakeEventID(arEVENTLOG_SEVERITY_INFO, 10, 100);
		stringConcat(message, " Changes=FALSE", sizeof(message));
	}
	writeToLog.AddDataFormat = arEVENTLOG_ADDFORMAT_TEXT;
	writeToLog.AddDataSize = strlen(message) + 1;
	writeToLog.AddData = (uint32_t)message;
	stringCopy(writeToLog.ObjectID, "BuildVersion", sizeof(writeToLog.ObjectID));
	writeToLog.Execute = true;
	do {
		ArEventLogWrite(&writeToLog);
	} while(!writeToLog.Done && !writeToLog.Error);
	
	getLogIdent.Execute = false;
	ArEventLogGetIdent(&getLogIdent);
	writeToLog.Execute = false;
	ArEventLogWrite(&writeToLog);
	BuildVersion.Git.AdditionalCommits = BuildVersion.Git.AdditionalCommits;
}

/* Copies source to destination up to size (of destination) or source length */
void stringCopy(char *destination, char *source, uint32_t size)
{
	uint32_t bytes_remaining = size - 1;
	if (destination == NULL || source == NULL || size == 0) return;
	
	while (bytes_remaining--)
	{
		if (*source == '\0') break;
		*destination++ = *source++;
	}
	
	*destination = '\0';
}

/* Concatentate source to destination up to size (of destination) or source length */
void stringConcat(char *destination, char *source, uint32_t size)
{
	if (destination == NULL || source == NULL || size == 0) return;
	strncat(destination, source, size - 1);
}

