#ifndef __AST_H
#define __AST_H

/** AST Implementation for the Toy Language
 * Different AST Node types
 *  - AST_BEGIN_PROGRAM         : Represents the entire program
 *  - AST_VAR_DECL              : Represents a variable declaration
 *  - AST_VAR                   : Represents a variable
 *  - AST_BOOL_EXPR             : Represents a boolean expression
 *  - AST_BLOCK                 : Represents a block of statements
 *  - AST_ASSIGN_STMT           : Represents an assignment operation
 *  - AST_CONST_PRINT           : Represents a print statement with no arguments
 *  - AST_PRINT_STMT            : Represents a print statement with arguments
 *  - AST_FMT_STRING            : Represents a string containing '@' for formatting
 *  - AST_SCAN_STMT             : Represents a scan statement
 *  - AST_IF_STMT               : Represents an if statement
 *  - AST_ELSE_STMT             : Represents an else statement
 *  - AST_WHILE_STMT            : Represents a while statement
 *  - AST_FOR_STMT              : Represents a for statement
 *  - AST_FOR_STMT_INDEX        : Represents the index variable for a for statement
 *  - AST_FOR_STMT_UPDATE       : Represents the update part of a for statement
 */

#include <stdio.h>
#include <stdlib.h>

/** Enum to represent different node types */
typedef enum
{
    AST_BEGIN_PROGRAM,
    AST_VAR_DECL,
    AST_VAR_INT,
    AST_VAR_CHAR,
    AST_VAR_ARRAY_INT,
    AST_VAR_ARRAY_CHAR,
    AST_VAR,
    AST_STMT_BLOCK,
    AST_BLOCK,
    AST_ASSIGN_STMT,
    AST_CONST_PRINT,
    AST_PRINT_STMT,
    AST_SCAN_STMT,
    AST_SCAN_STMT_VAR,
    AST_IF_STMT,
    AST_ELSE_STMT,
    AST_WHILE_STMT,
    AST_FOR_STMT,
    AST_FOR_INC,
    AST_FOR_DEC,
    AST_PLUS,
    AST_MINUS,
    AST_MULTIPLY,
    AST_DIVIDE,
    AST_MODULUS,
    AST_CONSTANT_DECIMAL,
    AST_CONSTANT_OCTAL,
    AST_CONSTANT_BINARY,
    AST_CONSTANT_CHAR,
    AST_CONSTANT_STRING,
    AST_STMT_PLUS,
    AST_STMT_MINUS,
    AST_STMT_MULTIPLY,
    AST_STMT_DIVIDE,
    AST_STMT_MODULUS,
    AST_REL_OP_EQ,
    AST_REL_OP_LT,
    AST_REL_OP_LTE,
    AST_REL_OP_GT,
    AST_REL_OP_GTE,
    AST_REL_OP_NEQ,
} ASTNodeType;

const char *getASTNodeTagFromType(ASTNodeType type);

/** AST Node Implementations */
typedef struct Integer
{
    char *value;
    int base;
} Integer;

typedef struct ASTNodeData
{
    Integer intValue;       // Integer value
    char charValue;         // Character value
    char *stringValue;      // String value
} ASTNodeData;

typedef struct ASTNode
{
    ASTNodeType type;           // Type of the node
    struct ASTNodeData *data;   // Pointer to the data of this node
    struct ASTNode *components; // Pointer to the components of this node
    struct ASTNode *nextNode;   // Pointer to the next node in the program
} ASTNode;


/** Helper functions to create different nodes */
ASTNode *
createBasicASTNode_(ASTNodeType type, ASTNodeData *data);
ASTNodeData *createASTNodeData(void *data);
void insertComponentNode_(ASTNode *node, ASTNode *component);
void insertNextNode_(ASTNode *node, ASTNode *next);

// Function to free the allocated AST
void freeAST(ASTNode *root);

// Function to get the string representation of the node type
// Used to convert the AST into the generalised Lisp-style list string format
const char *getASTNodeTagFromType(ASTNodeType type);

// Function to print the AST as a generalised Lisp-style List
void printAST(ASTNode *root);

/** Functions to create respective AST Nodes
 *  Each will return a pointer to the created node,
 *  such that the corresponding Bison can use it to build the AST.
 */
// The main program node
ASTNode *buildProgramASTNode();

// Variable Declaration Section node
ASTNode *buildVarDeclASTNode();

// Individual Variable Declaration node
ASTNode *buildVariableDeclASTNode(char *varName, ASTNodeType type, int arraySize);

// Variable node
ASTNode *buildVariableASTNode(char *varName);

// Sentinel node to contain all statements
ASTNode *buildStatementsBlockASTNode();

// Assignment Statement node
ASTNode *buildAssignStmtASTNode(ASTNodeType type, char *varName, ASTNode *expr);

// Print Statement node
ASTNode *buildPrintStmtASTNode(char *string, ASTNode *variablesList);

// Scan Statement node
ASTNode *buildScanStmtASTNode(char *string, ASTNode *variablesList);

// Block of Statements node
ASTNode *buildBlockASTNode(ASTNode *stmtList);

// If Statement node
ASTNode *buildIfElseStmtASTNode(ASTNode *expr, ASTNode *stmtList, ASTNode *elseStmtList);

// While Statement node
ASTNode *buildWhileStmtASTNode(ASTNode *expr, ASTNode *stmtList);

// For Statement node
ASTNode *buildForStmtASTNode(ASTNode *initialExpr, ASTNode *terminateExpr, int direction, ASTNode *dirExpr, ASTNode *stmtList);

// Expression operator node
ASTNode *buildOperatorNode(ASTNodeType type, ASTNode *left, ASTNode *right);

// Constant node 
// Uses void* for generalisation
ASTNode *buildConstantNode(ASTNodeType type, void *value);

#endif