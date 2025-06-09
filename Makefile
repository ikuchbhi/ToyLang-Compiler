# Flex & Bison sources
FLEX_FILE      := lexical-analysis/lex.l
BISON_FILE     := syntax-analysis/bison.y

# Compiler binary
COMPILER_NAME  := toyc

# Generated sources
FLEX_OUTPUT    := lex.yy.c
BISON_TAB_C    := bison.tab.c
BISON_TAB_H    := bison.tab.h

# AST implementation
AST_C          := ast-generator/ast.c
AST_H          := ast-generator/ast.h

# Symbol‐table implementation
SYMTAB_C       := symbol-table/symbol_table.c
SYMTAB_H       := symbol‐table/symbol_table.h

# Interpreter implementation
INTERPRETER_C  := ast-interpreter/interpreter.c
INTERPRETER_H  := ast-interpreter/interpreter.h

# Default build: produce a.out
all: $(COMPILER_NAME)

# Link everything into the final compiler
$(COMPILER_NAME): $(FLEX_OUTPUT) $(BISON_TAB_C) $(AST_C) $(SYMTAB_C) $(INTERPRETER_C)
	$(CC) -o $@ \
	    $(FLEX_OUTPUT) \
	    $(BISON_TAB_C) \
	    $(AST_C) \
	    $(SYMTAB_C) \
	    $(INTERPRETER_C) \
	    -lfl

# Generate the Flex scanner
$(FLEX_OUTPUT): $(FLEX_FILE)
	flex $(FLEX_FILE)

# Generate the Bison parser (and header)
$(BISON_TAB_C) $(BISON_TAB_H): $(BISON_FILE)
	bison -d $(BISON_FILE) -Wnone

# Clean up generated files
clean:
	rm -rf $(BISON_TAB_C) $(BISON_TAB_H) $(FLEX_OUTPUT) $(COMPILER_NAME)