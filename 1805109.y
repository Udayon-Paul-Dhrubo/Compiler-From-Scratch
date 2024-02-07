%{

#include"parserBase.h"

#define ARRAY "ARR"
#define VARIABLE "VAR"
#define FUNCTION "FUNC"
#define INT_TYPE "INT"
#define FLOAT_TYPE "FLOAT"
#define VOID_TYPE "VOID"
#define CHAR_TYPE "CHAR"

using namespace std;



%}
%union{
SYMBOL_INFO* symbol;
vector<SYMBOL_INFO*>* vectorsymbol;
}


%token IF FOR DO INT FLOAT VOID SWITCH DEFAULT ELSE WHILE BREAK CHAR DOUBLE RETURN CASE CONTINUE
%token INCOP DECOP ASSIGNOP NOT SEMICOLON PRINTLN
%token STRING

%token<symbol> LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA

%token <symbol>ID
%token <symbol>CONST_INT
%token <symbol>CONST_FLOAT
%token <symbol>CONST_CHAR
%token <symbol>ADDOP
%token <symbol>MULOP
%token <symbol>LOGICOP
%token <symbol>RELOP
%token <symbol>BITOP


%type <symbol> type_specifier var_declaration declaration_list func_declaration func_definition unit start program 
%type <vectorsymbol> parameter_list compound_statement  statements statement
%type <vectorsymbol> expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments


%nonassoc second_precedence
%nonassoc ELSE

%%


start: program
        {
            printLog("start: program");
            
            $$ = $1;
            print($$->log);

            //assembly
            if(syntaxError + lexError == 0 ){
                initial_code += ".MODEL small\n";
                initial_code += ".STACK 100h\n";
                initial_code += ".DATA\n";
                initial_code += "\tprint_var dw ?\n";
                initial_code += "\tret_temp dw ?\n";

                for( int i = 0; i < data_list.size(); i++ ){
                    if( data_list.at(i).second == "0" ) initial_code += "\t"+data_list.at(i).first + " dw ?\n";
                    else initial_code += "\t"+ data_list.at(i).first + " dw " + data_list.at(i).second + " dup(?)\n";
                }

                initial_code += ".CODE\n";

                //define print func
                initial_code  += "print PROC\n";
                initial_code += "\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n";
                initial_code += "\tmov ax, print_var\n";


                initial_code += "\tcmp ax,0\n";
                initial_code += "\tjge end_minus_check\n";
                initial_code += "\tpush ax\n";
                initial_code += "\tmov ah, 2\n\tmov dl,\'-\'\n\tint 21h\n";

                initial_code += "\tpop ax\n";
                initial_code += "\tneg ax\n";
                initial_code += "end_minus_check:\n";

                initial_code += "\tmov bx, 10\n";
				initial_code += "\tmov cx, 0\n";

				initial_code += "printLabel1:\n";
				initial_code += "\tmov dx, 0\n";
				initial_code += "\tdiv bx\n";
				initial_code += "\tpush dx\n";
				initial_code += "\tinc cx\n";
				initial_code += "\tcmp ax, 0\n";
				initial_code += "\tjne printLabel1\n";

				initial_code += "printLabel2:\n";
				initial_code += "\tmov ah, 2\n";
				initial_code += "\tpop dx\n";
				initial_code += "\tadd dl, '0'\n";
				initial_code += "\tint 21h\n";
				initial_code += "\tdec cx\n";
				initial_code += "\tcmp cx, 0\n";
				initial_code += "\tjne printLabel2\n";
				initial_code += "\tmov dl, 0Ah\n";
				initial_code += "\tint 21h\n";
				initial_code += "\tmov dl, 0Dh\n";
				initial_code += "\tint 21h\n";
                
     
                initial_code += "\tpop ax\n\tpop bx\n\tpop cx\n\tpop dx\n";        
                initial_code += "\tret\n";
				initial_code += "print endp\n";


                codeOut << initial_code;

                final_code = initial_code;

                codeOut << $$->code;

                final_code += $$->code;

                if(includeMain) {
                    codeOut << "END main\n";
                    final_code += "END main\n";
                }

            }
        }
        ;

program: program unit
        {
            printLog("program: program unit");

            $$->log = $1->log + $2->log;
            print($$->log);

            //assembly
            $$->code = $1->code + $2->code;
        }
        | unit
        {
            printLog("program: unit");

            $$ = $1;
            print($$->log);
        }
        ;

unit: var_declaration
    {
        printLog("unit: var_declaration");

        $$ = $1;
        print($$->log);   

    }
    | func_declaration
    {
        printLog("unit: func_declaration");

        $$ = $1;
        print($$->log);;
    }
    | func_definition
    {
        printLog("unit: func_definition");

        $$ = $1;
        print($$->log);
    }
    ;

func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
                {
                    printLog("func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");               
                    
                    vector<string> paramList;
                    for( int i = 0; i < $4->size(); i++ ){
                        if( $4->at(i)->getType() == "ID" ){
                            paramList.push_back($4->at(i)->getName());

                            for( int j = 0; j < paramList.size()-1; j++ ){
                                if( $4->at(i)->getName() == paramList.at(j) ){
                                    paramList.pop_back();
                                    printError("Multiple definition of " + paramList.at(j) + " in parameter list");
                                    syntaxError++;
                                }
                            }
                        }
                    }

                    if( table.Insert($2->getName(), "ID") ){                        

                        SYMBOL_INFO* temp2 = table.Lookup($2->getName(), "ID");                        

                        temp2->setIDType(FUNCTION);
                        temp2->setFuncRetType($1->getVarType());
                        
                        for( int i = 0; i < $4->size(); i++ ) {
                            if( $4->at(i)->getType() == INT_TYPE || $4->at(i)->getType() == FLOAT_TYPE  || $4->at(i)->getType() == CHAR_TYPE ){
                                temp2->paramList_type.push_back($4->at(i)->getType() );
                            }
                        }                        

                    }
                    else{
                        printError("function " + $2->getName() + " already declared");
                        syntaxError++;
                    }    

                    $$->log = $1->log + " " + $2->getName() + "(" + $4->at(0)->log + ");";
                    print($$->log);
   
                } 
                | type_specifier ID LPAREN parameter_list RPAREN error
                {
                    printError("; missing");
                    syntaxError++;
                }
                ;

