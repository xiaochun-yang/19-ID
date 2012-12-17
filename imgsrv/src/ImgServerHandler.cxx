#include "xos.h"
#include "xos_socket.h"
#include "log_quick.h"


//#include "XosTimeCheck.h"
#include "XosException.h"

#include "HttpUtil.h"
#include "HttpServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"

#include "diffimage.h"
#include "ImgServerHandler.h"
#include "imgsrv_cache.h"
#include "ImgSrvCacheEntry.h"
#include "write_png.h"



class DiffImageRAII {

public:
	DiffImageRAII(ImgSrvCacheEntrySafePtr & pEntry) {
		LOG_INFO("DiffImageRAII");

		try {
			image_ = new Diffimage(pEntry.getImage(), 255, 100, 100, 125, 125);
		} catch (std::bad_alloc & e) {
			LOG_SEVERE("diffimage was not created");
			throw e;
		}
	}
	;

	~DiffImageRAII () {
		LOG_INFO("delete DiffImageRAII");
		delete image_;
		Diffimage::free_uncompressed_buffer(uncompressedBuffer_);
	}

	void configureView(double percentx, double percenty, int sizex, int sizey, double zoom, int gray, diffimage_mode_t mode) {

		const double im_centerx = (percentx * (double) image_->get_image_size_x());
		const double im_centery = (percenty * (double) image_->get_image_size_y());

		image_->set_mode(mode);
		image_->set_display_size(sizex, sizey);
		image_->set_image_center(im_centerx, im_centery);
		image_->set_zoom(zoom);
		image_->set_contrast_min(0);
		image_->set_contrast_max(gray);
		image_->set_jpeg_quality(90);
		image_->set_sampling_quality(3);

		image_->get_image_parameters(wavelength, distance, originX,
				originY, pixelSize, time, detectorTypeC64);


	}

	void sendJpegOfImage(xos_socket_t* socket) {

		// create the uncompressed image
		JINFO jinfo;

		if ( image_->create_uncompressed_buffer(&uncompressedBuffer_,
					&jinfo) != XOS_SUCCESS) {
				LOG_WARNING("Failed to create compressed buffer");
				ImgServerHandler::sendErrorResponse(socket, "500",
						"Failed to create compressed buffer");
				return;
		}

		// send a jpeg compressed image
		if (send_jpeg_buffer(socket, &uncompressedBuffer_, &jinfo,
				JPEG_HTTP_PROTOCOL) != XOS_SUCCESS) {
			LOG_WARNING("Failed to write jpeg in http body");
			return;
		}

	}

	void sendPngOfImage(xos_socket_t * socket) {
#ifdef DIFFIMAGE_HAVE_PNG_Z
		LOG_INFO("Creating a PNG response using " );

		std::vector<unsigned char> png_compressed;
		try {
			png_compressed.reserve(image_->get_display_size().first * image_->get_display_size().second);
			diffimage_png::get_png_buffer(*image_, &png_compressed);}
		catch (std::exception& e) {
			LOG_WARNING1( "Failed to compress the PNG with %s\n", e.what() );
			return;
		}

		LOG_INFO("Releasing the image...\n");
		LOG_INFO("Sending image...\n");

		std::vector<unsigned char>::const_iterator compressed_ptr = png_compressed.begin();
		if (xos_socket_write(socket, (const char*)(void*)&*compressed_ptr, png_compressed.size()) != XOS_SUCCESS) {
			LOG_WARNING( "unable to write PNG to the socket" );
			return;
		}
#endif
	}

void sendHeader(xos_socket_t * socket, const std::string& contentType) {
	std::string endofline(CRLF);
	std::string response("");
	std::string serverName("Image Server/2.0");

	//image was loaded successfully or found in cache
	response += "HTTP/1.1 200 OK" + endofline;
	response += "Connection: close" + endofline;
	response += "Server: " + serverName + endofline;
	response += "Content-Type: " + contentType + endofline;
	response += "wavelength: " + XosStringUtil::fromDouble(wavelength)
			+ endofline;
	response += "distance: " + XosStringUtil::fromDouble(distance)
			+ endofline;
	response += "originX: " + XosStringUtil::fromDouble(originX)
			+ endofline;
	response += "originY: " + XosStringUtil::fromDouble(originY)
			+ endofline;
	response += "pixelSize: " + XosStringUtil::fromDouble(pixelSize)
			+ endofline;
	response += "time: " + XosStringUtil::fromDouble(time) + endofline;
	response += std::string("detectorTypeC64: ") + detectorTypeC64
			+ endofline;
	response += std::string(EH_CONTENT_TYPE) + std::string(": ")
			+ WWW_JPEG + endofline;
	response += endofline;

	if (xos_socket_write(socket, response.c_str(), response.size())
			!= XOS_SUCCESS) {
		LOG_WARNING("Error: Failed in xos_socket_write");
		return;
	}
}

private:
	Diffimage * image_;
	unsigned char *uncompressedBuffer_;

