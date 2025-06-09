%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ast-generator/ast.h"

extern int yylex();
extern FILE *yyin, *yyout;
extern char* yytext;
void yyerror(const char* s);

void printLine() {
    fprintf(yyout, "-------------------------------------------------------------------------------\n");
}

%}

%code requires {
    #include "ast-generator/ast.h"
}

%union {
    ASTNodeType astType;
    ASTNode *astNode;
    char charVal;
    char* str;
    Integer intVal;
    int decimalVal;
}

%token <str> IDENTIFIER STRING DTYPE
%token <intVal> DECIMAL BINARY OCTAL 
%token <charVal> CHARACTER
%token BEGIN_TOKEN END PROGRAM VARDECL
%token PRINT SCAN
%token IF ELSE WHILE FOR TO DO 
%token <str> INC DEC
%token <str> ASSIGN_OP REL_OP EQ 
%token <decimalVal> ARRAY_SIZE
%token MAIN ERR 

%type <astNode>             Program VarDeclBlock StatementsBlock
%type <astNode>             Declarations Declaration
%type <astNode>             Statements Statement 
%type <astNode>             PrintStmt ScanStmt AssignStmt BlockStmt IfStmt WhileStmt ForStmt
%type <astNode>             ConstantPrintStmt FormattedPrintStmt
%type <astNode>             ExprList Expression 
%type <astNode>             Variable
%type <astNode>             BlockStatements 
%type <astNode>             SimpleBlockStatements SimpleBlockStmt SimpleStatement
%type <astNode>             Condition
%type <astNode>             Constant
%left '+' '-'
%left '*' '/' '%'

%%

Program:
    BEGIN_TOKEN PROGRAM ':' VarDeclBlock StatementsBlock END PROGRAM
    { 
        printLine(); 
        fprintf(yyout, "No errors found, valid program\n");
        $$ = buildProgramASTNode();
        insertComponentNode_($$, $4);
        insertComponentNode_($$, $5);

        fprintf(yyout, "Printing AST as generalised Lisp-style list:\n");
        printAST($$);
        fprintf(yyout, "\n");
        
        freeAST($$);
    }
    ;

VarDeclBlock: 
    BEGIN_TOKEN VARDECL ':' Declarations END VARDECL 
    {
        $$ = buildVarDeclASTNode();
        insertComponentNode_($$, $4);
    }
    ;

Declarations: 
    Declaration ';' Declarations 
    {  
        $$ = $1;
        if($3 != NULL)
        {
            insertNextNode_($$, $3);
        }
    }
    | /* empty */ 
    {
        $$ = NULL;
    }
    ;

Declaration: 
    '(' IDENTIFIER ',' DTYPE ')'
    {
        ASTNodeType type = strcmp($4, "int") == 0 ? AST_VAR_INT : AST_VAR_CHAR;
        $$ = buildVariableDeclASTNode($2, type, -1);
    }
    | '(' IDENTIFIER ARRAY_SIZE ',' DTYPE ')'
    {
        ASTNodeType type = strcmp($5, "int") == 0 ? AST_VAR_ARRAY_INT : AST_VAR_ARRAY_CHAR;
        $$ = buildVariableDeclASTNode($2, type, $3);
    }
    ;

StatementsBlock: 
    Statements 
    { 
        $$ = buildStatementsBlockASTNode(); 
        insertComponentNode_($$, $1); 
    }
    ;

Statements: 
    Statement Statements 
    {
        $$ = $1;
        if($2 != NULL)
        {
            insertNextNode_($$, $2);
        }
    }
    | /* empty */
    {
        $$ = NULL;
    }
    ;

Statement: 
    PrintStmt                  { $$ = $1; } 
    | ScanStmt                 { $$ = $1; }
    | AssignStmt               { $$ = $1; }
    | BlockStmt                { $$ = $1; }
    | IfStmt                   { $$ = $1; }
    | WhileStmt                { $$ = $1; }
    | ForStmt                  { $$ = $1; }
    ;

PrintStmt: 
    ConstantPrintStmt               { $$ = $1;}
    | FormattedPrintStmt            { $$ = $1;}
    ;

