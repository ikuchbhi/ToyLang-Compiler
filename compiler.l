%{
#include "bison.tab.h"
#include <ctype.h>
#include <stdio.h>

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

int yywrap(void) {
    return 1;
}

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
    const char *keywords[] = {"int","char", "if", "else", "while", "for", "main", "begin", "end", "print", "scan", "program", "VarDecl", "inc", "dec","to","do"};
    for (int i = 0; i < 17; i++) {
        if (strcmp(str, keywords[i]) == 0) return 1;
    }
    return 0;
}


int token_to_return(const char *text) {
    if(strcmp(text, "int") == 0)       return DTYPE;
    if(strcmp(text, "char") == 0)      return DTYPE;
    if(strcmp(text, "if") == 0)        return IF;
    if(strcmp(text, "else") == 0)      return ELSE;
    if(strcmp(text, "while") == 0)     return WHILE;
    if(strcmp(text, "for") == 0)       return FOR;
    if(strcmp(text, "main") == 0)      return MAIN;
    if(strcmp(text, "begin") == 0)     return BEGIN_TOKEN;
    if(strcmp(text, "end") == 0)       return END; 
    if(strcmp(text, "print") == 0)     return PRINT;
    if(strcmp(text, "scan") == 0)      return SCAN;
    if(strcmp(text, "program") == 0)   return PROGRAM;
    if(strcmp(text, "VarDecl") == 0)   return VARDECL;
    if(strcmp(text, "inc") == 0)       return INC;
    if(strcmp(text, "dec") == 0)       return DEC;
    if(strcmp(text, "to") == 0)        return TO;
    if(strcmp(text, "do") == 0)        return DO;
    return 0;  
}

int is_duplicate(const char *str) {
    return search(variables_defined, str);
}

int check(const char *str) {
    int len = strlen(str);
    if (len == 0) return 0; 
    if (!isalpha(str[0])) return 0; 

    int un = 0;
    
    for (int i = 0; i < len; i++) {
        if (isalpha(str[i]) || isdigit(str[i])) {
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

KEYWORD int|char|float|if|else|while|for|main|begin|end|input|output|program|VarDecl|inc|dec|print|scan|then
IDENTIFIER [a-zA-Z0-9_]+
INTEGER \(([0-9]+),[ ]*([0-9]+)\)
CHARACTER '[^\\']'|'\n'|'\t'|'\r'|'\0'|'\\'
STRING \"([^"\\]|\\.)*\"
ARITH_OP [+\-*/%]
ASSIGN_OP :=|\+=|-=|\*=|\/=|%=
REL_OP [=<>]=?|<>
SEPARATOR [(){};,:]
COMMENT \/\*([^*]|\*+[^/])*\*+\/|\/\/.*
WHITESPACE [ \t\n\r]+

%%
"begin"/{WHITESPACE}*"VarDecl"{WHITESPACE}*:      {if(c){BEGIN(VARDECL_STATE); c=0;}; expecting_type = 0; printf("%-50s KEYWORD\n", yytext); return BEGIN_TOKEN; }
"end"/{WHITESPACE}*"VarDecl"          { BEGIN(0); printf("%-50s KEYWORD\n", yytext); return END; }
"VarDecl"   {printf("%-50s KEYWORD\n", yytext);  return VARDECL; }


<VARDECL_STATE>{IDENTIFIER} {
    if(!expecting_type){
        if(is_keyword(yytext)){
            printf("%-50s LEXICAL ERROR: Keyword is used as an identifier\n", yytext);
            return ERR;
        }
        else if(is_duplicate(yytext)){
            printf("%-50s LEXICAL ERROR: Duplicate variable declaration\n", yytext);
            return ERR;
        }
        else{
            if(check(yytext)){
                add_variable(yytext);
                printf("%-50s IDENTIFIER\n", yytext);
                expecting_type = 1;
                return IDENTIFIER;
            } else{
                printf("%-50s LEXICAL ERROR : Invalid identifier\n",yytext);
                return ERR;
            }
        }
    }
    else{
        expecting_type = 0;
        if(is_keyword(yytext)){
            printf("%-50s KEYWORD\n", yytext);
            return token_to_return(yytext);
        }
        else if(check(yytext)){
                printf("%-50s IDENTIFIER\n", yytext);
                return IDENTIFIER;
        } else{
            printf("%-50s LEXICAL ERROR : Invalid identifier\n",yytext);
            return ERR;
        }
    }
}

