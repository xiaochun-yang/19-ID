extern "C" {
#include "xos.h"
}

#include <string>
#include "HttpServer.h"
#include "InetdServer.h"
#include "HttpServerFactory.h"

HttpServer* HttpServerFactory::createServer(const std::string& type)
{
    if (type == INETD_STREAM) {
        return new InetdServer();
    }

    return NULL;
}


