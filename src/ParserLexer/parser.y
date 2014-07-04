%pure-parser
%lex-param {void * scanner}
%parse-param {ParseState * x}
%locations %pure-parser
%{
    #define YYERROR_VERBOSE 1

    #include "node.h"
    #include "parser.hpp"
    #include <memory>
    #define scanner x->scanner
    #define NLINE(A,B) (A*)((new A B )->set_line(yylloc.first_line+1,yylloc.first_column))

    extern int yylex(YYSTYPE * lvalp,YYLTYPE *locp,void * scan);
    void yyerror( YYLTYPE *locp,ParseState* x,const char *s) {
        Error e;
        e.error = s;
        e.line =locp->first_line+1;
        e.column_start =locp->first_column;
        e.column_end =locp->last_column-1;
        x->error.push_back(e);
    }
%}

/* Represents the many different ways we can access our data */
%union {
    Node *node;
    NBlock *block;
    NExpression *expr;
    NStatement *stmt;
    NIdentifier *ident;
    NVariableDeclaration *var_decl;
    NModule *mod_decl;
    std::vector<NVariableDeclaration*> *varvec;
    std::vector<NExpression*> *exprvec;
    std::string *string;
    int token;
}

/* Define our terminal symbols (tokens). This should
   match our tokens.l lex file. We also define the node type
   they represent.
 */
%token <string> TIDENTIFIER TINTEGER TDOUBLE
%token <token> TCEQ TCNE '<' TCLE '>' TCGE '='
%token <token> '(' ')' '{' '}' ',' '.' TARROW
%token <token> '+' '-' '*' '/'
%token <token> '!'
%token <token> TPLUSEQUAL TMINUSEQUAL TMULEQUAL TDIVEQUAL
%token <token> TMODULE TIMPORT TRETURN TLEX_ERROR

/* Define the type of node our nonterminal symbols represent.
   The types refer to the %union declaration above. Ex: when
   we call an ident (defined by union type ident) we are really
   calling an (NIdentifier*). It makes the compiler happy.
 */
%type <ident> ident
%type <expr> numeric expr 
%type <varvec> func_decl_args
%type <exprvec> call_args
%type <block> program stmts block
%type <stmt> stmt var_decl var_decl_func func_decl mod_decl
%type <token> comparison
%type <token> op_equal


/* Operator precedence for mathematical operators */
%left '+' '-'
%left '*' '/'
%right '!'

%start program

%%

program : stmts { x->programBlock = $1; }
        ;


stmts : stmt { $$ = NLINE(NBlock,());$$->statements.push_back($<stmt>1); }
      | stmts stmt { $1->statements.push_back($<stmt>2); }
      |  stmt error '\n' { yyerror(&yylloc,x,YY_("Lexical Error: Unexpected Token"));yyclearin;yyerrok;}
      ;

stmt : var_decl | func_decl | mod_decl
     | expr ';' { $$ = NLINE(NExpressionStatement,({*$1})); }
| TRETURN expr ';' {$$ = NLINE(NReturnStatement,({*$2}));}
     ;

block : '{' stmts '}' { $$ = $2; }
      | '{' '}' { $$ = NLINE(NBlock,()); }
      ;

var_decl_func : ident ident { $$ = NLINE(NVariableDeclaration,(*$1, *$2)); }
              | ident ident '=' expr { $$ = NLINE(NVariableDeclaration,(*$1, *$2, $4)); }
              ;
var_decl : ident ident ';' { $$ = NLINE(NVariableDeclaration,(*$1, *$2)); }
         | ident ident '=' expr ';' { $$ = NLINE(NVariableDeclaration,(*$1, *$2, $4)); }
        | ident '*' ident ';' { $$ = NLINE(NVariableDeclaration,(*$1, *$3)); }
        | ident '*' ident '=' expr ';' { $$ = NLINE(NVariableDeclaration,(*$1, *$3, $5)); }
         ;

func_decl : ident ident '(' func_decl_args ')' block 
            { $$ = NLINE(NFunctionDeclaration,(*$1, *$2, *$4, *$6)); delete $4; }

          ;

mod_decl : TMODULE ident block ';'
            { $$ = NLINE(NModule,(*$2, *$3));}
         ;

func_decl_args : /*blank*/  { $$ = new VariableList(); }
          | var_decl_func { $$ = new VariableList(); $$->push_back($<var_decl>1); }
          | func_decl_args ',' var_decl_func { $1->push_back($<var_decl>3); }
          ;

ident : TIDENTIFIER { $$ = NLINE(NIdentifier,(*$1)); delete $1; }
      ;

numeric : TINTEGER { $$ = NLINE(NInteger,(atol($1->c_str()))); delete $1; }
        | TDOUBLE { $$ = NLINE(NDouble,(atof($1->c_str()))); delete $1; }
        ;
    
expr : expr '=' expr { $$ = NLINE(NAssignment,(*$<ident>1, *$3)); }
     | ident op_equal expr { $$ = NLINE(NAssignment,(*$<ident>1, *$3,$2)); }
     | ident '(' call_args ')' { $$ = NLINE(NMethodCall,(*$1, *$3)); delete $3; }
     | '(' ident ')' expr {$$ = NLINE(NCast,(*$2, *$4));}
     | ident { $<ident>$ = $1; }
     | numeric
     | expr comparison expr { $$ = NLINE(NBinaryOperator,(*$1, $2, *$3)); }
     | '(' expr ')' { $$ = NLINE(NExpressionParen,(*$2)); }
| expr '.' ident { $$ = NLINE(NMemberAccess,(*$1,*$3)); }
| '*' expr { $$ = NLINE(NDereference,(*$2));}
| expr TARROW ident {$$ = NLINE(NMemberAccess,(*NLINE(NDereference,(*$1)),*$3));}
| expr TARROW ident '(' call_args ')' {$$ = NLINE(NMemberCall,(*NLINE(NDereference,(*$1)),*$3,*$5));}
    ;
    
call_args : /*blank*/  { $$ = new ExpressionList(); }
          | expr { $$ = new ExpressionList(); $$->push_back($1); }
          | call_args ',' expr  { $1->push_back($3); }
          ;

comparison : TCEQ | TCNE | '<' | TCLE | '>' | TCGE 
           | '+' | '-' | '*' | '/' | '!'
           ;
op_equal :  TPLUSEQUAL | TMINUSEQUAL | TMULEQUAL | TDIVEQUAL
;

%%
