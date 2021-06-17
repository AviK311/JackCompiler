import system'io;
import system'text;
import system;
import system'collections;
import system'routines;
import extensions;
import extensions'text;
import extensions'routines;
import compiler;

CompileEngine
{
    static SymbolTable classTable;
    static SymbolTable routineTable;
    static string className;
    static int numOfFields;
    static ArrayList tokens;
    static int index;
    static int labelIndex;
    static string output;
    static debug;
    
    static getLabel()
    {
        string newLabel := "L"+labelIndex.toString();
        labelIndex+=1;
        ^newLabel;
    }
    
    
    static reset(Tokenizer tokenizer, var withDebug)
    {
        classTable := new SymbolTable();
        numOfFields := 0;
        labelIndex := 0;
        index := 0;
        output := tokenizer.getOutputFile("vm");
        tokens := tokenizer.Tokens; 
        debug := withDebug; 
    }
    
    static debugPrint(string funcName)
    {
        if(debug)
        {
            console.printLine("func: "+funcName).printLine("index: "+(index+1).toString()).printLine("token: "+tokens[index].Tag).printLine();
        }
    }

    static compileTerm(var writer)
    {
        CompileEngine.debugPrint("compileTerm");
        string type := tokens[index].Type;
        string val:= tokens[index].Val;
        
        type=>
        "symbol"
        {
            val=>
            "-"
            {
                index+=1;
                CompileEngine.compileTerm(writer);
                writer.writeLine("neg");
            }
            "~"
            {
                index+=1;
                CompileEngine.compileTerm(writer);
                writer.writeLine("not");
            }
            "("
            {
                index+=1;
                CompileEngine.compileExpression(writer);
                index+=1;
            } 
        }
        "keyword"
        {
            val=>
            "true"
            {
                writer.writeLine("push constant 1");
                writer.writeLine("neg");
            }
            "null"{writer.writeLine("push constant 0");}
            "false"{writer.writeLine("push constant 0");}
            "this"{writer.writeLine("push pointer 0");};
            index+=1; 
        }
        "stringConstant"
        {
            writer.writeLine("push constant "+val.Length.toString());
            writer.writeLine("call String.new 1");
                   
            val.forEach:(char)
            {
                writer.writeLine("push constant "+char.toInt().toString());
                writer.writeLine("call String.appendChar 2");
            };
            index+=1;
                          
        }
        "integerConstant"
        {
            writer.writeLine("push constant " +val);
            index+=1;
        }
        "identifier"
        {           
            var sym := routineTable.getSymbol(tokens[index].Val);
            if (sym==nil)
            {
                sym:= classTable.getSymbol(tokens[index].Val);
            };           
            val:= tokens[index+1].Val;
            
            val=>
            "("{CompileEngine.compileSubroutineCall(writer);}
            "."{CompileEngine.compileSubroutineCall(writer);}
            "["
            {   
                writer.writeLine(sym.push);
                index+=2;
                CompileEngine.compileExpression(writer);
                writer.writeLine("add");
                writer.writeLine("pop pointer 1");
                writer.writeLine("push that 0");
                index+=1;
            }
            :
            {
                writer.writeLine(sym.push);
                index+=1;                
            };
        };
    }
        
    static compileParameterList()
    {
    CompileEngine.debugPrint("compileParameterList");
        if(tokens[index].match("symbol",")"))
        {
            ^0;
        };
        index-=1;
        until(tokens[index].match("symbol",")"))
        {
            index+=1;
            string type := tokens[index].Val;
            string sym := tokens[index+1].Val;
            routineTable.addSymbol(sym, "argument", type);
            index+=2;
        };
    
    }
    

    static compileExpression(var writer)
    {
        CompileEngine.debugPrint("compileExpression");
        Map<string, string> opMap := new Map<string, string>();
        opMap["+"] := "add";
        opMap["-"] := "sub";
        opMap["*"] := "call Math.multiply 2";
        opMap["/"] := "call Math.divide 2";
        opMap["&"] := "and";
        opMap["|"] := "or";
        opMap["<"] := "lt";
        opMap[">"] := "gt";
        opMap["="] := "eq"; 
         
        CompileEngine.compileTerm(writer); 
        string nextVal:= Parser.extractVal(tokens[index]);
         
        while(opMap[nextVal]!=nil)
        {
            index+=1;
            CompileEngine.compileTerm(writer);
            writer.writeLine(opMap[nextVal]);
            nextVal := Parser.extractVal(tokens[index]);
        };  
    } 
        
    static compileLet(var writer)
    {
        CompileEngine.debugPrint("compileLet");
        index+=1;
        var sym := routineTable.getSymbol(tokens[index].Val);
        if(sym==nil)
        {
            sym:= classTable.getSymbol(tokens[index].Val);
        };
        
        index+=1;
        if(tokens[index].match("symbol","["))
        {
            writer.writeLine(sym.push);
            index+=1;
            CompileEngine.compileExpression(writer);
            writer.writeLine("add");
            index+=2;
            CompileEngine.compileExpression(writer);
            writer.writeLine("pop temp 0");
            writer.writeLine("pop pointer 1");
            writer.writeLine("push temp 0");
            writer.writeLine("pop that 0");
        }
        else
        {
            index+=1;
            CompileEngine.compileExpression(writer);
            writer.writeLine(sym.pop);
        };   
        index+=1;
    }
     
    static compileExpressionList(var writer)
    {
        CompileEngine.debugPrint("compileExpressionList");
        int paramsLen:= 0;
        
        ifnot(tokens[index].match("symbol",")"))
        {
            CompileEngine.compileExpression(writer);
            paramsLen+=1;
        };
        while(tokens[index].match("symbol",","))
        {
            index+=1;
            CompileEngine.compileExpression(writer);
            paramsLen+=1;
        };
            
        ^paramsLen;
    
    }

    static compileSubroutineCall(var writer)
    {
        CompileEngine.debugPrint("compileSubroutineCall");
        string funcCall;
        var sym:= routineTable.getSymbol(tokens[index].Val);
        if (sym==nil)
            sym:= classTable.getSymbol(tokens[index].Val);
        if (sym!=nil)//object method outside class
        {
            writer.writeLine(sym.push);
            funcCall := tokens[index+2].Val;
            index+=4;
            int params := CompileEngine.compileExpressionList(writer)+1;
            writer.writeLine("call "+sym.Type+"."+funcCall+" "+params.toString());
        }
        else if (tokens[index+1].match("symbol","."))//class method
        {
            funcCall := tokens[index].Val + "." + tokens[index+2].Val;
            index+=4;
            int params := CompileEngine.compileExpressionList(writer);
            writer.writeLine("call "+funcCall+" "+params.toString());
        }
        else//object method inside class
        {
            funcCall:= className+"."+tokens[index].Val;
            writer.writeLine("push pointer 0");
            index+=2;
            int params := CompileEngine.compileExpressionList(writer)+1;
            writer.writeLine("call "+funcCall+" "+params.toString());
        };
        index+=1;
    }
        
               
    static compileDo(var writer)
    {
        CompileEngine.debugPrint("compileDo");
        index+=1;
        CompileEngine.compileSubroutineCall(writer);
        writer.writeLine("pop temp 0");
        index+=1;
    }
    static compileReturn(var writer)
    {
        CompileEngine.debugPrint("compileReturn");
        index+=1;
        ifnot(tokens[index].match("symbol",";"))
        {
            CompileEngine.compileExpression(writer);
        }
        else
        {
            writer.writeLine("push constant 0");
        };
        writer.writeLine("return");
        index+=1;
    }
    static compileIf(var writer)
    {
        CompileEngine.debugPrint("compileIf");
        string label1 := CompileEngine.getLabel();
        index+=2;
        CompileEngine.compileExpression(writer);
        writer.writeLine("not");
        writer.writeLine("if-goto "+label1);
        index+=2;
        CompileEngine.compileStatements(writer);
        
        if(tokens[index].match("keyword","else"))
        {
            string label2 := CompileEngine.getLabel();
            writer.writeLine("goto "+label2);
            writer.writeLine("label "+label1);
            index+=3;
            CompileEngine.compileStatements(writer);
            writer.writeLine("label "+label2);
        }
        else
        {
            writer.writeLine("label "+label1);
        };
        index+=1;
    }
    static compileWhile(var writer)
    {
        CompileEngine.debugPrint("compileWhile");
         string label1 := CompileEngine.getLabel();
         string label2 := CompileEngine.getLabel();
         writer.writeLine("label "+label1);
         index+=2;
         CompileEngine.compileExpression(writer);
         writer.writeLine("not");
         writer.writeLine("if-goto "+label2);
         index+=2;
         CompileEngine.compileStatements(writer);
         writer.writeLine("goto "+label1);
         writer.writeLine("label "+label2);
         index+=1;
    }
        
    static compileVarDec()
    {
        CompileEngine.debugPrint("compileVarDec");
        string type:= tokens[index+1].Val;
        string sym := tokens[index+2].Val;
        routineTable.addSymbol(sym, "local", type);
        index+=3;
        
        while(tokens[index].match("symbol",","))
        {
            sym := tokens[index+1].Val;
            routineTable.addSymbol(sym, "local", type);
            index+=2;
        };
        index+=1;
    }
    static compileStatements(var writer)
    {
        CompileEngine.debugPrint("compileStatements");
        
        until(tokens[index].match("symbol","}"))
        {
            string statementType:= tokens[index].Val;
            statementType=>
            "if"{CompileEngine.compileIf(writer)}
            "while"{CompileEngine.compileWhile(writer)}
            "do"{CompileEngine.compileDo(writer)}
            "let"{CompileEngine.compileLet(writer)}
            "return"{CompileEngine.compileReturn(writer);};
        };
    }
        
    static compileSubroutineBody(var writer)
    {
        CompileEngine.debugPrint("compileSubroutineBody");
        index+=1;
        while(tokens[index].match("keyword","var"))
        {
            CompileEngine.compileVarDec();
        };
        
        CompileEngine.compileStatements(writer);
        index+=1;
    }
        
    static numOfLocals()
    {
        CompileEngine.debugPrint("numOfLocals");
        int i:= index+2;
        int cntr:= 0;
        
        while(tokens[i].match("keyword","var"))
        {
            cntr+=1;
            i+=3;
            while(tokens[i].match("symbol",","))
            {
                cntr+=1;
                i+=2;
            };
            i+=1;
        };
        ^cntr;
    }
    
    static compileConstructor(var writer)
    {
        CompileEngine.debugPrint("compileConstructor");
        routineTable := new SymbolTable();
        index+=4;
        CompileEngine.compileParameterList();
        int i := CompileEngine.numOfLocals();
        writer.writeLine("function "+className+".new "+i.toString());
        writer.writeLine("push constant "+numOfFields.toString());
        writer.writeLine("call Memory.alloc 1");
        writer.writeLine("pop pointer 0");
        index+=1;
        CompileEngine.compileSubroutineBody(writer);
    }

    static compileSubroutineDec(var writer)
    {        
        CompileEngine.debugPrint("compileSubroutineDec");
        var isMethod := tokens[index].match("keyword","method");
        routineTable := new SymbolTable();
        string funcName := tokens[index+2].Val;
        if(isMethod)
        {
            routineTable.addSymbol("this", "argument", className); 
        };
        index+=4;
        CompileEngine.compileParameterList();
        int i := CompileEngine.numOfLocals();
        writer.writeLine("function "+className+"."+funcName+" "+i.toString());
        if(isMethod)
        {
            writer.writeLine("push argument 0");
            writer.writeLine("pop pointer 0");
        };
        
        index+=1;
        CompileEngine.compileSubroutineBody(writer);
        
    }
    
    
    static compileClassVarDec()
    {
        CompileEngine.debugPrint("compileClassVarDec");
        string kind := tokens[index].Val;
        string type := tokens[index+1].Val;
        string sym := tokens[index+2].Val;
        classTable.addSymbol(sym, kind, type);
        index+=3;
        until(tokens[index].match("symbol",";"))
        {
             sym := tokens[index+1].Val;
             classTable.addSymbol(sym, kind, type);
             index+=2;
             numOfFields+=1;
        };
        index+=1;
        
    }
    
    static compileClass(var writer)
    {
        CompileEngine.debugPrint("compileClass");
        className := tokens[1].Val;
        index:= 3;
        while(tokens[index].match("keyword","field") ||
            tokens[index].match("keyword","static"))
        {
            numOfFields+=1;     
            CompileEngine.compileClassVarDec();
        };
        
        while(tokens[index].match("keyword","constructor") ||
            tokens[index].match("keyword","function")||
            tokens[index].match("keyword","method"))
        {
            
            if(tokens[index].match("keyword","constructor"))
            {
                CompileEngine.compileConstructor(writer);
            }
            else
                CompileEngine.compileSubroutineDec(writer);   
        };        
    }
    
    static createVM()
    {
        using(auto writer := File.assign(output).textwriter())
        {
            CompileEngine.compileClass(writer);
        }
    }
}
           
