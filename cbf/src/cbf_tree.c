/**********************************************************************
 * cbf_tree -- handle cbf nodes                                       *
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "cbf.h"
#include "cbf_alloc.h"
#include "cbf_tree.h"
#include "cbf_context.h"
#include "cbf_binary.h"


  /* Make a new node */

int cbf_make_node (cbf_node **node, CBF_NODETYPE type, 
                   cbf_context *context, const char *name)
{
  int errorcode;
  
  if (!node)

    return CBF_ARGUMENT;


    /* Create the new node */

  cbf_failnez (cbf_alloc ((void **) node, NULL, sizeof (cbf_node), 1))

    
    /* Initialise the node */

  (*node)->type = type;

  (*node)->name = NULL;

  (*node)->link = NULL;

  (*node)->parent = NULL;
      
  (*node)->children = 0;

  (*node)->child_size = 0;

  (*node)->child = NULL;


    /* Add the context? */

  if (type == CBF_LINK)

    (*node)->context = NULL;

  else
  {
      /* Does the context exist? */

    if (context)

      (*node)->context = context;

    else
    
      (*node)->context = NULL;


      /* Add a context connection */

    cbf_onfailnez (cbf_add_contextconnection (&(*node)->context), 
               cbf_free ((void **) node, NULL))


      /* Name the node */

    errorcode = cbf_name_node (*node, name);

    if (errorcode)
    {
      errorcode |= cbf_free_context (&(*node)->context);
      
      return errorcode | cbf_free_node (*node);
    }
  }


    /* Success */

  return 0;
}


  /* Make a new node allowing for duplicates */

int cbf_make_new_node (cbf_node **node, CBF_NODETYPE type, 
                       cbf_context *context, const char *name)
{
  int errorcode;
  
  if (!node)

    return CBF_ARGUMENT;


    /* Create the new node */

  cbf_failnez (cbf_alloc ((void **) node, NULL, sizeof (cbf_node), 1))

    
    /* Initialise the node */

  (*node)->type = type;

  (*node)->name = NULL;

  (*node)->link = NULL;

  (*node)->parent = NULL;
      
  (*node)->children = 0;

  (*node)->child_size = 0;

  (*node)->child = NULL;


    /* Add the context? */

  if (type == CBF_LINK)

    (*node)->context = NULL;

  else
  {
      /* Does the context exist? */

    if (context)

      (*node)->context = context;

    else
    
      (*node)->context = NULL;


      /* Add a context connection */

    cbf_onfailnez (cbf_add_contextconnection (&(*node)->context), 
                   cbf_free ((void **) node, NULL))


      /* Name the node */

    errorcode = cbf_name_new_node (*node, name);

    if (errorcode)
    {
      errorcode |= cbf_free_context (&(*node)->context);
      
      return errorcode | cbf_free_node (*node);
    }
  }


    /* Success */

  return 0;
}


  /* Free a node */

int cbf_free_node (cbf_node *node)
{
  unsigned int count;

  
    /* Check the arguments */
    
  if (!node)

    return CBF_ARGUMENT;


    /* Disconnect the node from its parent? */

  if (node->parent)

    for (count = 0; count < node->parent->children; count++)

      if (node->parent->child [count] == node)
      {
        node->parent->children--;

        if (node->parent->children == 0)

          cbf_failnez (cbf_free ((void **) &node->parent->child,
                                       &node->parent->child_size))

        else

          if (node->parent->children > count)
          
            memmove (node->parent->child + count, 
                     node->parent->child + count + 1,
                    (node->parent->children - count) * sizeof (cbf_node *));

        break;
      }


    /* Free the children */

  cbf_failnez (cbf_set_children (node, 0))


    /* Free the name */

  cbf_free_string (NULL, node->name);


    /* Free the context connection */

  cbf_failnez (cbf_delete_contextconnection (&node->context))


    /* Free the node */

  return cbf_free ((void **) &node, NULL);
}


  /* Set the number of children */

int cbf_set_children (cbf_node *node, unsigned int children)
{
  unsigned int count, new_size, kblock;

  int errorcode;


    /* Check the arguments */

  if (!node)

    return CBF_ARGUMENT;


    /* Is the current size correct? */

  if (children == node->children)

    return 0;
    
    /* Compute a target new size */

  kblock = 16;

  if (children > 128*2) kblock = 128;

  if (children > 512*2) kblock = 512;

  new_size = (((int)((children -1)/kblock)))*kblock+kblock;

  if (new_size < children) new_size = children;

    /* Decrease the number of children? */

  if (children < node->children)
  {
    errorcode = 0;
    
    for (count = children; count < node->children; count++)

        /* Free the child */

      if (node->type == CBF_COLUMN)
    
        errorcode |= cbf_set_columnrow (node, count, NULL, 1);

      else

        if (node->type != CBF_LINK)

          if (node->child [count])
          {
            node->child [count]->parent = NULL;
        
            errorcode |= cbf_free_node (node->child [count]);

            node->child [count] = NULL;
          }

    if (children == 0)

      errorcode = cbf_free ((void **) &node->child, &node->child_size);

    node->children = children;

    if (new_size < node->child_size )
      cbf_failnez (cbf_realloc ((void * *) &node->child, &node->child_size,
                                           sizeof (cbf_node  *), new_size))

    return errorcode;
  }


    /* Increase the number of children */

  if (new_size > node->child_size)
    cbf_failnez (cbf_realloc ((void **) &node->child, &node->child_size,
                                        sizeof (cbf_node *), new_size))

  node->children = children;


    /* Success */

  return 0;
}
  

  /* Trace a link */

