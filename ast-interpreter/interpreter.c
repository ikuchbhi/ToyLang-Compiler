#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "interpreter.h"
#include "../symbol-table/symbol_table.h"
#include "../ast-generator/ast.h"

static int semanticErrorCount = 0;

int runSemanticAnalysis(ASTNode *root)
{
    semanticErrorCount = 0;
    ASTNode *stmtsBlock = root->components->nextNode;
    checkStatementBlock(stmtsBlock);
    return semanticErrorCount;
}

static void checkStatementBlock(ASTNode *block)
{
    for (ASTNode *cur = block->components; cur != NULL; cur = cur->nextNode)
    {
        switch (cur->type)
        {
        case AST_ASSIGN_STMT:
        {
            const char *name = cur->components->data->stringValue;
            SymbolTableEntry *e = lookupFromSymbolTable(name);
            if (!e)
            {
                fprintf(stderr, "Semantic error: undeclared variable '%s' in assignment\n", name);
                exit(EXIT_FAILURE);
            }

            SymbolType rhsType;
            checkExpression(cur->components->nextNode, &rhsType);

            if ((e->type == TYPE_INT && rhsType != TYPE_INT) ||
                (e->type == TYPE_CHAR && rhsType != TYPE_CHAR))
            {
                fprintf(stderr, "Semantic error: type mismatch assigning to '%s'\n", name);
                exit(EXIT_FAILURE);
            }

            e->isInitialized = true;
            break;
        }
        case AST_PRINT_STMT:
            for (ASTNode *arg = cur->components; arg; arg = arg->nextNode)
            {
                SymbolType t;
                checkExpression(arg, &t);
            }
            break;

        case AST_SCAN_STMT:
            for (ASTNode *v = cur->components; v; v = v->nextNode)
            {
                const char *name = v->data->stringValue;
                SymbolTableEntry *e = lookupFromSymbolTable(name);
                if (!e)
                {
                    fprintf(stderr, "Semantic error: undeclared variable '%s' in scan\n", name);
                    exit(EXIT_FAILURE);
                }
                e->isInitialized = true;
            }
            break;
        case AST_IF_STMT:
        {
            SymbolType conditionType;
            checkExpression(cur->components, &conditionType);

            if (conditionType != TYPE_INT)
            {
                fprintf(stderr, "Semantic error: non-integer condition in if statement\n");
                exit(EXIT_FAILURE);
            }

            checkStatementBlock(cur->components->nextNode);

            ASTNode *elseBlock = cur->components->nextNode->nextNode;
            if (elseBlock != NULL)
            {
                checkStatementBlock(elseBlock);
            }
            break;
        }
        case AST_WHILE_STMT:
        {
            SymbolType conditionType;
            checkExpression(cur->components, &conditionType);

            if (conditionType != TYPE_INT)
            {
                fprintf(stderr, "Semantic error: non-integer condition in while statement\n");
                exit(EXIT_FAILURE);
            }

            checkStatementBlock(cur->components->nextNode);
            break;
        }
        case AST_FOR_STMT:
        {
            checkStatementBlock(cur);

            SymbolType bT;
            checkExpression(cur->components->nextNode, &bT);

            if (bT != TYPE_INT)
            {
                fprintf(stderr, "Semantic error: non-integer bound in for\n");
                exit(EXIT_FAILURE);
            }

            ASTNode *directionNode = cur->components->nextNode->nextNode;

            SymbolType sT;
            checkExpression(directionNode->components, &sT);

            if (sT != TYPE_INT)
            {
                fprintf(stderr, "Semantic error: non-integer step in for\n");
                exit(EXIT_FAILURE);
            }

            checkStatementBlock(directionNode->nextNode);

            break;
        }
        case AST_BLOCK:
        case AST_STMT_BLOCK:
            checkStatementBlock(cur->components);
            break;
        default:
            break;
        }
    }
}

