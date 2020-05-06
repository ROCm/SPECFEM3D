# -*- Autoconf -*-


## ------------------------- ##
## Autoconf macros for HIP. ##
## ------------------------- ##


# ----------------------------------------------------------------------
# CIT_HIP_CONFIG
# ----------------------------------------------------------------------
# Determine the directory containing <hip_runtime.h>
AC_DEFUN([CIT_HIP_CONFIG], [

  # influential environment variables
  AC_ARG_VAR(HIPCC, [AMD HIP compiler command])
  AC_ARG_VAR(HIP_FLAGS, [HIP compiler flags])
  AC_ARG_VAR(HIP_INC, [Location of HIP include files])
  AC_ARG_VAR(HIP_LIB, [Location of HIP library libhip_hcc])
  #********The paths which you want to set*********
 AC_SUBST([HIP_INC],[/opt/rocm/include])         #Please set this path as your requirement#
 AC_SUBST([HIP_LIB],[/opt/rocm/lib])             #Please set this path as your requirement#
  #******************************
  # tests HIPCC variable
  AS_IF([test x"$HIPCC" = x],[
    HIPCC=hipcc
  ])

  # Check for compiler
  # checks if program in path
  AC_PATH_PROG(HIPCC_PROG, $HIPCC)
  if test -z "$HIPCC_PROG" ; then
    AC_MSG_ERROR([cannot find '$HIPCC' program, please check your PATH.])
  fi

  # Checks for compiling and linking
  AC_LANG_PUSH([C])
  AC_REQUIRE_CPP
  CFLAGS_save="$CFLAGS"
  LDFLAGS_save="$LDFLAGS"
  LIBS_save="$LIBS"

  # uses hipcc compiler
  CFLAGS="$HIP_FLAGS"
  if test "x$HIP_INC" != "x"; then
    HIP_CPPFLAGS="-I$HIP_INC"
    CFLAGS="$CFLAGS $HIP_CPPFLAGS"
  fi

  # Check for HIP headers
  # runs test with hipcc
  AC_MSG_CHECKING([for hip_runtime.h])
  ac_compile='$HIPCC -c $CFLAGS conftest.$ac_ext >&5'
  AC_COMPILE_IFELSE([
    AC_LANG_PROGRAM([[
    #include <hip/hip_runtime.h>]],[[void* ptr = 0;]])
  ], [
    AC_MSG_RESULT(yes)
  ], [
    AC_MSG_RESULT([HIP runtime header not found; try setting HIP_INC.])
  ])

  # Check fo HIP library
  if test "x$HIP_LIB" != "x"; then
    HIP_LDFLAGS="-L$HIP_LIB"
    LDFLAGS="$HIP_LDFLAGS $LDFLAGS"
  fi
  HIP_LIBS="-lhip_hcc"
  LIBS="$HIP_LIBS $LIBS"

  # runs compilation test with hipcc
  AC_MSG_CHECKING([hipcc compilation with hipMalloc in -lhip_hcc])
  ac_compile='$HIPCC -c $CFLAGS conftest.$ac_ext >&5'
  AC_COMPILE_IFELSE([
    AC_LANG_PROGRAM([[
    #include <hip/hip_runtime.h>]],[[void* ptr = 0;hipMalloc(&ptr, 1);]])
  ], [
    AC_MSG_RESULT(yes)
  ], [
    AC_MSG_RESULT([HIP library function with hipcc compilation failed; try setting HIP_INC.])
  ])

  # runs linking test with hipcc
  AC_MSG_CHECKING([hipcc linking with hipMalloc in -lhip_hcc])
  ac_link='$HIPCC -o conftest$ac_exeext $CFLAGS $LDFLAGS conftest.$ac_ext $LIBS >&5'
  AC_LINK_IFELSE(
    [AC_LANG_PROGRAM([[
#include <stdio.h>
#include <hip/hip_runtime.h>]],[[void* ptr = 0;hipMalloc(&ptr, 1);]])],
    [AC_MSG_RESULT(yes)],
    [AC_MSG_RESULT([HIP library linking with HIP failed; try setting HIP_LIB.])
  ])

##runs linking test with standard compiler
#  AC_MSG_CHECKING([linking with hipMalloc in -lhip_hcc])
#
#C compiler linking
#ac_link='$HIPCC -c $CFLAGS conftest.$ac_ext >&5; $CC -o conftest$ac_exeext $LDFLAGS conftest.$ac_objext $LIBS >&5'
  
#  AC_LINK_IFELSE(
#    [AC_LANG_PROGRAM([[
#    #include <stdio.h>
#    #include <hip/hip_runtime.h>]],[[void* ptr = 0;hipMalloc(&ptr, 1);]])],
#    [AC_MSG_RESULT(yes)],
#    [AC_MSG_RESULT(no)
#     AC_MSG_ERROR([HIP library linking failed; try setting HIP_LIB.])
#  ])

  CFLAGS="$CFLAGS_save"
  LDFLAGS="$LDFLAGS_save"
  LIBS="$LIBS_save"
  AC_LANG_POP([C])

  AC_SUBST([HIPCC])
  AC_SUBST([HIP_CPPFLAGS])
  AC_SUBST([HIP_LDFLAGS])
  AC_SUBST([HIP_LIBS])
])dnl CIT_HIP_COMPILER


dnl end of file