ConstantPrintStmt: 
    PRINT '(' STRING ')' ';'        
    {
        $$ = buildPrintStmtASTNode($3, NULL);
    }
    ;

FormattedPrintStmt: 
    PRINT '(' STRING ',' ExprList ')' ';'
    {
        $$ = buildPrintStmtASTNode($3, $5);
    }
    ;

ScanStmt: 
    SCAN '(' STRING ',' Variable ')' ';'
    {
        $$ = buildScanStmtASTNode($3, $5);
    }
    ;

ExprList: 
    Expression ',' ExprList 
    {
        $$ = $1;
        if($3 != NULL)
        {
            insertNextNode_($$, $3);
        }
    }
    | Expression 
    { 
        $$ = $1; 
    }
    ;

Variable: 
    IDENTIFIER ',' Variable 
    {
        $$ = buildVariableASTNode($1);
        if($3 != NULL)
        {
            insertNextNode_($$, $3);
        }
    }
    | IDENTIFIER
    {
        $$ = buildVariableASTNode($1);
    }
    ;

AssignStmt: 
    IDENTIFIER ASSIGN_OP Expression ';'
    {
        ASTNodeType type;
        if(strcmp($2, "+=") == 0)
        {
            type = AST_STMT_PLUS;
        }
        else if(strcmp($2, "-=") == 0)
        {
            type = AST_STMT_MINUS;
        }
        else if(strcmp($2, "*=") == 0)
        {
            type = AST_STMT_MULTIPLY;
        }
        else if(strcmp($2, "/=") == 0)
        {
            type = AST_STMT_DIVIDE;
        }
        else if(strcmp($2, "%=") == 0)
        {
            type = AST_STMT_MODULUS;
        }
        else
        {
            fprintf(stderr, "Invalid operator for assignment statement\n");
            $$ = NULL;
        }
       $$ = buildAssignStmtASTNode(type, $1, $3);
    }
    | IDENTIFIER EQ Expression ';'
    {
        $$ = buildAssignStmtASTNode(AST_ASSIGN_STMT, $1, $3);
    }
    ;

BlockStmt: 
    BEGIN_TOKEN BlockStatements END ';'
    {
        $$ = buildBlockASTNode($2);
    }
    ;

BlockStatements: 
    Statement BlockStatements
    {
        $$ = $1;
        if($2 != NULL)
        {
            insertNextNode_($$, $2);
        }
    } 
    | Statement
    {
        $$ = $1;
    }
    ;

SimpleBlockStmt: 
    BEGIN_TOKEN SimpleBlockStatements END 
    {
        $$ = buildBlockASTNode($2);
    }
    ;

SimpleBlockStatements: 
    SimpleStatement SimpleBlockStatements 
    {
        $$ = $1;
        if($2 != NULL)
        {
            insertNextNode_($$, $2);
        }
    }
    | SimpleStatement
    {
        $$ = $1;
    }
    ;

SimpleStatement: 
    PrintStmt         
    { 
        $$ = $1; 
    }
    | ScanStmt        
    { 
        $$ = $1; 
    }
    | AssignStmt
    { 
        $$ = $1; 
    }      
    ;

IfStmt: 
    IF '(' Condition ')' SimpleBlockStmt ';'
    {
        $$ = buildIfElseStmtASTNode($3, $5, NULL);
    }
    | IF '(' Condition ')' SimpleBlockStmt ELSE SimpleBlockStmt ';'
    {
        $$ = buildIfElseStmtASTNode($3, $5, $7);
    }
    ;

Condition: 
    Expression REL_OP Expression
    {
        ASTNodeType type;
        if(strcmp($2, "<") == 0)
        {
            type = AST_REL_OP_LT;
        }
        else if(strcmp($2, ">") == 0)
        {
            type = AST_REL_OP_GT;
        }
        else if(strcmp($2, "<=") == 0)
        {
            type = AST_REL_OP_LTE;
        }
        else if(strcmp($2, ">=") == 0)
        {
            type = AST_REL_OP_GTE;
        }
        else if(strcmp($2, "=") == 0)
        {
            type = AST_REL_OP_EQ;
        }
        else if(strcmp($2, "<>") == 0)
        {
            type = AST_REL_OP_NEQ;
        }
        else
        {
            fprintf(stderr, "Invalid relational operator\n");
            $$ = NULL;
        }
        $$ = buildOperatorNode(type, $1, $3);
    }
    | Expression
    {
        $$ = $1;
    }
    ;

