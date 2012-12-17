//*********************************************************************
//* Base64 - a simple base64 encoder and decoder.
//*
//*     Copyright (c) 1999, Bob Withers - bwit@pobox.com
//*
//* This code may be freely used for any purpose, either personal
//* or commercial, provided the authors copyright notice remains
//* intact.
//*********************************************************************

#include "xos.h"
#include "Base64.h"
#include <string>


// This code is taken from Base64.java by Ken Sharp

/**
 * Base64 is a utility class that supplies static methods performs Base64
 * encoding and decoding on Strings or byte arrays.
 *
 * Found on the Internet, this code is copyright 1999 by the author, Bob Withers
 */

/**
 * Static variables
 **/
int Base64::fillchar = '=';
std::string Base64::cvt = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";



/**********************************************************
 *
 * Performs Base64 encoding of a std::string.
 *
 * @param std::string containing the text to be encoded.
 * @return std::string containing the encoded text.
 *
 **********************************************************/
bool Base64::encode(const std::string& data, std::string& ret)
{
	ret = "";
	
    int c;
    size_t len = data.size();
    for (int i = 0; i < len; ++i)
    {
        c = (data[i] >> 2) & 0x3f;
        ret += cvt[c];
        c = (data[i] << 4) & 0x3f;
        if (++i < len)
            c |= (data[i] >> 4) & 0x0f;

        if (c < 0 || c >= cvt.size())
            return false;
        ret += cvt[c];

        if (i < len)
        {
            c = (data[i] << 2) & 0x3f;
            if (++i < len)
                c |= (data[i] >> 6) & 0x03;

            if (c < 0 || c >= cvt.size())
                return false;
            ret += cvt[c];
        }
        else
        {
            ++i;
            ret += (char)fillchar;
        }

        if (i < len)
        {
            c = data[i] & 0x3f;
            if (c < 0 || c >= cvt.size())
                return false;
            ret += cvt[c];
        }
        else
        {
            ret += (char)fillchar;
        }
    }

    return true;
}


/**********************************************************
 *
 * Performs Base64 decoding of a std::string.
 *
 * @param std::string containing the text to be decoded.
 * @return std::string containing the decoded text.
 *
 **********************************************************/
bool Base64::decode(const std::string& data, std::string& ret)
{
	ret = "";
	
    int c;
    int c1;
    int len = data.size();
    for (int i = 0; i < len; ++i)
    {
        c = cvt.find(data[i]);
        if (c < 0 || c >= cvt.size())
            return false;
        ++i;
        c1 = cvt.find(data[i]);
        if (c1 < 0 || c1 >= cvt.size())
            return false;
        c = ((c << 2) | ((c1 >> 4) & 0x3));
        ret += (char)c;
        if (++i < len)
        {
            c = data[i];
            if (fillchar == c)
                break;

            c = cvt.find((char) c);
            if (c < 0 || c >= cvt.size())
                return false;
            c1 = ((c1 << 4) & 0xf0) | ((c >> 2) & 0xf);
            ret += (char) c1;
        }

        if (++i < len)
        {
            c1 = data[i];
            if (fillchar == c1)
                break;

            c1 = cvt.find((char) c1);
            if (c1 < 0 || c1 >= cvt.size())
                return false;
            c = ((c << 6) & 0xc0) | c1;
            ret += (char) c;
        }
    }

    return true;
}


/**********************************************************
 *
 * Performs Base64 encoding of a byte array.
 *
 * @param byte[] array containing the data to be encoded.
 * @return byte[] array containing the encoded data.
 *
 **********************************************************/
/*static byte[] encode(byte[] data)
{
    int c;
    int len = data.length;
    StringBuffer ret = new StringBuffer(((len / 3) + 1) * 4);
    for (int i = 0; i < len; ++i)
    {
        c = (data[i] >> 2) & 0x3f;
        ret.append(cvt.charAt(c));
        c = (data[i] << 4) & 0x3f;
        if (++i < len)
            c |= (data[i] >> 4) & 0x0f;

        ret.append(cvt.charAt(c));
        if (i < len)
        {
            c = (data[i] << 2) & 0x3f;
            if (++i < len)
                c |= (data[i] >> 6) & 0x03;

            ret.append(cvt.charAt(c));
        }
        else
        {
            ++i;
            ret.append((char) fillchar);
        }

        if (i < len)
        {
            c = data[i] & 0x3f;
            ret.append(cvt.charAt(c));
        }
        else
        {
            ret.append((char) fillchar);
        }
    }

    return(getBinaryBytes(ret.toString()));
}
*/


/**********************************************************
 *
 * Performs Base64 decoding of a byte array.
 *
 * @param byte[] array containing the data to be decoded.
 * @return byte[] array containing the decoded data.
 *
 **********************************************************/
/*static byte[] decode(byte[] data)
{
    int c;
    int c1;
    int len = data.length;
    StringBuffer ret = new StringBuffer((len * 3) / 4);
    for (int i = 0; i < len; ++i)
    {
        c = cvt.indexOf(data[i]);
        ++i;
        c1 = cvt.indexOf(data[i]);
        c = ((c << 2) | ((c1 >> 4) & 0x3));
        ret.append((char) c);
        if (++i < len)
        {
            c = data[i];
            if (fillchar == c)
                break;

            c = cvt.indexOf((char) c);
            c1 = ((c1 << 4) & 0xf0) | ((c >> 2) & 0xf);
            ret.append((char) c1);
        }

        if (++i < len)
        {
            c1 = data[i];
            if (fillchar == c1)
                break;

            c1 = cvt.indexOf((char) c1);
            c = ((c << 6) & 0xc0) | c1;
            ret.append((char) c);
        }
    }

    return(getBinaryBytes(ret.toString()));
}

*/

/**********************************************************
 *
 * Static method
 *
 **********************************************************/
static void test(int argc, char** argv)
{
    std::string org_str;
    std::string encoded_str;
    std::string decoded_str;

    if (argc > 1)
        org_str = argv[1];
    else
        org_str = "Now is the time for all good men";

    printf("Original string [%s]\n", org_str.c_str());

    if (Base64::encode(org_str, encoded_str))
        printf("Encoded string [%s]\n", encoded_str.c_str());
    else
        printf("Error: failed to encode string\n");

    if (Base64::decode(encoded_str, decoded_str))
        printf("Decoded string [%s]\n", decoded_str.c_str());
    else
        printf("Error: failed to decode string\n");


    if (decoded_str != org_str)
        printf("Error: decoded string is not the same as original string!\n");
    else
        printf("decode & encode work fine.\n");

}




