#Clover Parser

##Expressions

**Variable Declaration**
    
    IDENTIFIER{TYPENAME} IDENTIFIER{VARNAME}

**Variable Declaration and Assignment**
    
    IDENTIFIER{TYPENAME} IDENTIFIER{VARNAME} '=' EXPRESSION

**Variable Assignment**

    EXPRESSION{Assignable} ASSIGN_OP EXPRESSION

**Prefix Operator**

    (&|*|++|--) EXPRESSION 

**Postfix Operator** 

    EXPRESSION (++|--)

**Array Access**

    EXPRESSION '[' EXPRESSION ']'

**Variable Read**
    
    IDENTIFIER{VARNAME}

**Ternary** 

    EXPRESSION '?' EXPRESSION ':' EXPRESSION 

**Struct Access**

    EXPRESSION '.' IDENTIFIER

**Struct Access Indirect**

    EXPRESSION '->' IDENTIFIER

**Comma**

    EXPRESSION ',' EXPRESSION 

**Function**

    EXPRESSION '(' ARGUMENT ')'

**Parentheses**

    '(' EXPRESSION ')'

**Arithmetic Expression**
    
    EXPRESSION ARITHMETIC_OP EXPRESSION

**Constant**

    CONSTANT

**String Literal**
    
    STRING_LITERAL

##Argument

**Single Argument**

    EXPRESSION

**Argument List (Higher Precedence than Comma Expression)**

    EXPRESSION ',' ARGUMENT 


##Statements

**Expression Statement**

    EXPRESSION ';'

**If**

    IF '(' EXPRESSION ')' STATEMENT

**If-else**

    IF '(' EXPRESSION ')' STATEMENT ELSE STATEMENT

**While Loop**

    WHILE '(' EXPRESSION ')' STATEMENT

**For Loop**
    
    FOR '(' EXPRESSION ';' EXPRESSION ';' EXPRESSION ')' STATEMENT 

**Do-While Loop**

    DO STATEMENT WHILE '(' EXPRESSION ')' ';'
    
**Statement List**

    STATEMENT STATEMENT

**Block**

    '{' STATEMENT '}'

**Function Declaration**
    
    IDENTIFIER{TYPENAME OR INTENT} IDENTIFIER{VARNAME} '(' ARGUMENT ')' STATEMENT

**Struct Declaration**

    IDENTIFIER{STRUCT_TYPE} IDENTIFIER{TYPENAME} STATEMENT

**Empty Statement**
    
    ';'

##Assignment Operators
- '='
- '+='
- '-='
- '*='
- '/='
- '%='
- '^='
- '&='
- '|='
- '<<='
- '>>='

## Arithmetic Operators 
- +
- -
- *
- /
- %
- &
- | 
- ~
- ^
- >
- <
- <=
- >=
- ==
- !=
- !
- &&
- ||
- <<
- >>


## Unary Operators
- *
- &
- ++
- -- 
- +
- -
- !
- ~

## Operator Precedence 

1. '(', ')', '[', ']'
2. '.', '->'
3. '++', '--'
4. '~', '!'
5. '-'(Unary), '+'(Unary), '*'
 '=', '+=', '-=', '*=', '/=', '%=', '^=', '&=', '|=', '<<=' '>>=' 
