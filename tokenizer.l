import system'io;
import system'text;
import system;
import system'collections;
import system'routines;
import extensions;
import extensions'text;
import extensions'routines;

compareStrings(string val1, string val2)
{
    ifnot(val1.Length==val2.Length)
    {
        ^false;
    };
    for(int i:=0, i< val1.Length, i+=1)
    {
        if (val1[i]!=val2[i])
        {
            ^false;
        }
    };
    ^true;
}

Token
{
    string type;
    string val;
    Type = type;
    Val = val;
    constructor(string _type, string _val)
    {
        type:= _type;
        val:= _val;
    }
    
    string Tag = "<"+type+"> "+val+" </"+type+">";
    match(string _type, string _val)
    {
        ^compareStrings(_type, type) && compareStrings(_val, val);
    }
}

Tokenizer
{
    ArrayList arr;
    string fileName;
    constructor(string fn)
    {
        arr := new ArrayList();
        fileName := fn;
    }
    addTok(Token tok)
    {
        arr.append:tok;
    }
    getTok(int i)
    {
        ^arr[i]
    }
    Tokens = arr;
    
    getOutputFile(string postfix)
    {
        ^fileName.replace(".jack","."+postfix);
    }
    makeTXML()
    {
        using(auto writer := File.assign(fileName.replace(".jack","T.xml")).textwriter())
        {
            arr.forEach:(token)
            {
                writer.writeLine(token.Tag);
            }
        }
    }    
}

createTokens(string line, var tokenizer)
{
    string digits := "0123456789";
    string symbols := "{}()[].,;+-*/&|<>=~";
    string letters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    letters := letters+letters.lowerCase()+"_";
    
    string thisLine := line.trim();
    
    while(thisLine!=""&& thisLine!="\n")
    {
        //string
        if (thisLine[0]=="""")
        {
            int i:= getStringIndex(thisLine.Substring(1));
            string token:= thisLine.Substring(1, i);
            tokenizer.addTok(TokenMaker.stringToken(token));
            thisLine:= thisLine.Substring(i+2).trimLeft();
        }
        //int
        else if(digits.indexOf(0,thisLine[0])!=-1 && digits.indexOf(0,thisLine[0])!=digits.Length)
        {
            int i:= getNumIndex(thisLine.Substring(0));
            string token:= thisLine.Substring(0, i);
            tokenizer.addTok(TokenMaker.intToken(token));
            thisLine:= thisLine.Substring(i).trimLeft();
        }
        //symbol
        else if(symbols.indexOf(0,thisLine[0])!=-1 && symbols.indexOf(0,thisLine[0])!=symbols.Length)
        {
            tokenizer.addTok(TokenMaker.getToken(thisLine[0].toString()));
            thisLine:= thisLine.Substring(1).trimLeft();
        }
        //identifier+keyword
        else if(letters.indexOf(0,thisLine[0])!=-1 && letters.indexOf(0,thisLine[0])!=letters.Length)
        {
            int i:= getIdentifierIndex(thisLine.Substring(1));
            string token:= thisLine.Substring(0, i+1);
            tokenizer.addTok(TokenMaker.getToken(token));
            thisLine:= thisLine.Substring(i+1).trimLeft();
        }
        else{//shouldn't happen
            thisLine:= thisLine.Substring(1).trimLeft();
        }
    
    }
}

getStringIndex(string line)
{
    int i:= 0;
    while(i<line.Length && line[i]!="""")
    {
        i+=1;
    };
    ^i;
}

getNumIndex(string line)
{
    string digits := "0123456789";
    int i:= 0;
    while(i<line.Length && digits.indexOf(0,line[i])!=-1)
    {
        i+=1;
    };
    ^i;
}

getIdentifierIndex(string line)
{
    string letters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    letters:= letters+letters.lowerCase()+"_0123456789";
    int i := 0;
    while(i<line.Length && letters.indexOf(0,line[i])!=-1)
    {
        i+=1;
    };
    ^i;
}

TokenMaker{
    static stringToken(string item)
    {
        ^new Token("stringConstant",item);
    }
    static intToken(string num)
    {
        ^new Token("integerConstant",num);
    }
    static idToken(string id)
    {
        ^new Token("identifier",id);
    }
    static getToken(string item)
    {
        string tag;
        string details:=item;
        item=>
        "class"{tag:="keyword"}
        "field"{tag:="keyword"}
        "int"{tag:="keyword"}
        "static"{tag:="keyword"}
        "boolean"{tag:="keyword"}
        "let"{tag:="keyword"}
        "do"{tag:="keyword"}
        "return"{tag:="keyword"}
        "this"{tag:="keyword"}
        "method"{tag:="keyword"}
        "void"{tag:="keyword"}
        "true"{tag:="keyword"}
        "false"{tag:="keyword"}
        "function"{tag:="keyword"}
        "else"{tag:="keyword"}
        "if"{tag:="keyword"}
		"while"{tag:="keyword"}
        "var"{tag:="keyword"}
        "char"{tag:="keyword"}
        "null"{tag:="keyword"}
        "constructor"{tag:="keyword"}
        "{"{tag:="symbol"}
        "}"{tag:="symbol"}
        "("{tag:="symbol"}
        ")"{tag:="symbol"}
        "["{tag:="symbol"}
        "]"{tag:="symbol"}
        "."{tag:="symbol"}
        ","{tag:="symbol"}
        ";"{tag:="symbol"}
        "+"{tag:="symbol"}
        "-"{tag:="symbol"}
        "*"{tag:="symbol"}
        "/"{tag:="symbol"}
        "&"{tag:="symbol"; details:="&amp;";}
        "|"{tag:="symbol"}
        "<"{tag:="symbol"; details:="&lt;";}
        ">"{tag:="symbol"; details:="&gt;";}
        "="{tag:="symbol"}
        "~"{tag:="symbol"}
        :{^TokenMaker.idToken(item)};

        ^new Token(tag, details);        
    }
}