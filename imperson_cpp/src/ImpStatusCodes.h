#ifndef __Include_ImpStatusCodes_h__
#define __Include_ImpStatusCodes_h__

/**
 * @file ImpStatusCodes.h
 * Header file for definitions of response codes returned
 * by the impersonation server.
 */

#include "HttpStatusCodes.h"

/**
 * @defgroup IMP_CODE Response Codes
 * @ingroup ImpConst
 * @brief HTTP Status codes returned by the impersonation server. These are extension codes
 * in addition to the standard HTTP code defined in HttpStatusCodes.h.
 * @{
 */

/**
 * @def SC_431
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_431 "Missing impSessionID"

/**
 * @def SC_432
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_432 "Missing impUser"

/**
 * @def SC_433
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_433 "Missing impCommand"

/**
 * @def SC_434
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_434 "Invalid impExecutable"

/**
 * @def SC_435
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_435 "Missing impFileFilter"

/**
 * @def SC_436
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_436 "Missing impFileMode"

/**
 * @def SC_437
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_437 "Missing impFilePath"

/**
 * @def SC_438
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_438 "Invalid impFileStartOffset"

/**
 * @def SC_439
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_439 "Invalid impFileEndOffset"

/**
 * @def SC_440
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_440 "Missing impDirectory"

/**
 * @def SC_441
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_441 "Missing impExecutable"

/**
 * @def SC_442
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_442 "Invalid impFileType"

/**
 * @def SC_443
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_443 "Invalid impFileFilter"

/**
 * @def SC_444
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_444 "Invalid impDirectory"

/**
 * @def SC_445
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_445 "Missing impOldFilePath"

/**
 * @def SC_446
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_446 "Missings impNewFilePath"

/**
 * @def SC_447
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_447 "Missing impOldDirectory"

/**
 * @def SC_448
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_448 "Missing impNewDirectory"

/**
 * @def SC_449
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_449 "Invalid impMaxDepth"

/**
 * @def SC_450
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_450 "impOldDirectory is not a valid directory"

/**
 * @def SC_451
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_451 "Missing impCommandLine"

/**
 * @def SC_452
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_452 "Invalid impShell"

/**
 * @def SC_453
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_453 "Invalid impFileMode"

/**
 * @def SC_454
 * @brief The request contains impUser as root
 */
#define SC_454 "User root not allowed"

/**
 * @def SC_455
 * @brief The request is missing impProcessId parameter
 */
#define SC_455 "Missing impProcessId"

/**
 * @def SC_456
 * @brief The request has invalid impProcessId parameter
 */
#define SC_456 "Invalid impProcessId"


/**
 * @def SC_457
 * @brief The request has invalid impSizeX parameter
 */
#define SC_457 "Missing impSizeX"

/**
 * @def SC_458
 * @brief The request has invalid impSizeY parameter
 */
#define SC_458 "Missing impSizeY"

/**
 * @def SC_459
 * @brief The request has invalid impSizeY parameter
 */
#define SC_459 "Missing impSizeY"

/**
 * @def SC_460
 * @brief The request has invalid impZoom parameter
 */
#define SC_460 "Missing impZoom"

/**
 * @def SC_461
 * @brief The request has invalid impGray parameter
 */
#define SC_461 "Missing impGray"

/**
 * @def SC_462
 * @brief The request has invalid impPercentX parameter
 */
#define SC_462 "Missing impPercentX"

/**
 * @def SC_463
 * @brief The request has invalid impPercentY parameter
 */
#define SC_463 "Missing impPercentY"



/**
 * @def SC_551
 * @brief Server error while processing the command.
 */
#define SC_551 "Authentication failed"

/**
 * @def SC_552
 * @brief Server error while processing the command.
 */
#define SC_552 "Permission Denied"

/**
 * @def SC_553
 * @brief Server error while processing the command.
 */
#define SC_553 "Invalid session ID"

/**
 * @def SC_554
 * @brief Server error while processing the command.
 */
#define SC_554 "Invalid command"

/**
 * @def SC_555
 * @brief Server error while processing the command.
 */
#define SC_555 "Failed to open file for reading"

/**
 * @def SC_556
 * @brief Server error while processing the command.
 */
#define SC_556 "Failed to convert file descriptor to a stream"

/**
 * @def SC_557
 * @brief Server error while processing the command.
 */
