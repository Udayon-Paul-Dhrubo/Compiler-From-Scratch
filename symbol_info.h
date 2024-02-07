#include<bits/stdc++.h>


#define ARRAY "ARR"
#define VARIABLE "VAR"
#define FUNCTION "FUNC"
#define INT_TYPE "INT"
#define FLOAT_TYPE "FLOAT"
#define VOID_TYPE "VOID"
#define CHAR_TYPE "CHAR"

using namespace std;

class SYMBOL_INFO {
private:
    string Name;
    string Type;

    string idType; // for function, variable, array
    string varType; // int, float, void type

    string funcReturnType; // int, float, void type
    bool funcDefined = false;

    long long AraSize;
    long long AraIndex;


    

public:
    SYMBOL_INFO* next;

    vector<string> paramList_type; //INT, FLOAT, STRING, CHAR
    vector<string> paramList_name;    
	
    string symbol = "";
    string code = "";
    string log = "";


    SYMBOL_INFO(){
        next = nullptr;
    }

    SYMBOL_INFO( string _type){
        varType = _type;        
        next = nullptr;
    }
    SYMBOL_INFO( string _name, string _type ){
        Name = _name;
        Type = _type;
        next = nullptr;
    }



    void setName( string _name ) { Name = _name; }
    void setType( string _type ) { Type = _type; }
    void setIDType( string _idType ) { idType = _idType; }    
    void setFuncRetType( string _funcRetType ) { funcReturnType = _funcRetType; }
    void setAraSize(long long n) { AraSize = n; }
    void setAraIndex(long long n) { AraIndex = n; }
    void setFuncDefined(bool state ) { funcDefined = state; }    
    void setVarType( string _varType ) { varType = _varType; }

    string getName() { return Name; }
    string getType() { return Type; }
    string getIDType() { return idType; }
    string getVarType() { return varType; }
    string getFuncRetType() { return funcReturnType; }
    bool getFuncDefined() { return funcDefined; }
    long long getAraSize() { return AraSize; }
    long long getAraIndex() { return AraIndex; }

    bool isFuncDefined() { return funcDefined; }

    bool isFunction() const { return idType == FUNCTION; }//type == "ID" &&

	bool isArrayVar() const { return idType == ARRAY; }//type == "ID" &&

	bool isVariable() const { return idType == VARIABLE; } //type == "ID" &&

	bool isVoidFunc() const { return ( isFunction() && funcReturnType == VOID_TYPE) ; }

    ~SYMBOL_INFO() { next = nullptr; }
};



