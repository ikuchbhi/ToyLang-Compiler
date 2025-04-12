%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern FILE* yyin;
extern char* yytext;
void yyerror(const char* s);
%}

%token IDENTIFIER STRING DTYPE
%token DECIMAL BINARY OCTAL CHARACTER
%token BEGIN_TOKEN END PROGRAM VARDECL
%token PRINT SCAN
%token IF ELSE WHILE FOR MAIN TO DO INC DEC
%token ASSIGN_OP REL_OP ARRAY_SIZE EQ
%token ERR

%left '+' '-'
%left '*' '/' '%'

%%

Program: 
    BEGIN_TOKEN PROGRAM ':' VarDeclBlock Statements END PROGRAM
    { printf("Valid program\n"); }
    ;

VarDeclBlock: 
    BEGIN_TOKEN VARDECL ':' Declarations END VARDECL
    ;

Declarations: 
    Declaration ';' Declarations 
    | /* empty */
    ;

Declaration: 
    '(' IDENTIFIER ',' DTYPE ')'
    | '(' IDENTIFIER ARRAY_SIZE ',' DTYPE ')'
    ;

Statements: 
    Statement Statements 
    | /* empty */
    ;

Statement: 
    PrintStmt 
    | ScanStmt 
    | AssignStmt 
    | BlockStmt 
    | IfStmt 
    | WhileStmt 
    | ForStmt
    ;

PrintStmt: 
    ConstantPrintStmt 
    | FormattedPrintStmt
    ;

ConstantPrintStmt: 
    PRINT '(' STRING ')' ';'
    ;

FormattedPrintStmt: 
    PRINT '(' STRING ',' ExprList ')' ';'
    ;

ScanStmt: 
    SCAN '(' STRING ',' VarList ')' ';'
    ;

ExprList: 
    Expression ',' ExprList 
    | Expression
    ;

VarList: 
    IDENTIFIER ',' VarList 
    | IDENTIFIER
    ;

AssignStmt: 
    IDENTIFIER ASSIGN_OP Expression ';'
    | IDENTIFIER EQ Expression ';'
    ;

BlockStmt: 
    BEGIN_TOKEN BlockStatements END ';'
    ;

BlockStatements: 
    Statement BlockStatements 
    | Statement
    ;

SimpleBlockStmt: 
    BEGIN_TOKEN SimpleBlockStatements END 
    ;

SimpleBlockStatements: 
    SimpleStatement SimpleBlockStatements 
    | SimpleStatement
    ;

SimpleStatement: 
    PrintStmt 
    | ScanStmt 
    | AssignStmt
    ;

IfStmt: 
    IF '(' Condition ')' SimpleBlockStmt ';'
    | IF '(' Condition ')' SimpleBlockStmt ELSE SimpleBlockStmt ';'
    ;

Condition: 
    Expression REL_OP Expression 
    | Expression
    ;

WhileStmt: 
    WHILE '(' Condition ')' SimpleBlockStmt ';'
    ;

ForStmt: 
    FOR IDENTIFIER EQ Expression TO Expression INC Expression DO SimpleBlockStmt ';'
    | FOR IDENTIFIER EQ Expression TO Expression DEC Expression DO SimpleBlockStmt ';'
    ;

Expression: 
    Term 
    | Expression '+' Term
    | Expression '-' Term
    ;

Term: 
    Factor 
    | Term '*' Factor
    | Term '/' Factor
    | Term '%' Factor
    ;

Factor: 
    '(' Expression ')'
    | Constant
    | IDENTIFIER
    | IDENTIFIER '[' Expression ']'
    ;

Constant: 
    DECIMAL
    | BINARY
    | OCTAL
    | CHARACTER
    | STRING
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Error: %s at '%s'\n", s, yytext);
}

int main(int argc, char** argv) {
    if (argc > 1) {
        FILE* file = fopen(argv[1], "r");
        if (!file) {
            fprintf(stderr, "Cannot open file %s\n", argv[1]);
            return 1;
        }
        yyin = file;
    }
    
    int result = yyparse();
    
    if (result == 0) {
        printf("Parsing completed successfully\n");
    } else {
        printf("Parsing failed\n");
    }
    
    return result;
}
