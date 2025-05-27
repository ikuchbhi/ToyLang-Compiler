%{
#include <ctype.h>
#include <stdio.h>
#include "bison.tab.h"
#include "ast-generator/ast.h"

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

int main();
%}

%s VARDECL_STATE

KEYWORD int|char|float|if|else|while|for|main|begin|end|input|output|program|VarDecl|inc|dec|print|scan|then
IDENTIFIER [a-z][a-z0-9_]*
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
"begin"/{WHITESPACE}*"VarDecl"{WHITESPACE}*:      {if(c){BEGIN(VARDECL_STATE); c=0;}; expecting_type = 0; fprintf(yyout, "%-50s KEYWORD\n", yytext); return BEGIN_TOKEN; }
"end"/{WHITESPACE}*"VarDecl"          { BEGIN(0); fprintf(yyout, "%-50s KEYWORD\n", yytext); return END; }
"VarDecl"   {fprintf(yyout, "%-50s KEYWORD\n", yytext);  return VARDECL; }


<VARDECL_STATE>{IDENTIFIER} {
    if(!expecting_type){
        if(is_keyword(yytext)){
            fprintf(yyout, "%-50s LEXICAL ERROR: Keyword is used as an identifier\n", yytext);
            return ERR;
        }
        else if(is_duplicate(yytext)){
            fprintf(yyout, "%-50s LEXICAL ERROR: Duplicate variable declaration\n", yytext);
            return ERR;
        }
        else{
            if(check(yytext)){
                add_variable(yytext);
                fprintf(yyout, "%-50s IDENTIFIER\n", yytext);
                expecting_type = 1;
                yylval.str = strdup(yytext);
                return IDENTIFIER;
            } else{
                fprintf(yyout, "%-50s LEXICAL ERROR : Invalid identifier\n",yytext);
                return ERR;
            }
        }
    }
    else{
        expecting_type = 0;
        if(is_keyword(yytext)){
            fprintf(yyout, "%-50s KEYWORD\n", yytext);
            yylval.str = strdup(yytext);
            return token_to_return(yytext);
        }
        else if(check(yytext)){
                fprintf(yyout, "%-50s IDENTIFIER\n", yytext);
                yylval.str = strdup(yytext);
                return IDENTIFIER;
        } else{
            fprintf(yyout, "%-50s LEXICAL ERROR : Invalid identifier\n",yytext);
            return ERR;
        }
    }
}

<VARDECL_STATE>\[[0-9]+\] {
    fprintf(yyout, "%-50s ARRAY SIZE\n", yytext);
    yytext[yyleng - 1] = '\0';
    yylval.decimalVal = atoi(yytext + 1); // Convert the string to an integer
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
            fprintf(yyout, "%-50s LEXICAL ERROR: Invalid Input Statement\n",yytext);
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
                fprintf(yyout, "%-50s LEXICAL ERROR: Invalid Input Statement\n",yytext);
                return ERR;
                break;
            }
        }
        }
        if(flag == 0){
            fprintf(yyout, "%-50s Valid Input Statement\n", yytext);
            yyless(4);
            return SCAN;
        }
        else{
            fprintf(yyout, "%-50s LEXICAL ERROR: Invalid Input Statement\n",yytext);
            return ERR;
        }
        }
        }
    
    else{
        if(cnt_formatted != count){
            fprintf(yyout, "%-50s LEXICAL ERROR: Invalid Output Statement\n",yytext);
            return ERR;
        }
        else{
        fprintf(yyout, "%-50s Valid Output Statement\n", yytext);
        yyless(5);
        return PRINT;
        }
    }
    
}

("print"|"scan")\([ ]*{STRING}[ ]*([ ]*,[ ]*({IDENTIFIER}|{INTEGER}))*\) {
    char* str = yytext;
    if(str[4] == '(') {
        fprintf(yyout, "%-50s LEXICAL ERROR: Invalid Input Statement\n",yytext);
        return ERR;
    }
    else{
        fprintf(yyout, "%-50s LEXICAL ERROR: Invalid Output Statement\n",yytext);
        return ERR;
    }
}


{IDENTIFIER}   {
    if(is_keyword(yytext)){
        fprintf(yyout, "%-50s KEYWORD\n", yytext);
        return token_to_return(yytext);
    }
    else{
        fprintf(yyout, "%-50s IDENTIFIER\n", yytext);
        yylval.str = strdup(yytext);
        return IDENTIFIER;
    }
    /*else if(is_duplicate(yytext)) {
        fprintf(yyout, "%-50s IDENTIFIER\n", yytext);
    }
    else{
        fprintf(yyout, "LEXICAL ERROR : Undefined identifier\n");
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
            // fprintf(yyout, "%-50s INTEGER CONSTANT\n", yytext);
            if (base == 2) {
                fprintf(yyout, "%-50s BINARY CONSTANT\n", yytext);
                int len = snprintf(NULL, 0, "%d", num);
                char *str = malloc(len + 1);
                snprintf(str, len + 1, "%d", num); 
                yylval.intVal.value = str;
                yylval.intVal.base = 2;
                return BINARY;
            } else if (base == 8) {
                fprintf(yyout, "%-50s OCTAL CONSTANT\n", yytext);
                int len = snprintf(NULL, 0, "%d", num);
                char *str = malloc(len + 1);
                snprintf(str, len + 1, "%d", num); 
                yylval.intVal.value = str;
                yylval.intVal.base = 8;
                return OCTAL;
            } else if (base == 10) {
                fprintf(yyout, "%-50s DECIMAL CONSTANT\n", yytext);
                int len = snprintf(NULL, 0, "%d", num);
                char *str = malloc(len + 1);
                snprintf(str, len + 1, "%d", num); 
                yylval.intVal.value = str;
                yylval.intVal.base = 10;
                return DECIMAL;
            }
            else {
                fprintf(yyout, "%-50s LEXICAL ERROR: Invalid Integer Constant\n", yytext);
                return ERR;
            }
        } else {
            fprintf(yyout, "%-50s LEXICAL ERROR: Invalid Integer Constant\n", yytext);
            return ERR;
        }
    } else {
        fprintf(yyout, "%-50s LEXICAL ERROR: Invalid Integer Constant", yytext);
        return ERR;
    }
}
{CHARACTER}    { fprintf(yyout, "%-50s CHARACTER\n", yytext); yylval.charVal = yytext[1]; return CHARACTER; }
{STRING}       { 
    fprintf(yyout, "%-50s STRING\n", yytext);
    // Remove the first and last characters in the string ('"' and '"') 
    // with pointer manipulation magic instead of creating a new string :)
    yytext[yyleng - 1] = '\0'; 
    yylval.str = strdup(yytext + 1); 
    return STRING; 
}

{ARITH_OP}     { fprintf(yyout, "%-50s ARITHMETIC OPERATOR\n", yytext); return yytext[0]; }
":="           { fprintf(yyout, "%-50s EQUAL OPERATOR\n",yytext); return EQ;}
{ASSIGN_OP}    { fprintf(yyout, "%-50s ASSIGNMENT OPERATOR\n", yytext); yylval.str = strdup(yytext); return ASSIGN_OP; }
{REL_OP}       { fprintf(yyout, "%-50s RELATIONAL OPERATOR\n", yytext); yylval.str = strdup(yytext); return REL_OP; }

{SEPARATOR}    { fprintf(yyout, "%-50s SEPARATOR\n", yytext);  return yytext[0]; }
{COMMENT}      { }
{WHITESPACE}   { /* Ignore whitespace */ }

.              { fprintf(yyout, "%-50s LEXICAL ERROR\n", yytext); return ERR; }

%%
