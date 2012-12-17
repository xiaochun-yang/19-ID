/**********************************************************************
 * cbf_context -- handle cbf contexts                                 *
 *                                                                    *
 * Version 0.7.2 22 April 2001                                        *
 *                                                                    *
 *            Paul Ellis (ellis@ssrl.slac.stanford.edu) and           *
 *         Herbert J. Bernstein (yaya@bernstein-plus-sons.com)        *
 **********************************************************************/
  
/**********************************************************************
 *                               NOTICE                               *
 * Creative endeavors depend on the lively exchange of ideas. There   *
 * are laws and customs which establish rights and responsibilities   *
 * for authors and the users of what authors create.  This notice     *
 * is not intended to prevent you from using the software and         *
 * documents in this package, but to ensure that there are no         *
 * misunderstandings about terms and conditions of such use.          *
 *                                                                    *
 * Please read the following notice carefully.  If you do not         *
 * understand any portion of this notice, please seek appropriate     *
 * professional legal advice before making use of the software and    *
 * documents included in this software package.  In addition to       *
 * whatever other steps you may be obliged to take to respect the     *
 * intellectual property rights of the various parties involved, if   *
 * you do make use of the software and documents in this package,     *
 * please give credit where credit is due by citing this package,     *
 * its authors and the URL or other source from which you obtained    *
 * it, or equivalent primary references in the literature with the    *
 * same authors.                                                      *
 *                                                                    *
 * Some of the software and documents included within this software   *
 * package are the intellectual property of various parties, and      *
 * placement in this package does not in any way imply that any       *
 * such rights have in any way been waived or diminished.             *
 *                                                                    *
 * With respect to any software or documents for which a copyright    *
 * exists, ALL RIGHTS ARE RESERVED TO THE OWNERS OF SUCH COPYRIGHT.   *
 *                                                                    *
 * Even though the authors of the various documents and software      *
 * found here have made a good faith effort to ensure that the        *
 * documents are correct and that the software performs according     *
 * to its documentation, and we would greatly appreciate hearing of   *
 * any problems you may encounter, the programs and documents any     *
 * files created by the programs are provided **AS IS** without any   *
 * warranty as to correctness, merchantability or fitness for any     *
 * particular or general use.                                         *
 *                                                                    *
 * THE RESPONSIBILITY FOR ANY ADVERSE CONSEQUENCES FROM THE USE OF    *
 * PROGRAMS OR DOCUMENTS OR ANY FILE OR FILES CREATED BY USE OF THE   *
 * PROGRAMS OR DOCUMENTS LIES SOLELY WITH THE USERS OF THE PROGRAMS   *
 * OR DOCUMENTS OR FILE OR FILES AND NOT WITH AUTHORS OF THE          *
 * PROGRAMS OR DOCUMENTS.                                             *
 **********************************************************************/
 
/**********************************************************************
 *                                                                    *
 *                           The IUCr Policy                          *
 *      for the Protection and the Promotion of the STAR File and     *
 *     CIF Standards for Exchanging and Archiving Electronic Data     *
 *                                                                    *
 * Overview                                                           *
 *                                                                    *
 * The Crystallographic Information File (CIF)[1] is a standard for   *
 * information interchange promulgated by the International Union of  *
 * Crystallography (IUCr). CIF (Hall, Allen & Brown, 1991) is the     *
 * recommended method for submitting publications to Acta             *
 * Crystallographica Section C and reports of crystal structure       *
 * determinations to other sections of Acta Crystallographica         *
 * and many other journals. The syntax of a CIF is a subset of the    *
 * more general STAR File[2] format. The CIF and STAR File approaches *
 * are used increasingly in the structural sciences for data exchange *
 * and archiving, and are having a significant influence on these     *
 * activities in other fields.                                        *
 *                                                                    *
 * Statement of intent                                                *
 *                                                                    *
 * The IUCr's interest in the STAR File is as a general data          *
 * interchange standard for science, and its interest in the CIF,     *
 * a conformant derivative of the STAR File, is as a concise data     *
 * exchange and archival standard for crystallography and structural  *
 * science.                                                           *
 *                                                                    *
 * Protection of the standards                                        *
 *                                                                    *
 * To protect the STAR File and the CIF as standards for              * 
 * interchanging and archiving electronic data, the IUCr, on behalf   *
 * of the scientific community,                                       *
 *                                                                    *
 * * holds the copyrights on the standards themselves,                *
 *                                                                    *
 * * owns the associated trademarks and service marks, and            *
 *                                                                    *
 * * holds a patent on the STAR File.                                 *
 *                                                                    *
 * These intellectual property rights relate solely to the            *
 * interchange formats, not to the data contained therein, nor to     *
 * the software used in the generation, access or manipulation of     *
 * the data.                                                          *
 *                                                                    *
 * Promotion of the standards                                         *
 *                                                                    *
 * The sole requirement that the IUCr, in its protective role,        *
 * imposes on software purporting to process STAR File or CIF data    *
 * is that the following conditions be met prior to sale or           *
 * distribution.                                                      *
 *                                                                    *
 * * Software claiming to read files written to either the STAR       *
 * File or the CIF standard must be able to extract the pertinent     *
 * data from a file conformant to the STAR File syntax, or the CIF    *
 * syntax, respectively.                                              *
 *                                                                    *
 * * Software claiming to write files in either the STAR File, or     *
 * the CIF, standard must produce files that are conformant to the    *
 * STAR File syntax, or the CIF syntax, respectively.                 *
 *                                                                    *
 * * Software claiming to read definitions from a specific data       *
 * dictionary approved by the IUCr must be able to extract any        *
 * pertinent definition which is conformant to the dictionary         *
 * definition language (DDL)[3] associated with that dictionary.      *
 *                                                                    *
 * The IUCr, through its Committee on CIF Standards, will assist      *
 * any developer to verify that software meets these conformance      *
 * conditions.                                                        *
 *                                                                    *
 * Glossary of terms                                                  *
 *                                                                    *
 * [1] CIF:  is a data file conformant to the file syntax defined     *
 * at http://www.iucr.org/iucr-top/cif/spec/index.html                *
 *                                                                    *
 * [2] STAR File:  is a data file conformant to the file syntax       *
 * defined at http://www.iucr.org/iucr-top/cif/spec/star/index.html   *
 *                                                                    *
 * [3] DDL:  is a language used in a data dictionary to define data   *
 * items in terms of "attributes". Dictionaries currently approved    *
 * by the IUCr, and the DDL versions used to construct these          *
 * dictionaries, are listed at                                        *
 * http://www.iucr.org/iucr-top/cif/spec/ddl/index.html               *
 *                                                                    *
 * Last modified: 30 September 2000                                   *
 *                                                                    *
 * IUCr Policy Copyright (C) 2000 International Union of              *
 * Crystallography                                                    *
 **********************************************************************/