#define SC_557 "fseek failed"

/**
 * @def SC_558
 * @brief Server error while processing the command.
 */
#define SC_558 "Failed to get file stat"

/**
 * @def SC_561
 * @brief Server error while processing the command.
 */
#define SC_561 "Failed to open file for writing"

/**
 * @def SC_562
 * @brief Server error while processing the command.
 */
#define SC_562 "Failed to write file"

/**
 * @def SC_563
 * @brief Server error while processing the command.
 */
#define SC_563 "Failed to change file mode"

/**
 * @def SC_564
 * @brief Server error while processing the command.
 */
#define SC_564 "Failed to change dir"

/**
 * @def SC_565
 * @brief Server error while processing the command.
 */
#define SC_565 "Failed to fork a process"

/**
 * @def SC_566
 * @brief Server error while processing the command.
 */
#define SC_566 "Failed to create pipe"

/**
 * @def SC_567
 * @brief Server error while processing the command.
 */
#define SC_567 "Failed to run executable"

/**
 * @def SC_568
 * @brief Server error while processing the command.
 */
#define SC_568 "Failed to redirect stdout of child process"

/**
 * @def SC_569
 * @brief Server error while processing the command.
 */
#define SC_569 "Failed to redirect stderr of child process"

/**
 * @def SC_570
 * @brief Server error while processing the command.
 */
#define SC_570 "Home directory not set"

/**
 * @def SC_571
 * @brief Server error while processing the command.
 */
#define SC_571 "Not a valid directory"

/**
 * @def SC_572
 * @brief Server error while processing the command.
 */
#define SC_572 "Failed to read dir"

/**
 * @def SC_573
 * @brief Server error while processing the command.
 */
#define SC_573 "Failed to create dir"

/**
 * @def SC_574
 * @brief Server error while processing the command.
 */
#define SC_574 "Failed to remove file or dir"

/**
 * @def SC_575
 * @brief Server error while processing the command.
 */
#define SC_575 "Can not remove system or special file"

/**
 * @def SC_576
 * @brief Server error while processing the command.
 */
#define SC_576 "Failed to unlink symbolic link file"

/**
 * @def SC_577
 * @brief Server error while processing the command.
 */
#define SC_577 "Write file incomplete"

/**
 * @def SC_578
 * @brief Server error while processing the command.
 */
#define SC_578 "Content-Length differs from body length"

/**
 * @def SC_579
 * @brief Server error while processing the command.
 */
#define SC_579 "Failed to read file"

/**
 * @def SC_580
 * @brief Server error while processing the command.
 */
#define SC_580 "Failed to allocate memory"

/**
 * @def SC_581
 * @brief Server error while processing the command.
 */
#define SC_581 "Failed to rename file"

/**
 * @def SC_582
 * @brief Server error while processing the command.
 */
#define SC_582 "Failed to close file"

/**
 * @def SC_583
 * @brief Server error while processing the command.
 */
#define SC_583 "Failed to close dir"

/**
 * @def SC_584
 * @brief Server error while processing the command.
 */
#define SC_584 "Failed to get process status"

/**
 * @def SC_585
 * @brief Server error while processing the command.
 */
#define SC_585 "Failed to kill the process"

/**
 * @def SC_586
 * @brief Zero length file
 */
#define SC_586 "Zero length file"

/**
 * @def SC_587
 * @brief Invalid file length
 */
#define SC_587 "Invalid file length"

/**
 * @def SC_588
 */
#define SC_588 "Failed to read image header"

/**
 * @def SC_589
 */
#define SC_589 "Failed to allocate memory for an image"

/**
 * @def SC_590
 */
#define SC_590 "Failed to create compressed buffer"

/**
 * @def SC_591
 */
#define SC_591 "Failed to write jpeg in http response body"

/**
 * @def SC_592
 */
#define SC_592 "Failed to load image from file"

/**
 * @def SC_593
 */
#define SC_593 "Failed to allocate memory for image header"

/**
 * @def SC_594
 */
#define SC_594 "Abort due to internal error"

/**
 * @def SC_595
 * @brief The request contains bad syntax, parameters are invalid or missing.
 */
#define SC_595 "impNewDirectory is not a valid directory"

/**
 * @}
 */

#endif // __Include_ImpStatusCodes_h__


