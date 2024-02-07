#include "symbol_table.h"
#include "y.tab.h" 

extern ofstream errorOut;


long long lineCount = 1, lexError = 0;





void print_LexError(string msg, ofstream &errorOut ){
	errorOut<<"Lexical Error @ Line No. "<<lineCount<<": "<<msg<<" : "<<yytext<<endl<<endl;

	lexError++;
	
}

void print_LexError(string msg) {
	print_LexError(msg, errorOut);	
}

void assignSymbol(const string& name,const string& type) {

	SYMBOL_INFO* temp = new SYMBOL_INFO(name,type);
	yylval.symbol = temp;
}

void assignSymbol(const string& type) {
	assignSymbol(yytext, type);
}







void add_IDENTIFIER_Token(){
	string token_name = "ID";
	assignSymbol(token_name);
}

void add_CONST_INT_Token(){
	string tokenName = "CONST_INT";
	assignSymbol(tokenName);
}

void add_CONST_FLOAT_Token(){
	string tokenName = "CONST_FLOAT";
	assignSymbol(tokenName);
}


void add_CONST_CHAR_Token(string str){
	string tokenName = "CONST_CHAR";

	string content = "";
	if( str.length()==3 ){		
		for( int i = 1; i<str.length()-1; i++ ) content += str[i];
	}
	else content = str;	

	assignSymbol(content, tokenName);

}

void add_OPERATOR_Token(string tokenName){

	assignSymbol(tokenName);
}


void add_STRING_Token(string str){
	string tokenName = "STRING";

	string content = "";

	for( int i = 0; i<str.length(); i++ ){
		if( str[i] == '\\' && (str[i+1] != 'n' && str[i+1] != 't') ){
			i++;
			i++;
			lineCount++;
		}
		else if( str[i] == '\\' && str[i+1] == 'n' ) {content += '\n'; i++; }
		else if( str[i] == '\\' && str[i+1] == 't' ) {content += '\t'; i++; }
		else content += str[i];
	}

	assignSymbol(content, tokenName);

}

void comment_handle(string str){

	for(int i = 0; i<str.length(); i++ )
	{
		if( str[i] == '\n') lineCount++;
	}
}

void unfinished_handle(string str, bool fromString = true){

	for(int i = 0; i<str.length(); i++ )
	{
		if( str[i] == '\n') lineCount++;
	}

	if( !fromString )print_LexError("Unfinished star comment");
	else print_LexError("Unfinished string");
	
}