static void checkExpression(ASTNode *node, SymbolType *outType)
{
    if (!node)
    {
        *outType = TYPE_INT;
        return;
    }
    switch (node->type)
    {
    case AST_CONSTANT_CHAR:
        *outType = TYPE_CHAR;
        break;
    case AST_CONSTANT_STRING:
        *outType = TYPE_CHAR;
        break;
    case AST_CONSTANT_DECIMAL:
    case AST_CONSTANT_OCTAL:
    case AST_CONSTANT_BINARY:
        *outType = TYPE_INT;
        break;
    case AST_VAR:
    {
        const char *name = node->data->stringValue;
        SymbolTableEntry *e = lookupFromSymbolTable(name);

        if (e == NULL)
        {
            fprintf(stderr, "Semantic error: undeclared variable '%s' in expression\n", name);
            exit(EXIT_FAILURE);
        }

        if (!e->isInitialized)
        {
            fprintf(stderr, "Semantic error: use of uninitialized '%s'\n", name);
            exit(EXIT_FAILURE);
        }

        *outType = e->type;
        break;
    }
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
    {
        SymbolType leftType, rightType;
        checkExpression(node->components, &leftType);
        checkExpression(node->components->nextNode, &rightType);

        if (leftType != TYPE_INT || rightType != TYPE_INT)
        {
            fprintf(stderr, "Semantic error: non-integer operands for '%s'\n", getASTNodeTagFromType(node->type));
            exit(EXIT_FAILURE);
        }

        *outType = TYPE_INT;
        break;
    }
    default:
        fprintf(stderr, "Semantic error: unsupported AST node '%s' in expression\n", getASTNodeTagFromType(node->type));
        exit(EXIT_FAILURE);
    }
}

static void executeProgram(ASTNode *node)
{
    ASTNode *decls = node->components;
    ASTNode *stmts = decls->nextNode;
    executeStatementBlock(stmts);
}

static void executeStatementBlock(ASTNode *node)
{
    for (ASTNode *cur = node->components; cur; cur = cur->nextNode)
    {
        switch (cur->type)
        {
            case AST_STMT_PLUS:
            case AST_STMT_MINUS:
            case AST_STMT_MULTIPLY:
            case AST_STMT_DIVIDE:
            case AST_STMT_MODULUS:
            case AST_ASSIGN_STMT:
                executeAssignmentStatement(cur);
                break;
            case AST_PRINT_STMT:
                executePrintStatement(cur);
                break;
            case AST_SCAN_STMT:
                executeScanStatement(cur);
                break;
            case AST_IF_STMT:
                executeIfStatement(cur);
                break;
            case AST_WHILE_STMT:
                executeWhileStatement(cur);
                break;
            case AST_FOR_STMT:
                executeForStatement(cur);
                break;
            default:
                printf("Unsupported statement type: %s\n", getASTNodeTagFromType(cur->type));
                break;
        }
    }
}

static void executeAssignmentStatement(ASTNode *node)
{
    EvalResult lhsEval = evaluateExpression(node->components);
    EvalResult rightEval = evaluateExpression(node->components->nextNode);

    EvalResult resultEval;
    long result;
    
    switch (node->type)
    {
        case AST_STMT_PLUS:
            result = lhsEval.value + rightEval.value;
            break;
        case AST_STMT_MINUS:
            result = lhsEval.value - rightEval.value;
            break;
        case AST_STMT_MULTIPLY:
            result = lhsEval.value * rightEval.value;
            break;
        case AST_STMT_DIVIDE:
            result = (rightEval.value != 0 ? (lhsEval.value / rightEval.value) : 0);
            break;
        case AST_STMT_MODULUS:
            result = (rightEval.value != 0 ? (lhsEval.value % rightEval.value) : 0);
            break;
        case AST_ASSIGN_STMT:
            result = rightEval.value;
            break;
        default:
            result = 0;
            break;
    }

    resultEval.value = result;
    resultEval.base = (lhsEval.base > rightEval.base ? lhsEval.base : rightEval.base);

    node = node->components;
    SymbolTableEntry *e = lookupFromSymbolTable(node->data->stringValue);
    
    if (e == NULL)
    {
        printf("Undeclared variable '%s'\n", node->data->stringValue);
        return;
    }
    
    if (e->type == TYPE_INT)
    {
        e->value.intVal = (int) resultEval.value;
        e->base = resultEval.base;
    }
    else if (e->type == TYPE_CHAR)
    {
        e->value.charVal = (char) resultEval.value;
    }

    e->isInitialized = true;
}

