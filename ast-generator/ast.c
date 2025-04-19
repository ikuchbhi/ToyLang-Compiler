#include <string.h>
#include "ast.h"

extern FILE *yyout;

ASTNode *createBasicASTNode_(ASTNodeType type, ASTNodeData *data)
{
    ASTNode *node = (ASTNode *)malloc(sizeof(ASTNode));
    if (!node)
    {
        fprintf(stderr, "Memory allocation failed for AST node\n");
        exit(EXIT_FAILURE);
    }
    node->type = type;
    node->data = data;
    node->components = NULL;
    node->nextNode = NULL;
    return node;
}

void insertComponentNode_(ASTNode *node, ASTNode *component)
{
    if (node->components == NULL)
    {
        node->components = component;
    }
    else
    {
        ASTNode *temp = node->components;
        while (temp->nextNode != NULL)
        {
            temp = temp->nextNode;
        }
        temp->nextNode = component;
    }
}

// Every node can have only one next node, hence direct assignment
void insertNextNode_(ASTNode *node, ASTNode *nextNode)
{
    node->nextNode = nextNode;
}

// Free the allocated AST
// Recursively free the components LL, followed by the next nodes
void freeAST(ASTNode *root)
{
    if (root == NULL)
        return;

    // Free pointer to data if exists
    if (root->data != NULL)
    {
        free(root->data);
    }

    freeAST(root->components);
    freeAST(root->nextNode);

    // Free current node
    free(root);
}

const char *getASTNodeTagFromType(ASTNodeType type)
{
    switch (type)
    {
    case AST_BEGIN_PROGRAM:
        return "";
    case AST_VAR_DECL:
        return "";
    case AST_VAR_INT:
    case AST_VAR_ARRAY_INT:
        return "int";
    case AST_VAR_CHAR:
    case AST_VAR_ARRAY_CHAR:
        return "char";
    case AST_VAR:
        return "";
    case AST_STMT_BLOCK:
        return "";
    case AST_BLOCK:
        return "";
    case AST_ASSIGN_STMT:
        return ":=";
    case AST_PRINT_STMT:
        return "print";
    case AST_SCAN_STMT:
        return "scan";
    case AST_SCAN_STMT_VAR:
        return "";
    case AST_IF_STMT:
        return "if";
    // case AST_ELSE_STMT:
    //     return "ELSE";
    case AST_WHILE_STMT:
        return "while";
    case AST_FOR_STMT:
        return "for";
    case AST_FOR_INC:
        return "inc";
    case AST_FOR_DEC:
        return "dec";
    case AST_PLUS:
        return "+";
    case AST_MINUS:
        return "-";
    case AST_MULTIPLY:
        return "*";
    case AST_DIVIDE:
        return "/";
    case AST_MODULUS:
        return "%";
    case AST_CONSTANT_BINARY:
        return "";
    case AST_CONSTANT_OCTAL:
        return "";
    case AST_CONSTANT_DECIMAL:
        return "";
    case AST_CONSTANT_CHAR:
        return "";
    case AST_CONSTANT_STRING:
        return "";
    case AST_STMT_PLUS:
        return "+=";
    case AST_STMT_MINUS:
        return "-=";
    case AST_STMT_MULTIPLY:
        return "*=";
    case AST_STMT_DIVIDE:
        return "/=";
    case AST_STMT_MODULUS:
        return "%=";
    case AST_REL_OP_EQ:
        return "=";
    case AST_REL_OP_LT:
        return "<";
    case AST_REL_OP_LTE:
        return "<=";
    case AST_REL_OP_GT:
        return ">";
    case AST_REL_OP_GTE:
        return ">=";
    case AST_REL_OP_NEQ:
        return "<>";
    default:
        fprintf(stderr, "Unknown AST node type: %d\n", type);
        return "??";
    }
}

