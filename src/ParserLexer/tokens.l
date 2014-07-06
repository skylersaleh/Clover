%option reentrant
%option bison-bridge bison-locations yylineno
%{
#include <string>
#include "node.h"
#include "parser.hpp"
#define SAVE_TOKEN yylval->string = new std::string(yytext, yyleng)
#define TOKEN(t) (yylval->token = t)
#define YY_USER_ACTION { \
yylloc->first_column = yylloc->first_line!=yylineno ?0:yylloc->last_column;                 \
yylloc->first_line = yylineno; \
yylloc->last_column=yylloc->first_column+yyleng;                    \
}
extern "C" int yywrap(yyscan_t yyscanner) { }
%}

%%

[ \t\n]                 ;
(\/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+\/)|(\/\/.*) ; //C/C++ style comments

"+"                     return TOKEN('+');
"-"                     return TOKEN('-');
"*"                     return TOKEN('*');
"/"                     return TOKEN('/');
"%"                     return TOKEN('%');
"&"                     return TOKEN('&');
"|"                     return TOKEN('|');
"~"                     return TOKEN('~');
"^"                     return TOKEN('^');
">"                     return TOKEN('<');
"<"                     return TOKEN('<');
"<="                    return TOKEN('<=');
">="                    return TOKEN('>=');
"=="                    return TOKEN('==');
"!="                    return TOKEN('!=');
"!"                     return TOKEN('!');
"&&"                    return TOKEN('&&');
"||"                    return TOKEN('||');
"["                     return TOKEN('[');
"]"                     return TOKEN(']');
"}"                     return TOKEN('}');
"{"                     return TOKEN('{');
"("                     return TOKEN('(');
")"                     return TOKEN(')');
"."                     return TOKEN('.');
"="                     return TOKEN('=');
"->"                    return TOKEN('->');
"+="                    return TOKEN('+=');
"-="                    return TOKEN('-=');
"*="                    return TOKEN('*=');
"/="                    return TOKEN('/=');
"%="                    return TOKEN('%=');
"&="                    return TOKEN('&=');
"^="                    return TOKEN('^=');
";"                     return TOKEN(';');
"?"                     return TOKEN('?');
":"                     return TOKEN(':');
","                     return TOKEN(',');

"sizeof"                return TOKEN(SIZEOF);
"#import"               return TOKEN(IMPORT);
"if"                    return TOKEN(IF);
"else"                  return TOKEN(ELSE);
"while"                 return TOKEN(WHILE);
"do"                    return TOKEN(DO);
"for"                   return TOKEN(FOR);
"switch"                return TOKEN(SWITCH);
"case"                  return TOKEN(CASE);
"break"                 return TOKEN(BREAK);
"return"                return TOKEN(RETURN);
"continue"              return TOKEN(CONTINUE);
"default"               return TOKEN(DEFAULT);

"global"                return TOKEN(GLOBAL);
"local"                 return TOKEN(LOCAL);
"constant"              return TOKEN(CONSTANT);

"static"                return TOKEN(STATIC);
"const"                 return TOKEN(CONST);

"typedef"               return TOKEN(TYPEDEF);
"struct"                return TOKEN(STRUCT);
"module"                return TOKEN(MODULE);
"state_machine"         return TOKEN(STATE_MACHINE);

[a-zA-Z_][a-zA-Z0-9_]*  SAVE_TOKEN; return IDENTIFIER;
[0-9]+\.[0-9]*          SAVE_TOKEN; return DOUBLE;
[0-9]+                  SAVE_TOKEN; return INTEGER; 

.                       return TOKEN(TLEX_ERROR);
%%
