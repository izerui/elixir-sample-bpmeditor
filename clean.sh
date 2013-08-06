#!/bin/sh

# Shell script to build the sample.

# This script is known to work with the standard Bourne shell under
# Unix and the MKS Korn shell under Windows.

ILV_PRG="$0"

# Determine this program's absolute pathname.
case "$ILV_PRG" in
  /* ) ILV_ABS_PRG="$ILV_PRG" ;;
  */* ) ILV_ABS_PRG=`pwd`/"$ILV_PRG" ;;
  * ) ILV_ABS_PRG=
      for d in `echo "$PATH" | sed -e 's/:/ /g'`; do
        if test -x "$d/$ILV_PRG" ; then
          ILV_ABS_PRG="$d/$ILV_PRG"
          break
        fi
      done
      if test -z "$ILV_ABS_PRG"; then
        # Not found in $PATH. This means this script does not have execute
        # permissions and has been called as "sh run.sh".
        if test -f "$ILV_PRG"; then
          ILV_ABS_PRG=`pwd`/"$ILV_PRG"
        else
          echo "Could not resolve full path name. Please try calling \"sh fullpathname/$ILV_PRG\"." 1>&2
          exit 1
        fi
      fi
      ;;
esac
# Resolve symlinks.
sed_dirname='s,/[^/]*$,,'
sed_linkdest='s,^.* -> \(.*\),\1,p'
while : ; do
  lsline=`LC_ALL=C ls -l "$ILV_ABS_PRG"`
  case "$lsline" in
    *" -> "* )
      linkdest=`echo "$lsline" | sed -n -e "$sed_linkdest"`
      case "$linkdest" in
        /* ) ILV_ABS_PRG="$linkdest" ;;
        * ) ILV_ABS_PRG=`echo "$ILV_ABS_PRG" | sed -e "$sed_dirname"`/"$linkdest" ;;
      esac ;;
    * ) break ;;
  esac
done

ILV_DIR=`dirname "$ILV_ABS_PRG"`

# Change current directory.
cd "$ILV_DIR"

echo "Sample running in directory $ILV_DIR" 1>&2

# Check to see if the user has set FLEX_HOME
if test -z "$FLEX_HOME"; then
  # Try to set FLEX_HOME to something reasonable
  FLEX_HOME="E:/Adobe/Adobe Flash Builder 4.5/sdks/4.5.0.20967"
fi
export FLEX_HOME

# Check whether JAVA_HOME is set ('ant' needs it)
if test -z "$JAVA_HOME"; then
  echo "Error: JAVA_HOME is not set." 1>&2
  exit 1
fi

# Set ANT_HOME.

if test -z "$ANT_HOME"; then
  echo "Error: ANT_HOME is not set." 1>&2
  exit 2
fi
# Export it, just in case the user has defined ANT_HOME him/herself to point
# to a different version of ant, and we're unlucky enough to run in Solaris sh,
# where setting a variable shadows the value from the environment without
# overwriting the value in the environment.
export ANT_HOME

# We need to increase the memory, if you use the ANT_OPTS
# option you may need to add this option to your setting.
if test -z "$ANT_OPTS"; then
  ANT_OPTS="-Xmx512m"
fi
export ANT_OPTS

# Now run it.
exec "$ANT_HOME/bin/ant" --noconfig "-DFLEX_HOME=$FLEX_HOME" "-DILOG_HOME=D:/Program Files/IBM/ILOG/Elixir Enterprise 3.5 Trial" clean
