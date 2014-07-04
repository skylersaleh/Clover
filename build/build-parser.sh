mkdir ../built-src
mkdir ../built-src/Clover
bison -d -o ../built-src/Clover/parser.cpp ../src/ParserLexer/parser.y &&
lex -o ../built-src/Clover/tokens.cpp ../src/ParserLexer/tokens.l
