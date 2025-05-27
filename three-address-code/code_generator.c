#include <stdlib.h>
#include <string.h>

#include "../ast-generator/ast.h"
#include "code_generator.h"

static int tempCount = 0;
static int labelCount = 0;

// Create a new temporary variable name
static char *createNewTempVariable()
{
    char buf[32];
    snprintf(buf, sizeof(buf), "t%d", ++tempCount);
    return strdup(buf);
}

// Create a new label name
static char *createNewLabel()
{
    char buf[32];
    snprintf(buf, sizeof(buf), "L%d", ++labelCount);
    return strdup(buf);
}

// Walk the AST and emit Three-Address Code
void generateTAC(ASTNode *root, FILE *out)
{
    if (!root)
        return;

    if (root->type == AST_BEGIN_PROGRAM)
        generateForStatements(root->components, out);
    else
        generateForStatement(root, out);
}

// Generate TAC for a list of statements
static void generateForStatements(ASTNode *node, FILE *out)
{
    for (ASTNode *cur = node; cur; cur = cur->nextNode)
        generateForStatement(cur, out);
}

// Generate TAC for a single statement node
static void generateForStatement(ASTNode *node, FILE *out)
{
    switch (node->type)
    {
        case AST_ASSIGN_STMT:
        {
            ASTNode *varNode = node->components;
            ASTNode *exprNode = varNode->nextNode;
            char *tmp = generateForExpression(exprNode, out);
            fprintf(out, "%s = %s\n", varNode->data->stringValue, tmp);
            free(tmp);
            break;
        }

        case AST_PRINT_STMT:
        {

            break;
        }

        case AST_SCAN_STMT:
        {

            break;
        }

        case AST_IF_STMT:
        {
            ASTNode *expr = node->components;
            ASTNode *thenBlk = expr->nextNode;
            ASTNode *elseBlk = thenBlk->nextNode;

            char *cond = generateForExpression(expr, out);
            char *falseL = createNewLabel();

            // branch when condition is False
            fprintf(out, "if %s == 0 goto %s\n", cond, falseL);
            free(cond);

            // iterate only until else block
            for (ASTNode *cur = thenBlk; cur != elseBlk; cur = cur->nextNode)
            {
                generateForStatement(cur, out);
            }

            if (elseBlk)
            {
                char *endL = createNewLabel();

                fprintf(out, "goto %s\n", endL);
                fprintf(out, "%s:\n", falseL);

                generateForStatements(elseBlk, out);

                fprintf(out, "%s:\n", endL);
                free(endL);
            }
            else
            {
                fprintf(out, "%s:\n", falseL);
            }

            free(falseL);
            break;
        }

        case AST_WHILE_STMT:
        {
            ASTNode *expr = node->components;
            ASTNode *body = expr->nextNode;

            char *beginL = createNewLabel();
            char *exitL = createNewLabel();

            fprintf(out, "%s:\n", beginL);
            char *condTemp = generateForExpression(expr, out);

            // exit when condition becomes False
            fprintf(out, "if %s == 0 goto %s\n", condTemp, exitL);
            free(condTemp);

            generateForStatements(body, out);

            fprintf(out, "goto %s\n", beginL);
            fprintf(out, "%s:\n", exitL);

            free(beginL);
            free(exitL);

            break;
        }

        case AST_FOR_STMT:
        {
            ASTNode *init = node->components;
            ASTNode *term = init->nextNode;
            ASTNode *dir = term->nextNode;
            ASTNode *body = dir->nextNode;

            // initialize loop var
            ASTNode *varNode = init->components;
            ASTNode *exprNode = varNode->nextNode;

            char *val = generateForExpression(exprNode, out);

            fprintf(out, "%s = %s\n", varNode->data->stringValue, val);
            free(val);

            char *testL = createNewLabel();
            char *exitL = createNewLabel();

            // Compute bound
            fprintf(out, "%s:\n", testL);
            char *boundTemp = generateForExpression(term, out);

            // Format: tX = var > bound; if tX == 1 goto exit
            char *testTemp = createNewTempVariable();
            int isInc = dir->type == AST_FOR_INC;

            const char *op = isInc ? ">" : "<";

            fprintf(out, "%s = %s %s %s\n", testTemp, varNode->data->stringValue, op, boundTemp);
            fprintf(out, "if %s == 1 goto %s\n", testTemp, exitL);

            free(testTemp);

            generateForStatements(body, out);

            // increment
            char *incTemp = generateForExpression(dir->components, out);
            char *tmp = createNewTempVariable();

            fprintf(out, "%s = %s + %s\n", tmp, varNode->data->stringValue, incTemp);
            fprintf(out, "%s = %s\n", varNode->data->stringValue, tmp);

            free(tmp);
            free(incTemp);

            fprintf(out, "goto %s\n", testL);
            fprintf(out, "%s:\n", exitL);

            free(testL);
            free(exitL);

            break;
        }

        case AST_BLOCK:
        case AST_STMT_BLOCK:
            generateForStatements(node->components, out);
            break;
        case AST_VAR_DECL:
            break;
        default:

            fprintf(stderr, "[CODE_GENERATOR]: unhandled statement type %s\n", getASTNodeTagFromType(node->type));
            break;
    }
}

// Generate TAC for expressions; returns operand holding result
static char *generateForExpression(ASTNode *node, FILE *out)
{
    if (!node)
        return NULL;

    switch (node->type)
    {
        case AST_CONSTANT_DECIMAL:
        case AST_CONSTANT_OCTAL:
        case AST_CONSTANT_BINARY:
        {
            char buf[32];
            Integer num = node->data->intValue;
            sprintf(buf, "(%s,%d)", num.value, num.base);
            return strdup(buf);
        }
        case AST_CONSTANT_CHAR:
        {
            char buf[4] = {'\'', node->data->charValue, '\'', '\0'};
            return strdup(buf);
        }
        case AST_CONSTANT_STRING:
            return strdup(node->data->stringValue);

        case AST_VAR:
            return strdup(node->data->stringValue);

        // Binary & relational operators
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
            ASTNode *leftSide = node->components;
            ASTNode *rightSide = leftSide->nextNode;
            char *leftSideTAC = generateForExpression(leftSide, out);
            char *rightSideTAC = generateForExpression(rightSide, out);
            
            char *res = createNewTempVariable();
            
            const char *op = getASTNodeTagFromType(node->type);

            fprintf(out, "%s = %s %s %s\n", res, leftSideTAC, op, rightSideTAC);
            
            free(leftSideTAC);
            free(rightSideTAC);
            
            return res;
        }

        default: 
            fprintf(stderr, "[CODE_GENERATOR]: unhandled expression type (%d)\n", node->type);
            exit(EXIT_FAILURE);
    }
}