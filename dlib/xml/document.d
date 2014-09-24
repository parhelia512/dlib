/*
Copyright (c) 2013-2014 Timur Gafarov 

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module dlib.xml.document;

private
{
    import std.stdio;
    import std.file;
    import std.conv;
    import std.utf;

    import dlib.container.stack;
    import dlib.xml.lexer;
    import dlib.xml.node;
}

final class XmlDocument
{
    private XmlNode prolog = null;
    XmlNode root = null;
    dstring type;
    
    @property dstring xmlVersion()
    {
        if (prolog is null)
            return "1.0";
        else
        {
            if ("version"d in prolog.properties)
                return prolog.properties["version"];
            else
                return "1.1";
        }
    }

    @property XmlNode rootNode()
    {
        if (root.children)
            return root.children[0];
        else
            return null;
    }
    
    enum XmlToken
    {
        TagOpen,
        TagClose,
        TagName,
        Assignment,
        PropValue
    }

    this(string text)
    {
        this(text.toUTF32);
    }
    
    this(dstring text)
    {
        Lexer lex = new Lexer(text);
        lex.addDelimiters(
        [
            "<", ">", "</", "/>", "=", "<?", "?>", "\"", "&",
            "<!--", "-->", "<![CDATA[", "]]>"
        ]);
        
        Stack!XmlNode nodeStack;
        root = new XmlNode("");
        nodeStack.push(root);
        
        XmlToken expect = XmlToken.TagOpen;
        bool tagOpening = false;
        bool xmlPrologDeclaration = false;
        bool ampersand = false;
        bool doctype = false;
        bool comment = false;
        bool cdata = false;
        dstring tmpPropName;
        dstring token;
        
        do
        {
            token = lex.getLexeme();

            if (token.length)
            {
                switch(token)
                {
                    case "<![CDATA[":
                        if (comment) break;
                        cdata = true;
                        break;

                    case "]]>":
                        if (comment) break;
                        if (cdata)
                            cdata = false;
                        else
                            throw new Exception("Unexpected token \'" ~ to!string(token) ~ "\'");
                        break;

                    case "<!--":
                        if (cdata)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            node.text = token;
                        }
                        else comment = true;
                        break;

                    case "-->":
                        if (cdata)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            node.text = token;
                        }
                        else 
                        if (comment)
                            comment = false;
                        else
                            throw new Exception("Unexpected token \'" ~ to!string(token) ~ "\'");
                        break;

                    case "<":
                        if (comment) break;
                        if (cdata)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            node.text = token;
                        }
                        else if (expect == XmlToken.TagOpen)
                        {
                            expect = XmlToken.TagName;
                            tagOpening = true;
                        }
                        else
                            throw new Exception("Unexpected token \'" ~ to!string(token) ~ "\'");
                        break;
                        
                    case ">":
                        if (comment) break;
                        if (cdata)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            node.text = token;
                        }
                        else if (expect == XmlToken.TagClose && !xmlPrologDeclaration)
                        {
                            expect = XmlToken.TagOpen;
                            if (doctype)
                                doctype = false;
                        }
                        else
                            throw new Exception("Unexpected token \'" ~ to!string(token) ~ "\'");
                        break;

                    case "</":
                        if (comment) break;
                        if (cdata)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            node.text = token;
                        }
                        else if (expect == XmlToken.TagOpen)
                        {
                            expect = XmlToken.TagName;
                        }
                        break;
                        
                    case "/>":
                        if (comment) break;
                        if (cdata)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            node.text = token;
                        }
                        else if (expect == XmlToken.TagClose && !xmlPrologDeclaration)
                        {
                            expect = XmlToken.TagOpen;
                            nodeStack.pop();
                        }
                        else
                            throw new Exception("Unexpected token \'" ~ to!string(token) ~ "\'");
                        break;
                        
                    case "<?":
                        if (comment) break;
                        if (cdata)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            node.text = token;
                        }
                        else if (expect == XmlToken.TagOpen)
                        {
                            expect = XmlToken.TagName;
                            xmlPrologDeclaration = true;
                            tagOpening = true;
                        }
                        break;
                        
                    case "?>":
                        if (comment) break;
                        if (cdata)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            node.text = token;
                        }
                        else if (expect == XmlToken.TagClose && xmlPrologDeclaration)
                        {
                            expect = XmlToken.TagOpen;
                            xmlPrologDeclaration = false;
                            nodeStack.pop();
                        }
                        break;

                    case "=":
                        if (comment) break;
                        if (cdata)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            node.text = token;
                        }
                        else if (expect == XmlToken.Assignment)
                        {
                            expect = XmlToken.PropValue;
                        }
                        else
                            throw new Exception("Unexpected token \'" ~ 
                                to!string(token) ~ "\', expected " ~ expect.to!string);
                        break;
                        
                    case "&":
                        if (comment) break;
                        if (cdata)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            node.text = token;
                        }
                        else if (expect == XmlToken.TagOpen)
                        {
                            ampersand = true;
                        }
                        else
                            throw new Exception("Unexpected token \'" ~ to!string(token) ~ "\'");
                        break;
                        
                    default:
                        if (comment) break;

                        if (cdata)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            node.text = token;
                        }
                        else if (token.isWhitespace || token == "\n")
                        {
                            if (expect == XmlToken.TagOpen)
                            {
                                if (nodeStack.top.children.length)
                                {
                                    if (nodeStack.top.children[$-1].text == " ")
                                        break;
                                }
                                else if (!nodeStack.top.text.length)
                                    break;
                                else if (nodeStack.top.text[$-1] == ' ')
                                    break;
                            
                                XmlNode node = new XmlNode("", nodeStack.top);
                                node.text = " ";
                            }
                        }
                        else if (expect == XmlToken.TagName)
                        {
                            expect = XmlToken.TagClose;
                            
                            if (xmlPrologDeclaration)
                            {
                                if (tagOpening)
                                {
                                    if (prolog is null)
                                    {
                                        if (token == "xml")
                                        {
                                            prolog = new XmlNode(token);
                                            nodeStack.push(prolog);
                                            tagOpening = false;
                                        }
                                        else
                                            throw new Exception("Illegal XML prolog");
                                    }
                                    else
                                        throw new Exception("More than one XML prolog is not allowed");
                                }
                                else
                                {
                                    nodeStack.pop();
                                }
                            }
                            else if (token == "!DOCTYPE")
                            {
                                //writeln("!DOCTYPE");
                                expect = XmlToken.TagClose;
                                doctype = true;
                            }
                            else
                            {
                                if (tagOpening)
                                {
                                    XmlNode node = new XmlNode(token, nodeStack.top);
                                    nodeStack.push(node);
                                    tagOpening = false;
                                }
                                else
                                {
                                    if (token == nodeStack.top.name)
                                        nodeStack.pop();
                                    else
                                        throw new Exception("Mismatched tag");
                                }
                            }
                        }
                        else if (expect == XmlToken.TagOpen)
                        {
                            XmlNode node = new XmlNode("", nodeStack.top);
                            if (ampersand)
                            {
                                if (token[0] == '#' && token.length > 1)
                                {
                                    if (token[1] == 'x')
                                        node.text ~= cast(dchar)hexCharacterCode(token[2..$]);
                                    else
                                        node.text ~= cast(dchar)to!uint(token[1..$-1]);
                                }
                                ampersand = false;
                            }
                            else node.text = token;
                        }
                        else if (expect == XmlToken.TagClose)
                        {
                            if (doctype)
                            {
                                expect = XmlToken.TagClose;
                                type = token;
                            }
                            else
                            {
                                expect = XmlToken.Assignment;
                                tmpPropName = token;
                            }
                        }
                        else if (expect == XmlToken.PropValue)
                        {
                            expect = XmlToken.TagClose;
                            dstring val;
                            if (token[0] == '\"' && token[$-1] == '\"')
                                val = token[1..$-1];
                            else
                                val = token;
                            nodeStack.top.addProperty(tmpPropName, val);
                        }
                        else
                            throw new Exception("Unexpected token \'" ~ 
                                to!string(token) ~ "\', expected " ~ to!string(expect));
                        break;
                }
            }
        }
        while (token.length);
    }
}

int hexCharacterCode(dstring input)
{
    int res;
    foreach(c; input)
    {
        switch(c)
        {
            case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
                res = res * 0x10 | c - '0';
                break;
            case 'a', 'b', 'c', 'd', 'e', 'f':
                res = res * 0x10 | c - 'a' + 0xA;
                break;
            case 'A', 'B', 'C', 'D', 'E', 'F':
                res = res * 0x10 | c - 'A' + 0xA;
                break;
            case ';':
                return res;
            default:
                throw new Exception("Expected hex digit in character reference, found \'" ~ to!char(c) ~ "\'");
        }
    }
    return res;
}

/+
    // usage:
    XmlDocument doc = new XmlDocument(readText("test1.xml"));
    auto b = doc.rootNode.getChildByName("b");
    if (b)
    {
        writeln(b[0].getText);
    }
+/
