
#ifdef _DEFAULT_INCLUDES
	#include <AsDefault.h>
#endif

#include <ArEventLog.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

static void stringCopy(char *destination, uint32_t size, char *source);
static void stringConcat(char *destination, uint32_t size, char *source);

ArEventLogGetIdent_typ getLogIdent;
ArEventLogWrite_typ writeToLog;
char message[121];

/* Program initialization */
void _INIT ProgramInit(void)
{
	stringCopy(getLogIdent.Name, sizeof(getLogIdent.Name), "$arlogusr");
	getLogIdent.Execute = true;
	do 
	{
		ArEventLogGetIdent(&getLogIdent);
	} 
	while (!getLogIdent.Done && !getLogIdent.Error);
	
	writeToLog.Ident = getLogIdent.Ident;
	stringCopy(message, sizeof(message), "Project BuildVersion=");
	stringConcat(message, sizeof(message), BuildVersion.Git.Version);
	stringConcat(message, sizeof(message), " Branch=");
	stringConcat(message, sizeof(message), BuildVersion.Git.Branch);
	if (BuildVersion.Git.ChangeWarning)
	{
		writeToLog.EventID = ArEventLogMakeEventID(arEVENTLOG_SEVERITY_WARNING, 10, 100);
		stringConcat(message, sizeof(message), " Changes=TRUE");
	}
	else 
	{
		writeToLog.EventID = ArEventLogMakeEventID(arEVENTLOG_SEVERITY_INFO, 10, 100);
		stringConcat(message, sizeof(message), " Changes=FALSE");
	}
	writeToLog.AddDataFormat = arEVENTLOG_ADDFORMAT_TEXT;
	writeToLog.AddDataSize = strlen(message) + 1;
	writeToLog.AddData = (uint32_t)message;
	stringCopy(writeToLog.ObjectID, sizeof(writeToLog.ObjectID), "BuildVersion");
	writeToLog.Execute = true;
	do 
	{
		ArEventLogWrite(&writeToLog);
	} 
	while (!writeToLog.Done && !writeToLog.Error);
	
	getLogIdent.Execute = false;
	ArEventLogGetIdent(&getLogIdent);
	writeToLog.Execute = false;
	ArEventLogWrite(&writeToLog);
	BuildVersion.Git.AdditionalCommits = BuildVersion.Git.AdditionalCommits;
}

/* Copies source to destination up to size (of destination) or source length */
void stringCopy(char *destination, uint32_t size, char *source)
{
	if (destination == NULL || source == NULL || size == 0) return;
	
	/* Copy, decrement first for size - 1 characters remaining */
	while (--size && *source != '\0')
		*destination++ = *source++;
	
	*destination = '\0';
}

/* Concatentate source to destination up to size (of destination) or source length */
void stringConcat(char *destination, uint32_t size, char *source)
{
	if (destination == NULL || source == NULL || size == 0) return;
	strncat(destination, source, size - 1);
}