// Function to print the AST as a generalised Lisp-style List
// Recursively print the components and then the next node
// To be used by NLTK, hence will be printed in preorder fashion
void printAST(ASTNode *root)
{
    if (root == NULL)
    {
        return;
    }

    // Format of list: (<tag> <value> <components> <nextNode>)
    // Tag
    fprintf(yyout, "(");

    // Value
    switch (root->type)
    {
        case AST_VAR_INT:
        case AST_VAR_CHAR:
            fprintf(yyout, "%s %s ", root->data->stringValue, getASTNodeTagFromType(root->type));
            break;
        case AST_VAR_ARRAY_INT:
        case AST_VAR_ARRAY_CHAR:
            fprintf(yyout, "%s ( (%s) (%s %d)) ", root->data->stringValue, getASTNodeTagFromType(root->type), root->data->intValue.value, root->data->intValue.base);
            break;
        case AST_CONSTANT_BINARY:
        case AST_CONSTANT_OCTAL:
        case AST_CONSTANT_DECIMAL:
            fprintf(yyout, "(%s %d) ", root->data->intValue.value, root->data->intValue.base);
            break;
        case AST_CONSTANT_CHAR:
            fprintf(yyout, "'%c' ", root->data->charValue);
            break;
        case AST_CONSTANT_STRING:
            fprintf(yyout, "\"%s\" ", root->data->stringValue);
            break;
        case AST_VAR:
        case AST_SCAN_STMT_VAR:
            fprintf(yyout, "%s ", root->data->stringValue);
            break;
        case AST_ASSIGN_STMT:
            fprintf(yyout, "%s ", getASTNodeTagFromType(root->type));
            break;
        case AST_PRINT_STMT:
        case AST_SCAN_STMT:
            fprintf(yyout, "%s \"%s\"", getASTNodeTagFromType(root->type), root->data->stringValue);
            break;
        case AST_PLUS:
        case AST_MINUS:
        case AST_MULTIPLY:
        case AST_DIVIDE:
        case AST_MODULUS:
        case AST_REL_OP_EQ:
        case AST_REL_OP_LT:
        case AST_REL_OP_LTE:
        case AST_REL_OP_GT:
        case AST_REL_OP_GTE:
        case AST_REL_OP_NEQ:
            fprintf(yyout, "%s ", getASTNodeTagFromType(root->type));
            break;
        default:
            fprintf(yyout, "%s ", getASTNodeTagFromType(root->type));
            break;
    }

    // Components
    if (root->components != NULL)
    {
        ASTNode *temp = root->components;
        while (temp != NULL)
        {
            ASTNode *next = temp->nextNode;

            // Remove nextNode before processing component
            // Avoids printing the subtree multiple times
            temp->nextNode = NULL;
            printAST(temp);
            temp->nextNode = next;
            temp = next;
        }
    }

    // Next
    if (root->nextNode != NULL)
    {
        printAST(root->nextNode);
    }

    fprintf(yyout, ")");
}

/** Implementation of helper functions for each AST Node */
// Create Program Node
ASTNode *buildProgramASTNode()
{
    ASTNode *node = createBasicASTNode_(AST_BEGIN_PROGRAM, NULL);
    return node;
}

// Create Variable Declaration block
ASTNode *buildVarDeclASTNode()
{
    ASTNode *node = createBasicASTNode_(AST_VAR_DECL, NULL);
    return node;
}

// Individual Variable Declaration Node (a int) ->
ASTNode *buildVariableDeclASTNode(char *varName, ASTNodeType type, int arraySize)
{
    ASTNodeData *data = (ASTNodeData *)malloc(sizeof(ASTNodeData));
    if (!data)
    {
        fprintf(stderr, "Memory allocation failed for AST node data\n");
        exit(EXIT_FAILURE);
    }

    data->stringValue = strdup(varName);

    if(arraySize != -1)
    {
        data->intValue.value = "[]";
        data->intValue.base = arraySize;    
    }

    ASTNode *varTypeNode = createBasicASTNode_(type, data);
    return varTypeNode;
}

// Create Variable Node
ASTNode *buildVariableASTNode(char *varName)
{
    ASTNodeData *data = (ASTNodeData *)malloc(sizeof(ASTNodeData));
    if (!data)
    {
        fprintf(stderr, "Memory allocation failed for AST node data\n");
        exit(EXIT_FAILURE);
    }
    data->stringValue = strdup(varName);
    ASTNode *node = createBasicASTNode_(AST_VAR, data);
    return node;
}

// Sentinel node to contain all statements
ASTNode *buildStatementsBlockASTNode()
{
    ASTNode *node = createBasicASTNode_(AST_STMT_BLOCK, NULL);
    return node;
}

// Create Assign statement Node
ASTNode *buildAssignStmtASTNode(ASTNodeType type, char *varName, ASTNode *expr)
{
    ASTNode *node = createBasicASTNode_(type, NULL);
    insertComponentNode_(node, buildVariableASTNode(varName));
    insertComponentNode_(node, expr);
    return node;
}

