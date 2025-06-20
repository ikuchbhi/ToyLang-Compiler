# Context Free Grammar for ToyLang

To successfully build the syntax analyser (and as a part of Part-1's submission), the CFG for ToyLang is as below, taking into account the specifications mentioned in [Project Description](/Project%20Description.pdf):

```bnf
<Program> ::= "begin program:" <VarDeclBlock> <Statements> "end program"

<VarDeclBlock> ::= "begin VarDecl:" <Declarations> "end VarDecl"
<Declarations> ::= <Declaration> ";" <Declarations> | ε

# Scalar or Array
<Declaration> ::= "(" <Identifier> "," <DataType> ")" | "(" <Identifier> "[" <DecimalConstant> "]" "," <DataType> ")"

<DataType> ::= "int" | "char"

<Statements> ::= <Statement> <Statements> | ε
<Statement> ::= <PrintStmt> | <ScanStmt> | <AssignStmt> | <BlockStmt> | <IfStmt> | <WhileStmt> | <ForStmt>

<PrintStmt> ::= <ConstantPrintStmt> | <FormattedPrintStmt>
<ConstantPrintStmt> ::= "print" "(" <StringConstant> ")" ";"
<FormattedPrintStmt> ::= "print" "(" <FormattedPrintString> "," <ExprList> ")" ";"

<ScanStmt> ::= "scan" "(" <FormattedScanString> "," <VarList> ")" ";"
<ExprList> ::= <Expression> "," <ExprList> | <Expression>
<VarList> ::= <Identifier> "," <VarList> | <Identifier>

<AssignStmt> ::= <Identifier> <AssignOp> <Expression> ";"
<AssignOp> ::= ":=" | "+=" | "-=" | "*=" | "/=" | "%="

<BlockStmt> ::= "begin" <BlockStatements> "end" ";"
<BlockStatements> ::= <Statement> <BlockStatements> | <Statement>

<SimpleBlockStmt> ::= "begin" <SimpleBlockStatements> "end" ";"
<SimpleBlockStatements> ::= <SimpleStatement> <SimpleBlockStatements> | <SimpleStatement>
<SimpleStatement> ::= <PrintStmt> | <ScanStmt> | <AssignStmt>

<IfStmt> ::= "if" "(" <Condition> ")" <SimpleBlockStmt> | "if" "(" <Condition> ")" "else" <SimpleBlockStmt> ";"
<Condition> ::= <Expression> <RelOp> <Expression> | <Expression>
<RelOp> ::= "=" | ">" | "<" | ">=" | "<=" | "<>"    

<WhileStmt> ::= "while" "(" <Condition> ")" <SimpleBlockStmt>

<ForStmt> ::= "for" <Identifier> ":=" <Expression> "to" <Expression> ("inc" | "dec") <Expression> "do" <SimpleBlockStmt>

<Expression> ::= <Term> | <Expression> <AddOp> <Term>
<Term> ::= <Factor> | <Term> <MulOp> <Factor>
<Factor> ::= "(" <Expression> ")" | <Constant> | <Identifier> | <Identifier> "[" <Expression> "]"

<AddOp> ::= "+" | "-"
<MulOp> ::= "*" | "/" | "%"

<Identifier> ::= ^[a-z][a-z0-9]*(_[a-z0-9]*)?$

<Constant> ::= <IntConstant> | <CharConstant> | <StringConstant>
<IntConstant> ::= "(" <DecimalConstant> ", 10)" | "(" <BinaryConstant> ", 2)" | "(" <OctalConstant> ", 8)"
<BinaryConstant> ::= ^(0|1)+$
<OctalConstant> ::= ^[0-7]+$
<DecimalConstant> ::= ^[0-9]+$

<CharConstant> ::= ^['].[']$

<FormattedPrintString> ::= ^["]([^@]*[@][^@]*)*["]$
<FormattedScanString> ::= ^["](@([,][@])*)["]$

<StringConstant> ::= ^["].*["]$
```