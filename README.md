# ELox
A Elixir port of jlox, the Lox language's AST interpreter (http://www.craftinginterpreters.com/). This is still a work in progress.

## What has been done so far?

**Lexical Analysis**

Done!

**Parsing/Interpreter**:

Everything except classes and closures.

**Grammar**:

```
program     → declaration* EOF ;

declaration → varDecl
            | funDecl
            | statement ;

statement   → exprStmt
            | ifStmt
            | printStmt 
            | returnStmt
            | whileStmt
            | forStmt
            | block ;

funDecl  → "fun" function ;
function → IDENTIFIER "(" parameters? ")" block ;

forStmt   → "for" "(" ( varDecl | exprStmt | ";" )
                      expression? ";"
                      expression? ")" statement ;

block → "{" declaration* "}" ;

ifStmt    → "if" "(" expression ")" statement ( "else" statement )? ;

varDecl → "var" IDENTIFIER ( "=" expression )? ";" ;

exprStmt  → expression ";" ;
printStmt → "print" expression ";" ;

whileStmt → "while" "(" expression ")" statement ;

returnStmt → "return" expression? ";" ;

expression → assignment ;
assignment → identifier "=" assignment
           | equality
           | logic ;

logic   → equality ( ( "or" | "and" ) logic )* ;

equality       → comparison ( ( "!=" | "==" ) comparison )* ;
comparison     → addition ( ( ">" | ">=" | "<" | "<=" ) addition )* ;
addition       → multiplication ( ( "-" | "+" ) multiplication )* ;
multiplication → unary ( ( "/" | "*" ) unary )* ;

unary          → ( "!" | "-" ) unary
               | call ;

call  → primary ( "(" arguments? ")" )* ";" ;

arguments → expression ( "," expression )* ;

primary        → NUMBER | STRING | "false" | "true" | "nil" | IDENTIFIER
               | "(" expression ")" ;
```


```               
expression → literal
           | unary
           | binary
           | grouping ;

literal    → NUMBER | STRING | "false" | "true" | "nil" | IDENTIFIER;
grouping   → "(" expression ")" ;
unary      → ( "-" | "!" ) expression ;
binary     → expression operator expression ;
operator   → "==" | "!=" | "<" | "<=" | ">" | ">="
           | "+"  | "-"  | "*" | "/" ;

```
