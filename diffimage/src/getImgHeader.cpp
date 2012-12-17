#include <diffimage.h>
#include <iostream>
#include <cstdio>

#define IMAGE_HEADER_MAX_LEN 65535

int main(int argc, char* argv[]) {

    if (argc < 2) {
        fprintf(stderr, "%s imag_file_name\n", argv[0] );
        return -1;
    }

    Diffimage D(255, 100,100,125,125);

    if (D.load_header(argv[1]) != XOS_SUCCESS) {
        fprintf(stderr,"failed to load image\n");
        return -2;
    }

    char header[IMAGE_HEADER_MAX_LEN]={0};
    if (D.get_header(header, IMAGE_HEADER_MAX_LEN) != XOS_SUCCESS) {
        fprintf(stderr,"failed to get header\n");
        return -3;
    }

    printf("%s", header);

    return 0;
}
