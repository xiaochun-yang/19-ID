#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

char* my_fgets( char* buffer, int max_len, int fd ) {
    int i = 0;

    if (max_len < 1) return NULL;

    memset(buffer, 0, max_len);

    --max_len;

    while (i < max_len) {
        size_t nRead = read( fd, buffer+i, 1 );
        if (nRead <= 0) {
            break;
        }

        if (buffer[i] == '\n') {
            break;
        }
        ++i;
    }
    if (i <= 0) return NULL;

    return buffer;
}
int main( int argc, const char** argv ) {
    char line[1024] = {0};

    while (strstr(line, "END") == NULL) {
        my_fgets( line, 1024, fileno(stdin) );

        printf("got: %s", line);
        printf("\n");
        fflush(stdout);
    }
    return 0;

}
