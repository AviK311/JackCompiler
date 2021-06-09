import system'io;
import system'text;
import system;
import system'collections;
import system'routines;
import extensions;
import extensions'text;
import extensions'routines;
import compiler;


outputPath(string jackPath)
{
    ^jackPath.replace(".jack","T.xml");
}

removeCommentsAndWhitespace(string line)
{
    int commentIndex := line.indexOf(0, "//");
    string newLine:=line;
    if (commentIndex!=-1)
    {
        newLine:= newLine.Substring(0, commentIndex);  
    };
    commentIndex := newLine.indexOf(0, "/*");
    while(commentIndex!=-1)
    {
        int endIndex := newLine.indexOf(0, "*/");
        if (endIndex==-1)
        {
            ^newLine;
        };
        newLine := newLine.Substring(0, commentIndex) + newLine.Substring(endIndex+2);

        commentIndex := newLine.indexOf(0, "/*");
    };
    ^newLine.trim();
}

getTokenizers(pathToDir)
{
    var dir := Directory.assign(pathToDir);
    var jackFiles := dir.getFiles("*.jack");
    var inComment:= false;
    ArrayList Tokenizers := new ArrayList();
    jackFiles.forEach:(file)
    {
        Tokenizer tokenizer := new Tokenizer(file);
        string fileName := outputPath(file);
        inComment:=false;
    	File.assign(file).forEachLine:(line)
        {
            ifnot(inComment)
            {
                string cleanLine := removeCommentsAndWhitespace(line);
			    int startComment := cleanLine.indexOf(0, "/*");
                if (startComment==-1)
                {
                    createTokens(cleanLine, tokenizer);
                }
                else
                {
                    createTokens(cleanLine.Substring(0,startComment), tokenizer);
                    inComment:=true;
                }
            }
            else
            {
                int endComment := line.indexOf(0, "*/");
                if (endComment!=-1)
                {
                    string cleanLine := line.Substring(endComment+2).trim();
                    cleanLine := removeCommentsAndWhitespace(cleanLine);
                    inComment := false;
			        int startComment := cleanLine.indexOf(0, "/*");
                    if (startComment==-1)
                    {
                        createTokens(cleanLine, tokenizer);
                    }
                    else
                    {
                        createTokens(cleanLine.Substring(0,startComment), tokenizer);
                        inComment := true;
                    }
                }
            };
        };
        console.print();
        Tokenizers.append:tokenizer;
    }; 
    ^Tokenizers;
}

checkSwitch(string switch)
{
    ^program_arguments.filterBy:(str => compareStrings(str, switch)).toArray().Length>0;
}
    

public program()
{
    
    ArrayList myTokenizers := getTokenizers(program_arguments[1]);
    
    var withXml := checkSwitch("-x");
    var withTxml := checkSwitch("-t");
    var withCompile := checkSwitch("-c");
    var compileWithDebug := checkSwitch("-cd");
    myTokenizers.forEach:(tokenizer)
    {
        
        if (withTxml)
        {
            tokenizer.makeTXML();
        };
        if (withXml)
        {
            console.printLine("Writing to "+ tokenizer.getOutputFile("xml"));
            Parser.createXML(tokenizer);
            console.printLine("Finished "+ tokenizer.getOutputFile("xml"));
        };
        if (withCompile || compileWithDebug)
        {
            console.printLine("Compiling to "+ tokenizer.getOutputFile("vm"));
            CompileEngine.reset(tokenizer, compileWithDebug);
            CompileEngine.createVM();
            console.printLine("Finished "+ tokenizer.getOutputFile("vm"));
        };
    };
    console.printLine("Finished Compiling");
    console.readChar();
}                                  