.PHONY: clean default run
# Compiler and flags
CXX = g++
CFLAGS = -Wall -g

ALL_SRC = $(wildcard src/*.cpp)
SRC_OBJ = $(subst src,obj,$(ALL_SRC:.cpp=.o))

# Bison and Flex configuration
BISON = bison
B_CNTR = -Wcounterexamples
BISONFLAGS = -d $(B_CNTR)

FLEX = flex

# Files
BISON_SRC = src/fsl.y
FLEX_SRC  = src/fsl.l
BISON_OUT = obj/yy.tab.cpp
BISON_H   = obj/yy.tab.hpp
FLEX_OUT  = obj/lex.yy.cpp
TARGET    = bin/fslcc

PARSE_OBJ = $(BISON_OUT:.cpp=.o) $(FLEX_OUT:.cpp=.o)

ALL_OBJ = $(SRC_OBJ) $(PARSE_OBJ)

INC  = -I./inc -I./obj
LIBS = -lboost_program_options

#INP_FILES = -i syntax_tests/_1_syntax_test.fsl \

INP_FILES = -i examples/dhrystone.fsl

OUT_FILE  = -o output.txt

CFLAGS  = $(INC)
LDFLAGS =

default: run

$(TARGET): $(ALL_OBJ)
	@mkdir -p bin
	$(CXX) $(LDFLAGS) $^ -o $@ $(LIBS)

obj/%.o : src/%.cpp
	$(CXX) -c $(CFLAGS) $< -o $@

obj/yy.tab.o: $(BISON_OUT)
	$(CXX) -c $(CFLAGS) $< -o $@

obj/lex.yy.o: $(FLEX_OUT)
	$(CXX) -c $(CFLAGS) $< -o $@

# Bison build rule, generating both .c and .h files
$(BISON_OUT) $(BISON_H): $(BISON_SRC)
	@mkdir -p obj
	$(BISON) $(BISONFLAGS) $(BISON_SRC) -o $(BISON_OUT)

# Flex build rule, depends on Bison header
$(FLEX_OUT): $(FLEX_SRC) $(BISON_H)
	@mkdir -p obj
	$(FLEX) -o $(FLEX_OUT) $(FLEX_SRC)

#TRACE=--trace_en
run:  $(TARGET)
	$(TARGET) $(INP_FILES) $(OUT_FILE) $(TRACE)

# Clean build files
clean:
	rm -f ./bin/* ./obj/*


