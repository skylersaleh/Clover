%option reentrant
%option bison-bridge bison-locations yylineno  

D           [0-9]
L           [a-zA-Z_]
H           [a-fA-F0-9]
E           [Ee][+-]?{D}+
FS          (f|F|l|L)
IS          (u|U|l|L)*

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

{L}({L}|{D})*           { SAVE_TOKEN; return IDENTIFIER);}
 
0[xX]{H}+{IS}?          { SAVE_TOKEN; return(CONSTANT); }
0{D}+{IS}?              { SAVE_TOKEN; return(CONSTANT); }
{D}+{IS}?               { SAVE_TOKEN; return(CONSTANT); }
L?'(\\.|[^\\'])+'       { SAVE_TOKEN; return(CONSTANT); }

{D}+{E}{FS}?            { SAVE_TOKEN; return(CONSTANT); }
{D}*"."{D}+({E})?{FS}?  { SAVE_TOKEN; return(CONSTANT); }
{D}+"."{D}*({E})?{FS}?  { SAVE_TOKEN; return(CONSTANT); }

L?\"(\\.|[^\\"])*\"     { SAVE_TOKEN; return(STRING_LITERAL); }

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
"++"                    return TOKEN('++');
"--"                    return TOKEN('--');

"<<"                    return TOKEN('<<');
">>"                    return TOKEN('>>');
">>="                   return TOKEN('>>=');
"<<="                   return TOKEN('<<=');


.                       return TOKEN(TLEX_ERROR);
%%
