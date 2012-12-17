#ifndef __ImpServer_h__
#define __ImpServer_h__

/**
 * @file ImpServer.h
 * Header file for ImpServer class.
 */

#include "HttpServerHandler.h"
#include "ImpCommand.h"

/**
 * @class ImpServer
 * Subclass of HttpServerHandler that handles the HTTP request and response
 * for the impersonation server application.
 * The main() routine creates an instance of HttpServer ImpServer classes.
 * Then register the ImpServer with the HttpServer so that when a request
 * arrive, the HttpServer will call doGet() or doPost() of ImpServer.
 *
 * In doGet() and doPost(), ImpServer expects a command name and a list of
 * parameters for the command from the URL or header or URL form in the body.
 * It then creates one of the ImpCommand subclasses accordingly to handle
 * the command.
 * Example:
 *
 * @code

 void main(int argc, char** argv)
 {

     // Create an imp server that will
     // handle a specific command received
     // via an http request
     ImpServer* server = new ImpServer("Impersonation Server/2.0");

     // Create an http server stream
     // The stream will be used to extract the command
     // and parameters from the http request
     // and send the result back to the client
     HttpServer* conn = HttpServerFactory::createServer(INETD_STREAM);

     // Register the ImpServer with the HttpServer.
     conn->setHandler(server);

     // Start waiting for the request
     conn->start();

     delete conn;
     delete server;

 }

 * @endcode
 *
 */


class ImpServer : public HttpServerHandler
{
public:

    /**
     * @brief Constructor.
     *
     * The server name is sent to client in the "Server" response header
     **/
    ImpServer(const std::string& name);

    /**
     * @brief destructor
     **/
    virtual ~ImpServer();

    /**
     * @brief HttpServerHandler method
     * Called by the HttpServer to
     * set the "Server" response header.
     * @return Name of this server.
     **/
    virtual std::string getName() const
    {
        return name;
    }
    
    /**
     * @brief Sets this server to be a readly only server or not.
     * Readonly server only do readFile, listDirectory, 
     * getFilePermissions, and getFileStatus
     * @param b true or false
     **/
    void setReadOnly(bool b)
    {
    	readOnly = b;
    }

    /**
     * @brief Returns true if this server is a readonly server.
     * Readonly server only do readFile, listDirectory, 
     * getFilePermissions, and getFileStatus
     * @param b true or false
     **/
    bool isReadOnly() const
    {
    	return readOnly;
    }

    /**
     * @brief Returns true if this server allows
     * the given method in the request.
     *
     * Called when the stream reads the request
     * line. If this method returns false, the HttpServer
     * will stop parsing the rest of the request
     * and will return a response with an error code 405,
     * Method Not Allowed.
     *
     * @param m Method name such as GET, POST or PUT.
     * @return True if this server wishes to handle this method.
     **/
    virtual bool isMethodAllowed(const std::string& m) const;

    /**
     * @brief Called by the HttpServer if the request method is GET.
     *
     * The method is called when after the request has been parsed
     * and the request headers are saved in the HttpRequest object
     * which can be accessed via the HttpServer object.
     *
     * @param s The HttpServer.
     * @exception XosException Can be thrown by this method if there is an error.
     **/
    virtual void doGet(HttpServer* s)
        throw (XosException);

    /**
     * @brief Called by the HttpServer if the request method is POST.
     *
     * The method is called when after the request has been parsed
     * and the request headers are saved in the HttpRequest object
     * which can be accessed via the HttpServer object.
     *
     * @param s The HttpServer.
     * @exception XosException Can be thrown by this method if there is an error.
     **/
    virtual void doPost(HttpServer* s)
        throw (XosException);


    /**
     * @brief Sets tmp dir for this server into which temporary files will be written.
     *
     * The files written into this directory are
     * owned by impUser and will be deleted
     * when the command is finished, unless imp server crashes
     **/
    void setTmpDir(const std::string& d)
    {
        tmpDir = d;
    }

    void setDefShell(const std::string& shell) {
	defShell = shell;
    }
    
    /**
     * @brief Sets the authentication host and port
     * @param h The authentication server host name
     * @param p The authentication server port number
     * @param sp The authentication server secure port number
     */
    void setAuthentication(const std::string& h, int p, int sp)
    {
    	authHost = h;
    	authPort = p;
		authSecurePort = sp;
    }

	
    /**
     * @brief Sets the authentication host and port
     * @param h The authentication server host name
     * @param p The authentication server port number
     * @param sp The authentication server secure port number
     * @param m Application name that connects to the auth server
     * @param n Authentication method
     */
    void setAuthentication(const std::string& h, int p, int sp, 
								const std::string& n, const std::string& m, 
								const std::string& caFile, std::string caDir,
								const std::string& c)
    {
    	authHost = h;
    	authPort = p;
		authSecurePort = sp;
		authAppName = n;
		authMethod = m;
		authCaFile = caFile;
		authCaDir = caDir;
		ciphers = c;
    }



private:

    /**
     * Name of this server
     * Appears in "Server" response header field
     **/
    std::string name;

    /**
     **/
    std::string tmpDir;
    
    /**
     * The authentication server host name
     **/    
    std::string authHost;
    
    /**
     * The authentication server port number
     **/    
    int authPort;
    
    /**
     * The authentication server secure port number
     **/    
    int authSecurePort;
    
    /** 
     * Flag indicating whether or not this server 
     * can perform readonly command.
     */
    bool readOnly;
    
    /**
     * Application name to send to the authentication server.
     * This app name must be recognized by auth server.
     */
    std::string authAppName;
    
    /**
     * Authentication method supported by the auth server.
     */
    std::string authMethod;

    /**
     * Authentication server certificate file
     */
    std::string authCaFile;

    /**
     * Authentication server certificate dir
     */
    std::string authCaDir;

	 /**
     * openssl cipher suites. Comma separated string. 
     */
	  std::string ciphers;

    /**
     **/
   ImpCommand* commandHandler;

   std::string defShell;
   
   /**
    * Number of times to retry validating session id
    */
   static int numValidations;
   
   /**
    * Millisections to sleep between retrying
    */
   static int validationInterval;
   
    /**
     * Utility func that uses the authentication server to
     * validate a session.
     **/
    bool validateSession(const std::string& impSessionID, const std::string& impUser, bool& staff)
        throw (XosException);
    /**
     * Change from root the requested user
     * This is done before we execute the command
	  * Returns true if this user is staff.
     **/
    bool changeUser(const std::string& impSessionID,
                    const std::string& impUser,
                    uid_t& userID,
                    gid_t& primaryGroupId,
                    std::string& homeDir)
        throw(XosException);
	

};

#endif // __ImpServer_h__