	//characteristics of image
	float wavelength;
	float originX;
	float originY;
	float time;
	float pixelSize;
	float distance;
	char detectorTypeC64[64];

};

void debugRequest(const HttpRequest* res, const std::string& title)
{
    if (!res)
        return;

    printf("********************\n");
    printf("START HTTP REQUEST: %s\n", title.c_str());

    printf("%s %s %s\n", res->getMethod().c_str(),
                         res->getURI().c_str(),
                         res->getVersion().c_str());

    // Results are in the response headers
    // Fill the member variables

    printf(res->getHeaderString().c_str());
    printf("\n");

    printf("%s\n", res->getBody().c_str());

    printf("END HTTP REQUEST\n");
    printf("********************\n");
}

void debugResponse(const HttpResponse* res, const std::string& title)
{
    if (!res)
        return;

    printf("********************\n");
    printf("START HTTP RESPONSE: %s\n", title.c_str());

    printf("%s %d %s\n", res->getVersion().c_str(),
                         res->getStatusCode(),
                         res->getStatusPhrase().c_str());

    // Results are in the response headers
    // Fill the member variables

    printf(res->getHeaderString().c_str());
    printf("\n");

    printf("%s\n", res->getBody().c_str());

    printf("END HTTP RESPONSE\n");
    printf("********************\n");


    fflush(stdout);
}


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






/***************************************************************
 *
 * @brief Utility func to read an HTTP request from the socket and parse it.
 *  Expect the reuqest to contain the request line and headers only.
 *
 * @param uri Input URI to parse
 * @param method Returned request method such as POST or GET
 * @param version Returned HTTP version info
 * @param host Returned host name
 * @param port Returned port number
 * @param resource Returned resource part of the URI
 * @param params Returned list of parameter names and
 *        values from the query part of the URI.
 * @param reason Returned error string if the func returns false.
 * @return True if the func parses the URI successfully.
 *         If the func returns false, the error string is also returned.
 *
 ***************************************************************/
bool ImgServerHandler::readRequest(xos_socket_t* socket,
							std::string& uri,
							std::string& method,
							std::string& version,
							std::string& host,
							std::string& port,
							std::map<std::string, std::string>& params,
							std::string& reason)
{

	char buf[1001];
	int maxSize = 1000;
	int size = 0;
	std::string str;
	LOG_FINEST("Start reading request\n");
		if (xos_socket_read_any_length(socket, buf, maxSize, &size) != XOS_SUCCESS) {
		LOG_INFO1("xos_socket_read_any_length failed: size = %d\n", size);
		reason = "Failed in xos_socket_read_any_length";
		return false;
		}
		if (size > 0) {
			buf[size] = '\0';
			str.append(buf, size);
//		fwrite(buf, sizeof(char), size, stdout); fflush(stdout);
	} else {
		LOG_WARNING1("Invalid request: size = %d\n", size);
		reason = "Invalid request";
		return false;
	}

	LOG_FINEST("Finished reading request\n");
	//LOG_FINEST("Start parsing request\n");
	LOG_FINEST1("request: %s", buf) ;

    size_t pos = 0;
    size_t pos1 = 0;

    pos1 = str.find(' ', pos);

    if (pos1 == std::string::npos) {
        reason = "Cound not find the first space character in the request line";
        return false;
    }

    method = str.substr(pos, pos1-pos);

    pos = pos1+1;
    pos1 = str.find(' ', pos);
    if (pos1 == std::string::npos) {
        reason = "Cound not find the second space character in the request line";
        return false;
    }

    if (!HttpUtil::decodeURI(str.substr(pos, pos1-pos), uri)) {
    	reason = "Failed to decode URL";
        return false;
    }


    pos = pos1+1;
    version = XosStringUtil::trim(str.substr(pos));

	std::string resource;
    if (!HttpUtil::parseURI(uri, host, port, resource, params, reason))
    	return false;

    if (resource.size() < 2) {
    	reason = "Invalid command in URI";
    	return false;
    }

    pos = resource.find_first_not_of("/");


    if (pos != std::string::npos)
    	params.insert(std::map<std::string, std::string>::value_type("command", resource.substr(pos)));
    else
    	params.insert(std::map<std::string, std::string>::value_type("command", resource));

    LOG_FINEST("Finished parsing request\n");

    return true;
}

