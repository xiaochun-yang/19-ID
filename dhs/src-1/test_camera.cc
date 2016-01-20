extern "C" {
#include "xos_hash.h"
#include "libimage.h"
}
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/wait.h>
#include <string>
#include "math.h"
#include "dhs_config.h"
#include "dhs_database.h"
#include "dhs_messages.h"
#include "dhs_network.h"
#include "dhs_monitor.h"
#include "dhs_Camera.h"
#include "imgCentering.h"

int g_countObjs();
void g_dumpObjs();

static CameraInfo mcurCamera;
static ImageList* m_ImgLst = NULL;  /* Store Image List for Current Camera */
static char* operationHandle = "1.22";

void do_getLoopTip(int ifaskPinPosFlag)
{
    xos_result_t result;
    char operationResult[200];

    // Debug memory
//    printf("in getLoopTip\n");
    g_dumpObjs();

    if ((result = handle_getLoopTip(&mcurCamera, operationHandle, operationResult, ifaskPinPosFlag ))
            != XOS_FAILURE) {
        printf("Result: %s\n", operationResult );
    } else {
        xos_error("Handling getLoopTip raised Error!\n");
    }

//    printf("out getLoopTip\n");
    g_dumpObjs();
}


bool do_addImageToList(int imgIndex)
{

    xos_result_t result;
    char operationResult[200];

//    printf("out addImageToList\n");
//    g_dumpObjs();

    if ((result = handle_addImageToList(&mcurCamera, imgIndex,&m_ImgLst,operationHandle,operationResult))
        != XOS_FAILURE) {
        printf("Result: %s\n",operationResult);
    } else {
        xos_error("Handling addImageList raised Error!\n");
    }

//    printf("out addImageToList\n");
//    g_dumpObjs();

    std::string tmp = operationResult;
    int pos = tmp.find("error");
    if (pos > -1) {
        printf("result = %s found error pos (%d)\n", operationResult, pos);
        return false;
    }
    return true;
}

void do_findBoundingBox()
{
    xos_result_t result;
    char* operationParameter = "Both";
    char operationResult[200];

//    printf("in findBoundingBox\n");
    g_dumpObjs();

    if ((result = handle_findBoundingBox(&m_ImgLst, operationHandle, operationParameter, operationResult))
        != XOS_FAILURE) {
            printf("Result: %s\n", operationResult );
    } else {
        xos_error("Handling findBoundingBox raised Error!\n");
    }

//    printf("out findBoundingBox\n");
    g_dumpObjs();
}

// Not used
// length: specified length
// number (1->8): specified needed number of diameters.From right most of pin to left,
//                return diameter for each length.
void do_getPinDiameters()
{
    xos_result_t result;
    float length;
    int   number;
    char operationResult[200];

    printf("in getPinDiameters");
    g_dumpObjs();

        if ((result = handle_getPinDiameters(&mcurCamera, operationHandle, operationResult,(int)length, number))
            != XOS_FAILURE) {
            printf("Result: %s\n", operationResult );
    } else {
        xos_error("Handling findBoundingBox raised Error!\n");
    }

    printf("out getPinDiameters");
    g_dumpObjs();
}


int main( int argc, char *argv[] )
{
    std::string command("getLoopTip");
    if (argc < 2) {
        printf("Usage: test <getLoopTip|findBoundingBox>\n");
        printf("Make sure that ./log directory exists\n");
        exit(0);
    }

    command = argv[1];


    // Set the camera info
    mcurCamera.mName = "simple_camera";
    mcurCamera.mIPAddress = "blctlxx.slac.stanford.edu";
    mcurCamera.mPort = 7070;
    mcurCamera.mUsrName = "penjitk";
    mcurCamera.mPwd = "penjitk";
    mcurCamera.mUrlPath = "/";

    if (command == "getLoopTip") {

        for (int i = 0; i < 1000; ++i) {

            printf("MAIN loop (%d): calling do_getLoopTip\n", i);
            do_getLoopTip(0);

            // sleep fro 1 sec
            xos_thread_sleep(1000);

        }

    } else if (command == "findBoundingBox") {

        for (int i = 0; i < 1000; ++i) {

            printf("MAIN loop (%d): calling do_findBoundingBox\n", i);

            // Add images to list before finding the bounding box.
            // Each image shows each angle of the pin (0 -> 180, step 5).
            for (int j = 0; j < 36; ++j) {
                if (!do_addImageToList(j)) {
                    printf("STOP due to bad result\n");
                    exit(0);
                }
            }

            do_findBoundingBox();

            // sleep fro 1 sec
            xos_thread_sleep(2000);

        }

        if (m_ImgLst) {
          freeImageList(m_ImgLst);
        }

    } else {
        printf("command %s not supported\n", command.c_str());
    }

}