static void executePrintStatement(ASTNode *node)
{
    const char *fmt = node->data->stringValue;
    ASTNode *arg = node->components;

    for (const char *p = fmt; *p; ++p)
    {
        // Handle special characters
        if (*p == '\\')
        {
            ++p;
            if (*p == NULL) 
            {
                break;
            }

            switch (*p)
            {
                case 'n':
                    putchar('\n');
                    break;
                case 't':
                    putchar('\t');
                    break;
                case '\\':
                    putchar('\\');
                    break;
                case '"':
                    putchar('"');
                    break;
                default:
                    putchar('\\');
                    putchar(*p);
            }
        }
        else if (*p != '@')
        {
            putchar(*p);
        }
        else
        {
            if (!arg)
            {
                fprintf(stderr, "Missing argument for '@' in print\n");
                return;
            }
            switch (arg->type)
            {
                case AST_CONSTANT_CHAR:
                    putchar(arg->data->charValue);
                    break;
                case AST_VAR:
                {
                    SymbolTableEntry *e = lookupFromSymbolTable(arg->data->stringValue);
                    if (e->type == TYPE_CHAR)
                        putchar(e->value.charVal);
                    else
                        printf("%d", e->value.intVal);
                    break;
                }
                default:
                {
                    EvalResult r = evaluateExpression(arg);
                    printf("%ld", r.value);
                }
            }
            arg = arg->nextNode;
        }
    }
}

static void executeScanStatement(ASTNode *node)
{
    for (ASTNode *varNode = node->components; varNode; varNode = varNode->nextNode)
    {
        const char *name = varNode->data->stringValue;
        SymbolTableEntry *e = sym_lookup(name);
        
        if (e == NULL)
        {
            fprintf(stderr, "Undeclared variable '%s' in scan\n", name);
            return;
        }

        if (e->type == TYPE_INT)
        {
            long tmp;
            
            if (scanf("%ld", &tmp) != 1)
            {
                fprintf(stderr, "Failed to read integer for '%s'\n", name);
                exit(EXIT_FAILURE);
            }
            
            e->value.intVal = (int) tmp;
            e->base = 10;
        }
        else if (e->type == TYPE_CHAR)
        {
            char tmp;
            if (scanf(" %c", &tmp) != 1)
            {
                fprintf(stderr, "Failed to read character for '%s'\n", name);
                exit(EXIT_FAILURE);
            }
            e->value.charVal = tmp;
        }
        else
        {
            fprintf(stderr, "Invalid scan target '%s'\n", name);
            return;
        }
        e->isInitialized = true;
    }
}

static void executeIfStatement(ASTNode *node)
{
    EvalResult cond = evaluateExpression(node->components);

    ASTNode *thenBlock = node->components->nextNode;
    ASTNode *elseBlock = thenBlock->nextNode;

    if (cond.value != 0)
    {
        executeStatementBlock(thenBlock);
    }
    else if (elseBlock != NULL)
    {
        executeStatementBlock(elseBlock);
    }
}

static void executeWhileStatement(ASTNode *node)
{
    ASTNode *condExpr = node->components;
    ASTNode *bodyBlock = condExpr->nextNode;

    while (true)
    {
        EvalResult cond = evaluateExpression(condExpr);
        if (cond.value == 0)
        {
            break;
        }
        executeStatementBlock(bodyBlock);
    }
}

static void executeForStatement(ASTNode *node)
{
    ASTNode *assignInit = node->components;
    ASTNode *termExpr = assignInit->nextNode;
    ASTNode *dirNode = termExpr->nextNode;
    ASTNode *bodyBlock = dirNode->nextNode;

    executeAssignmentStatement(assignInit);

    EvalResult bound = evaluateExpression(termExpr);
    EvalResult stepRes = evaluateExpression(dirNode->components);

    const char *varName = assignInit->components->data->stringValue;
    SymbolTableEntry *e = lookupFromSymbolTable(varName);
    
    if (e == NULL)
    {
        printf("Undeclared loop variable '%s'\n", varName);
        return;
    }

    bool isInc = (dirNode->type == AST_FOR_INC);

    while (true)
    {
        bound = evaluateExpression(termExpr);
        long cur = e->value.intVal;

        if (isInc && cur > bound.value)
        {
            break;
        }

        if (!isInc && cur < bound.value)
        {
            break;
        }

        executeStatementBlock(bodyBlock);

        long updated = isInc ? (cur + stepRes.value) : (cur - stepRes.value);
        int newBase = (e->base > stepRes.base ? e->base : stepRes.base);

        e->value.intVal = (int)updated;
        e->base = newBase;
    }
}