cbf_node *cbf_get_link (const cbf_node *node)
{
  while (node)

    if (node->type == CBF_LINK)

      node = node->link;

    else

      return (cbf_node *) node;


    /* Fail */

  return NULL;
}


  /* Find a child node */

int cbf_find_child (cbf_node **child, const cbf_node *node, const char *name)
{
  unsigned int count;

  const char *namec, *nodenamec;


    /* Follow any links */

  node = cbf_get_link (node);
  

    /* Check the arguments */

  if (!node)

    return CBF_ARGUMENT;


    /* Is it a normal node? */

  if (node->type == CBF_COLUMN)

    return CBF_ARGUMENT;


    /* Search the children */

  for (count = 0; count < node->children; count++)

    if (name)
    {
      if (node->child [count]->name)
      {
        for (namec = name, nodenamec = node->child [count]->name;
            *namec && toupper (*nodenamec) == toupper (*namec);
             namec++, nodenamec++);

        if (!*namec && !*nodenamec)
        {
          if (child)
          
            *child = node->child [count];

          return 0;
        }
      }
    }
    else

      if (name == node->child [count]->name)
      {
        if (child)
        
          *child = node->child [count];

        return 0;
      }


    /* Fail */

  return CBF_NOTFOUND;
}


  /* Find a child node, accepting the last match  */

int cbf_find_last_child (cbf_node **child, const cbf_node *node, 
                         const char *name)
{
  int count;

  const char *namec, *nodenamec;


    /* Follow any links */

  node = cbf_get_link (node);
  

    /* Check the arguments */

  if (!node)

    return CBF_ARGUMENT;


    /* Is it a normal node? */

  if (node->type == CBF_COLUMN)

    return CBF_ARGUMENT;


    /* Search the children */

  for (count = ((int) node->children) - 1; count >= 0; count--)

    if (name)
    {
      if (node->child [count]->name)
      {
        for (namec = name, nodenamec = node->child [count]->name;
            *namec && toupper (*nodenamec) == toupper (*namec);
             namec++, nodenamec++);

        if (!*namec && !*nodenamec)
        {
          if (child)
          
            *child = node->child [count];

          return 0;
        }
      }
    }
    else

      if (name == node->child [count]->name)
      {
        if (child)
        
          *child = node->child [count];

        return 0;
      }


    /* Fail */

  return CBF_NOTFOUND;
}


  /* Find a parent node */

int cbf_find_parent (cbf_node **parent, const cbf_node *node, 
                     CBF_NODETYPE type)
{
    /* Follow any links */

  node = cbf_get_link (node);


    /* Check the arguments */

  if (!node)

    return CBF_ARGUMENT;


    /* Find the parent */
    
  while (node)
  {
    if (node->type == type)
    {
      if (parent)
      
        *parent = (cbf_node *) node;
      
      return 0;
    }

    node = node->parent;
  }


    /* Fail */

  return CBF_NOTFOUND;
}


  /* Count the number of children */

int cbf_count_children (unsigned int *children, const cbf_node *node)
{
    /* Follow any links */

  node = cbf_get_link (node);


    /* Check the arguments */
    
  if (!children || !node)

    return CBF_ARGUMENT;


    /* Success */

  *children = node->children;
  
  return 0;
}


  /* Get the index of a child */

int cbf_child_index (unsigned int *index, const cbf_node *node)
{
  cbf_node *parent;

  unsigned int child;

  
    /* Follow any links */

  node = cbf_get_link (node);


    /* Check the arguments */

  if (!node)

    return CBF_ARGUMENT;


    /* Get the parent */

  parent = node->parent;

  if (!parent)

    return CBF_NOTFOUND;


    /* Find the child */

  for (child = 0; child < parent->children; child++)

    if (parent->child [child] == node)
    {
      if (index)

        *index = child;

      return 0;
    }


    /* Fail */

  return CBF_NOTFOUND;
}


  /* Get the specified child */