WhileStmt: 
    WHILE '(' Condition ')' DO SimpleBlockStmt ';'
    {
        $$ = buildWhileStmtASTNode($3, $6);
    }
    ;

ForStmt: 
    FOR IDENTIFIER EQ Expression TO Expression INC Expression DO SimpleBlockStmt ';'
    {
        ASTNode *initial = buildAssignStmtASTNode(AST_ASSIGN_STMT, $2, $4);
        int isInc = strcmp($7, "inc") == 0 ? 1 : 0;
        $$ = buildForStmtASTNode(initial, $6, isInc, $8, $10);
    }
    | FOR IDENTIFIER EQ Expression TO Expression DEC Expression DO SimpleBlockStmt ';'
    {
        ASTNode *initial = buildAssignStmtASTNode(AST_ASSIGN_STMT, $2, $4);
        int isDec = strcmp($7, "dec") == 0 ? 1 : 0;
        $$ = buildForStmtASTNode(initial, $6, isDec, $8, $10);
    }
    ;

Expression: 
      '(' Expression ')'
    {
        $$ = $2;
    }
    | Expression '+' Expression {
        $$ = buildOperatorNode(AST_PLUS, $1, $3);
    }
    | Expression '-' Expression
    {
        $$ = buildOperatorNode(AST_MINUS, $1, $3);
    }
    | Expression '*' Expression
    {
        $$ = buildOperatorNode(AST_MULTIPLY, $1, $3);
    }

    | Expression '/' Expression{
        $$ = buildOperatorNode(AST_DIVIDE, $1, $3);
    }
    | Expression '%' Expression
    {
        $$ = buildOperatorNode(AST_MODULUS, $1, $3);
    }
    | Constant
    {
        $$ = $1;
    }
    | IDENTIFIER
    {
        $$ = buildVariableASTNode($1);
    }
    ;

Constant: 
    DECIMAL
    {
        $$ = buildConstantNode(AST_CONSTANT_DECIMAL, &($1));
        
    }
    | BINARY
    {
        $$ = buildConstantNode(AST_CONSTANT_BINARY, &($1));
    }
    | OCTAL
    {
        $$ = buildConstantNode(AST_CONSTANT_OCTAL, &($1));
    }
    | CHARACTER
    {
        $$ = buildConstantNode(AST_CONSTANT_CHAR, &($1));
    }
    | STRING
    {
        $$ = buildConstantNode(AST_CONSTANT_STRING, &($1));
    }
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Error: %s at '%s'\n", s, yytext);
}

int main(int argc, char** argv) {
    if(argc < 3) {
        fprintf(stderr, "Usage: %s <input_file> <output_file>\n", argv[0]);
        return 1;
    }

    if (argc > 1) {
        FILE* inputFile = fopen(argv[1], "r");
        FILE *outputFile = fopen(argv[2], "w");
        
        if (!inputFile) {
            fprintf(stderr, "Cannot open file %s\n", argv[1]);
            return 1;
        }

        // Ensure input file has extension 'toy'
        if(strcmp(strrchr(argv[1], '\0') - 4, ".toy") != 0)
        {
            fprintf(stderr, "Invalid input file: input file must have extension .toy");
            return 1;
        }

        yyin = inputFile;
        yyout = outputFile;
    }

    fprintf(yyout, "Starting lexical analysis...\n");
    printLine();
    fprintf(yyout, "%-50s Lexeme\n", "Token");
    printLine();

    int result = yyparse();
    
    if (result == 0) {
        fprintf(yyout, "Parsing completed successfully\n");
    } else {
        fprintf(yyout, "Parsing failed\n");
    }
    
    return result;
}
