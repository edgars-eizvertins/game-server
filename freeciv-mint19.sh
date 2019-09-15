#!/bin/bash

if test "x$1" = "x-v" || test "x$1" = "x--version" ; then
  echo "Freeciv build script for Linux Mint19 version 1.00"
  exit
fi

echo "Installing requirements"
sudo apt-get install \
  build-essential wget libcurl4-openssl-dev zlib1g-dev \
  libreadline-dev libbz2-dev liblzma-dev libgtk-3-dev \
  libgtk2.0-dev qt5-default \
  libsdl2-mixer-dev libsdl2-image-dev libsdl2-gfx-dev libsdl2-ttf-dev \
  libsdl-mixer1.2-dev libsdl-image1.2-dev libsdl-gfx1.2-dev libsdl-ttf2.0-dev \
  libicu-dev

if test "x$1" = "x" || test "x$2" = "x" ||
   test "x$1" = "x-h" || test "x$1" = "x--help" ; then
  echo "Usage: $0 <release> <gui> [main dir=freeciv] [download URL]"
  echo "Supported releases are those of 2.5 and 2.6 major versions"  
  echo "Supported guis are 'gtk2', 'gtk3.22', 'gtk3', 'qt', 'sdl', 'sdl2'"
  echo "URL must point either to tar.bz2 or tar.xz package"
  exit
fi

REL=$1
GUI=$2

if test "x$3" = "x" ; then
  MAINDIR="freeciv"
else
  MAINDIR="$3"
fi

FREECIV_MAJMIN=$(echo $REL | sed 's/\./ /g' | (read MAJOR MINOR PATCH ; echo -n "$MAJOR.$MINOR"))

if test "x$FREECIV_MAJMIN" != "x2.5" &&
   test "x$FREECIV_MAJMIN" != "x2.6" &&
   test "x$FREECIV_MAJMIN" != "x3.0" &&
   test "x$FREECIV_MAJMIN" != "x2.94" ; then
  echo "Release '$REL' from unsupported branch. See '$0 --help' for supported options" >&2
  exit 1
fi

if test "x$GUI" != "xgtk3.22" &&
   test "x$GUI" != "xgtk3" &&
   test "x$GUI" != "xgtk2" &&
   test "x$GUI" != "xqt"   &&
   test "x$GUI" != "xsdl2" &&
   test "x$GUI" != "xsdl" ; then
  echo "Unsupported gui '$GUI' given. See '$0 --help' for supported options" >&2
  exit 1
fi

if test "x$FREECIV_MAJMIN" = "x2.5" && test "x$GUI" = "xsdl2" ; then
  echo "sdl2 is not supported gui for freeciv-2.5" >&2
  exit 1
fi

if test "x$FREECIV_MAJMIN" = "x2.5" && test "x$GUI" = "xgtk3.22" ; then
  echo "gtk3.22 is not supported gui for freeciv-2.5" >&2
  exit 1
fi

if test "x$GUI" = "xsdl" ; then
  if test "x$FREECIV_MAJMIN" = "x3.0" || test "x$FREECIV_MAJMIN" = "x2.94"
  then
    echo "sdl is not supported gui for freeciv-3.0" >&2
    exit 1
  fi
fi

if test -d "$MAINDIR" ; then
  echo "There's already directory called '$MAINDIR'. Should I use it?"
  echo "y)es or no?"
  echo -n "> "
  read -n 1 ANSWER
  if test "x$ANSWER" != "xy" ; then
    echo "Didn't get definite yes for using existing directory. Aborting"
    exit 1
  fi
  echo
fi

if ! mkdir -p "$MAINDIR" ; then
  echo "Failed to create directory '$MAINDIR'" >&2
  exit 1
fi

if ! cd "$MAINDIR" ; then
  echo "Can't go to '$MAINDIR' directory" >&2
  exit 1
fi

export FREECIV_MAINDIR=$(pwd)

if ! test -f freeciv-$REL.tar.bz2 && ! test -f freeciv-$REL.tar.xz ; then
  echo "Downloading freeciv-$REL"
  if test "x$4" = "x" ; then
    URL="http://sourceforge.net/projects/freeciv/files/Freeciv $FREECIV_MAJMIN/$REL/freeciv-$REL.tar.bz2"
  else
    URL="$4"
  fi
  if ! wget "$URL" ; then
    echo "Can't download freeciv release freeciv-$REL." >&2
    exit 1
  fi
else
  echo "freeciv-$REL already downloaded"
fi

if ! test -d freeciv-$REL ; then
  echo "Unpacking freeciv-$REL"
  if test -f freeciv-$REL.tar.xz ; then
    if ! tar xJf freeciv-$REL.tar.xz ; then
      echo "Failed to unpack freeciv-$REL.tar.xz" >&2
      exit 1
    fi
  elif ! tar xjf freeciv-$REL.tar.bz2 ; then
    echo "Failed to unpack freeciv-$REL.tar.bz2" >&2
    exit 1
  fi
else
  echo "freeciv-$REL source directory already exist"
fi

if ! cd freeciv-$REL ; then
  echo "Failed to go to source directory freeciv-$REL" >&2
  exit 1
fi

if ! cd $FREECIV_MAINDIR ; then
  echo "Failed to return to main directory '$FREECIV_MAINDIR'" >&2
  exit 1
fi

if ! mkdir -p builds-$REL/$GUI ; then
  echo "Failed to create build directory 'builds-$REL/$GUI'" >&2
  exit 1
fi

if test -f install-$REL/$GUI ; then
  echo "Removing old $REL $GUI installation directory"
  if ! rm -Rf install-$REL/$GUI ; then
    echo "Failed to remove old installation directory" >&2
    exit 1
  fi
fi

if ! cd builds-$REL/$GUI ; then
  echo "Failed to go to directory builds-$REL/$GUI" >&2
  exit 1
fi

if test "x$GUI" = "xsdl" ; then
  EXTRA_CONFIG="--enable-sdl-mixer=sdl"
fi

if test "x$GUI" = "xgtk2" ; then
  FCMP="gtk2"
elif test "x$GUI" = "xqt" ; then
  FCMP="qt"
else
  FCMP="gtk3"
fi

echo "configure"
if ! ../../freeciv-$REL/configure --prefix=$FREECIV_MAINDIR/install-$REL/$GUI --enable-client=$GUI --enable-fcmp=$FCMP $EXTRA_CONFIG ; then
  echo "Configure failed" >&2
  exit 1
fi

echo "make"
if ! make ; then
  echo "Make failed" >&2
  exit 1
fi

echo "make install"
if ! make install ; then
  echo "'Make install' failed" >&2
  exit 1
fi

echo
echo "freeciv-$REL $GUI installation is now at $FREECIV_MAINDIR/install-$REL/$GUI"