func_definition: type_specifier ID LPAREN parameter_list RPAREN 
                {                                    
    
                    if( Func_definition_operation( $1, $2, $4 ) ){
                        
                        table.Insert($2->getName(), "ID");                      

                        SYMBOL_INFO* temp = table.Lookup($2->getName(), "ID");                       
                        
                        temp->setIDType(FUNCTION);
                        temp->setFuncRetType($1->getVarType());
                        
                        temp->setFuncDefined(true);


                        // LCURL of compound statement
                        table.Enter_Scope();

                        //insert parameter into symbol table
                        for( int i = 0; i < $4->size(); i++ ){
                            if( $4->at(i)->getType() == "ID" ){

                                if( table.Insert($4->at(i)->getName(), "ID") ){
                                    
                                    SYMBOL_INFO* temp = table.Lookup($4->at(i)->getName(), "ID");

                                    temp->setIDType(VARIABLE);
                                    temp->setVarType($4->at(i-1)->getType());

                                    //assembly
                                    string symbol = createSymbol($4->at(i)->getName());
                                    temp->symbol = symbol;

                                }
                            }
                        }


                        SYMBOL_INFO* func = table.Lookup($2->getName(), "ID" );

                        if( func->paramList_type.size() == 0 ) { //if the func is not declared
                            
                            for( int i = 0; i < $4->size(); i++ ){
                                
                                if( $4->at(i)->getType() == INT_TYPE || $4->at(i)->getType() == FLOAT_TYPE  || $4->at(i)->getType() == CHAR_TYPE )
                                    func->paramList_type.push_back($4->at(i)->getType() );
                                
                                else if( $4->at(i)->getType() == "ID" ){

                                    //assembly 
                                    string symbol = createSymbol($4->at(i)->getName());
                                    
                                    SYMBOL_INFO* tempVar = table.Lookup($4->at(i)->getName(), "ID" );
                                    tempVar->symbol = symbol;
                                    data_list.push_back({symbol, "0"});

                                    //temp->paramList_name.push_back($4->at(i)->getName()); //need to rethink what to input
                                    func->paramList_name.push_back(symbol);
                                }
                                
                            }
                        }                       
                        
   
                    }
                } compound_statement {
                    table.Print_All_ScopeTable(logOut);
                    table.Exit_Scope(); //RCURL of compound statement
                }
                {
                    printLog("func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement");  

                    $$ = $1;

                    $$->log += $2->getName() + "(" + $4->at(0)->log + ")" + $7->at(0)->log;
                    print($$->log);


                    //assembly
                    string segment_code = "";
                    segment_code += $2->getName() + " PROC\n";

                    if( $2->getName() == "main" ) segment_code += "\tmov ax, @data\n\tmov ds, ax\n";
                    else segment_code += "\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n";

                    segment_code += $7->at(0)->code;

                    if( $2->getName() != "main" ) segment_code += "\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n\tret\n";

                    segment_code += $2->getName() + " ENDP\n";

                    $$->code += segment_code;
                }
                | type_specifier ID LPAREN RPAREN {

                    if( table.Lookup($2->getName(), "ID") == nullptr ){
                        if( table.Insert($2->getName(), "ID") ){

                            SYMBOL_INFO* temp = table.Lookup($2->getName(), "ID");                       
                        
                            temp->setIDType(FUNCTION);
                            temp->setFuncRetType($1->getVarType());                            
                        }
                    }
                    else{
                        SYMBOL_INFO* temp = table.Lookup($2->getName(), "ID"); 

                        if( temp->getFuncRetType() != $1->getType() ){
                            printError("function " + $2->getName() + " return type doesn't match");
                            syntaxError++;           
                        }
                    }

                    SYMBOL_INFO* func = table.Lookup($2->getName(), "ID");
                    if( func->getFuncDefined() ){
                        logOut << "Multiple Definition of " << $2->getName() << "\n\n";
                        syntaxError++;
                    }
                    else func->setFuncDefined(true);

                    // LCURL of compound statement
                        table.Enter_Scope();
                } compound_statement {
                    table.Print_All_ScopeTable(logOut);
                    table.Exit_Scope(); //RCURL of compound statement
                }
                {
                    printLog("func_definition: type_specifier ID LPAREN RPAREN compound_statement");

                    $$ = $1;

                    $$->log += + " " + $2->getName() + "(" + ")" + $6->at(0)->log;
                    print($$->log);

                    //assembly code
                    string segment_code = "";

                    segment_code += $2->getName() + " PROC\n";
                    if($2->getName() == "main")
				        {
                            segment_code += "\tmov ax, @data\n\tmov ds, ax\n";
                            includeMain= true;
                        }
                    
                    else 
				        segment_code += "\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n";
                    
                    segment_code += $6->at(0)->code;

                    if($2->getName() != "main")
				        segment_code += "\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n\tret\n";
                    
                    segment_code += $2->getName() + " ENDP\n";

                    $$->code += segment_code;
                }
                ;


parameter_list: parameter_list COMMA type_specifier ID
                {
                    printLog("parameter_list: parameter_list COMMA type_specifier ID");
                    
                    $$ = new vector<SYMBOL_INFO*>();

                    for( int i = 0; i < $1->size(); i++ )                        
                        $$->push_back($1->at(i)); 
                    

                    $4->setIDType(VARIABLE);
                    $4->setVarType(variable_type);
                    

                    $$->push_back($2);
                    $$->push_back($3);
                    $$->push_back($4);

                    $$->at(0)->log += "," + $3->getName() + " " + $4->getName();
                    print($$->at(0)->log); 
                    

                }
                | parameter_list COMMA type_specifier
                {
                    printLog("parameter_list: parameter_list COMMA type_specifier");

                    $$ = new vector<SYMBOL_INFO*>();  

                    for( int i = 0; i < $1->size(); i++ )                        
                        $$->push_back($1->at(i));                   

                    $$->push_back($2);
                    $$->push_back($3);

                    $$->at(0)->log += "," + $3->getName();
                    print($$->at(0)->log); 

                    
                }
                | type_specifier ID
                {
                    printLog("parameter_list: type_specifier ID");                    

                    $$ = new vector<SYMBOL_INFO*>();

                    $$->push_back($1);
                    $$->push_back($2);    

                    $$->at(0)->log += " " + $2->getName();
                    print($$->at(0)->log);              

                }
                | type_specifier
                {
                    printLog("parameter_list: parameter_list COMMA type_specifier");
                    print($1->log);

                    $$ = new vector<SYMBOL_INFO*>();
                    $$->push_back($1);
                }
                ;