#ifdef __cplusplus

extern "C" {

#endif

#include "cbf.h"
#include "cbf_alloc.h"
#include "cbf_context.h"

#include <stdlib.h>
#include <string.h>
#include <limits.h>


  /* Create and initialise a context */

int cbf_make_context (cbf_context **context)
{
    /* Allocate the memory */

  cbf_failnez (cbf_alloc ((void **) context, NULL, sizeof (cbf_context), 1))


    /* Initialise */
    
  (*context)->temporary = NULL;

  (*context)->connections = 1;


    /* Success */

  return 0;
}


  /* Free a context */

int cbf_free_context (cbf_context **context)
{
  int errorcode;

  errorcode = 0;

  if (context)

    if (*context)
    {
      if ((*context)->temporary)

        errorcode = cbf_free_file (&(*context)->temporary);

      errorcode |= cbf_free ((void **) context, NULL);
    }


    /* Success? */

  return errorcode;
}


  /* Add a context connection */

int cbf_add_contextconnection (cbf_context **context)
{
    /* Does the context pointer exist? */

  if (!context)

    return CBF_ARGUMENT;


    /* Does the context exist? */

  if (*context)
  {
    (*context)->connections++;

    return 0;
  }


    /* Create a new context */

  return cbf_make_context (context);
}


  /* Remove a context connection */

int cbf_delete_contextconnection (cbf_context **context)
{
    /* Does the context pointer exist? */

  if (!context)

    return CBF_ARGUMENT;


    /* Does the context exist? */

  if (!*context)

    return CBF_ARGUMENT;


    /* Remove a connection */

  (*context)->connections--;


    /* Delete the context? */

  if ((*context)->connections == 0)

    return cbf_free_context (context);


    /* Success */

  return 0;
}


  /* Open a temporary file connection */

int cbf_open_temporary (cbf_context *context, cbf_file **temporary)
{
  FILE *stream;

  int errorcode;

  
    /* Check the arguments */

  if (!context || !temporary)

    return CBF_ARGUMENT;


    /* Does a temporary file already exist? */

  if (context->temporary)
  {
    cbf_failnez (cbf_add_fileconnection (&context->temporary, NULL))

    *temporary = context->temporary;

    return 0;
  }


    /* Create the temporary file */

  stream = tmpfile ();

  if (!stream)

    return CBF_FILEOPEN;

  errorcode = cbf_make_file (&context->temporary, stream);
  
  if (errorcode)
  {
    if (fclose (stream))

      errorcode |= CBF_FILECLOSE;

    return errorcode;
  }


    /* Open a connection */
    
  return cbf_open_temporary (context, temporary);
}


  /* Close a temporary file connection */

int cbf_close_temporary (cbf_context *context, cbf_file **temporary)
{
    /* Check the arguments */

  if (!context || !temporary)

    return CBF_ARGUMENT;

  if (!*temporary)

    return CBF_ARGUMENT;


    /* Check that the temporary file matches */

  if (context->temporary != *temporary)

    return CBF_NOTFOUND;
    

    /* Delete the connection */

  cbf_failnez (cbf_delete_fileconnection (&context->temporary))

  *temporary = NULL;


    /* Is there only one connection left? */

  if (context->temporary)

    if (cbf_file_connections (context->temporary) == 1)

      cbf_failnez (cbf_free_file (&context->temporary))


    /* Success */

  return 0;
}


  /* Copy a string */

const char *cbf_copy_string (cbf_context *context, const char *string, 
                                                         char type)
{
  char *new_string;

  if (string)

    if (type)
    {
      if (cbf_alloc ((void **) &new_string, NULL, 
                      sizeof (char), strlen (string) + 2) == 0)
      {
        *new_string = type;
        
        strcpy (new_string + 1, string);

        return new_string;
      }
    }
    else

      if (cbf_alloc ((void **) &new_string, NULL, \
                      sizeof (char), strlen (string) + 1) == 0)
      {
        strcpy (new_string, string);

        return new_string;
      }

 
    /* Fail */

  return NULL;
}


  /* Free a string */

void cbf_free_string (cbf_context *context, const char *string)
{
  cbf_free ((void **) &string, NULL);
}


#ifdef __cplusplus

}

#endif
