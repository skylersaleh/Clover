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

"module"                return TOKEN(TMODULE);
"return"                return TOKEN(TRETURN);

[a-zA-Z_][a-zA-Z0-9_]*  SAVE_TOKEN; return TIDENTIFIER;
[0-9]+\.[0-9]*          SAVE_TOKEN; return TDOUBLE;
[0-9]+                  SAVE_TOKEN; return TINTEGER;

"="                     return TOKEN('=');
"=="                    return TOKEN(TCEQ);
"!="                    return TOKEN(TCNE);
"<"                     return TOKEN('<');
"<="                    return TOKEN(TCLE);
">"                     return TOKEN('>');
">="                    return TOKEN(TCGE);
"("                     return TOKEN('(');
")"                     return TOKEN(')');
"{"                     return TOKEN('{');
"}"                     return TOKEN('}');
"."                     return TOKEN('.');
"->"                    return TOKEN(TARROW);
","                     return TOKEN(',');
"+="                    return TOKEN(TPLUSEQUAL);
"-="                    return TOKEN(TMINUSEQUAL);
"*="                    return TOKEN(TMULEQUAL);
"/="                    return TOKEN(TDIVEQUAL);
"+"                     return TOKEN('+');
"-"                     return TOKEN('-');
"*"                     return TOKEN('*');
";"                     return TOKEN(';');
"/"                     return TOKEN('/');
"!"                     return TOKEN('!');
"#import"               return TOKEN(TIMPORT);
.                       return TOKEN(TLEX_ERROR);
%%