int cbf_get_child (cbf_node **child, const cbf_node *node, unsigned int index)
{
    /* Follow any links */

  node = cbf_get_link (node);
  

    /* Check the arguments */

  if (!node)

    return CBF_ARGUMENT;


    /* Is it a normal node? */

  if (node->type == CBF_COLUMN)

    return CBF_ARGUMENT;


    /* Does the child exists? */

  if (index < node->children)
  {
    if (child)
          
      *child = node->child [index];

    return 0;
  }


    /* Fail */

  return CBF_NOTFOUND;
}


  /* Get the name of a node */

int cbf_get_name (const char **name, cbf_node *node)
{
    /* Follow any links */

  node = cbf_get_link (node);


    /* Check the arguments */
      
  if (!node)

    return CBF_ARGUMENT;


    /* Set the name */

  if (name)

    *name = node->name;


    /* Success */

  return 0;
}


  /* All of the following functions assume that all of the strings have
     been created using cbf_copy_string and that no pointers to the
     strings are retained by the calling functions */

  /* Name a node */

int cbf_name_node (cbf_node *node, const char *name)
{
    /* Follow any links */

  node = cbf_get_link (node);


    /* Check the arguments */
      
  if (!node)

    return CBF_ARGUMENT;
    

    /* Is there a sibling with this name? */

  if (node->parent)

    if (cbf_find_child (NULL, node->parent, name) == 0)

      return CBF_IDENTICAL;
      

    /* Replace the old name */

  cbf_free_string (NULL, node->name);

  node->name = name;


    /* Success */      

  return 0;
}


  /* Name a node allowing for duplicates  */

int cbf_name_new_node (cbf_node *node, const char *name)
{
    /* Follow any links */

  node = cbf_get_link (node);


    /* Check the arguments */
      
  if (!node)

    return CBF_ARGUMENT;
    

    /* Replace the old name */

  cbf_free_string (NULL, node->name);

  node->name = (char *) name;


    /* Success */      

  return 0;
}


  /* Add a child to a node */

int cbf_add_child (cbf_node *node, cbf_node *child)
{
    /* Follow any links */

  node = cbf_get_link (node);


    /* Check the first argument */
    
  if (!node)

    return CBF_ARGUMENT;


    /* Follow any links */

  child = cbf_get_link (child);


    /* Check the second argument */
    
  if (!child)

    return CBF_ARGUMENT;
    

    /* Is there already a child with this name? */
    
  if (cbf_find_child (NULL, node, child->name) == 0)

    return CBF_IDENTICAL;


    /* Add the child */

  cbf_failnez (cbf_set_children (node, node->children + 1))

  child->parent = node;

  node->child [node->children - 1] = child;


    /* Success */

  return 0;
}


  /* Add a child to a node with duplicates allowed */

int cbf_add_new_child (cbf_node *node, cbf_node *child)
{
    /* Follow any links */

  node = cbf_get_link (node);


    /* Check the first argument */
    
  if (!node)

    return CBF_ARGUMENT;


    /* Follow any links */

  child = cbf_get_link (child);


    /* Check the second argument */
    
  if (!child)

    return CBF_ARGUMENT;


    /* Add the child */

  cbf_failnez (cbf_set_children (node, node->children + 1))

  child->parent = node;

  node->child [node->children - 1] = child;


    /* Success */

  return 0;
}


  /* Make a new child node */

int cbf_make_child (cbf_node **child, cbf_node *node, 
                    CBF_NODETYPE type, const char *name)
{
  cbf_node *newchild;

  int errorcode;

  
    /* Check the type */

  if (type == CBF_LINK)

    return CBF_ARGUMENT;
    

    /* Follow any links */

  node = cbf_get_link (node);


    /* Does the child already exist? */

  errorcode = cbf_find_last_child (child, node, name);

  if (errorcode == 0)
  {
    cbf_free_string (NULL, name);
    
    return 0;
  }

  if (errorcode != CBF_NOTFOUND)

    return errorcode;


    /* Make a new node */

  cbf_failnez (cbf_make_node (&newchild, type, node->context, name))

  errorcode = cbf_add_child (node, newchild);

  if (errorcode)
  {
    newchild->name = NULL;

    cbf_free_node (newchild);
    
    return errorcode;
  }


    /* Success */

  if (child)

    *child = newchild;

  return 0;
}


  /* Make a new child node, with duplicates allowed */

int cbf_make_new_child (cbf_node **child, cbf_node *node,
                        CBF_NODETYPE type, const char *name)
{
  cbf_node *newchild;

  int errorcode;

  
    /* Check the type */

  if (type == CBF_LINK)

    return CBF_ARGUMENT;
    

    /* Follow any links */

  node = cbf_get_link (node);


    /* Make a new node */

  cbf_failnez (cbf_make_new_node (&newchild, type, node->context, name))

  errorcode = cbf_add_new_child (node, newchild);

  if (errorcode)
  {
    newchild->name = NULL;

    cbf_free_node (newchild);
    
    return errorcode;
  }


    /* Success */

  if (child)

    *child = newchild;

  return 0;
}


  /* Change a link */

