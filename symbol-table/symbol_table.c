#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "symbol_table.h"

#define HASH_SIZE 211
static SymbolTableEntry *table[HASH_SIZE];

static unsigned long custom_string_hash(const char *s)
{
    unsigned long h = 5381;
    while (*s)
        h = ((h << 5) + h) + (unsigned char)(*s++);
    return h;
}

void initialiseSymbolTable(void)
{
    for (int i = 0; i < HASH_SIZE; i++)
        table[i] = NULL;
}

int insertIntoSymbolTable(const char *name, SymbolType type, int size)
{
    unsigned long h = custom_string_hash(name) % HASH_SIZE;
    for (SymbolTableEntry *e = table[h]; e; e = e->next)
    {
        if (strcmp(e->name, name) == 0)
            return -1;
    }

    SymbolTableEntry *e = malloc(sizeof(SymbolTableEntry));

    if (!e)
        return -1;

    e->name = strdup(name);
    e->type = type;
    e->base = 10;
    e->isInitialized = false;

    table[h] = e;
    return 0;
}

SymbolTableEntry *lookupFromSymbolTable(const char *name)
{
    unsigned long h = custom_string_hash(name) % HASH_SIZE;
    for (SymbolTableEntry *e = table[h]; e; e = e->next)
    {
        if (strcmp(e->name, name) == 0)
            return e;
    }
    return NULL;
}

void printSymbolTable(void)
{
    printf("\n=== Symbol Table ===\n");
    for (int i = 0; i < HASH_SIZE; i++)
    {
        for (SymbolTableEntry *e = table[i]; e; e = e->next)
        {
            char type[8];

            switch (e->type)
            {
            case TYPE_INT:
                snprintf(type, sizeof(type), "int");
                break;
            case TYPE_CHAR:
                snprintf(type, sizeof(type), "char");
                break;
            case TYPE_INT_ARRAY:
                snprintf(type, sizeof(type), "int[]");
                break;
            case TYPE_CHAR_ARRAY:
                snprintf(type, sizeof(type), "char[]");
                break;
            default:
                break;
            }

            printf("Name: %s, Type: %s, Initialized: %s", e->name, type, e->isInitialized ? "yes" : "no");

            if (e->isInitialized)
            {
                if (e->type == TYPE_INT)
                {
                    printf(", Value: %d, Base: %d", e->value.intVal, e->base);
                }
                else if (e->type == TYPE_CHAR)
                {
                    printf(", Value: '%c'", e->value.charVal);
                }
            }
            printf("\n");
        }
    }
}

void freeSymbolTable(void)
{
    for (int i = 0; i < HASH_SIZE; i++)
    {
        SymbolTableEntry *e = table[i];
        while (e)
        {
            SymbolTableEntry *next = e->next;
            free(e->name);
            if (e->type == TYPE_INT_ARRAY)
            {
                free(e->value.intArr);
            }
            else if (e->type == TYPE_CHAR_ARRAY)
            {
                free(e->value.charArr);
            }
            free(e);
            e = next;
        }
        table[i] = NULL;
    }
}