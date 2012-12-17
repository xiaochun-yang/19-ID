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

import java.util.List;
import java.util.Collections;
import java.util.Arrays;

/**
 * A type-safe enum for PAM return values.
 * <p/>
 * Warning. When comparing values do not use <code>==</code>.
 * Use the <code>.equals(Object o)</code> method.
 * <p/>
 * These are based on the Linux PAM projects return values.
 *
 * @author <a href="mailto:gregluck@users.sourceforge.net">Greg Luck</a>
 * @version $Id: PamReturnValue.java,v 1.1 2007/09/13 18:38:14 penjitk Exp $
 */
public class PamReturnValue {

    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_SUCCESS =
            new PamReturnValue(0, "Successful function return.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_OPEN_ERR =
            new PamReturnValue(1, "dlopen() failure when dynamically loading a service module.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_SYMBOL_ERR =
            new PamReturnValue(2, "Symbol not found.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_SERVICE_ERR =
            new PamReturnValue(3, "Error in service module.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_SYSTEM_ERR =
            new PamReturnValue(4, "System error.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_BUF_ERR =
            new PamReturnValue(5, "Memory buffer error.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_PERM_DENIED =
            new PamReturnValue(6, "Permission denied.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_AUTH_ERR =
            new PamReturnValue(7, "Authentication failure.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_CRED_INSUFFICIENT =
            new PamReturnValue(8, "Can not access authentication data due to insufficient credentials.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_AUTHINFO_UNAVAIL =
            new PamReturnValue(9, "Underlying authentication service can not retrieve authentication information.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_USER_UNKNOWN =
            new PamReturnValue(10, "User not known to the underlying authentication module.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_MAXTRIES =
            new PamReturnValue(11, "An authentication service has maintained a retry "
            + "count which has been reached.  No further retries should be attempted.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_NEW_AUTHTOK_REQD =
            new PamReturnValue(12, "New authentication token required. This is normally returned if"
            + " the machine security policies require that the password should be changed because"
            + " the password is NULL or it has aged.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_ACCT_EXPIRED =
            new PamReturnValue(13, "User account has expired.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_SESSION_ERR =
            new PamReturnValue(14, "Can not make/remove an entry for the specified session.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_CRED_UNAVAIL =
            new PamReturnValue(15, "Underlying authentication service can not retrieve user credentials unavailable.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_CRED_EXPIRED =
            new PamReturnValue(16, "User credentials expired.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_CRED_ERR =
            new PamReturnValue(17, "Failure setting user credentials.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_NO_MODULE_DATA =
            new PamReturnValue(18, "No module specific data is present.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_CONV_ERR =
            new PamReturnValue(19, "Conversation error.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_AUTHTOK_ERR =
            new PamReturnValue(20, "Authentication token manipulation error.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_AUTHTOK_RECOVER_ERR =
            new PamReturnValue(21, "Authentication information cannot be recovered.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_AUTHTOK_LOCK_BUSY =
            new PamReturnValue(22, "Authentication token lock busy.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_AUTHTOK_DISABLE_AGING =
            new PamReturnValue(23, "Authentication token aging disabled.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_TRY_AGAIN =
            new PamReturnValue(24, "Preliminary check by password service.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_IGNORE =
            new PamReturnValue(25, "Ignore underlying account module regardless of whether the control flag"
            + "is required, optional, or sufficient.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_ABORT =
            new PamReturnValue(26, "Critical error (?module fail now request).");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_AUTHTOK_EXPIRED =
            new PamReturnValue(27, "User's authentication token has expired.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_MODULE_UNKNOWN =
            new PamReturnValue(28, "Module is not known.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_BAD_ITEM =
            new PamReturnValue(29, "Bad item passed to pam_*_item().");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_CONV_AGAIN =
            new PamReturnValue(30, "Conversation function is event driven and data is not available yet.");
    /**
     * A constant PamReturnValue
     */
    public static final PamReturnValue PAM_INCOMPLETE =
            new PamReturnValue(31, "Please call this function again to complete authentication stack. Before calling"
            + " again, verify that conversation is completed.");


    private static final PamReturnValue[] PRIVATE_VALUES =
            {PAM_SUCCESS, PAM_OPEN_ERR, PAM_SYMBOL_ERR, PAM_SERVICE_ERR, PAM_SYSTEM_ERR,
             PAM_BUF_ERR, PAM_PERM_DENIED, PAM_AUTH_ERR, PAM_CRED_INSUFFICIENT, PAM_AUTHINFO_UNAVAIL,
             PAM_USER_UNKNOWN, PAM_MAXTRIES, PAM_NEW_AUTHTOK_REQD, PAM_ACCT_EXPIRED, PAM_SESSION_ERR,
             PAM_CRED_UNAVAIL, PAM_CRED_EXPIRED, PAM_CRED_ERR, PAM_NO_MODULE_DATA, PAM_CONV_ERR,
             PAM_AUTHTOK_ERR, PAM_AUTHTOK_RECOVER_ERR, PAM_AUTHTOK_LOCK_BUSY, PAM_AUTHTOK_DISABLE_AGING,
             PAM_TRY_AGAIN, PAM_IGNORE, PAM_ABORT, PAM_AUTHTOK_EXPIRED, PAM_MODULE_UNKNOWN, PAM_BAD_ITEM,
             PAM_CONV_AGAIN, PAM_INCOMPLETE
            };

    private final String description;
    private final int id;

    private PamReturnValue(int id, String description) {
        this.id = id;
        this.description = description;
    }

    /**
     * Returns true if the supplied object is of the
     * same type and has the same id.
     */
    public boolean equals(final Object o) {
        if (this == o) {
            return true;
        }
        if (!(o instanceof PamReturnValue)) {
            return false;
        }
        final PamReturnValue pamReturnValue = (PamReturnValue) o;
        if (id != pamReturnValue.id) {
            return false;
        }
        return true;
    }

    /**
     * Gets the PamReturnValue that matches the given id
     * @param id a valid Integer with a value between 0 and 31
     * @return the PamReturnValue matching the id
     * @throws IllegalArgumentException if the id is outside the range of possible return values
     */
    public static PamReturnValue fromId(int id) throws IllegalArgumentException {
        int maxId = VALUES.size() - 1;
        if (id > maxId || id < 0) {
            throw new IllegalArgumentException("id " + id + " is not between 0 and " + maxId);
        }
        return (PamReturnValue) VALUES.get(id);
    }

    /**
     * @return a hash code for the object.
     */
    public int hashCode() {
        return id;
    }

    /**
     * @return the String description of the return value
     */
    public String toString() {
        return description;
    }
    
    /**
     * The enumeration of possible values
     */
    public static final List VALUES = Collections.unmodifiableList(Arrays.asList(PRIVATE_VALUES));
}


