/*******************************************************************************
 * File: Main.c
 * Created: 2022-03-21
 * 
 * Contributors: 
 * - Tyler Matijevich
 * 
 * License:
 *  This file Main.c is part of the BuildVersion project released under the
 *  MIT License agreement.  For more information, please visit 
 *  https://github.com/br-na-pm/BuildVersion/blob/main/LICENSE.
 ******************************************************************************/

#include <BuildVersiontyp.h>
#include <Variablesvar.h>
#include <ArEventLog.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>

static void StringCopy(char *Destination, uint32_t Size, char *Source);
static void StringConcat(char *Destination, uint32_t Size, char *Source);

ArEventLogGetIdent_typ GetLogbookIdent;
ArEventLogWrite_typ WriteToLogbook;
char Message[121];

/* Program initialization */
void _INIT ProgramInit(void)
{
	/* Get User logbook ident */
	StringCopy(GetLogbookIdent.Name, sizeof(GetLogbookIdent.Name), "$arlogusr");
	GetLogbookIdent.Execute = true;
	do {
		ArEventLogGetIdent(&GetLogbookIdent);
	}
	while(!GetLogbookIdent.Done && !GetLogbookIdent.Error);
	
	/* Write to User logbook */
	WriteToLogbook.Ident = GetLogbookIdent.Ident;
	StringCopy(Message, sizeof(Message), "BuildVersion=");
	StringConcat(Message, sizeof(Message), BuildVersion.Git.Version);
	StringConcat(Message, sizeof(Message), " Branch=");
	StringConcat(Message, sizeof(Message), BuildVersion.Git.Branch);
	if(BuildVersion.Git.ChangeWarning) {
		WriteToLogbook.EventID = ArEventLogMakeEventID(arEVENTLOG_SEVERITY_WARNING, 400, 10000);
		StringConcat(Message, sizeof(Message), " Changes=TRUE");
	}
	else {
		WriteToLogbook.EventID = ArEventLogMakeEventID(arEVENTLOG_SEVERITY_INFO, 400, 10000);
		StringConcat(Message, sizeof(Message), " Changes=FALSE");
	}
	WriteToLogbook.AddDataFormat = arEVENTLOG_ADDFORMAT_TEXT;
	WriteToLogbook.AddDataSize = strlen(Message) + 1;
	WriteToLogbook.AddData = (uint32_t)Message;
	StringCopy(WriteToLogbook.ObjectID, sizeof(WriteToLogbook.ObjectID), "BuildVersion");
	WriteToLogbook.Execute = true;
	do {
		ArEventLogWrite(&WriteToLogbook);
	} 
	while(!WriteToLogbook.Done && !WriteToLogbook.Error);
	
	GetLogbookIdent.Execute = false;
	ArEventLogGetIdent(&GetLogbookIdent);
	WriteToLogbook.Execute = false;
	ArEventLogWrite(&WriteToLogbook);
	
	/* Use BuildVersion variable in task to register with OPCUA */
	BuildVersion.Git.AdditionalCommits = BuildVersion.Git.AdditionalCommits;
}

/* Copy source to destination up to size (of destination) or source length */
void StringCopy(char *Destination, uint32_t Size, char *Source) {
	if(Destination == NULL || Source == NULL || Size == 0)
		return;
	
	/* Decrement first, loop up to size - 1 */
	while(--Size && *Source != '\0')
		*Destination++ = *Source++;
	
	*Destination = '\0';
}

/* Concatenate source to destination up to size (of destination) or source length */
void StringConcat(char *Destination, uint32_t Size, char *Source) {
	if(Destination == NULL || Source == NULL || Size == 0)
		return;
	
	strncat(Destination, Source, Size - 1 - strlen(Destination));
}
