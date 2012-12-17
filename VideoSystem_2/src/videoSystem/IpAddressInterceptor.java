/*
 *                        Copyright 2001
 *                              by
 *                 The Board of Trustees of the 
 *               Leland Stanford Junior University
 *                      All rights reserved.
 *
 *
 *                       Disclaimer Notice
 *
 *     The items furnished herewith were developed under the sponsorship
 * of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
 * Leland Stanford Junior University, nor their employees, makes any war-
 * ranty, express or implied, or assumes any liability or responsibility
 * for accuracy, completeness or usefulness of any information, apparatus,
 * product or process disclosed, or represents that its use will not in-
 * fringe privately-owned rights.  Mention of any product, its manufactur-
 * er, or suppliers shall not, nor is it intended to, imply approval, dis-
 * approval, or fitness for any particular use.  The U.S. and the Univer-
 * sity at all times retain the right to use and disseminate the furnished
 * items for any purpose whatsoever.                       Notice 91 02 01
 *
 *   Work supported by the U.S. Department of Energy under contract
 *   DE-AC03-76SF00515; and the National Institutes of Health, National
 *   Center for Research Resources, grant 2P41RR01209. 
 *
 *
 *                       Permission Notice
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
 * BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
 * EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
 * THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * Created on Feb 8, 2006
 */
package videoSystem;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

/**
 * @author harchara
 *
 */
public class IpAddressInterceptor extends HandlerInterceptorAdapter {
    
    private String ipAddressFile;
        
    @Override
	public boolean preHandle(HttpServletRequest request,
            HttpServletResponse response, Object handler) throws Exception {
    		
    	return true;
        
    }

	public String getIpAddressFile() {
		return ipAddressFile;
	}

	public void setIpAddressFile(String ipAddressFile) {
		this.ipAddressFile = ipAddressFile;
	}
    
}
