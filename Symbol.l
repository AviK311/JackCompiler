import system'io;
import system'text;
import system;
import system'collections;
import system'routines;
import extensions;
import extensions'text;
import extensions'routines;
import compiler;


Symbol{
    int num;
    string kind;
    string type;
    string name;
    constructor(string k, string t, string n, int index)
    {
        num := index;
        name := n;
        type:= t;
        if (compareStrings(k,"field")){
            kind:= "this";
        }else{
            kind:= k;
        }
    }
    Num=num;
    Name=name;
    Type=type;
    Kind=kind;
    string push = "push "+ kind+" "+num.toString();
    string pop = "pop "+ kind+" "+num.toString();
    
    
}

SymbolTable{
    Map<string, Symbol> map;
    Map<string, int> counters;
    constructor()
    {
        map := new Map<string, Symbol>();
        counters := new Map<string, int>();
        counters["field"] := 0;
        counters["argument"] := 0;
        counters["local"] := 0;
        counters["static"] := 0;
    }
    getSymbol(string sym)
    {
        ^map[sym];
    }
    
    addSymbol(string sym, string kind, string type)
    {
        map[sym] := new Symbol(kind, type, sym, counters[kind]);
        counters[kind] := counters[kind]+1;
    }
}
    