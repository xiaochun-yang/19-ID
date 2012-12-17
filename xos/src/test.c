#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include "xos.h"

typedef struct WorkerData {
    xos_semaphore_t worker_wait;
    xos_semaphore_t worker_post;
} WorkerData_t;

XOS_THREAD_ROUTINE worker( WorkerData_t* data ) {
    xos_semaphore_wait( &data->worker_wait, 0 );

    usleep( 2000 ); /* 2 ms */

    xos_semaphore_post( &data->worker_post );

    XOS_THREAD_ROUTINE_RETURN;
}

int main( int argc, const char** argv ) {
    xos_thread_t workerThread;
    WorkerData_t data;

    xos_time_t timeout;
    if (argc > 1) {
        timeout = strtol( argv[1], (char**)NULL, 10 );
    } else {
        timeout = 1;
        printf( "timeout set to 1 ms, you should see a timeout\n" );
    }

    if (xos_semaphore_create( &data.worker_wait, 0 ) != XOS_SUCCESS) {
        fprintf( stderr, "create sem failed for worker_wait\n" );
        return -1;
    }
    if (xos_semaphore_create( &data.worker_post, 0 ) != XOS_SUCCESS) {
        fprintf( stderr, "create sem failed for worker_post\n" );
        return -1;
    }

    if (xos_thread_create( &workerThread, (xos_thread_routine_t*)worker,
    &data ) != XOS_SUCCESS) {
        fprintf( stderr, "create worker thread failed\n" );
        return -1;
    }

    sleep( 1 );

    xos_semaphore_post( &data.worker_wait );
    xos_wait_result_t result = xos_semaphore_wait( &data.worker_post, timeout );
    switch (result) {
    case XOS_WAIT_SUCCESS:
        printf( "wait success\n" );
        break;
    case XOS_WAIT_FAILURE:
        printf( "wait failed\n" );
        break;
    case XOS_WAIT_TIMEOUT:
        printf( "wait timeout\n" );
        break;
    default:
        printf( "wait default\n" );
    }

    return 0;
}