int cbf_set_link (cbf_node *link, cbf_node *node)
{
    /* Check the arguments */
    
  if (!link)

    return CBF_ARGUMENT;


    /* Check the type */

  if (link->type != CBF_LINK)

    return CBF_ARGUMENT;


    /* Change the link */

  link->link = node;


    /* Success */

  return 0;
}


  /* Add a child link */

int cbf_add_link (cbf_node *link, cbf_node *child)
{
    /* Check the arguments */
    
  if (!link)

    return CBF_ARGUMENT;


    /* Check the type */

  if (link->type != CBF_LINK)

    return CBF_ARGUMENT;


    /* Add the child */

  cbf_failnez (cbf_set_children (link, link->children + 1))

  link->child [link->children - 1] = child;
  

    /* Success */

  return 0;
}
                                                  

  /* Set a link successively to each child link */

int cbf_shift_link (cbf_node *link)
{
    /* Check the arguments */
    
  if (!link)

    return CBF_ARGUMENT;


    /* Check the type */

  if (link->type != CBF_LINK)

    return CBF_ARGUMENT;


    /* Do the children exist? */

  if (link->children == 0)

    return CBF_ARGUMENT;


    /* Change the link */

  link->link = link->child [0];


    /* Shift the children */

  memmove (link->child, link->child + 1, 
          (link->children - 1) * sizeof (cbf_node *));

  link->child [link->children - 1] = link->link;


    /* Success */

  return 0;
}


  /* Set the value of a row */

int cbf_set_columnrow (cbf_node *column, unsigned int row,
                                         const char *value, int free)
{
    /* Follow any links */

  column = cbf_get_link (column);


    /* Check the arguments */
    
  if (!column)

    return CBF_ARGUMENT;


    /* Check the node type */

  if (column->type != CBF_COLUMN)

    return CBF_ARGUMENT;


    /* Increase the column size? */

  if (row + 1 > column->children)

    cbf_failnez (cbf_set_children (column, row + 1))


    /* Remove the old value */

  if (free)

    cbf_failnez (cbf_free_value (column->context, column, row))


    /* Set the new value */

  column->child [row] = (cbf_node *) value;


    /* Success */

  return 0;
}


  /* Get the value of a row */

int cbf_get_columnrow (const char **value, const cbf_node *column, 
                                           unsigned int row)
{
    /* Follow any links */

  column = cbf_get_link (column);


    /* Check the arguments */
    
  if (!column)

    return CBF_ARGUMENT;


    /* Check the node type */

  if (column->type != CBF_COLUMN)

    return CBF_ARGUMENT;


    /* Is the value in the column? */

  if (row + 1 > column->children)

    return CBF_NOTFOUND;


    /* Success */

  if (value)

    *value = (const char *) column->child [row];

  return 0;
}


  /* Inset a value into a column */

int cbf_insert_columnrow (cbf_node *column, unsigned int row, 
                          const char *value)
{
    /* Follow any links */

  column = cbf_get_link (column);


    /* Check the arguments */

  if (!column)

    return CBF_ARGUMENT;

  if (row > column->children)

    return CBF_NOTFOUND;


    /* Increase the column size */

  cbf_failnez (cbf_set_children (column, column->children + 1))


    /* Move any values further down the column */

  if (row < column->children - 1)

    memmove (column->child + row + 1, column->child + row,
               sizeof (cbf_node *) * (column->children - row - 1));
  

    /* Set the value */

  column->child [row] = (cbf_node *) value;


    /* Success */

  return 0;
}


  /* Delete a row from a column */

int cbf_delete_columnrow (cbf_node *column, unsigned int row)
{
    /* Follow any links */

  column = cbf_get_link (column);


    /* Check the arguments */

  if (!column)

    return CBF_ARGUMENT;

  if (row >= column->children)

    return CBF_NOTFOUND;


    /* Free the value */

  cbf_failnez (cbf_set_columnrow (column, row, NULL, 1))


    /* Move any values further down the column */

  if (row < column->children - 1)

    memmove (column->child + row, column->child + row + 1,
             sizeof (cbf_node *) * (column->children - row - 1));

  column->child [column->children - 1] = NULL;


    /* Decrease the column size */

  return cbf_set_children (column, column->children - 1);
}


  /* Add a value to a column */

int cbf_add_columnrow (cbf_node *column, const char *value)
{
    /* Follow any links */

  column = cbf_get_link (column);


    /* Check the arguments */

  if (!column)

    return CBF_ARGUMENT;


    /* Add the value */

  return cbf_set_columnrow (column, column->children, value, 1);
}


#ifdef __cplusplus

}

#endif
