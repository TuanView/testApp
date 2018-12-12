################################################################################
################################################################################
ROOT_DIR = ../../..
BACNETDIR = $(ROOT_DIR)/bacnet-stack-0.8.2

-include $(ROOT_DIR)/makefile.init

SRC := ../src
BIN := ../bin
INC := ../include

INCPATH := -I$(INC) 

CPPFLAGS := -g
LDFLAGS := -g
LDLIBS := -lm

# Add inputs and outputs from these tool invocations to the build variables 
OBJS := $(SRC)/hello.o 
  
BINS := $(BIN)/testHello

# All Target
all: $(BINS)

Test: $(BIN)/testHello

# Other Targets
clean:
	-$(RM) $(OBJS) $(C_DEPS) $(EXECUTABLES) $(BINS)
	-@echo ' '

cleanRelease:
	$(RM) $(BIN_PATH)/helloProj
	make clean
	
cleanTest:
	$(RM) 

$(BIN)/testHello: $(SRC)/hello.o
	g++ $(LDFLAGS) -o $(BIN)/testHello $(SRC)/hello.o $(LDLIBS)

$(SRC)/hello.o: $(SRC)/hello.cpp
	g++ $(CPPFLAGS) -c $(SRC)/hello.cpp -o $(SRC)/hello.o