EvalResult evaluateExpression(ASTNode *node)
{
    if (node == NULL) return (EvalResult){0, 10};

    switch (node->type)
    {
        case AST_CONSTANT_CHAR:
            return (EvalResult){node->data->charValue, 10};

        case AST_CONSTANT_DECIMAL:
        case AST_CONSTANT_OCTAL:
        case AST_CONSTANT_BINARY:
        {
            long v = strtol(node->data->intValue.value, NULL, node->data->intValue.base);
            return (EvalResult){v, node->data->intValue.base};
        }

        case AST_VAR:
        {
            SymbolTableEntry *e = sym_lookup(node->data->stringValue);
            if (e != NULL)
            {
                fprintf(stderr, "Undeclared variable '%s'\n", node->data->stringValue);
                exit(EXIT_FAILURE);
            }
            if (!e->isInitialized)
            {
                fprintf(stderr, "Use of uninitialized '%s'\n", node->data->stringValue);
                exit(EXIT_FAILURE);
            }
            return (EvalResult){e->value.intVal, e->base};
        }

        case AST_REL_OP_EQ:
        case AST_REL_OP_LT:
        case AST_REL_OP_LTE:
        case AST_REL_OP_GT:
        case AST_REL_OP_GTE:
        case AST_REL_OP_NEQ:
        {
            EvalResult lhsEval = evaluateExpression(node->components);
            EvalResult rightEval = evaluateExpression(node->components->nextNode);
            
            long result;
            switch (node->type)
            {
                case AST_REL_OP_EQ:
                    result = (lhsEval.value == rightEval.value);
                    break;
                case AST_REL_OP_LT:
                    result = (lhsEval.value < rightEval.value);
                    break;
                case AST_REL_OP_LTE:
                    result = (lhsEval.value <= rightEval.value);
                    break;
                case AST_REL_OP_GT:
                    result = (lhsEval.value > rightEval.value);
                    break;
                case AST_REL_OP_GTE:
                    result = (lhsEval.value >= rightEval.value);
                    break;
                case AST_REL_OP_NEQ:
                    result = (lhsEval.value != rightEval.value);
                    break;
                default:
                    result = 0;
                   break;
            }
        int resultBase = (lhsEval.base > rightEval.base ? lhsEval.base : rightEval.base);
        return (EvalResult){result, resultBase};
    }

        case AST_PLUS:
        case AST_MINUS:
        case AST_MULTIPLY:
        case AST_DIVIDE:
        case AST_MODULUS:
        {
            EvalResult lhsEval = evaluateExpression(node->components);
            EvalResult rhsEval = evaluateExpression(node->components->nextNode);

            long result;
            switch (node->type)
            {
                case AST_PLUS:
                    result = lhsEval.value + rhsEval.value;
                    break;
                case AST_MINUS:
                    result = lhsEval.value - rhsEval.value;
                    break;
                case AST_MULTIPLY:
                    result = lhsEval.value * rhsEval.value;
                    break;
                case AST_DIVIDE:
                    result = (rhsEval.value != 0 ? lhsEval.value / rhsEval.value : 0);
                    break;
                case AST_MODULUS:
                    result = (rhsEval.value != 0 ? lhsEval.value % rhsEval.value : 0);
                    break;
                default:
                    result = 0;
                    break;
            }

            int resultBase = (lhsEval.base > rhsEval.base ? lhsEval.base : rhsEval.base);
            return (EvalResult){result, resultBase};
        }

        default:
            fprintf(stderr, "Unsupported AST node in eval_expr: %s\n", getASTNodeTagFromType(node->type));
            exit(EXIT_FAILURE);
    }
}