// codegen.h
#ifndef CODE_GENERATOR_H
#define CODE_GENERATOR_H

#include <stdio.h>
#include "../ast-generator/ast.h"

// Entry point for TAC generation
void generateTAC(ASTNode *root, FILE *out);

// Create new temporary variable (t_<num>)
static char *createNewTempVariable();

// Create a new label name
static char *createNewLabel();

// Generate Three Address Code for an expression
static char *generateForExpression(ASTNode *node, FILE *out);

// Generate Three Address Code for a statement
static void generateForStatement(ASTNode *node, FILE *out);

// Generate Three Address Code for a list of statements
static void generateForStatements(ASTNode *node, FILE *out);

#endif