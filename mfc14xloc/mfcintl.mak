# This is a part of the Microsoft Foundation Classes C++ library.
# Copyright (C) Microsoft Corporation
# All rights reserved.
#
# This source code is only intended as a supplement to the
# Microsoft Foundation Classes Reference and related
# electronic documentation provided with the library.
# See these sources for detailed information regarding the
# Microsoft Foundation Classes product.

# MFC14X[LANG].DLL is a DLL which contains language specific resources
# There should be a l.[LANG] and a ..\..\include\l.[LANG] directories
#   before attempting this build.
# These directories should contain the language specific MFC .rc
#   files used to build this DLL.
# The resulting DLL contains no code, just the MFC standard resources.
#
# The following macros are used to control the build process:
#   LANG=<3 character language identifier>
#       This is used to uniquely identify the DLL.  It is the standard
#       3 character language abbreviation retrieved via GetLocaleInfo.
#
#   LANGID=<4 character string indicating language ID>
#       This is used to construct a correct version resource.
#       The LANGID is specified in hex.
#
#   CP=<decimal codepage>
#   CPHEX=<hex codepage>
#       This codepage matches the last 4 digits of the LANGCODE,
#       except that they are in decimal where as the LANGCODE is
#       specified in hex.
#
# Examples:
#   // build for LANG=ENGLISH
#   nmake LANG=ENU LANGID=0409 /f mfcintl.mak
#
#   // build for LANG=FRENCH
#   nmake LANG=FRA LANGID=040C /f mfcintl.mak
#
#   // build for LANG=JAPANESE
#   nmake LANG=JPN LANGID=0411 CP=932 CPHEX=03A4 /f mfcintl.mak
#       (Note: you must have codepage 932 installed)
#

!if "$(MFC_VER)" == ""
MFC_VER=14X
!endif

# Name of this makefile for use in recursion
!if "$(MAKNAME)" == ""
MAKNAME=mfcintl.mak
!endif

!ifndef CP
# Default to "Windows, Multilingual" codepage (ANSI)
CP=1252
CPHEX=04E4
!endif


TARG=MFC$(MFC_VER)$(LANG)
RC_DEFINES=/DLANG=$(LANG)
LFLAGS=/noentry /dll /base:0x5d360000 /merge:.rdata=.text
LINK32=link

# Default PLATFORM depending on host environment
!ifndef PLATFORM
!ifndef PROCESSOR_ARCHITECTURE
!error PLATFORM must be set to intended target
!endif
!if "$(PROCESSOR_ARCHITECTURE)" == "x86"
PLATFORM=INTEL
!endif
!if "$(PROCESSOR_ARCHITECTURE)" == "ALPHA"
PLATFORM=ALPHA
!endif
!if "$(PROCESSOR_ARCHITECTURE)" == "MIPS"
PLATFORM=MIPS
!endif
!if "$(PROCESSOR_ARCHITECTURE)" == "PPC"
PLATFORM=PPC
!endif
!endif

!if "$(PLATFORM)" == "INTEL"
LFLAGS=$(LFLAGS) /machine:i386
!endif
!if "$(PLATFORM)" == "AMD64"
LFLAGS=$(LFLAGS) /machine:x64
LFLAGS=$(LFLAGS) /base:0x5d3600000
!endif
!if "$(PLATFORM)" == "IA64"
LFLAGS=$(LFLAGS) /machine:ia64
!endif
!if "$(PLATFORM)" == "MIPS"
LFLAGS=$(LFLAGS) /machine:mips
!endif
!if "$(PLATFORM)" == "ALPHA"
LFLAGS=$(LFLAGS) /machine:alpha
!endif
!if "$(PLATFORM)" == "PPC"
LFLAGS=$(LFLAGS) /machine:ppc
!endif

!ifdef RELEASE # Release VERSION info
RC_DEFINES=$(RC_DEFINES) /DRELEASE
LFLAGS=$(LFLAGS) /release
!endif

RC_DEFINES=$(RC_DEFINES) \
	/DLANGCODE=\"$(LANGID)$(CPHEX)\" /DLANGID=0x$(LANGID) /DCODEPAGE=$(CP) \
	/DVER_LANGID=0x$(LANGID) /DVER_LANGID_HEX=$(LANGID)  
RC_CODEPAGE=/c$(CP) /l$(LANGID)

dll_goal: $(PLATFORM)\$(TARG).dll

#############################################################################
# Build target

$(PLATFORM)\$(TARG).res: mfcintl.rc ..\..\include\atlbuild.h
	rc /r $(RC_CODEPAGE) $(RC_DEFINES) /fo "$(OUTDIR)\$(TARG).res" mfcintl.rc

$(PLATFORM)\$(TARG).dll: $(PLATFORM)\$(TARG).res
	$(LINK32) $(LFLAGS) /out:"$(OUTDIR)\$(TARG).DLL" "$(OUTDIR)\$(TARG).res"
	-del "$(OUTDIR)\$(TARG).res"

#############################################################################
# Predefined locales

# Chinese (PRC)
chs:
	$(MAKE) -$(MAKEFLAGS) -f "$(MAKNAME)" LANG=CHS LANGID=0804 CP=936 CPHEX=03A8

# Chinese (Traditional)
cht:
	$(MAKE) -$(MAKEFLAGS) -f "$(MAKNAME)" LANG=CHT LANGID=0404 CP=950 CPHEX=03B6

# English (American)
enu:
	$(MAKE) -$(MAKEFLAGS) -f "$(MAKNAME)" LANG=ENU LANGID=0409

# French (Standard)
fra:
	$(MAKE) -$(MAKEFLAGS) -f "$(MAKNAME)" LANG=FRA LANGID=040C

# German (Standard)
deu:
	$(MAKE) -$(MAKEFLAGS) -f "$(MAKNAME)" LANG=DEU LANGID=0407

# Italian (standard)
ita:
	$(MAKE) -$(MAKEFLAGS) -f "$(MAKNAME)" LANG=ITA LANGID=0410

# Korean
kor:
	$(MAKE) -$(MAKEFLAGS) -f "$(MAKNAME)" LANG=KOR LANGID=0412 CP=949 CPHEX=03B5

# Japanese
jpn:
	$(MAKE) -$(MAKEFLAGS) -f "$(MAKNAME)" LANG=JPN LANGID=0411 CP=932 CPHEX=03A4

# Spanish (International Sort)
esn:
	$(MAKE) -$(MAKEFLAGS) -f "$(MAKNAME)" LANG=ESN LANGID=0C0A

# Russian
rus:
	$(MAKE) -$(MAKEFLAGS) -f "$(MAKNAME)" LANG=RUS LANGID=0419 CP=1251 CPHEX=04E3

#############################################################################
