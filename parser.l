import system'io;
import system'text;
import system;
import system'collections;
import system'routines;
import extensions;
import extensions'text;
import extensions'routines;

Parser
{
    static extractVal(Token tok)
    {
        string val:=tok.Val;
        val=>
        "&lt;"{^"<"}
        "&gt;"{^">"}
        "&amp;"{^"&"}
        :{^val};
        
    }
    
    static genParameterList(var lineArray, int index, var writer)
    {
        writer.writeLine("<parameterList>");
         
        int i := index;
         
        until(lineArray[i].match("symbol",")"))
        {
            writer.writeLine(lineArray[i].Tag);
            i+=1;
        };
        writer.writeLine("</parameterList>");
        ^i;
    }
    static genLet(var lineArray, int index, var writer)
    {
        writer.writeLine("<letStatement>");
        writer.writeLine("<keyword> let </keyword>");
        writer.writeLine(lineArray[index+1].Tag);
        int i := index+2;
        ifnot(lineArray[i].match("symbol","="))
        {
            writer.writeLine("<symbol> [ </symbol>");
            i := Parser.genExpression(lineArray, i+1, writer);
            writer.writeLine("<symbol> ] </symbol>");
            i+=1;
        };
        writer.writeLine("<symbol> = </symbol>");
        i := Parser.genExpression(lineArray, i+1, writer);
        writer.writeLine("<symbol> ; </symbol>");
        writer.writeLine("</letStatement>");
        ^i+1;
    }
    static genTerm(var lineArray, int index, var writer){
        writer.writeLine("<term>");
        int i := index;
        string type := lineArray[i].Type;
        string val := lineArray[i].Val;
        type=>
        "symbol"
        {
            val=>
            "-"
            {
                writer.writeLine("<symbol> - </symbol>");
                i:= Parser.genTerm(lineArray, i+1, writer);
            }
            "~"
            {
                writer.writeLine("<symbol> ~ </symbol>");
                i:= Parser.genTerm(lineArray, i+1, writer);
            }
            "("
            {
                writer.writeLine("<symbol> ( </symbol>");
                i:= Parser.genExpression(lineArray, i+1, writer);
                writer.writeLine("<symbol> ) </symbol>");
                i+=1;
            }
        }
         "keyword"
         {
            writer.writeLine(lineArray[i].Tag);
            i+=1;
        }
        "stringConstant"
        {
            writer.writeLine(lineArray[i].Tag);
            i+=1;
        }
        "integerConstant"
        {
            writer.writeLine(lineArray[i].Tag);
            i+=1;
        }
        "identifier"
        {
            val := lineArray[i+1].Val;
            val=>
            "("{i := Parser.genSubroutineCall(lineArray, i, writer)}
            "."{i := Parser.genSubroutineCall(lineArray, i, writer)}
            "["
            {
                writer.writeLine(lineArray[i].Tag);
                writer.writeLine("<symbol> [ </symbol>");
                i := Parser.genExpression(lineArray, i+2, writer);
                writer.writeLine("<symbol> ] </symbol>");
                i+=1;
            }
            :
            {
                writer.writeLine(lineArray[i].Tag);
                i+=1;
            };
        };
        writer.writeLine("</term>");
        ^i;
    }

    static genExpression(var lineArray, int index, var writer)
    {
        writer.writeLine("<expression>");
        string ops := "+-*/&|<>=";
        
        int i := Parser.genTerm(lineArray, index, writer);
        string nextVal := Parser.extractVal(lineArray[i]);
        while(ops.indexOf(nextVal)!=-1)
        {
            writer.writeLine(lineArray[i].Tag);
            i := Parser.genTerm(lineArray, i+1, writer);
            nextVal := lineArray[i].Val;
        };
        writer.writeLine("</expression>");
        ^i;
    }

    static genExpressionList(var lineArray, int index, var writer)
    {
        writer.writeLine("<expressionList>");
        int i := index;
        ifnot(lineArray[i].match("symbol",")"))
        {
            i := Parser.genExpression(lineArray, i, writer);
        };
        
        while(lineArray[i].match("symbol",","))
        {
            writer.writeLine("<symbol> , </symbol>");
            i := Parser.genExpression(lineArray, i+1, writer);
        };
        writer.writeLine("</expressionList>");
        ^i;
    }

    static genSubroutineCall(var lineArray, int index, var writer)
    {
        writer.writeLine(lineArray[index].Tag);
        int i:= index+1;
        if(lineArray[i].match("symbol","."))
        {
            writer.writeLine("<symbol> . </symbol>");
            writer.writeLine(lineArray[i+1].Tag);
            i+=2;
        };
        writer.writeLine("<symbol> ( </symbol>");
        i := Parser.genExpressionList(lineArray, i+1, writer);
        writer.writeLine("<symbol> ) </symbol>");
        ^i+1;       
    }
    static genDo(var lineArray, int index, var writer)
    {
        writer.writeLine("<doStatement>");
        writer.writeLine("<keyword> do </keyword>");
        int i := Parser.genSubroutineCall(lineArray, index+1, writer);
        writer.writeLine("<symbol> ; </symbol>");
        writer.writeLine("</doStatement>");
        ^i+1;
    }

    static genReturn(var lineArray, int index, var writer)
    {
        writer.writeLine("<returnStatement>");
        writer.writeLine("<keyword> return </keyword>");
        int i := index+1;
        ifnot(lineArray[i].match("symbol",";"))
        {
            i := Parser.genExpression(lineArray, i, writer);
        };
        writer.writeLine("<symbol> ; </symbol>");
        writer.writeLine("</returnStatement>");
        ^i+1;
    }

    static genIf(var lineArray, int index, var writer)
    {
        writer.writeLine("<ifStatement>");
        writer.writeLine("<keyword> if </keyword>");
        writer.writeLine("<symbol> ( </symbol>");
        int i := Parser.genExpression(lineArray, index+2, writer);
        writer.writeLine("<symbol> ) </symbol>");
        writer.writeLine("<symbol> { </symbol>");
        i := Parser.genStatements(lineArray, i+2, writer);
        writer.writeLine("<symbol> } </symbol>");
        if(lineArray[i].match("keyword","else"))
        {
            writer.writeLine("<keyword> else </keyword>");
            writer.writeLine("<symbol> { </symbol>");
            i := Parser.genStatements(lineArray, i+3, writer);
            writer.writeLine("<symbol> } </symbol>");
        };
        writer.writeLine("</ifStatement>");
        ^i+1;
    }

    static genWhile(var lineArray, int index, var writer)
    {
        writer.writeLine("<whileStatement>");
        writer.writeLine("<keyword> while </keyword>");
        writer.writeLine("<symbol> ( </symbol>");
        int i := Parser.genExpression(lineArray, index+2, writer);
        writer.writeLine("<symbol> ) </symbol>");
        writer.writeLine("<symbol> { </symbol>");
        i := Parser.genStatements(lineArray, i+2, writer);
        writer.writeLine("<symbol> } </symbol>");
        writer.writeLine("</whileStatement>");
        ^i+1;
    }
        
    static genVarDec(var lineArray, int index, var writer)
    {
        writer.writeLine("<varDec>");
        writer.writeLine("<keyword> var </keyword>");
        writer.writeLine(lineArray[index+1].Tag);
        writer.writeLine(lineArray[index+2].Tag);
        int i := index+3;
        while(lineArray[i].match("symbol",","))
        {
            writer.writeLine("<symbol> , </symbol>");
            writer.writeLine(lineArray[i+1].Tag);
            i+=2;
        };
        writer.writeLine("<symbol> ; </symbol>");
        writer.writeLine("</varDec>");
        ^i+1;
    }

    static genStatements(var lineArray, int index, var writer)
    {
        writer.writeLine("<statements>");
        int i := index;
        until(lineArray[i].match("symbol","}"))
        {
            string type := lineArray[i].Val;
            type=>
            "if"{i := Parser.genIf(lineArray, i, writer)}
            "while"{i := Parser.genWhile(lineArray, i, writer)}
            "do"{i := Parser.genDo(lineArray, i, writer)}
            "let"{i := Parser.genLet(lineArray, i, writer)}
            "return"{i := Parser.genReturn(lineArray, i, writer)};
        };
        
        writer.writeLine("</statements>");
        ^i;
    }
        
    static genSubroutineBody(var lineArray, int index, var writer)
    {
        writer.writeLine("<subroutineBody>");
        writer.writeLine("<symbol> { </symbol>");
        int i := index+2;
        while(lineArray[i].match("keyword","var"))
        {
            i := Parser.genVarDec(lineArray, i, writer);
        };
        i := Parser.genStatements(lineArray, i, writer);
        writer.writeLine("<symbol> } </symbol>");
        writer.writeLine("</subroutineBody>");
        ^i+1;
    }
    
    static genSubroutineDec(var lineArray, int index, var writer)
    {
        writer.writeLine("<subroutineDec>");
        writer.writeLine(lineArray[index].Tag);
        writer.writeLine(lineArray[index+1].Tag);
        writer.writeLine(lineArray[index+2].Tag);
        writer.writeLine("<symbol> ( </symbol>");
        int i := Parser.genParameterList(lineArray, index+4, writer);
        writer.writeLine("<symbol> ) </symbol>");
        i := Parser.genSubroutineBody(lineArray, i, writer);
        writer.writeLine("</subroutineDec>");
        ^i;
    }
    
    
    static genClassVarDec(var lineArray, int index, var writer)
    {
        writer.writeLine("<classVarDec>");
        writer.writeLine(lineArray[index].Tag);
        writer.writeLine(lineArray[index+1].Tag);
        writer.writeLine(lineArray[index+2].Tag);
        int i := index+3;
        while(lineArray[i].match("symbol",","))
        {
             writer.writeLine("<symbol> , </symbol>");
             writer.writeLine(lineArray[i+1].Tag);
             i+=2;
        };
        writer.writeLine("<symbol> ; </symbol>");
        writer.writeLine("</classVarDec>");
        ^i+1;
    }
    
    static genClass(var lineArray, var writer){
            
            writer.writeLine("<class>");
            writer.writeLine("<keyword> class </keyword>");
            
            writer.writeLine(lineArray[1].Tag);
            writer.writeLine("<symbol> { </symbol>");
            int i:= 3;
            
            while(lineArray[i].match("keyword","field") ||
                 lineArray[i].match("keyword","static")){
                     
                i:=Parser.genClassVarDec(lineArray, i, writer);
               
            };
            
            while(lineArray[i].match("keyword","constructor") ||
                    lineArray[i].match("keyword","function")||
                    lineArray[i].match("keyword","method")){
                i:=Parser.genSubroutineDec(lineArray, i, writer);
                
            };
            
            
            writer.writeLine("<symbol> } </symbol>");
            writer.writeLine("</class>");
            
            
        }
    
    
    
    static createXML(Tokenizer tokenizer)
    {
        string fileName := tokenizer.getOutputFile("xml");
        var lineArray := tokenizer.Tokens;
        
        using(auto writer := File.assign(fileName).textwriter()){
            Parser.genClass(lineArray, writer);
        }
    }
}
           