<VARDECL_STATE>\[[0-9]+\] {
    printf("%-50s ARRAY SIZE\n", yytext);
    return ARRAY_SIZE;
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
    if(str[4] == '(') {

        if(cnt_formatted != count){
            printf("%-50s LEXICAL ERROR: Invalid Input Statement\n",yytext);
            return ERR;
        }
        else{
        int flag = 1;
        char *start_quote = strchr(str, '"');
        char *end_quote = strrchr(str, '"');
        if (start_quote && end_quote && start_quote != end_quote) {
            for (char *ptr = start_quote + 1; ptr < end_quote; ptr++) {
            if(isspace(*ptr)){
                continue;
            }
            else if(flag ==1 && *ptr == '@'){
                flag = 0;
            }
            else if(flag == 0 && *ptr == ','){
                flag = 1;
            }
            else{
                printf("%-50s LEXICAL ERROR: Invalid Input Statement\n",yytext);
                return ERR;
                break;
            }
        }
        }
        if(flag == 0){
            printf("%-50s Valid Input Statement\n", yytext);
            yyless(4);
            return SCAN;
        }
        else{
            printf("%-50s LEXICAL ERROR: Invalid Input Statement\n",yytext);
            return ERR;
        }
        }
        }
    
    else{
        if(cnt_formatted != count){
            printf("%-50s LEXICAL ERROR: Invalid Output Statement\n",yytext);
            return ERR;
        }
        else{
        printf("%-50s Valid Output Statement\n", yytext);
        yyless(5);
        return PRINT;
        }
    }
    
}

("print"|"scan")\([ ]*{STRING}[ ]*([ ]*,[ ]*({IDENTIFIER}|{INTEGER}))*\) {
    char* str = yytext;
    if(str[4] == '(') {
        printf("%-50s LEXICAL ERROR: Invalid Input Statement\n",yytext);
        return ERR;
    }
    else{
        printf("%-50s LEXICAL ERROR: Invalid Output Statement\n",yytext);
        return ERR;
    }
}


{IDENTIFIER}   {
    if(is_keyword(yytext)){
        printf("%-50s KEYWORD\n", yytext);
        return token_to_return(yytext);
    }
    else{
        printf("%-50s IDENTIFIER\n", yytext);
        return IDENTIFIER;
    }
    /*else if(is_duplicate(yytext)) {
        printf("%-50s IDENTIFIER\n", yytext);
    }
    else{
        printf("LEXICAL ERROR : Undefined identifier\n");
        return ERR;
    }*/
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
            // printf("%-50s INTEGER CONSTANT\n", yytext);
            if (base == 2) {
                printf("%-50s BINARY CONSTANT\n", yytext);
                // set value in union 
                return BINARY;
            } else if (base == 8) {
                printf("%-50s OCTAL CONSTANT\n", yytext);
                // set value in union
                return OCTAL;
            } else if (base == 10) {
                printf("%-50s DECIMAL CONSTANT\n", yytext);
                // set value in union
                return DECIMAL;
            }
            else {
                printf("%-50s LEXICAL ERROR: Invalid Integer Constant\n", yytext);
                return ERR;
            }
        } else {
            printf("%-50s LEXICAL ERROR: Invalid Integer Constant\n", yytext);
            return ERR;
        }
    } else {
        printf("%-50s LEXICAL ERROR: Invalid Integer Constant", yytext);
        return ERR;
    }
}
{CHARACTER}    { printf("%-50s CHARACTER\n", yytext); return CHARACTER; }
{STRING}       { printf("%-50s STRING\n", yytext); return STRING; }

{ARITH_OP}     { printf("%-50s ARITHMETIC OPERATOR\n", yytext); return yytext[0]; }
":="           { printf("%-50s EQUAL OPERATOR\n",yytext); return EQ;}
{ASSIGN_OP}    { printf("%-50s ASSIGNMENT OPERATOR\n", yytext); return ASSIGN_OP; }
{REL_OP}       { printf("%-50s RELATIONAL OPERATOR\n", yytext); return REL_OP; }

{SEPARATOR}    { printf("%-50s SEPARATOR\n", yytext); return yytext[0]; }
{COMMENT}      { }
{WHITESPACE}   { /* Ignore whitespace */ }

.              { printf("%-50s LEXICAL ERROR\n", yytext); return ERR; }

%%
