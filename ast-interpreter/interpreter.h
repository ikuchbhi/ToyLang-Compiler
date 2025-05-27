#ifndef INTERPRETER_H
#define INTERPRETER_H

#include "../ast-generator/ast.h"
#include "../symbol-table/symbol_table.h"

typedef struct
{
    long value;
    int base;
} EvalResult;

// Run semantic analysis on the AST
int runSemanticAnalysis(ASTNode *root);

// Execute the program by performing a traversal on the AST
void executeProgram(ASTNode *root);

// Evaluate a given AST expression
EvalResult evaluateExpression(ASTNode *node);

// Execute a Variable Declaration block
void executeVariableDeclarationBlock(ASTNode *node);

// Execute a Statement block
void executeStatementBlock(ASTNode *node);

// Execute Assignment statement
void executeAssignmentStatement(ASTNode *node);

// Execute Print statement
void executePrintStatement(ASTNode *node);

// Execute Scan Statement
void executeScanStatement(ASTNode *node);

// Execute If Statement
void executeIfStatement(ASTNode *node);

// Execute While Statement
void executeWhileStatement(ASTNode *node);

// Execute For Statement
void executeForStatement(ASTNode *node);

// Run semantic analysis on a statement block
void checkStatementBlock(ASTNode *block);

// Run semantic analysis on a expression
void checkExpression(ASTNode *node, SymbolType *outType);

#endif