// Create Print statement Node
ASTNode *buildPrintStmtASTNode(char *string, ASTNode *variablesList)
{
    ASTNodeData *data = (ASTNodeData *)malloc(sizeof(ASTNodeData));
    if (!data)
    {
        fprintf(stderr, "Memory allocation failed for AST node data\n");
        exit(EXIT_FAILURE);
    }
    data->stringValue = strdup(string);
    ASTNode *node = createBasicASTNode_(AST_PRINT_STMT, data);
    if (variablesList != NULL)
    {
        insertComponentNode_(node, variablesList);
    }
    return node;
}

// Create Scan statement Node
ASTNode *buildScanStmtASTNode(char *string, ASTNode *variablesList)
{
    ASTNodeData *data = (ASTNodeData *)malloc(sizeof(ASTNodeData));
    if (!data)
    {
        fprintf(stderr, "Memory allocation failed for AST node data\n");
        exit(EXIT_FAILURE);
    }
    data->stringValue = string;
    ASTNode *node = createBasicASTNode_(AST_SCAN_STMT, data);
    insertComponentNode_(node, variablesList);
    return node;
}

// Create Block of Statements Node
ASTNode *buildBlockASTNode(ASTNode *stmtList)
{
    ASTNode *node = createBasicASTNode_(AST_BLOCK, NULL);
    insertComponentNode_(node, stmtList);
    return node;
}

// Create If statement Node
ASTNode *buildIfElseStmtASTNode(ASTNode *expr, ASTNode *stmtList, ASTNode *elseStmtList)
{
    ASTNode *node = createBasicASTNode_(AST_IF_STMT, NULL);
    insertComponentNode_(node, expr);
    insertComponentNode_(node, stmtList);
    if (elseStmtList != NULL)
    {
        insertComponentNode_(node, elseStmtList);
    }
    return node;
}

// Create While statement Node
ASTNode *buildWhileStmtASTNode(ASTNode *expr, ASTNode *stmtList)
{
    ASTNode *node = createBasicASTNode_(AST_WHILE_STMT, NULL);
    insertComponentNode_(node, expr);
    insertComponentNode_(node, stmtList);
    return node;
}

// Create For statement Node
ASTNode *buildForStmtASTNode(ASTNode *initialExpr, ASTNode *terminateExpr, int isInc, ASTNode *dirExpr, ASTNode *stmtList)
{
    ASTNode *node = createBasicASTNode_(AST_FOR_STMT, NULL);
    ASTNodeData *data = (ASTNodeData *)malloc(sizeof(ASTNodeData));
    if (!data)
    {
        fprintf(stderr, "Memory allocation failed for AST node data\n");
        exit(EXIT_FAILURE);
    }
    data->intValue.value = isInc ? "1" : "0"; // 1 for increment, 0 for decrement
    data->intValue.base = 10;                 // Decimal
    ASTNode *direction = createBasicASTNode_(isInc ? AST_FOR_INC : AST_FOR_DEC, data);

    insertComponentNode_(direction, dirExpr);

    insertComponentNode_(node, initialExpr);
    insertComponentNode_(node, terminateExpr);
    insertComponentNode_(node, direction);
    insertComponentNode_(node, stmtList);
    return node;
}

// Create operator node
// build in preorder form for easy parsing
ASTNode *buildOperatorNode(ASTNodeType type, ASTNode *left, ASTNode *right)
{
    ASTNode *node = createBasicASTNode_(type, NULL);
    insertComponentNode_(node, left);
    insertComponentNode_(node, right);
    return node;
}

// Create constant node
ASTNode *buildConstantNode(ASTNodeType type, void *value)
{
    ASTNodeData *data = (ASTNodeData *)malloc(sizeof(ASTNodeData));
    if (!data)
    {
        fprintf(stderr, "Memory allocation failed for AST node data\n");
        exit(EXIT_FAILURE);
    }

    if (type == AST_CONSTANT_CHAR)
    {
        data->charValue = *((char *)value);
    }
    else if (type == AST_CONSTANT_STRING)
    {
        data->stringValue = strdup((*(char **)value));
    }
    else if (type == AST_CONSTANT_BINARY || type == AST_CONSTANT_OCTAL || type == AST_CONSTANT_DECIMAL)
    {
        data->intValue.value = strdup(*(char **)value);
        data->intValue.base = type == AST_CONSTANT_BINARY ? 2 : (type == AST_CONSTANT_OCTAL ? 8 : 10);
    }
    else
    {
        fprintf(stderr, "Invalid constant type\n");
        free(data);
        return NULL;
    }

    ASTNode *node = createBasicASTNode_(type, data);
    return node;
}