compound_statement: LCURL statements RCURL
                    {
                        printLog("compound_statement: LCURL staements RCURL"); 

                        $$ = new vector<SYMBOL_INFO*>();

                        
				        $$->push_back($1);

                        for( int i = 0; i < $2->size(); i++ )
                            $$->push_back($2->at(i));   

                        $$->push_back($3);

                        $$->at(0)->log = "{\n" + $2->at(0)->log + "}\n";

                        print($$->at(0)->log);

                        //assembly
                        $$->at(0)->code += $2->at(0)->code;

                                           
                    }
                    | LCURL RCURL
                    {
                        printLog("compound_statement: LCURL RCURL"); 

                        $$ = new vector<SYMBOL_INFO*>();

                        
				        $$->push_back($1);
                        $$->push_back($2);

                        $$->at(0)->log = $1->getName() + "\n" + $2->getName() + "\n";

                        print($$->at(0)->log);
                    }
                    ;


var_declaration: type_specifier declaration_list SEMICOLON
                {
                    printLog("var_declaration: type_specifier declaration_list SEMICOLON");


                    if( $1->getType() == VOID_TYPE ){
                        printError("Variable type can't be void");
                        syntaxError++;
                    }

                
                    $$->log += " " + $2->log + ";\n";                   
                    
                    print($$->log);
                                     

                }
                | type_specifier declaration_list error
                {
                    printError("; missing");
                    syntaxError++;
                }
                ;


type_specifier: INT 
                {
                    printLog("type_specifier: INT");  

                                      
                    
                    SYMBOL_INFO* temp = new SYMBOL_INFO("int",INT_TYPE);
                    variable_type = INT_TYPE;

                    temp->log = "int";                  

                    print(temp->log);
                    $$ = temp;
                }
                | FLOAT
                {
                    printLog("type_specifier: FLOAT");

                    

                    SYMBOL_INFO* temp = new SYMBOL_INFO("float",FLOAT_TYPE);
                    variable_type = FLOAT_TYPE;

                    temp->log = "float";                  

                    print(temp->log);
                    $$ = temp;
                    
                }
                | VOID 
                {
                    printLog("type_specifier: VOID");

                    

                    SYMBOL_INFO* temp = new SYMBOL_INFO("void",VOID_TYPE);
                    variable_type = VOID_TYPE;

                    temp->log = "void";                  

                    print(temp->log);
                    $$ = temp;

                }
                ;


declaration_list: declaration_list COMMA ID
                {
                    printLog("declaration_list: declaration_list COMMA ID");                    

                    SYMBOL_INFO* temp = push( $3, "variable" );

                        
                    $$->log = $1->log + "," + $3->getName();
                    print($$->log);                    

                    //assembly                    
                    SYMBOL_INFO* tempVar = table.Lookup($3->getName(), "ID");

                    string symbol = createSymbol($3->getName() );

                    tempVar->symbol = symbol;
                    data_list.push_back({symbol, "0"});

                }
                | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
                {
                    printLog("declaration_list: declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");                    

                    int araSize = atoi( $5->getName().c_str() );

                    SYMBOL_INFO* temp = push( $3, "array",  araSize );              


                    $$->log += $1->log + "," + $3->getName() + "[" + $5->getName() + "]";
                    print($$->log);
                 

                    //assembly
                    string symbol = createSymbol($3->getName());

                    SYMBOL_INFO* tempVar = table.Lookup($3->getName(), "ID");

                    tempVar->symbol = symbol;

                    
                    data_list.push_back({symbol, "0"});
                    
                }
                | ID
                {
                    printLog("declaration_list: ID");                    

                    SYMBOL_INFO* temp = push( $1, "variable" );                   

                    $1->log = $1->getName();
                    $$ = $1;

                    print($$->log);                    


                    //assembly
                    string symbol = createSymbol($1->getName());

                    SYMBOL_INFO* tempVar = table.Lookup($1->getName(), "ID");

                    tempVar->symbol = symbol ;
                    data_list.push_back({symbol, "0"});                   

                    
                }
                | ID LTHIRD CONST_INT RTHIRD
                {
                    printLog("declaration_list: ID LTHIRD CONST_INT RTHIRD");                    

                    int araSize = atoi( $3->getName().c_str() );                   

                    SYMBOL_INFO* temp = push( $1, "array",  araSize );
 

                    $$->log = $1->getName() + "["+ $3->getName() + "]";
                    print($$->log);

                    //assembly
                    string symbol = createSymbol($1->getName());
                    SYMBOL_INFO* tempVar = table.Lookup($1->getName(), "ID");

                    tempVar->symbol = symbol;
                    data_list.push_back({symbol, "0"});
                    
                }
                ;

statements: statement
            {
                printLog("statements: statement");               

                $$ = new vector<SYMBOL_INFO*>();

                for(int i = 0; i < $1->size(); i++)
                    $$->push_back($1->at(i));
                
                print($$->at(0)->log);

            }
            | statements statement
            {
                printLog("statements: statements statement");                

                $$ = new vector<SYMBOL_INFO*>();

                for(int i = 0; i < $1->size(); i++)
                    $$->push_back($1->at(i));
                for(int i = 0; i < $2->size(); i++)
                    $$->push_back($2->at(i));

                $$->at(0)->log += $2->at(0)->log;
                print($$->at(0)->log);

                //assembly code
		        $$->at(0)->code = $$->at(0)->code + $2->at(0)->code;
            }
            ;

