%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

int flag = 0; 
int expecting_type = 0;
int c=1;

typedef struct {
    char name[50];
    int defined;
} Variable;

Variable vars[100];
int var_count = 0;

int is_keyword(const char *str) {
    const char *keywords[] = {"int", "float", "if", "else", "while", "for", "main", "begin", "end", "input", "output", "program", "VarDecl", "inc", "dec", "print", "scan"};
    for (int i = 0; i < 17; i++) {
        if (strcmp(str, keywords[i]) == 0) return 1;
    }
    return 0;
}

int is_duplicate(const char *str) {
    for (int i = 0; i < var_count; i++) {
        if (strcmp(vars[i].name, str) == 0) return 1;
    }
    return 0;
}

int check(const char *str) {
    int len = strlen(str);
    if (len == 0) return 0; 
    if (!islower(str[0])) return 0; 

    int un = 0;
    
    for (int i = 0; i < len; i++) {
        if (islower(str[i]) || isdigit(str[i])) {
            continue; 
        }
        if (str[i] == '_') {
            un++;
            if (un > 1) return 0; 
        } else {
            return 0; 
        }
    }
    return 1; 
}

void add_variable(const char *str) {
    if (var_count < 100) {
        strcpy(vars[var_count].name, str);
        vars[var_count].defined = 1;
        var_count++;
    }
}
%}

KEYWORD int|float|if|else|while|for|main|begin|end|input|output|program|VarDecl|inc|dec|print|scan
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
INTEGER \(([0-9]+),[ ]*([0-9]+)\)
CHARACTER '\?.'
STRING \"([^"\\]|\\.)*\"
ARITH_OP [+\-*/%]
ASSIGN_OP :=|\+=|-=|\*=|/=|%=
REL_OP [=<>]=?|<>
SEPARATOR [(){};,:]
COMMENT \/\*([^*]|\*+[^/])*\*+\/|\/\/.*
WHITESPACE [ \t\n\r]+

%%
"VarDecl"      {if(c){flag = 1;c=0;}; expecting_type = 0; printf("KEYWORD: %s\n", yytext); }
"end"          { flag = 0; printf("KEYWORD: %s\n", yytext); }

{IDENTIFIER}   {
    if (flag && !expecting_type) { 
        if (is_keyword(yytext)) {
            printf("LEXICAL ERROR: Keyword used as identifier: %s\n", yytext);
        } else if (flag && is_duplicate(yytext)) {
            printf("LEXICAL ERROR: Duplicate variable declaration: %s\n", yytext);
        } else{
            if(check(yytext)){
                add_variable(yytext);
                printf("IDENTIFIER (variable name): %s\n", yytext);
            } else{
                printf("LEXICAL ERROR : Invalid Variable Name \n");
            }
        }
        expecting_type = 1; 
    } else if (flag && expecting_type) { 
        if (!is_keyword(yytext)) {
            printf("LEXICAL ERROR: Invalid variable type: %s\n", yytext);
        } else {
            printf("IDENTIFIER (variable type): %s\n", yytext);
        }
        expecting_type = 0; 
    } else if(!flag && is_keyword(yytext)){
        printf("KEYWORD: %s\n", yytext);
    }else if(is_duplicate(yytext)) {
        printf("IDENTIFIER: %s\n", yytext);
    }
    else{
        printf("LEXICAL ERROR : No variable matching\n");
    }
}

{INTEGER} { 
    int num, base;
    if (sscanf(yytext, "(%d, %d)", &num, &base) == 2) {
        int valid = 1;
        int temp = num;
        while (temp > 0) {
            int digit = temp % 10;
            if (digit >= base) {
                valid = 0;
                break;
            }
            temp /= 10;
        }
        if (valid) {
            printf("INTEGER (Base %d): %s\n", base, yytext);
        } else {
            printf("LEXICAL ERROR: Invalid digit in base %d: %s\n", base, yytext);
        }
    } else {
        printf("LEXICAL ERROR: Invalid integer format (missing base): %s\n", yytext);
    }
}
{CHARACTER}    { printf("CHARACTER: %s\n", yytext); }
{STRING}       { printf("STRING: %s\n", yytext); }

{ARITH_OP}     { printf("ARITHMETIC OPERATOR: %s\n", yytext); }
":="           { printf("ASSIGNMENT OPERATOR: %s\n", yytext); }
"+="           { printf("ASSIGNMENT OPERATOR: %s\n", yytext); }
"-="           { printf("ASSIGNMENT OPERATOR: %s\n", yytext); }
"*="           { printf("ASSIGNMENT OPERATOR: %s\n", yytext); }
"/="           { printf("ASSIGNMENT OPERATOR: %s\n", yytext); }
"%="           { printf("ASSIGNMENT OPERATOR: %s\n", yytext); }
{REL_OP}       { printf("RELATIONAL OPERATOR: %s\n", yytext); }

{SEPARATOR}    { printf("SEPARATOR: %s\n", yytext); }
{COMMENT}      { printf("COMMENT\n"); }
{WHITESPACE}   { /* Ignore whitespace */ }

.              { printf("LEXICAL ERROR: %s\n", yytext); }

%%

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        return 1;
    }
    FILE *file = fopen(argv[1], "r");
    if (!file) {
        perror("Error opening file");
        return 1;
    }
    yyin = file;
    yylex();
    fclose(file);
    return 0;
}

int yywrap() { return 1; }