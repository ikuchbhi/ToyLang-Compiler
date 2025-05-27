#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <stdbool.h>

typedef enum
{
    TYPE_INT,
    TYPE_CHAR,
    TYPE_INT_ARRAY,
    TYPE_CHAR_ARRAY
} SymbolType;

typedef union
{
    int intVal;
    char charVal;
    int *intArr;
    char *charArr;
} SymbolEntryValue;

typedef struct SymbolTableEntry
{
    char *name;
    SymbolType type;
    int base;
    bool isInitialized;
    SymbolEntryValue value;
    struct SymbolTableEntry *next;
} SymbolTableEntry;

// Initialise the symbol table
void initialiseSymbolTable(void);

// Insert into the symbol table
int insertIntoSymbolTable(const char *name, SymbolType type, int size);

// Lookup an entry
SymbolTableEntry *lookupFromSymbolTable(const char *name);

// Print the symbol table
void printSymbolTable(void);

// Free the symbol table
void freeSymbolTable(void);

#endif