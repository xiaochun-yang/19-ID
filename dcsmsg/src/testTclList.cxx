#include <cstring>
#include "TclList.h"
#include <stdio.h>

int main( int argc, char** argv )
{

    std::string str = "0";
    for (int i = 1; i < 1000; ++i)
    {
        char buffer[64] = {0};
        sprintf( buffer, " %d", i);
        str += buffer;
    }
    while (1)
    {
        TclList aList(1, 64);
        aList.parse( str.c_str( ));
        if (strcmp( str.c_str( ), aList.getList( ) ))
        {
            printf( "not match\n" );
        }

        printf( "looping\n" );
    }

}