statement: var_declaration
            {
                printLog("statement: var_declaration");
                $$ = new vector<SYMBOL_INFO*>();

                $$->push_back($1);
                
                print($$->at(0)->log);
            }
            | expression_statement
            {
                printLog("statement: expression_statement");
                $$ = new vector<SYMBOL_INFO*>();

                for(int i = 0; i < $1->size(); i++)
                    $$->push_back($1->at(i));
                
                print($$->at(0)->log);
            }
            | {table.Enter_Scope();} compound_statement {table.Print_All_ScopeTable(logOut); table.Exit_Scope();}
            {
                printLog("statement: compound_statement");
                $$ = new vector<SYMBOL_INFO*>();

                for(int i = 0; i < $2->size(); i++)
                    $$->push_back($2->at(i));
                
                print($$->at(0)->log);
            }
            | FOR LPAREN expression_statement expression_statement expression RPAREN statement
            {
                printLog("statement: FOR LPAREN expression_statement expression_statement expression RPAREN statement");

                $$ = new vector<SYMBOL_INFO*>();
                $$->push_back(new SYMBOL_INFO("for", "FOR"));
                $$->push_back($2);
                for(int i = 0; i < $3->size(); i++)
                    $$->push_back($3->at(i));
                for(int i = 0; i < $4->size(); i++)
                    $$->push_back($4->at(i));
                for(int i = 0; i < $5->size(); i++)
                    $$->push_back($5->at(i));
                $$->push_back($6);
                for(int i = 0; i < $7->size(); i++)
                    $$->push_back($7->at(i));

                $$->at(0)->log = "for (" + $3->at(0)->log + $4->at(0)->log + $5->at(0)->log + ")" + $7->at(0)->log;
                
                print($$->at(0)->log);

                //assembly
                string label1 = newLabel();
                string label2 = newLabel();

                

                string segment_code = "";
                segment_code += $3->at(0)->code;
                segment_code += label1 + ":\n";
                segment_code += $4->at(0)->code;
                segment_code += "\tmov ax, " + $4->at(0)->symbol + "\n";
                segment_code += "\tcmp ax, 0\n";
                segment_code += "\tje " + label2 + "\n";
                segment_code += $7->at(0)->code;
                segment_code += $5->at(0)->code;
                segment_code += "\tjmp " + label1 + "\n";
                segment_code += label2 + ":\n";

                $$->at(0)->code = segment_code;


            }
            | IF LPAREN expression RPAREN statement %prec second_precedence
            {
                printLog("statement: IF LPAREN expression RPAREN statement");

                $$ = new vector<SYMBOL_INFO*>();
                $$->push_back(new SYMBOL_INFO("if", "IF"));
                $$->push_back($2);
                for(int i = 0; i < $3->size(); i++)
                    $$->push_back($3->at(i));
                $$->push_back($4);
                for(int i = 0; i < $5->size(); i++)
                    $$->push_back($5->at(i));

                $$->at(0)->log = "if (" + $3->at(0)->log + ")" + $5->at(0)->log;
                print($$->at(0)->log);

                //assembly code
                string label1 = newLabel();
                
                string segment_code = "";

                segment_code += $3->at(0)->code;
                segment_code += "\tmov ax, " + $3->at(0)->symbol + "\n";
                segment_code += "\tcmp ax, 0\n";
                segment_code += "\tje " + label1 + "\n";
                segment_code += $5->at(0)->code;
                segment_code += label1 + ":\n";

                $$->at(0)->code += segment_code; 
                
            }
            | IF LPAREN expression RPAREN statement ELSE statement
            {
                printLog("statement: IF LPAREN expression RPAREN statement ELSE statement");
                
                $$ = new vector<SYMBOL_INFO*>();
                $$->push_back(new SYMBOL_INFO("if", "IF"));
                $$->push_back($2);
                for(int i = 0; i < $3->size(); i++)
                    $$->push_back($3->at(i));
                $$->push_back($4);
                for(int i = 0; i < $5->size(); i++)
                    $$->push_back($5->at(i));
                $$->push_back(new SYMBOL_INFO("else", "ELSE"));
                for(int i = 0; i < $7->size(); i++)
                    $$->push_back($7->at(i));

                $$->at(0)->log = "if (" + $3->at(0)->log + ")" + $5->at(0)->log + "else" + $7->at(0)->log;
                print($$->at(0)->log); 


                //assembly code
                string label1 = newLabel();
                string label2 = newLabel();
                string segment_code = "";

                segment_code += $3->at(0)->code;

                segment_code += "\tmov ax, " + $3->at(0)->symbol + "\n";
                segment_code += "\tcmp ax, 0\n";
                segment_code += "\tje " + label1 + "\n";
                segment_code += $5->at(0)->code;
                segment_code += "\tjmp " + label2 + "\n";
                segment_code += label1 + ":\n";
                segment_code += $7->at(0)->code;
                segment_code += label2 + ":\n";

                $$->at(0)->code +=  segment_code;                


            }
            | WHILE LPAREN expression RPAREN statement
            {
                printLog("statement: WHILE LPAREN expression RPAREN statement");

                $$ = new vector<SYMBOL_INFO*>();
                $$->push_back(new SYMBOL_INFO("while", "WHILE"));
                $$ = new vector<SYMBOL_INFO*>();
                $$->push_back($2);
                for(int i = 0; i < $3->size(); i++)
                    $$->push_back($3->at(i));
                $$->push_back($4);
                for(int i = 0; i < $5->size(); i++)
                    $$->push_back($5->at(i));

                $$->at(0)->log = "while (" + $3->at(0)->log + ")" + $5->at(0)->log;
                print($$->at(0)->log);


                //assembly
                string label1 = newLabel(); 
                string label2 = newLabel(); 

                

                string segment_code = "";
                //
                


                segment_code += label1 + ":\n";
                segment_code += $3->at(0)->code;

                segment_code += "\tmov ax, " + $3->at(0)->symbol + "\n";
                segment_code += "\tcmp ax, 0\n";
                segment_code += "\tje " + label2 + "\n";
                segment_code += $5->at(0)->code;
                segment_code += "\tjmp " + label1 + "\n";
                segment_code += label2 + ":\n";

                $$->at(0)->code = segment_code;
            }
            | PRINTLN LPAREN ID RPAREN SEMICOLON
            {
                
                printLog("PRINTLN LPAREN ID RPAREN SEMICOLON");

                SYMBOL_INFO* temp = table.Lookup($3->getName(), "ID");
                
                if( temp == nullptr ){
                    printError("Undeclared variable " + $3->getName());
                    syntaxError++;
                }

                $$ = new vector<SYMBOL_INFO*>();
                $$->push_back(new SYMBOL_INFO("println", "PRINTLN"));
                $$->push_back($2);
                $$->push_back($3);
                $$->push_back($4);

                $$->at(0)->log = "println(" + $3->getName() + ");\n";
                print($$->at(0)->log);


                //assembly
                string segment_code = "";

                segment_code += "\tmov ax, " + temp->symbol + "\n";
                segment_code += "\tmov print_var, ax\n";
                segment_code +=	"\tcall print\n";

                $$->at(0)->code += segment_code;
	  
            }
            | PRINTLN LPAREN ID RPAREN error 
            {
                printError("; missing");
                syntaxError++;
            }
            | RETURN expression SEMICOLON
            {
                printLog("statement: RETURN expression SEMICOLON");

                
                $$ = new vector<SYMBOL_INFO*>();

                
                $$->push_back(new SYMBOL_INFO("return", "RETURN"));

                for(int i = 0; i < $2->size(); i++)
                    $$->push_back($2->at(i));

                $$->at(0)->log = "return " + $2->at(0)->log + ";\n";
                
                print($$->at(0)->log);


                //assembly
                string segment_code = "";
                segment_code = $2->at(0)->code;
                segment_code += "\tmov ax, " + $2->at(0)->symbol + "\n";
                segment_code += "\tmov ret_temp, ax\n";

                $$->at(0)->code += segment_code;

            }
            | RETURN expression error
            {
                printError("; missing");
                syntaxError++;
            }
            ;