/***************************************************************
 *
 * @brief Sends an HTTP error response to the socket. The status code
 * should be in the 400 or 500 ranges to indicate an error.
 * The status phrase should explain what the error is.
 * Code should not be 200 since it's reserved as an OK response code.
 * The response body is optional.
 *
 * @param socket Socket stream for sending the response
 * @param code Response status code
 * @param phrase Response status phrase
 * @param body Response body
 *
 ***************************************************************/
void ImgServerHandler::sendErrorResponse(xos_socket_t* socket,
						const std::string& code,
						const std::string& phrase,
						const std::string& body)
{
	std::string serverName("Image Server/2.0");
	std::string endofline(CRLF);
	std::string response("");

	response += std::string("HTTP/1.1 ") + code + std::string(" ") + phrase + endofline;
	response += "Connection: close" + endofline;
	response += "Server: " + serverName + endofline;
	response += endofline;
	// body
	if (body.size() > 0)
		response += body;

	if (xos_socket_write(socket, response.c_str(), response.size()) != XOS_SUCCESS )
		xos_error( "Error: Failed in xos_socket_write" );
}

/***************************************************************
 *
 * @brief Sends an HTTP error response to the socket. The status code
 * should be in the 400 or 500 ranges to indicate an error.
 * The status phrase should explain what the error is.
 * Code should not be 200 since it's reserved as an OK response code.
 * The response body is the status code followed by status phrase in one line.
 *
 * @param socket Socket stream for sending the response
 * @param code Response status code
 * @param phrase Response status phrase
 *
 ***************************************************************/
void ImgServerHandler::sendErrorResponse(xos_socket_t* socket,
						const std::string& code,
						const std::string& phrase)
{


	sendErrorResponse(socket, code, phrase, code + " " + phrase);
}


/***************************************************************
 *
 * @brief Sends an HTTP OK response to the socket. The response code
 * is 200 and response phrase is OK.
 *
 * If the headerStr is NULL or headerSize is 0, only default headers,
 * such as Server, will be included. If the bodyStr is NULL or
 * bodySize is 0, the response will not have a body.
 *
 * @param socket Socket stream for sending the response
 * @param headerStr Buffer containing containing header lines.
 * @param headerSize Size of the header string
 * @param bodyStr Buffer contain the response body
 * @param bodySize Size of the response body
 *
 ***************************************************************/
void ImgServerHandler::sendOkResponse(xos_socket_t* socket,
						const std::string& header,
						const char* bodyStr,
						int bodySize)
{
	std::string endofline(CRLF);
	std::string response("");
	std::string serverName("Image Server/2.0");


	//image was loaded successfully or found in cache
	response += "HTTP/1.1 200 OK" + endofline;
	response += "Connection: close" + endofline;
	response += "Server: " + serverName + endofline;
	if (header.size() > 0) {
		response += header;
	}
	response += endofline;


	if (xos_socket_write(socket, response.c_str(), response.size()) != XOS_SUCCESS ) {
		xos_error( "Error: xos_socket_write failed to write response headers" );
		return;
	}

	if ((bodyStr != NULL) && (bodySize > 0)) {
		if (xos_socket_write(socket, bodyStr, bodySize) != XOS_SUCCESS ) {
			xos_error( "Error: xos_socket_write failed to write response body" );
			return;
		}
	}
}

namespace ImageServer{

class ErrorException{
  xos_socket_t* socket_ptr;
  std::string code,phrase;

