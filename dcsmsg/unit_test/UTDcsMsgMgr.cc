#include <iostream>
#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageManager.h"

using namespace std;
int main( int argc, char** argv )
{
    LOG_QUICK_OPEN;

    DcsMessageManager theMgr;

    char line[1024] = {0};

    while (!(cin.getline( line, sizeof(line) ).fail( )))
    {
        cout << line <<endl;
    }

    if (strlen( line ) >= sizeof(line) - 1)
    {
        cout << "line too long" << endl;
    }
    LOG_QUICK_CLOSE;
    return 0;
}