expression_statement: SEMICOLON
                        {
                            printLog("expression_statement: SEMICOLON");

                            $$ = new vector<SYMBOL_INFO*>();

                            $$->push_back(new SYMBOL_INFO(";", "SEMICOLON"));
                            $$->at(0)->log = ";";

                            print($$->at(0)->log);
                            
                        }
                        | expression SEMICOLON
                        {
                            printLog("expression_statement: expression SEMICOLON");

                            $$ = new vector<SYMBOL_INFO*>();
                            for( int i = 0; i < $1->size(); i++ )
                                $$->push_back($1->at(i));
                            $$->push_back(new SYMBOL_INFO(";", "SEMICOLON"));

                            $$->at(0)->log += ";\n";

                            print($$->at(0)->log);
                        }
                        | expression error
                        {
                            printError(" ; missing.");
                            syntaxError++;
                        }
                        ;
                        

variable:  ID   
            {
                printLog("variable: ID");

                $$ = new vector<SYMBOL_INFO*>();

                SYMBOL_INFO* temp = table.Lookup($1->getName(),"ID");               
                

                if( temp == nullptr ) {
					printError($1->getName() + "  doesn't exist");
					syntaxError++;                    
				}
                else if( temp->getIDType() == ARRAY ){
                    printError("Type mismatch, " + temp->getName() + " is an array");
                    syntaxError++;
                }
                else if( temp->getIDType() == FUNCTION ){
                    printError("Type mismatch, " + temp->getName() + " is an function");
                    syntaxError++;
                }

                $$->push_back($1);	
                $$->at(0)->log = $1->getName();
                print($$->at(0)->log);
                
                //assembly code                
                $$->at(0)->symbol = table.Lookup($1->getName(),"ID")->symbol;
                $$->at(0)->code = "";
				
            }
            | ID LTHIRD expression RTHIRD           
            {
                printLog("variable: ID LTHIRD expression RTHIRD");
                
                $$ = new vector<SYMBOL_INFO*>();
                
                SYMBOL_INFO* temp = table.Lookup($1->getName(), "ID");

                if( temp == nullptr ) {
                    printError($1->getName() + "  doesn't exist");
					syntaxError++;
                }
                else if( temp->getIDType() != ARRAY ){
                    printError($1->getName() + " is not an array.");
                    syntaxError++;
                }

                if( $3->at(0)->getType() != "CONST_INT"){
                    printError("must be integer type");
                    syntaxError++;
                }

                    
                $$->push_back($1);   
                $$->push_back($2);     
                $$->push_back($3->at(0)); 
                $$->push_back($4);      

                $$->at(0)->log = $1->getName() + "[" + $3->at(0)->log + "]";
                print($$->at(0)->log);         
                
                
                //assembly_code
                string segment_code = "";
                segment_code += "\tmov di, " + $3->at(0)->symbol + "\n";
		        segment_code += "\tadd di, di\n";

                $$->at(0)->symbol = table.Lookup($1->getName(),"ID")->symbol;
                $$->at(0)->code = segment_code;              

            }
            ;



expression: logic_expression
            {
                printLog("expression : logic_expression");

                
                $$ = new vector<SYMBOL_INFO*>();

                for(int i = 0; i < $1->size(); i++)
                    $$->push_back($1->at(i));
                
                print($$->at(0)->log);

            }
            | variable ASSIGNOP logic_expression
            {
                printLog("expression : variable ASSIGNOP logic_expression");


                $$ = new vector<SYMBOL_INFO*>();

                if( ASSIGN_operation($1, $3) ){

                    for(int i = 0; i < $1->size(); i++)
                        $$->push_back($1->at(i));
                    $$->push_back(new SYMBOL_INFO("=", "ASSIGNOP"));
                    for(int i = 0; i < $3->size(); i++)
                        $$->push_back($3->at(i));
                    

                    

                    //assembly
                    string segment_code = "";
                    string temp = newTemp();


                    if($3->size() == 4){
                        temp = newTemp();
                        segment_code += $3->at(0)->code;
                        segment_code += "\tmov ax, " + $3->at(0)->symbol + "[di]\n";
                        segment_code += "\tmov " + temp + ", ax\n";
                        segment_code += $1->at(0)->code;
                        if( $3->at(0)->getIDType() != ARRAY )
                            segment_code += "\tmov " + $1->at(0)->symbol + ", ax\n";
                        else{
                            segment_code += "\tmov ax, " + temp + "\n"; 
                            segment_code += "\tmov " + $1->at(0)->symbol + "[di], ax\n";
                        }
                    }

                    else{
                        segment_code += $3->at(0)->code;
                        segment_code += $1->at(0)->code;
                        segment_code += "\tmov ax, " + $3->at(0)->symbol + "\n";
                        
                        if( $3->at(0)->getIDType() != ARRAY )
                            segment_code += "\tmov " + $1->at(0)->symbol + ", ax\n";
                        else
                            segment_code += "\tmov " + $1->at(0)->symbol + "[di], ax\n";
                        
                    }


                    $$->at(0)->code = segment_code;


                    $$->at(0)->log += "=" + $3->at(0)->log;
                    print($$->at(0)->log);

                }
                

            }
            ;


