##
## This is a sample makefile for building Pin tools outside
## of the Pin environment.  This makefile is suitable for
## building with the Pin kit, not a Pin source development tree.
##
## To build the tool, execute the make command:
##
##      make
## or
##      make PIN_HOME=<top-level directory where Pin was installed>
##
## After building your tool, you would invoke Pin like this:
## 
##      $PIN_HOME/pin -t MyPinTool -- /bin/ls
##
##############################################################
#
# User-specific configuration
#
##############################################################

#
# 1. Change PIN_HOME to point to the top-level directory where
#    Pin was installed. This can also be set on the command line,
#    or as an environment variable.
#
PIN_HOME ?= ./..

#
# 2. If variable LIBELF_INC is defined, means that libelf is 
#    installed on the system and can be used. Note that PIN 
#    comes with libelf-0.8.5 and we tested only with that 
#    version installed
#
ifdef LIBELF_INC
    LIBELF_CXXFLAGS=-I$(LIBELF_INC) -I$(LIBELF_INC)/libelf -DQUAD_LIBELF
else
    $(warning To take advantage of all the features of QUAD please point LIBELF_INC to the include directory where libelf is installed (ex: /usr/local/include))
endif


##############################################################
#
# set up and include *.config files
#
##############################################################

PIN_KIT=$(PIN_HOME)
KIT=1
TESTAPP=$(OBJDIR)cp-pin.exe

CXX=g++

TARGET_COMPILER?=gnu
ifdef OS
    ifeq (${OS},Windows_NT)
        TARGET_COMPILER=ms
    endif
endif

ifeq ($(TARGET_COMPILER),gnu)
    ifeq ($(wildcard $(PIN_HOME)/source/tools/makefile.gnu.config),)
      $(error "QUAD was tested with pintools-2.12-55942. Are you using a newer (unsupported version?")
    else
      include $(PIN_HOME)/source/tools/makefile.gnu.config
    endif
    LINKER?=${CXX}
    CXXFLAGS ?= -Wall -Wno-unknown-pragmas $(DBG) $(OPT)
    PIN=$(PIN_HOME)/pin
endif

ifeq ($(TARGET_COMPILER),ms)
    include $(PIN_HOME)/source/tools/makefile.ms.config
    DBG?=
    PIN=$(PIN_HOME)/pin.bat
endif

##############################################################
# Tools - you may wish to add your tool name to TOOL_ROOTS
##############################################################
#CXXFLAGS+=-pg
#LDFLAGS+=-pg
SRCDIR=./src
INCDIR=./include
CXXFLAGS+=$(LIBELF_CXXFLAGS)
CXXXMLFLAGS=-O3 -g -DTIXML_USE_TICPP -fPIC $(LIBELF_CXXFLAGS)
#-std=c++0x
INCLUDES=-I$(INCDIR)
TOOL_ROOTS = QUAD
TOOLS = $(TOOL_ROOTS:%=$(OBJDIR)%$(PINTOOL_SUFFIX))

TINYXMLSRCS = ticpp.cpp tinystr.cpp tinyxml.cpp tinyxmlerror.cpp tinyxmlparser.cpp
Q2XMLSRCS = RenewalFlags.cpp Channel.cpp Q2XMLFile.cpp Exception.cpp $(TINYXMLSRCS)
XMLOBJS = $(Q2XMLSRCS:%.cpp=$(OBJDIR)%.o)

#add the names of more CPP files here for the added functionality in QUAD
CPPSRCS = BBlock.cpp Utility.cpp
CPPOBJS = $(CPPSRCS:%.cpp=$(OBJDIR)%.oo)
CPPFLAGS = -O3 -fPIC
CPPINCS = -I$(INCDIR)

##############################################################
# build rules
##############################################################
all: tools
tools: $(OBJDIR) $(CPPOBJS) $(XMLOBJS) $(TOOLS) $(OBJDIR)cp-pin.exe
test: $(OBJDIR) $(TOOL_ROOTS:%=%.test)

QUAD.test: $(OBJDIR)cp-pin.exe
      $(MAKE) -k -C QUAD PIN_HOME=$(PIN_HOME)

$(OBJDIR)cp-pin.exe:
	$(CXX) $(PIN_HOME)/source/tools/Tests/cp-pin.cpp $(APP_CXXFLAGS) $(CPPOBJS) $(XMLOBJS) -o $(OBJDIR)cp-pin.exe

$(OBJDIR):
	mkdir -p $(OBJDIR)

# TODO: This is added because tracing.cpp is included in QUAD.cpp. This is BAD PRACTICE
# and could be solved by making a QUAD.h, but I do not have time now.
$(OBJDIR)QUAD.o: $(SRCDIR)/QUAD.cpp $(SRCDIR)/tracing.cpp
	$(CXX) $(INCLUDES) -c $(CXXFLAGS) $(PIN_CXXFLAGS) ${OUTOPT}$@ $(SRCDIR)/QUAD.cpp

$(OBJDIR)%.o: $(SRCDIR)/%.cpp
	$(CXX) $(INCLUDES) $(PIN_CXXFLAGS) $(CXXXMLFLAGS) -c $< -o  $@

$(OBJDIR)%.oo: $(SRCDIR)/%.cpp
	$(CXX) $(CPPINCS) $(CPPFLAGS) -c $< -o $@

$(TOOLS): $(PIN_LIBNAMES)

$(TOOLS): %$(PINTOOL_SUFFIX) : %.o
	${LINKER} $(PIN_LDFLAGS) $(LINK_DEBUG) ${LINK_OUT}$@ $< $(CPPOBJS) $(XMLOBJS) ${PIN_LPATHS} $(PIN_LIBS) $(DBG) $(LDFLAGS)

## cleaning
clean:
	-rm -rf $(OBJDIR) *.out *.tested *.failed makefile.copy $(XMLOBJS) $(CPPOBJS) *~ $(SRCDIR)/*~ $(INCDIR)/*~  

