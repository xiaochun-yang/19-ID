# MAGICK_FUNC_FSEEKO
# --------------
AC_DEFUN([MAGICK_FUNC_FSEEKO],
[_AC_SYS_LARGEFILE_MACRO_VALUE(_LARGEFILE_SOURCE, 1,
   [ac_cv_sys_largefile_source],
   [Define to 1 to make fseeko visible on some hosts (e.g. glibc 2.2).],
   [[#include <sys/types.h> /* for off_t */
     #include <stdio.h>]],
   [[int (*fp) (FILE *, off_t, int) = fseeko; 
     return fseeko (stdin, 0, 0) && fp (stdin, 0, 0);]])

# We used to try defining _XOPEN_SOURCE=500 too, to work around a bug
# in glibc 2.1.3, but that breaks too many other things.
# If you want fseeko and ftello with glibc, upgrade to a fixed glibc.
if test $ac_cv_sys_largefile_source != unknown; then
  AC_DEFINE(HAVE_MAGICK_FSEEKO, 1,
    [Define to 1 if fseeko (and presumably ftello) exists and is declared.])
fi
])# MAGICK_FUNC_FSEEKO
