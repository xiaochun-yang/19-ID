#ifndef __XosException_h__
#define __XosException_h__

/**
 * @file XosException.h
 * Header file containing XosException class.
 */

#include <string>

/**
 * @class XosException
 * @brief Base class for all exceptions.
 * Example
 *
 * @code

   // Throw an exception without exception code (defaulted to -1)
   void func1(int x)
       throw (XosException)
   {
       if (x == 0)
           throw XosException("X is null");

   }

   // Throw an exception with exception code
   void func2(const std::string& userName)
       throw (XosException)
   {
       if (userName != "george")
           throw XosException(411, "Invalid user name");
   }

   // Catching an exception
   void func3(const std::string& userName)
   {
       try {

         do_somthing_that_throws_exception();

       } catch (XosException& e) {
         printf("Caught XosException: %d %s\n", e.getCode(), e.getMessage().c_str());
       } catch (std::exception& e) {
         printf("Caught std::exception: %s\n", e.what());
       } catch (...) {
         printf("Caught unknown exception\n");
       }
   }

 * @endcode
 */
class XosException
{
public:

    /**
     * @brief Default Constructor.
     * Error code is defaulted to -1 and error phrase is
     * XosException: unknown reason.
     */
    XosException();

    /**
     * @brief Constructor for an exception with a reason.
     * Error code is defaulted to -1.
     *
     * @param why The reason for this exception.
     */
    XosException(const std::string& why);

    /**
     * @brief Constructor for an exception with an error code and a reason.
     *
     * @param c An error code as integer
     * @param why The reason for this exception.
     */
    XosException(int c, const std::string& why);

    /**
     * @brief Virtual destructor. Can be overridden by subclass.
     */
    virtual ~XosException()
    {
    }

    /**
     * @brief Returns the error code. Default error code is -1.
     * @return The error code as integer.
     */
    int getCode() const
    {
        return code;
    }

    /**
     * @brief Returns the reason why the exception is thrown.
     * @return The reason for this exception as string.
     */
    std::string getMessage() const
    {
        return reason;
    }

private:

    int code;
    std::string reason;

};

#endif //  __XosException_h__

