
#include "symbol_table.h"


ofstream logOut, errorOut, codeOut, op_codeOut;
ifstream read_code;

SYMBOL_TABLE table(7);

long long syntaxError = 0;


extern long long lineCount, lexError;
extern FILE *yyin;
extern char *yytext;


string variable_type;
string initial_code = "";
string final_code = "";
vector<pair<string, string>> data_list;


int temp_variable_count = 0;
int label_count = 0;



bool funcDef = false;

bool includeMain = false;

int yyparse(void);

int yylex(void);


string newTemp(){
	string temp_variable  = "t" + to_string(temp_variable_count);
	temp_variable_count++;
	data_list.push_back({temp_variable,"0"});
	return temp_variable;
}

string newLabel(){
	string label  = "l" + to_string(label_count);
	label_count++;
	return label;
}

string makeScopeID(string id){
	string x = ".";
	string y = "_";
	size_t pos;
	while ((pos = id.find(x)) != std::string::npos) {
        id.replace(pos, 1, y);
    }
	return id;
}

string createSymbol(string _name){
    string symbol = _name + "_" + table.getCurrentID();
    return makeScopeID(symbol);
}





void yyerror(const char *s)
{
	//write your code
}

void printLog(string str)
{
    logOut << "Line No. " << lineCount << " : " << str << endl<< endl;
}

void printError(string str)
{
    errorOut << "Syntax Error @ Line No. " << lineCount << ": " << str << " : " << endl << endl;    
}

void print(string str){
    logOut << str << endl << endl;
}


bool MULOP_operation(vector<SYMBOL_INFO*>* s1, SYMBOL_INFO *s2, vector<SYMBOL_INFO*>* s3)
{
    if( s2->getName() == "%" ){
        if(s1->size() == 1 && s3->size() == 1){
            if(s3->at(0)->getType() != "CONST_INT"){
                print("Non-Integer operand on modulus operator");            
                syntaxError++;
                return false;
            }
            else if(s3->at(0)->getName() == "0"){
                print("Modulus by Zero");
                syntaxError++;
                return false;
            }
        }
    }
    else if( s2->getName() == "/" ){
        if(s1->size() == 1 && s3->size() == 1){
            if(s3->at(0)->getName() == "0"){
                print("Divide by Zero");
                syntaxError++;
                return false;            
            }
         }
    }

    return true;
}

