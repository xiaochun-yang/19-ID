#include "RobotEpson.h"
#include "RobotEpsonSymbal.h"
#include "log_quick.h"

//#include <math.h>

bool RobotEpson::ProcessMoveArgument( const char*& pRemainArgument,
                      char& source_cassette, char& source_column, short& source_row,
                      char& target_cassette, char& target_column, short& target_row )
{

    if (pRemainArgument == NULL ||pRemainArgument[0] == '\0')
    {
        return false;
    }

    //skip spaces
    while (*pRemainArgument == ' ' || *pRemainArgument == ',')
    {
        ++pRemainArgument;
    }

    source_cassette = *(pRemainArgument++);
    source_column = *(pRemainArgument++);

    //source_row =  *(pRemainArgument++) - '0';
	//support row 1-16
	char stringSourceRow[8] = {0};
	int i = 0;
	for (i = 0; i < sizeof(stringSourceRow) - 1; ++i)
	{
		char letter = pRemainArgument[i];
		if (isdigit(letter))
		{
			stringSourceRow[i] = letter;
		}
		else
		{
			break;
		}
	}
	if (i == 0)
	{
		return false;
	}
	source_row = (short)atoi( stringSourceRow );
	pRemainArgument += i;

    //check symbal "->"
    if (*(pRemainArgument++) != '-' || *(pRemainArgument++) != '>')
    {
        return false;
    }

    target_cassette = *(pRemainArgument++);
    target_column = *(pRemainArgument++);
    //target_row =  *(pRemainArgument++) - '0';
	//support row 1-16
	char stringTargetRow[8] = {0};
	for (i = 0; i < sizeof(stringTargetRow) - 1; ++i)
	{
		char letter = pRemainArgument[i];
		if (isdigit(letter))
		{
			stringTargetRow[i] = letter;
		}
		else
		{
			break;
		}
	}
	if (i == 0)
	{
		return false;
	}
	target_row = (short)atoi( stringTargetRow );
	pRemainArgument += i;
    return true;
}
