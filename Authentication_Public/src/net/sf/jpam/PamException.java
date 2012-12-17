/**
 *  Copyright 2003-2007 Greg Luck
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

package net.sf.jpam;

/**
 * The <code>PamException</code> class is used
 * to indicate that an exceptional condition has occurred in the native PAM library
 * <p/>
 * This exception does not use the new JDK1.4 chainable excecptions facility
 * to maintain backward compatibility with JDK1.2 and JDK1.3.
 *
 * @author Greg Luck
 * @version $Id: PamException.java,v 1.1 2007/09/13 18:38:14 penjitk Exp $
 */
public class PamException extends Exception {
    /**
     * Constructor for the PamException object
     */
    public PamException() {
        super();
    }

    /**
     * Constructor for the PamException object
     * @param message
     */
    public PamException(String message) {
        super(message);
    }

}