SYMBOL_INFO *ADD_operation(SYMBOL_INFO *s1, SYMBOL_INFO *s2, SYMBOL_INFO *s3){

    SYMBOL_INFO *temp = nullptr;

    string id1 = s1->getIDType();
    string id2 = s3->getIDType();

    string var1 = s1->getVarType();
    string var2 = s3->getVarType();


    

    if (s1->getIDType() == VARIABLE && s3->getIDType() == VARIABLE)
    {

        if (s1->getVarType() == INT_TYPE && s3->getVarType() == INT_TYPE)
        {

            temp = new SYMBOL_INFO(INT_TYPE);
            temp->setIDType(VARIABLE);

            //logOut<<" intData 1 = "<<s1->intData[0]<< " intData 2 = "<<s3->intData[0]<<endl<<endl;

            //temp->intData[0] = s1->intData[0] + s3->intData[0];
        }
        else
        {

            temp = new SYMBOL_INFO(FLOAT_TYPE);
            temp->setIDType(VARIABLE);

           //temp->floatData[0] = (s1->getVarType() == INT_TYPE ? s1->intData[0] : s1->floatData[0]) +
                                 //(s3->getVarType() == INT_TYPE ? s3->intData[0] : s3->floatData[0]);
        }
    }

    else if (s1->getIDType() == VARIABLE && s3->getIDType() == ARRAY)
    {

        if (s1->getVarType() == INT_TYPE && s3->getVarType() == INT_TYPE)
        {

            temp = new SYMBOL_INFO(INT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->intData[0] = s1->intData[0] + s3->intData[s3->getAraIndex()];
        }
        else
        {

            temp = new SYMBOL_INFO(FLOAT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->floatData[0] = (s1->getVarType() == INT_TYPE ? s1->intData[0] : s1->floatData[0]) +
                                 //(s3->getVarType() == INT_TYPE ? s3->intData[s3->getAraIndex()] : s3->floatData[s3->getAraIndex()]);
        }
    }

    else if (s1->getIDType() == ARRAY && s3->getIDType() == VARIABLE)
    {

        if (s1->getVarType() == INT_TYPE && s3->getVarType() == INT_TYPE)
        {

            temp = new SYMBOL_INFO(INT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->intData[0] = s1->intData[s1->getAraIndex()] + s3->intData[0];
        }
        else
        {

            temp = new SYMBOL_INFO(FLOAT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->floatData[0] = (s1->getVarType() == INT_TYPE ? s1->intData[s1->getAraIndex()] : s1->floatData[s1->getAraIndex()]) +
                                 //(s3->getVarType() == INT_TYPE ? s3->intData[0] : s3->floatData[0]);
        }
    }

    else if (s1->getIDType() == ARRAY && s3->getIDType() == ARRAY)
    {

        if (s1->getVarType() == INT_TYPE && s3->getVarType() == INT_TYPE)
        {

            temp = new SYMBOL_INFO(INT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->intData[0] = s1->intData[s1->getAraIndex()] + s3->intData[s3->getAraIndex()];
        }
        else
        {

            temp = new SYMBOL_INFO(FLOAT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->floatData[0] = (s1->getVarType() == INT_TYPE ? s1->intData[s1->getAraIndex()] : s1->floatData[s1->getAraIndex()]) +
                                 //(s3->getVarType() == INT_TYPE ? s3->intData[s3->getAraIndex()] : s3->floatData[s3->getAraIndex()]);
        }
    }

    return temp;
}

SYMBOL_INFO *MINUS_operation(SYMBOL_INFO *s1, SYMBOL_INFO *s2, SYMBOL_INFO *s3){

    SYMBOL_INFO *temp = nullptr;

    string id1 = s1->getIDType();
    string id2 = s3->getIDType();

    string var1 = s1->getVarType();
    string var2 = s3->getVarType();

    

    if (s1->getIDType() == VARIABLE && s3->getIDType() == VARIABLE)
    {

        if (s1->getVarType() == INT_TYPE && s3->getVarType() == INT_TYPE)
        {

            temp = new SYMBOL_INFO(INT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->intData[0] = s1->intData[0] - s3->intData[0];
        }
        else
        {

            temp = new SYMBOL_INFO(FLOAT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->floatData[0] = (s1->getVarType() == INT_TYPE ? s1->intData[0] : s1->floatData[0]) -
                                 //(s3->getVarType() == INT_TYPE ? s3->intData[0] : s3->floatData[0]);
        }
    }

    else if (s1->getIDType() == VARIABLE && s3->getIDType() == ARRAY)
    {

        if (s1->getVarType() == INT_TYPE && s3->getVarType() == INT_TYPE)
        {

            temp = new SYMBOL_INFO(INT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->intData[0] = s1->intData[0] - s3->intData[s3->getAraIndex()];
        }
        else
        {

            temp = new SYMBOL_INFO(FLOAT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->floatData[0] = (s1->getVarType() == INT_TYPE ? s1->intData[0] : s1->floatData[0]) -
            //                     (s3->getVarType() == INT_TYPE ? s3->intData[s3->getAraIndex()] : s3->floatData[s3->getAraIndex()]);
        }
    }

    else if (s1->getIDType() == ARRAY && s3->getIDType() == VARIABLE)
    {

        if (s1->getVarType() == INT_TYPE && s3->getVarType() == INT_TYPE)
        {

            temp = new SYMBOL_INFO(INT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->intData[0] = s1->intData[s1->getAraIndex()] - s3->intData[0];
        }
        else
        {

            temp = new SYMBOL_INFO(FLOAT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->floatData[0] = (s1->getVarType() == INT_TYPE ? s1->intData[s1->getAraIndex()] : s1->floatData[s1->getAraIndex()]) -
             //                    (s3->getVarType() == INT_TYPE ? s3->intData[0] : s3->floatData[0]);
        }
    }

    else if (s1->getIDType() == ARRAY && s3->getIDType() == ARRAY)
    {

        if (s1->getVarType() == INT_TYPE && s3->getVarType() == INT_TYPE)
        {

            temp = new SYMBOL_INFO(INT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->intData[0] = s1->intData[s1->getAraIndex()] - s3->intData[s3->getAraIndex()];
        }
        else
        {

            temp = new SYMBOL_INFO(FLOAT_TYPE);
            temp->setIDType(VARIABLE);

            //temp->floatData[0] = (s1->getVarType() == INT_TYPE ? s1->intData[s1->getAraIndex()] : s1->floatData[s1->getAraIndex()]) -
             //                    (s3->getVarType() == INT_TYPE ? s3->intData[s3->getAraIndex()] : s3->floatData[s3->getAraIndex()]);
        }
    }

    return temp;

}

SYMBOL_INFO *RELATION_operation(SYMBOL_INFO *s1, SYMBOL_INFO *s2, SYMBOL_INFO *s3){

    string relOp = s2->getName();

    SYMBOL_INFO* temp = new SYMBOL_INFO(INT_TYPE);
    
    string type1 = s1->getVarType();
    string type2 = s3->getVarType();


    if( type1 != type2 && relOp == "="){
        
            printError("Type mismatched for " + relOp +  " operand");
            syntaxError++;
            return temp;
    }

    temp->setIDType(VARIABLE);

    /*    if( relOp == "==" ){


        if( type1 != type2 ){
            printError("Type mismatched for == operand");
            syntaxError++;
            return temp;
        }   

        temp->intData[0] =  (   ( type1 == INT_TYPE ? s1->intData[0] : s1->floatData[0] ) ==
                                ( type2 == INT_TYPE ? s3->intData[0] : s3->floatData[0] ) ? 1:0
                            );     

        
    }

    else if( relOp == "!=" ){

        if( type1 != type2 ){
            printError("Type mismatched for != operand");
            syntaxError++;
            return temp;
        }
        

        temp->intData[0] =  (   ( type1 == INT_TYPE ? s1->intData[0] : s1->floatData[0] ) !=
                                ( type2 == INT_TYPE ? s3->intData[0] : s3->floatData[0] ) ? 1:0
                            );
    }

    else if( relOp == "<=" ){
        
        temp->intData[0] =  (   ( type1 == INT_TYPE ? s1->intData[0] : s1->floatData[0] ) <=
                                ( type2 == INT_TYPE ? s3->intData[0] : s3->floatData[0] ) ? 1:0
                            );
        
    }

    else if( relOp == "<" ){
        
        temp->intData[0] =  (   ( type1 == INT_TYPE ? s1->intData[0] : s1->floatData[0] ) <
                                ( type2 == INT_TYPE ? s3->intData[0] : s3->floatData[0] ) ? 1:0
                            );
        
    }

    else if( relOp == ">=" ){
        
        temp->intData[0] =  (   ( type1 == INT_TYPE ? s1->intData[0] : s1->floatData[0] ) >=
                                ( type2 == INT_TYPE ? s3->intData[0] : s3->floatData[0] ) ? 1:0
                            );
        
    }

    else if( relOp == ">" ){
        
        temp->intData[0] =  (   ( type1 == INT_TYPE ? s1->intData[0] : s1->floatData[0] ) >
                                ( type2 == INT_TYPE ? s3->intData[0] : s3->floatData[0] ) ? 1:0
                            );
        
    }*/

    return temp;


}


SYMBOL_INFO *LOGIC_operation(SYMBOL_INFO *s1, SYMBOL_INFO *s2, SYMBOL_INFO *s3){

    SYMBOL_INFO* temp = new SYMBOL_INFO(INT_TYPE);

    string logicOp = s2->getName();
    string type1 = s1->getVarType();
    string type2 = s3->getVarType();



    if( type1 == INT_TYPE && type2 == INT_TYPE ){
        temp->setIDType(VARIABLE);
        return temp;
    }

    printError("Logical operation allowed only for int type");
    syntaxError++;

    return nullptr;


    /*

    if( type1 == CHAR_TYPE || type2 == CHAR_TYPE ){
        printError("Logical operation not allowed for char datatype");
        syntaxError++;
        return temp;
    }


    s1->getVarType() == INT_TYPE ? s1->intData.push_back(0) : s1->floatData.push_back(0);

    s3->getVarType() == INT_TYPE ? s3->intData.push_back(0) : s3->floatData.push_back(0);


    if( logicOp == "&&" ){    

        if( ( s1->getVarType() == INT_TYPE ? s1->intData[0] : s1->floatData[0] ) == 0 )
            temp->intData[0] = 0;
        
        else if( ( s3->getVarType() == INT_TYPE ? s3->intData[0] : s3->floatData[0] ) == 0 )
            temp->intData[0] = 0;
        
        else 
            temp->intData[0] = 1;

    }


    else if( logicOp == "||" ){

        if( ( s1->getVarType() == INT_TYPE ? s1->intData[0] : s1->floatData[0] ) != 0 )
            temp->intData[0] = 1;
        
        else if( ( s3->getVarType() == INT_TYPE ? s3->intData[0] : s3->floatData[0] ) != 0 )
            temp->intData[0] = 1;
        
        else 
            temp->intData[0] = 0;

    }*/


    return temp;
    
}


bool ASSIGN_operation(vector<SYMBOL_INFO*>* s1, vector<SYMBOL_INFO*>* s3){

    for(int i = 0; i < s3->size(); i++){  //  void function in expression
           
        if(s3->at(i)->getType() == "ID" && table.Lookup(s3->at(i)->getName(), "ID") != nullptr){
            
            SYMBOL_INFO* temp = table.Lookup(s3->at(i)->getName(), "ID");

            if( temp->getIDType() == FUNCTION && temp->getVarType() == VOID_TYPE ){
                printError("void type found in expression");
                syntaxError++;
                return false;
            }
        }
    }

    SYMBOL_INFO* temp = table.Lookup(s1->at(0)->getName(), "ID");
    if( temp!= nullptr ){
        
        for(int i = 0; i < s3->size(); i++){
            if( s3->at(i)->getType() == "CONST_FLOAT" && s1->at(0)->getVarType() == INT_TYPE ){
                printError("type mismatch");
                syntaxError++;
                return false;
            }
        }

    }

    return true;

}


SYMBOL_INFO* push( SYMBOL_INFO* s1, string type, int size = 0 ) {

    SYMBOL_INFO* temp2 = nullptr;


    if( variable_type == VOID_TYPE ){
        printError("variable type can't be VOID");
        syntaxError++;
    }
    else{        

        if( table.Insert(s1->getName(), s1->getType()) ){      
            
            temp2 =  table.Lookup(s1->getName(), s1->getType());           

            temp2->setVarType(variable_type);            

            if( type == "variable" ) temp2->setIDType(VARIABLE);
            else if( type == "array" ) {
                temp2->setIDType(ARRAY);
                temp2->setAraSize(size);
            }

        }
        else{
            printError( type + " " + s1->getName() + " already exists");
            syntaxError++;
        }  
    
    }

    return temp2;

}


bool Func_definition_operation( SYMBOL_INFO* s1, SYMBOL_INFO* s2, vector<SYMBOL_INFO*>* s4 ) {


    vector<string> paramList;
    vector<string> paramType;


    for( int i = 0; i < s4->size(); i++ ){
        
        if( s4->at(i)->getType() == INT_TYPE || s4->at(i)->getType() == FLOAT_TYPE  || s4->at(i)->getType() == CHAR_TYPE ){
            paramType.push_back(s4->at(i)->getType());
        }
        else if( s4->at(i)->getType() == "ID" ){
            paramList.push_back(s4->at(i)->getName());

            for( int j = 0; j < paramList.size()-1; j++ ){
                if( s4->at(i)->getName() == paramList.at(j) ){
                    paramList.pop_back();
                    printError("Multiple definition of " + paramList.at(j) + " in parameter list");
                    syntaxError++;
                    return false;
                }
            }
        }
    }

    SYMBOL_INFO* temp = table.Lookup(s2->getName(), s2->getType());

    if( temp != nullptr ){

        if( temp->getIDType() != FUNCTION ){
            printError("multiple definition of " + temp->getName() );
            syntaxError++;
            return false;
        }

        else if( temp->isFuncDefined() ){
            
            printError("function " + s2->getName() + " multiple definition.");
            syntaxError++;       
            return false;
        }

        else if( temp->getFuncRetType() != s1->getType() ){
            printError("function " + s2->getName() + " return type doesn't match");
            syntaxError++;           
            return false;
        }

        else if( temp->paramList_type.size() != paramType.size() ) {
            printError("function " + s2->getName() + " parameter list doesn't match");
            syntaxError++;           
            return false;
        }
        
        for( int i = 0; i < temp->paramList_type.size(); i++ ){
            if( paramType.at(i) != temp->paramList_type.at(i) ){
                printError(i+1 + "th argument mismatch in the parameter list");
                syntaxError++;
                return false;
            }
        }


    }

    return true;
}

vector<string> tokenize(string str, char delim, bool comma = false)
{
    vector<string> ret;

    size_t start;
    size_t end = 0;

    while ((start = str.find_first_not_of(delim, end)) != string::npos)
    {
        end = str.find(delim, start);
        string arr = str.substr(start, end - start);

        string temp = "";

        if(delim != '\n'){
            int i = 0;
            for(char ch : arr){
                if( ch == '\t' || ch == ',' ) {}
                else temp += arr.at(i);
                i++;
            }      
            ret.push_back(temp);
        }
        else ret.push_back(arr);
        
    }
    return ret;
}

void optimize_code(string code)
{
    vector<string>codes  = tokenize(code, '\n');
    int n = codes.size();

    vector<string>prev_line_token;
    string prev_line_cmd = "";

    for( int i = 0;i < n; i++ ){

        string cur_line = codes[i];

        if( cur_line.size() == 0 ) continue;

        vector<string>cur_line_token = tokenize(cur_line,' ', true );               

        if( cur_line_token.at(0) == "mov") {

            if( prev_line_cmd == "mov" ){
                
                if( i > 0 ){

                    if( cur_line_token[1] == prev_line_token[2] && cur_line_token[2] == prev_line_token[1] ) { /* optimize */ }
                    else op_codeOut << cur_line << endl;
                }
                else op_codeOut << cur_line << endl;
                
            }
            else op_codeOut << cur_line << endl;

            prev_line_token = cur_line_token;

        }
        else{
            op_codeOut << cur_line << endl;
            prev_line_token.clear();
            
        }

        prev_line_cmd = cur_line_token.at(0);         
  
    }
}
