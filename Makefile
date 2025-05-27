# Flex File
FLEX_FILE := lexical-analysis/lex.l
# Bison File
BISON_FILE := syntax-analysis/bison.y

# Compiler Name
COMPILER_NAME := a.out

# Python Interpreter
PY := python3

# Python Script to generate AST
AST_SCRIPT := ast-generator/print_ast.py

# AST Output File
AST_FILE := ast.txt

# Generated Files
# Flex Output
FLEX_OUTPUT := lex.yy.c
# Bison Output
BISON_TAB_C := bison.tab.c
BISON_TAB_H := bison.tab.h

# AST Files
AST_C := ast-generator/ast.c 
AST_H := ast-generator/ast.h

# Default job: generate the compiler
all: default

default: flex bison
	@echo "Compiling the Toy compiler..."
	@echo ">> $(CC) -o $(COMPILER_NAME) -lfl $(FLEX_OUTPUT) $(BISON_TAB_C) $(AST_C)"
	@$(CC) -o $(COMPILER_NAME) $(FLEX_OUTPUT) $(BISON_TAB_C) $(AST_C) -lfl
	@echo "Compilation complete."
	@echo "Run ./$(COMPILER_NAME) <input_file> <output_file> to execute."

bison:
	@echo "Generating Bison parser..."
	@echo ">> bison -d $(BISON_FILE) -Wnone"
	@bison -d $(BISON_FILE) -Wnone
	@echo "Bison parser generated."
	@echo "\n"

flex:
	@echo "Generating Flex scanner..."
	@echo ">> flex $(FLEX_FILE)"
	@flex $(FLEX_FILE)
	@echo "Flex scanner generated."
	@echo "\n"

# Debug job: generate the compiler with debug mode enabled
debug: bison_debug flex_debug ast
	@echo "Compiling the Toy compiler in debug mode..."
	@echo ">> $(CC) -o $(COMPILER_NAME) -lfl $(FLEX_OUTPUT) $(BISON_TAB_C) $(AST_C)"
	@$(CC) -o $(COMPILER_NAME) -lfl $(FLEX_OUTPUT) $(BISON_TAB_C) $(AST_C)
	@echo "Debug compilation complete."
	@echo "Run ./$(COMPILER_NAME) <input_file> <output_file> to execute."

bison_debug:
	@echo "Generating Bison parser..."
	@echo ">> bison -d -t $(BISON_FILE) --debug"
	@bison -d -t $(BISON_FILE) --debug
	@echo "Bison parser generated."
	@echo "\n"


flex_debug:
	@echo "Generating Flex scanner..."
	@echo ">> flex $(FLEX_FILE)"
	@flex $(FLEX_FILE)
	@echo "Flex scanner generated."
	@echo "\n"

# Run the Python script to pretty-print the AST
ast:
	@echo "Generating AST..."
	@echo ">> $(PY) $(AST_SCRIPT) > $(AST_FILE)"
	@echo "Enter the output file name: "
	@$(PY) -u $(AST_SCRIPT) > $(AST_FILE)
	@echo "AST generation complete. See $(AST_FILE) for the output."
	@echo "\n"

# Clean job: remove generated files
clean:
	@echo "Cleaning up generated files..."
	@echo ">> rm -rf $(BISON_TAB_C) $(BISON_TAB_H) $(FLEX_OUTPUT) $(COMPILER_NAME) $(AST_FILE)"
	@rm -rf $(BISON_TAB_C) $(BISON_TAB_H) $(FLEX_OUTPUT) $(COMPILER_NAME) $(AST_FILE)
	@echo "\n"
