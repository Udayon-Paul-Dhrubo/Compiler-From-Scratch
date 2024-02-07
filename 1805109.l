%option noyywrap

%{

#include"LexBase.h"

using namespace std;

%}

EXCEPT_NEWLINE [^\r\n]

NEWLINE [\r\n]

WHITESPACE [ \t\f\r\v]+

LETTER [_a-zA-Z]
DIGIT [0-9]
DIGITS {DIGIT}+



IDENTIFIER {LETTER}({LETTER}|{DIGIT})*
NOT_IDENTIFIER {DIGIT}({LETTER}|{DIGIT})*


INTEGER {DIGITS}
FLOATING_POINT {DIGIT}*?(\.?{DIGITS})([eE][+-]?{DIGITS})?
TOO_DECIMAL {DIGIT}*((\.)+{DIGIT}*)+([eE][+-]?{DIGITS})?
ILL_NUM {DIGIT}*?(\.?{DIGITS})[eE]+{FLOATING_POINT}

SPECIAL_CHAR \\[nt\'\\afrbv0]
SPECIAL_CHARACTER \'{SPECIAL_CHAR}\'

CHAR [^\;\'\\\n\"]
CHARACTER \'{CHAR}\'
EMPTY_CHAR \'\'
ILL_CHAR \'{CHAR}{2,}\'
UNFINISHED_CHAR \'({CHAR}|{SPECIAL_CHAR}|"")

CHAR_STREAM	{CHAR}|{SPECIAL_CHAR}
STRING (\")({CHAR_STREAM}|(\\+{NEWLINE}))*(\")
UNFINISHED_STRING (\")({CHAR_STREAM}|(\\+{NEWLINE}))*

TEMP [^\n\\]
TEMP_STREAM {TEMP}*(\\[\n\r]?{TEMP}*)*
SINGLELINE_COMMENT "//"{TEMP_STREAM}



START "/*"
END "*/"
NOT_STAR [^\*]

UNFINISHED_STAR_COMMENT {START}({NOT_STAR}|([\*]+[^*/]))*
STAR_COMMENT {UNFINISHED_STAR_COMMENT}[\*]*{END}


ANYTHING ({EXCEPT_NEWLINE}|{NEWLINE})



%%
{NEWLINE} 						{ lineCount++; }

{WHITESPACE} 					{}


{INTEGER}						{ 
									add_CONST_INT_Token(); 
									return CONST_INT;
								}
								
{FLOATING_POINT}				{ 
									add_CONST_FLOAT_Token();
									return CONST_FLOAT;
								}

{TOO_DECIMAL}					{
									print_LexError("Too many decimal point in");
									assignSymbol(yytext, "CONST_FLOAT");
									return CONST_FLOAT;
								}

{ILL_NUM}						{ 
									print_LexError("Ill formed number");
									assignSymbol("0","CONST_FLOAT");
									return CONST_FLOAT;
							    }



{SPECIAL_CHARACTER}				{ 
									add_CONST_CHAR_Token(yytext);
									return CONST_CHAR;
								}

{CHARACTER}						{ 
									add_CONST_CHAR_Token(yytext); 
									return CONST_CHAR;
								}

{EMPTY_CHAR}					{ 
									print_LexError("Empty char"); 
									assignSymbol("\0","CONST_CHAR");
									return CONST_CHAR;
								}

{UNFINISHED_CHAR}				{ 
									print_LexError("Unfinished char"); 
									assignSymbol("\0","CONST_CHAR");
									return CONST_CHAR;
								}

{ILL_CHAR} 						{ 
									print_LexError("Ill char"); 
									assignSymbol("\0","CONST_CHAR");
									return CONST_CHAR;
								}


"if"							{	return IF; }
"else"							{	return ELSE; }
"for"							{	return FOR; }
"while"							{	return WHILE; }
"switch" 						{	return SWITCH; }
"case"							{	return CASE; }
"default"						{	return DEFAULT; }
"do"							{	return DO; }
"break"							{	return BREAK; }
"continue"						{	return CONTINUE; }
"int"							{	return INT; }
"float"							{	return FLOAT; }
"double"						{	return DOUBLE; }
"char"							{	return CHAR; }
"void"							{	return VOID; }
"return"						{	return RETURN; }
"println"						{	return PRINTLN; }




("+"|"-")						{	
									add_OPERATOR_Token("ADDOP");
									return ADDOP;
								}

("*"|"/"|"%")					{	
									add_OPERATOR_Token("MULOP");
									return MULOP;
								}

("&&"|"||")             		{	
									add_OPERATOR_Token("LOGICOP");
									return LOGICOP;
								}

("<="|">="|"=="|"!="|"<"|">") 	{	
									add_OPERATOR_Token("RELOP");
									return RELOP;
								}

("&"|"|"|"^"|"<<"|">>") 		{	
									add_OPERATOR_Token("BITOP");
									return BITOP;
								}


"++"							{	 return INCOP; }
"--"							{	 return DECOP; }
("=")							{	 return ASSIGNOP; }
"!"								{	 return NOT; }
"("								{	assignSymbol("LPAREN"); return LPAREN; }
")"								{	assignSymbol("RPAREN"); return RPAREN; }
"{"								{	assignSymbol("LCURL"); return LCURL; }
"}"								{	assignSymbol("RCURL"); return RCURL; }								
"["								{	assignSymbol("LTHIRD"); return LTHIRD; }
"]"								{	assignSymbol("RTHIRD"); return RTHIRD; }
","								{	assignSymbol("COMMA"); return COMMA; }
";"								{	return SEMICOLON; }


{SINGLELINE_COMMENT}			{ comment_handle(yytext); }

{STAR_COMMENT}					{ comment_handle(yytext); }
{UNFINISHED_STAR_COMMENT}		{ unfinished_handle(yytext); }

{STRING}						{ 
									add_STRING_Token(yytext);
									return STRING;
								}

{UNFINISHED_STRING}				{ unfinished_handle(yytext); }

{IDENTIFIER}					{ 
									add_IDENTIFIER_Token(); 
									return ID;	
								}

{NOT_IDENTIFIER}				{ print_LexError("Invalid identifier"); }




{ANYTHING}						{ print_LexError("Unrecognized character "); }



<<EOF>> 						{ return 0;	}

%%