 public:
  ErrorException(xos_socket_t* socket_ptr,const std::string& code,
    const std::string& phrase):
    socket_ptr(socket_ptr),code(code),phrase(phrase){}
  void report() const {
    ImgServerHandler::sendErrorResponse(socket_ptr, code, phrase);
  }
};

class ParamAdaptor{
  typedef std::map<std::string, std::string> maptype;
  const maptype map;
  xos_socket_t* socket_ptr;

 public:
  ParamAdaptor(const maptype& map, xos_socket_t* socket_ptr):
    map(map),socket_ptr(socket_ptr){}
  std::string getOptionalParameter(
    const std::string& parameter_name, const std::string& default_val)const{
    maptype::const_iterator i;
    if ((i=map.find(parameter_name)) == map.end()) {
      return default_val;
    }
    return i->second;
  }
};

}//namespace ImageServer

/***************************************************************
 *
 * @brief Processes the http request and sends an HTTP response.
 *
 * @param socket Socket stream
 * @param params A list of input parameter names and values
 *  extracted from the request URI.
 *
 ***************************************************************/
void ImgServerHandler::sendResponse(xos_socket_t* socket, std::map<std::string,
		std::string>& params) {
	ImageServer::ParamAdaptor PA(params, socket);

	// Mandatory parameters
	std::string command;
	std::string fileName;
	std::string userName;
	std::string sessionId;
	std::string reason ="";

	// Get input params from http request
	std::map<std::string, std::string>::iterator i;

	if ((i = params.find("command")) == params.end()) {
		ImgServerHandler::sendErrorResponse(socket, "400",
				"Missing command in URL");
		LOG_WARNING("Missing command parameter in URL");
		return;
	}

	command = i->second;


	// Check if the command is valid
	if ((command != "getThumbnail") && (command != "getImage" ) &&(command != "getHeader") ) {
		LOG_WARNING("Invalid command parameter in URL");
		ImgServerHandler::sendErrorResponse(socket, "400",
				"Invalid command in URL");
	}

	// Get the mandatory parameters
	if ((i = params.find("fileName")) == params.end()) {
		ImgServerHandler::sendErrorResponse(socket, "400",
				"Missing fileName parameter in URL");
		LOG_WARNING("Missing fileName parameter in URL");
		return;
	}
	fileName = i->second;

	if ( fileName.size()==0 || (fileName.compare(0,1,"/") != 0 )) {
		ImgServerHandler::sendErrorResponse(socket, "400",
				"invalid filename");
		LOG_WARNING("filename must start with '/'");
		return;
	}

	if ((i = params.find("userName")) == params.end()) {
		ImgServerHandler::sendErrorResponse(socket, "400",
				"Missing userName parameter in URL");
		LOG_WARNING("Missing userName parameter in URL");
		return;
	}
	userName = i->second;

	if ((i = params.find("sessionId")) == params.end()) {
		ImgServerHandler::sendErrorResponse(socket, "400",
				"Missing sessionId parameter in URL");
		LOG_WARNING("Missing sessionId parameter in URL");
		return;
	}
	sessionId = i->second;

	if (command == "getHeader") {

		// Only interested in header
		std::string header = "";

		if ( readImageHeaderNoCache(fileName,userName,sessionId,header,reason) != XOS_SUCCESS) {
			LOG_WARNING1("failed to load header %s",reason.c_str());
			LOG_INFO2("details for load failure: username %s %s",userName.c_str(), fileName.c_str());
			ImgServerHandler::sendErrorResponse(socket, "500", reason);
			return;
		}

		std::string httpHeader = "";
		httpHeader += "Content-Type: text/plain" + std::string(CRLF);
		httpHeader += "Content-Length: " + XosStringUtil::fromInt((int)header.size()) + std::string(CRLF);

		if ( (header.size() > 0) ) {
			ImgServerHandler::sendOkResponse(socket, httpHeader, header.c_str(), header.size() + 1);
		} else {
			LOG_WARNING("Failed to get image header");
			ImgServerHandler::sendErrorResponse(socket, "500",
					"Failed to get image header");
		}

		return;

	}

	// Get optional parameters (required by some commands)

	int sizex = 0;
	int sizey = 0;
	double zoom = 0.0;
	double percentx = 0.0;
	double percenty = 0.0;
	int gray = 0;
	std::string imageType = "JPEG";

	if ((command == "getThumbnail") || (command == "getImage")) {

		std::string str;

		if ((i = params.find("sizeX")) == params.end()) {
			ImgServerHandler::sendErrorResponse(socket, "400",
					"Missing sizeX parameter in URL");
			LOG_WARNING("Missing sizeX parameter in URL");
			return;
		}

		sizex = XosStringUtil::toInt(i->second, 0);

		if ((i = params.find("sizeY")) == params.end()) {
			ImgServerHandler::sendErrorResponse(socket, "400",
					"Missing sizeY parameter in URL");
			LOG_WARNING("Missing sizeY parameter in URL");
			return;
		}

		sizey = XosStringUtil::toInt(i->second, 0);

		if ((i = params.find("zoom")) == params.end()) {
			ImgServerHandler::sendErrorResponse(socket, "400",
					"Missing zoom parameter in URL");
			LOG_WARNING("Missing zoom parameter in URL");
			return;
		}

		zoom = XosStringUtil::toDouble(i->second, 0);

		if ((i = params.find("gray")) == params.end()) {
			ImgServerHandler::sendErrorResponse(socket, "400",
					"Missing gray parameter in URL");
			LOG_WARNING("Missing gray parameter in URL");
			return;
		}

		gray = XosStringUtil::toInt(i->second, 0);

		if ((i = params.find("percentX")) == params.end()) {
			ImgServerHandler::sendErrorResponse(socket, "400",
					"Missing percentX parameter in URL");
			LOG_WARNING("Missing percentX parameter in URL");
			return;
		}

		percentx = XosStringUtil::toDouble(i->second, 0.0);

		if ((i = params.find("percentY")) == params.end()) {
			ImgServerHandler::sendErrorResponse(socket, "400",
					"Missing percentY parameter in URL");
			LOG_WARNING("Missing percentY parameter in URL");
			return;
		}

		percenty = XosStringUtil::toDouble(i->second, 0.0);

		imageType = PA.getOptionalParameter("imageType", "JPEG");

	}

	/// set parameters for creating the zoomed image
	diffimage_mode_t mode = DIFFIMAGE_MODE_FULL;
	if (command == "getThumbnail") {
		mode = DIFFIMAGE_MODE_THUMB;
	}

	ImgSrvCacheEntrySafePtr pEntry;
	try {
		cache_get_image(fileName, userName, sessionId, pEntry);
	} catch (std::exception  & e) {
		LOG_WARNING1("failed to load image %s", e.what() );
		ImgServerHandler::sendErrorResponse(socket, "500", e.what() );
		return;
	}

	DiffImageRAII image(pEntry);

	image.configureView(percentx,percenty,sizex,sizey,zoom, gray, mode);

	try {
		if (imageType == "JPEG") {
			LOG_INFO("send jpeg ");
			image.sendHeader(socket, "image/jpeg");
			image.sendJpegOfImage(socket);
		} else if (imageType == "PNG") {
			image.sendHeader(socket, "image/x-png");
			image.sendPngOfImage(socket);
		} else {
			LOG_WARNING1("Invalid image type command%s\n", fileName.c_str() );
//			throw ImageServer::ErrorException(socket, "400",
//					"Unrecognized output imageType");
			ImgServerHandler::sendErrorResponse(socket, "500", "Invalid image type");
		}
	} catch (ImageServer::ErrorException e) {
		e.report();
		LOG_WARNING("unhandled exception");
		return;
	} catch (...) {
		LOG_WARNING("unhandled exception");
		return;
	}

}

/***************************************************************
 *
 * @brief Processes the http request and sends an HTTP response.
 *
 * @param socket Socket stream
 *
 ***************************************************************/
void ImgServerHandler::handleRequest(xos_socket_t* socket)
{
	std::string uri;
	std::string method;
	std::string version;
	std::string host;
	std::string port;
	std::map<std::string, std::string> params;
	std::string reason("Erroring parsing request");

	// Read the request
	if (ImgServerHandler::readRequest(
					socket, uri, method,
					version, host, port,
					params, reason)) {

		// Process the request and send response
		ImgServerHandler::sendResponse(socket, params);

	} else {

		ImgServerHandler::sendErrorResponse(socket, "400", reason);

	}
}
