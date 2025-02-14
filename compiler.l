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

typedef struct node{
    char name[256];
    struct node *next;
} node;


node* variables_defined = NULL;

node* create_node(const char *name){
    node *temp = (node*)malloc(sizeof(node));
    strcpy(temp->name, name);
    temp->next = NULL;
    return temp;
}

void insert(node **head, const char *name){
    if(*head == NULL){
        *head = create_node(name);
    }else{
        node *temp = *head;
        while(temp->next != NULL){
            temp = temp->next;
        }
        temp->next = create_node(name);
    }
}

int search(node *head, const char *name){
    node *temp = head;
    while(temp != NULL){
        if(strcmp(temp->name, name) == 0){
            return 1;
        }
        temp = temp->next;
    }
    return 0;
}

int is_keyword(const char *str) {
    const char *keywords[] = {"int", "float", "if", "else", "while", "for", "main", "begin", "end", "input", "output", "program", "VarDecl", "inc", "dec", "print", "scan"};
    for (int i = 0; i < 17; i++) {
        if (strcmp(str, keywords[i]) == 0) return 1;
    }
    return 0;
}

int is_duplicate(const char *str) {
    return search(variables_defined, str);
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
    insert(&variables_defined, str);
}
%}

%s VARDECL_STATE

KEYWORD int|float|if|else|while|for|main|begin|end|input|output|program|VarDecl|inc|dec|print|scan
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
INTEGER \(([0-9]+),[ ]*([0-9]+)\)
CHARACTER '\?.'
STRING \"([^"\\]|\\.)*\"
ARITH_OP [+\-*/%]
ASSIGN_OP :=|\+=|-=|\*=|\/=|%=
REL_OP [=<>]=?|<>
SEPARATOR [(){};,:]
COMMENT \/\*([^*]|\*+[^/])*\*+\/|\/\/.*
WHITESPACE [ \t\n\r]+

%%
"begin"/{WHITESPACE}*"VarDecl"{WHITESPACE}*:      {if(c){BEGIN(VARDECL_STATE); c=0;}; expecting_type = 0; printf("KEYWORD: %s\n", yytext); }
"end"/{WHITESPACE}*"VarDecl"          { BEGIN(0); printf("KEYWORD: %s\n", yytext); }
"VarDecl"   {printf("KEYWORD: %s\n", yytext); }

<VARDECL_STATE>{IDENTIFIER} {
    if(!expecting_type){
        if(is_keyword(yytext)){
            printf("LEXICAL ERROR: Keyword used as identifier: %s\n", yytext);
        }
        else if(is_duplicate(yytext)){
            printf("LEXICAL ERROR: Duplicate variable declaration: %s\n", yytext);
        }
        else{
            if(check(yytext)){
                add_variable(yytext);
                printf("IDENTIFIER (variable name): %s\n", yytext);
            } else{
                printf("LEXICAL ERROR : Invalid Variable Name \n");
            }
        }
        expecting_type = 1;
    }
    else{
        if(is_keyword(yytext)){
            printf("KEYWORD: %s\n", yytext);
        }
        else{
            printf("LEXICAL ERROR: Invalid variable type: %s\n", yytext);
        }
        expecting_type = 0;
    }
}

("print"|"scan")\([ ]*{STRING}[ ]*([ ]*,[ ]*({IDENTIFIER}|{INTEGER}))*\); {
    char* str = yytext;
    int cnt_formatted = 0;
    for(int i = 0; i < strlen(str); i++){
        if(str[i] == '@'){
            cnt_formatted++;
        }
    }

    char *last_quote = strrchr(str, '"');
    int count = 0;
    char *ptr = last_quote + 1;
    while (*ptr) {
        if (strncmp(ptr, "(", 1) == 0) {
            ptr++;
            while (*ptr && *ptr != ')') {
                ptr++;
            }
        } 
        else if(strncmp(ptr, ",", 1) == 0){
            count++;
        }
        ptr++;
        
    }
    if (count != cnt_formatted) {
        printf("LEXICAL ERROR: Mismatch in formatted specifiers and arguments\n");
        break;
    }
    
    if(str[4] == '(') {
        printf("KEYWORD: scan\n");
        yyless(4);
    }
    else{
        printf("KEYWORD: print\n");
        yyless(5);
    }
}

("print"|"scan")\([ ]*{STRING}[ ]*([ ]*,[ ]*({IDENTIFIER}|{INTEGER}))*\) {
    printf("LEXICAL ERROR: Invalid Statement - Missing semicolon at the end \n");
}


{IDENTIFIER}   {
    if(is_keyword(yytext)){
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
{ASSIGN_OP}    { printf("ASSIGNMENT OPERATOR: %s\n", yytext); }
{REL_OP}       { printf("RELATIONAL OPERATOR: %s\n", yytext); }

{SEPARATOR}    { printf("SEPARATOR: %s\n", yytext); }
{COMMENT}      { printf("COMMENT: %s\n",yytext); }
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