logic_expression: rel_expression
                    {
                        printLog("logic_expression: rel_expression");

                        
                        $$ = new vector<SYMBOL_INFO*>();

                        for(int i = 0; i < $1->size(); i++)
                            $$->push_back($1->at(i));
                        
                        print($$->at(0)->log);
					    
                    }
                    | rel_expression LOGICOP rel_expression
                    {
                        printLog("logic_expression: rel_expression LOGICOP rel_expression");

                        $$ = new vector<SYMBOL_INFO*>();
                        for(int i = 0; i < $1->size(); i++)
                            $$->push_back($1->at(i));
                        $$->push_back($2);
                        for(int i = 0; i < $3->size(); i++)
                            $$->push_back($3->at(i));


                        $$->at(0)->log += $2->getName() + $3->at(0)->log;
                        print($$->at(0)->log);

                        //assembly
                        string label1 = newLabel();
                        string label2 = newLabel();
                        string temp = newTemp();

                        string segment_code = "";

                        if( $2->getName() == "&&" ){
                            
                            segment_code += "\tcmp " + $1->at(0)->symbol + ", 0\n";
                            segment_code += "\tje " + label1 + "\n";
                            segment_code += "\tcmp " + $3->at(0)->symbol + ", 0\n";
                            segment_code += "\tje " + label1 + "\n";

                            segment_code += "\tmov " + temp + ", 1\n";
                            segment_code += "\tjmp " + label2 + "\n";

                            segment_code += label1 + ":\n";
                            segment_code += "\tmov " + temp + ", 0\n";
                            segment_code += label2 + ":\n";
                        }
                        else if( $2->getName() == "||" ){
                            
                            segment_code += "\tcmp " + $1->at(0)->symbol + ", 0\n";
                            segment_code += "\tjne " + label1 + "\n";
                            segment_code += "\tcmp " + $3->at(0)->symbol + ", 0\n";
                            segment_code += "\tjne " + label1 + "\n";
                            
                            segment_code += "\tmov " + temp + ", 0\n";
                            segment_code += "\tjmp " + label2 + "\n";
                            segment_code += label1 + ":\n";
                            segment_code += "\tmov " + temp + ", 1\n";
                            segment_code += label2 + ":\n";
                        }

                        $$->at(0)->code += segment_code;
                        $$->at(0)->symbol = temp;


                    }                    
                    ;




rel_expression: simple_expression
                {
                    printLog("rel_expression: simple_expression");

                    $$ = new vector<SYMBOL_INFO*>();

                    for(int i = 0; i < $1->size(); i++)
                        $$->push_back($1->at(i));
                    
                    print($$->at(0)->log);

                }
                | simple_expression RELOP simple_expression
                {
                    printLog("rel_expression: simple_expression RELOP simple_expression");

                    $$ = new vector<SYMBOL_INFO*>();

                    for(int i = 0; i < $1->size(); i++)
                        $$->push_back($1->at(i));
                    $$->push_back($2);
                    for(int i = 0; i < $3->size(); i++)
                        $$->push_back($3->at(i));

                    $$->at(0)->log += $2->getName() + $3->at(0)->log;
                    print($$->at(0)->log);

                   
                    //assembly code
                    string label1 = newLabel();
                    string label2 = newLabel();
                    string temp = newTemp();
                    string segment_code = "";    

                    segment_code += $3->at(0)->code;
                    segment_code += "\tmov ax, " + $1->at(0)->symbol + "\n";
                    segment_code += "\tcmp ax, " + $3->at(0)->symbol + "\n"; 

                     

                    if($2->getName() == ">")
                        segment_code += "\tjg " + label1 + "\n";
                    else if($2->getName() == ">=")
                        segment_code += "\tjge " + label1 + "\n";
                    else if($2->getName() == "<")
                        segment_code += "\tjl " + label1 + "\n";
                    else if($2->getName() == "<=")
                        segment_code += "\tjle " + label1 + "\n";
                    else if($2->getName() == "==")
                        segment_code += "\tje " + label1 + "\n";
                    else if($2->getName() == "!=")
                        segment_code += "\tjne " + label1 + "\n";    

                    segment_code += "\tmov " + temp + ", 0\n";
                    segment_code += "\tjmp " + label2 + "\n";
                    segment_code += label1 + ":\n";
                    segment_code += "\tmov " + temp + ", 1\n";
                    segment_code += label2 + ":\n";


                    $$->at(0)->code += segment_code;
                    $$->at(0)->symbol = temp ;                       


                }
                ;


simple_expression: term
                    {
                        printLog("simple_expression : term");                              

                        $$ = new vector<SYMBOL_INFO*>();

                        for (int i = 0; i < $1->size(); i++)
                            $$->push_back($1->at(i));
                        
                        $$->at(0)->log = $1->at(0)->log;
                        print($$->at(0)->log);

                    

                    }
                    | simple_expression ADDOP term
                    {
                        printLog("simple_expression : simple_expression ADDOP term");

                        $$ = new vector<SYMBOL_INFO*>();

                        for(int i = 0; i < $1->size(); i++)
                            $$->push_back($1->at(i));
                        
                        $$->push_back($2);

                        for(int i = 0; i < $3->size(); i++)
                            $$->push_back($3->at(i));
                        
                        $$->at(0)->log += ($2->getName() == "+" ? "+" : "-") + $3->at(0)->log;
                        
                        print($$->at(0)->log);


                        //assembly
                        string temp = newTemp();
                        string segment_code = "";

                        segment_code += $3->at(0)->code;
                        segment_code += "\tmov ax, " + $1->at(0)->symbol + "\n";

                        if( $2->getName() == "+" ) segment_code += "\tadd ax, " + $3->at(0)->symbol + "\n";
                        else segment_code += "\tsub ax, " + $3->at(0)->symbol + "\n";

                        segment_code += "\tmov " + temp + ", ax\n";
                        
                        $$->at(0)->code += segment_code;
                        $$->at(0)->symbol = temp;
                        
                    }
                    ;



term: unary_expression
    {
        printLog("term : unary_expression");       

        $$ = new vector<SYMBOL_INFO*>();

        for (int i = 0; i < $1->size(); i++)
            $$->push_back($1->at(i));

        print($$->at(0)->log);

        //SYMBOL_INFO* temp = table.Lookup($1->at(0)->getName(), "ID");
        //cout<<"in simple expression - term : "<< " symbol : " << $$->at(0)->symbol<<endl;

    }
    | term MULOP unary_expression
    {
        printLog("term : term MULOP unary_expression");

        $$ = new vector<SYMBOL_INFO*>();

        for(int i = 0; i < $1->size(); i++)
            $$->push_back($1->at(i));        
        $$->push_back($2);
        for(int i = 0; i < $3->size(); i++)
            $$->push_back($3->at(i));
        
        $$->at(0)->log += $2->getName() + $3->at(0)->log;
        print($$->at(0)->log);

        if( MULOP_operation($1, $2, $3) ){
            
            //assembly
            string temp = newTemp();
            string segment_code = "";

            segment_code += $3->at(0)->code;
            segment_code += "\tmov ax, " + $1->at(0)->symbol + "\n";
            segment_code += "\tmov bx, " + $3->at(0)->symbol + "\n";

            if($2->getName() == "*"){
				segment_code += "\tmul bx\n";
				segment_code += "\tmov " + temp + ", ax\n";
			}
				
			else if($2->getName() == "/"){
				segment_code += "\txor dx, dx\n";
				segment_code += "\tdiv bx\n";
				segment_code += "\tmov " + temp + ", ax\n";
			}
			else{   //operator % 
				segment_code += "\txor dx, dx\n";
				segment_code += "\tdiv bx\n";
				segment_code += "\tmov " + temp + ", dx\n";
			}


            $$->at(0)->code += segment_code;
            $$->at(0)->symbol = temp;             
            
        }
    }    
    ;


