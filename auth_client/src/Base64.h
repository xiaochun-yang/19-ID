#ifndef __Include_XosBase64_h__
#define __Include_XosBase64_h__

//*********************************************************************
//* Base64 - a simple base64 encoder and decoder.
//*
//*     Copyright (c) 1999, Bob Withers - bwit@pobox.com
//*
//* This code may be freely used for any purpose, either personal
//* or commercial, provided the authors copyright notice remains
//* intact.
//*********************************************************************

#include <string>

// This code is taken from Base64.java by Ken Sharp

/**
 * Base64 is a utility class that supplies static methods performs Base64
 * encoding and decoding on Strings or byte arrays.
 *
 * Found on the Internet, this code is copyright 1999 by the author, Bob Withers
 */
class Base64
{

public:
    /**
     * Performs Base64 encoding of a std::string.
     *
     * @param std::string data containing the text to be encoded.
     * @param std::string ret containing the encoded text.
     */
    static bool encode(const std::string& data, std::string& ret);


    /**
     * Performs Base64 decoding of a std::string.
     *
     * @param std::string data containing the text to be decoded.
     * @param std::string data containing the decoded text.
     */
    static bool decode(const std::string& data, std::string& ret);


private:

    static int fillchar;
    static std::string cvt;


};

#endif // __Include_XosBase64_h__