unary_expression: ADDOP unary_expression                
                {
                    printLog("unary_expression : ADDOP unary_expression");

                    $$ = new vector<SYMBOL_INFO*>();

                    $$->push_back($1);
                    for(int i = 0; i < $2->size(); i++)
                        $$->push_back($2->at(i));
                    $$->at(0)->log = $1->getName() + $2->at(0)->log;

                    print($$->at(0)->log);       


                    //assmebly
                    string temp = newTemp();
                    string segment_code = "";

                    segment_code += "\tmov ax, " + $2->at(0)->symbol + "\n";


                    if( $1->getName() == "-" ) segment_code += "\tneg ax\n";

                    segment_code += "\tmov " + $2->at(0)->symbol  + ", ax\n";
                    segment_code += "\tmov ax, 0\n";
                    

                    $$->at(0)->code += segment_code;
                    $$->at(0)->symbol = $2->at(0)->symbol;

                    
                }     
                | NOT unary_expression
                {
                    printLog("unary_expression : NOT unary_expression");

                    $$ = new vector<SYMBOL_INFO*>();

                    $$->push_back(new SYMBOL_INFO("!", "NOT"));
                    for(int i = 0; i < $2->size(); i++)
                        $$->push_back($2->at(i));
                    $$->at(0)->log = "!" + $2->at(0)->log;

                    print($$->at(0)->log); 


                    //assmebly
                    string temp = newTemp();
                    string label1 = newLabel();
                    string label2 = newLabel();
                    string segment_code = "";

                    segment_code += "\tmov ax, " + $2->at(0)->symbol + "\n";

                    segment_code += "\tnot ax\n";
                    segment_code += "\tmov " + $2->at(0)->symbol  + ", ax\n";
                    segment_code += "\tmov ax, 0\n";


                    $$->at(0)->code += segment_code;
                    $$->at(0)->symbol = $2->at(0)->symbol ;

                }  
                | factor
                {
                    printLog("unary_expression : factor");   

                    $$ = new vector<SYMBOL_INFO*>();

                    for (int i = 0; i < $1->size(); i++)                        
                        $$->push_back($1->at(i));
                    
                    print($$->at(0)->log);

                }     
                ;

factor: variable
        {
            printLog("factor : variable");

            $$ = new vector<SYMBOL_INFO*>();

            for( int i = 0; i < $1->size(); i++ )
                $$->push_back($1->at(i));
            
            print($$->at(0)->log);

            SYMBOL_INFO* temp = table.Lookup($1->at(0)->getName(), "ID");
            
            
            
        }
        | ID LPAREN argument_list RPAREN
        {
            printLog("factor : ID LPAREN argunment_list RPAREN");

            $$ = new vector<SYMBOL_INFO*>();

            SYMBOL_INFO *temp = table.Lookup($1->getName(), "ID"); 

            int n = $3->size();

           
           
            if( temp == nullptr ) {
                printError( "Function " + $1->getName() + " doesn't exist");
                syntaxError++;
            }
            else if( temp->getIDType() != FUNCTION ){
                printError( temp->getName() + " is not a function ");
                syntaxError++;
            }

            

            //assembly
            string temp_var = newTemp();
            string segment_code = "";
            vector<string> pushed_var;


            vector<string> param_type;       
            //getting parameter
            
                for( int i = 0; i < $3->size(); i++ ){
               
                    if( $3->at(i)->getType() == "ID" ){
                        
                        SYMBOL_INFO* tempVar = table.Lookup($3->at(i)->getName(), "ID");
                                
                        if( tempVar != nullptr ) {
                            param_type.push_back(tempVar->getVarType());  

                            //assembly code
                            pushed_var.push_back( tempVar->symbol );
                            segment_code += "\tpush " + tempVar->symbol + "\n";                  
                        }                    
                    }

                    else if($3->at(i)->getType() == "CONST_INT"){

                        if( i != 0 ){
                            if( $3->at(i-1)->getName() != "[" && $3->at(i-1)->getName() == "," )
                                    param_type.push_back("INT");						
                        }
                        else{
                            param_type.push_back("INT");
                        }
                    }

                    else if($3->at(i)->getType() == "CONST_FLOAT"){
                        param_type.push_back("FLOAT");					
                    }

                } //end of getting parameter
            


            if( param_type.size() != temp->paramList_type.size() ){
                printError("number of parameter for " + $1->getName() + " mismatch");
                syntaxError++;
            }
            else{
                for( int i = 0; i < temp->paramList_type.size(); i++ ){
                    if( param_type.at(i) != temp->paramList_type.at(i) ){
                        printError( (i+1) + "th parameter mismatch");
                        syntaxError++;
                    }
                }
            }
            
            

            //assembly
            int param_count = 0;
            for( int i = 0; i < $3->size(); i++ ){
                if( $3->at(i)->getType() == "ID" ){

                    segment_code += "\tmov ax, " + (table.Lookup($3->at(i)->getName(), "ID"))->symbol + "\n";
                    segment_code += "\tmov " + temp->paramList_name.at(param_count) + ", ax\n";
                    param_count++;
                }
            }

            

            segment_code += "\tcall " + $1->getName() + "\n";
			segment_code += "\tmov ax, ret_temp\n";
			segment_code += "\tmov " + temp_var + ", ax\n";

			for(int i = pushed_var.size()-1; i >= 0; i--)
				segment_code += "\tpop " + pushed_var.at(i) + "\n";

            
            //end of assembly

            $$->push_back($1);
            $$->push_back($2);
            for (int i = 0; i < $3->size(); i++)
	 		    $$->push_back($3->at(i));
            
		    $$->push_back($4);

            $$->at(0)->log = $1->getName() + "(" + ( ($3->size() == 0) ? "" : $3->at(0)->log ) + ")";
            print($$->at(0)->log);

            //assembly
            $$->at(0)->code += segment_code;
		    $$->at(0)->symbol = temp_var;


        }
        | LPAREN expression RPAREN
        {
            printLog("factor : LPAREN expression RPAREN");
            
            $$ = new vector<SYMBOL_INFO*>();

		    $$->push_back($1);
            for (int i = 0; i < $2->size(); i++)
	 		    $$->push_back($2->at(i));
            $$->push_back($3);

            $$->at(0)->log = "(" + $2->at(0)->log + ")";
            print($$->at(0)->log);

            //assembly code
            $$->at(0)->symbol = $2->at(0)->symbol;
            $$->at(0)->code += $2->at(0)->code;
            
        }
        | CONST_INT
        {
            printLog("factor : CONST_INT");

            $$ = new vector<SYMBOL_INFO*>();

            $1->setVarType(INT_TYPE);        
            $1->setIDType(VARIABLE);

            $$->push_back($1);
            $$->at(0)->log = $1->getName();
            print($$->at(0)->log);

            //assembly
            $$->at(0)->symbol = $1->getName();  
            $$->at(0)->code = "";    
			
        }
        | CONST_FLOAT
        {
            printLog("factor : CONST_FLOAT");           

            $$ = new vector<SYMBOL_INFO*>();
            

            $1->setVarType(FLOAT_TYPE);        
            $1->setIDType(VARIABLE);

            $$->push_back($1);
            $$->at(0)->log = $1->getName();
            print($$->at(0)->log);

            //assembly
            $$->at(0)->symbol = $1->getName(); 
            $$->at(0)->code = ""; 

        }
        | CONST_CHAR
        {
            printLog("factor : CONST_CHAR");
            
            $$ = new vector<SYMBOL_INFO*>();

            $1->setVarType(CHAR_TYPE);        
            $1->setIDType(VARIABLE);

            $$->push_back($1);
            $$->at(0)->log = $1->getName();
            print($$->at(0)->log);

            //assembly
            $$->at(0)->symbol = $1->getName();
            $$->at(0)->code = ""; 

        }
        | variable INCOP
        {
            printLog("factor : variable INCOP");

			$$ = new vector<SYMBOL_INFO*>();

            for (int i = 0; i < $1->size(); i++)
                $$->push_back($1->at(i));
  		    $$->push_back(new SYMBOL_INFO("++", "INCOP"));

            $$->at(0)->log = $1->at(0)->log + "++";
            print($$->at(0)->log);



            //assembly code
            string temp = newTemp();
            string segment_code = "";

            SYMBOL_INFO* tempID = table.Lookup($1->at(0)->getName(), "ID");

            if( tempID->getIDType() == ARRAY ){
                


                segment_code += "\tmov ax, " + $1->at(0)->symbol + "[di]\n";
                segment_code += "\tmov " + temp + ", ax\n";
                segment_code += "\tinc " + $1->at(0)->symbol + "[di]\n";
            }
            else if( tempID->getIDType() != ARRAY ){

                

                segment_code += "\tmov ax, " + $1->at(0)->symbol + "\n";
                segment_code += "\tmov " + temp + ", ax\n"; //kahini ki? <-----
                segment_code += "\tinc " + $1->at(0)->symbol + "\n";
            }
        
            $$->at(0)->symbol = tempID->symbol;
		    $$->at(0)->code += segment_code;

        }
        | variable DECOP
        {
            
            printLog("factor : variable DECOP");

            $$ = new vector<SYMBOL_INFO*>();

			for (int i = 0; i < $1->size(); i++)
                $$->push_back($1->at(i));
  		    $$->push_back(new SYMBOL_INFO("--", "DECOP"));

            $$->at(0)->log = $1->at(0)->log + "--";
            print($$->at(0)->log);




            //assembly code
            string temp = newTemp();
            string segment_code = "";

            SYMBOL_INFO* tempID = table.Lookup($1->at(0)->getName(), "ID");

            if( tempID->getIDType() == ARRAY ){
                
                segment_code += "\tmov ax, " + $1->at(0)->symbol + "[di]\n";
                segment_code += "\tmov " + temp + ", ax\n";
                segment_code += "\tdec " + $1->at(0)->symbol + "[di]\n";
            }
            else if( tempID->getIDType() != ARRAY ){
                segment_code += "\tmov ax, " + $1->at(0)->symbol + "\n";
                segment_code += "\tmov " + temp + ", ax\n";
                segment_code += "\tdec " + $1->at(0)->symbol + "\n";
            }
        
            //$$->at(0)->symbol = tempID->symbol;
            $$->at(0)->symbol = temp;
		    $$->at(0)->code = $$->at(0)->code + segment_code;
        }
        ;

argument_list: arguments
            {
                printLog("argument_list: arguments");

                $$ = new vector<SYMBOL_INFO*>();

                for(int i = 0; i < $1->size(); i++)
                    $$->push_back($1->at(i));
                
                print($$->at(0)->log);
            }
			|
            {
                $$ = new vector<SYMBOL_INFO*>();
                
                printLog("argument_list: ");
            }
			;

arguments: arguments COMMA logic_expression 
        {
            printLog("arguments: arguments COMMA logic_expression ");

            $$ = new vector<SYMBOL_INFO*>();

            for (int i = 0; i < $1->size(); i++)
		 		$$->push_back($1->at(i));
            
            $$->push_back($2);

            for (int i = 0; i < $3->size(); i++)
		 		$$->push_back($3->at(i));     

            $$->at(0)->log += "," + $3->at(0)->log;
            print($$->at(0)->log);      

            
        }
		| logic_expression
        {
            printLog("arguments: logic_expression");

            $$ = new vector<SYMBOL_INFO*>();

            for (int i = 0; i < $1->size(); i++)
		 		$$->push_back($1->at(i));
	  		
            print($$->at(0)->log);
            
        }
		;





%%

int main(int argc, char *argv[]){

    if((yyin=fopen(argv[1],"r"))==NULL)
	{
		cout<<"Can't open input file"<<endl;
		exit(1);
	}

    logOut.open("log.txt");
    errorOut.open("error.txt");
    codeOut.open("code.asm");

    yyparse();

    logOut << endl << endl;

    logOut<<"Total Lines : "<< lineCount <<endl<<endl;
    logOut<<"Total Errors : "<< syntaxError + lexError << endl;


    table.Print_All_ScopeTable(logOut);

    errorOut<<"Total Syntax Errors : "<< syntaxError << endl << endl;
    errorOut<<"Total Lexical Errors : "<< lexError << endl << endl;


    op_codeOut.open("op_code.asm");
    optimize_code(final_code);


    logOut.close();
    errorOut.close();
    codeOut.close();
    op_codeOut.close();

    return 0;

}