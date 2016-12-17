--[[
TBASIC: Simple BASIC language based on the Commodore BASIC Version 2.

(C64 rulz? Nope.)


How to use in your program:

    1. load the script by:
        if you're using ComputerCraft, use:
            os.loadAPI "TBASEXEC.lua"
        else, use:
            require "TBASEXEC"

    2. run:
        _TBASIC.EXEC(string of whole command)
]]

if os and os.loadAPI then -- ComputerCraft
    os.loadAPI "TBASINCL.lua"
else
    require "TBASINCL"
end

table.concat = function(t, delimeter)
    if #t == 0 then return "" end
    local outstr = t[1]
    for i = 2, #t do
        outstr = outstr..delimeter..tostring(t[i])
    end

    return outstr
end

-- Copy from TBASINCL; looks like OpenComputers has a bug...
function string_hash(str)
    local hash = 2166136261
    for i = 1, #str do
        hash = hash * 16777619
        hash = bit.bxor(hash, str:byte(i))
    end
    return hash
end





-- INTERPRETER STATUS ---------------------------------------------------------

local programlist = {}

-- LEXER ----------------------------------------------------------------------

local function appendcommand(lineno, statement)
    if lineno > _TBASIC._INTPRTR.MAXLINES then
        _TBASIC._ERROR.LINETOOBIG()
    elseif lineno < 0 then
        _TBASIC._ERROR.NOLINENUM()
    else
        programlist[lineno] = statement
    end
end

do -- Avoid heap allocs for performance
    local tokens = {" ", "\t", ",", "(", ")"} -- initial obvious tokens
    local longest_token_len = 0
    -- build 'tokens' table from list of operators from the language
    for _, v in ipairs(_TBASIC._OPERATR) do
        if not v:match("[A-Za-z]") then -- we want non-alphabetic operators as a token
            table.insert(tokens, v)
            -- get longest_token_len, will be used for 'lookahead'
            local tokenlen = #v
            if longest_token_len < #v then
                longest_token_len = #v
            end
        end
    end
    -- sort them out using ther hash for binary search
    table.sort(tokens, function(a, b) return string_hash(a) < string_hash(b) end)


    function parsewords(line)
        if line == nil then return end

        -----------------------
        -- check line sanity --
        -----------------------

        -- filter for IF statement
        if line:sub(1, 2):upper() == "IF" then
            -- no matching THEN
            if not line:match("[Tt][Hh][Ee][Nn]") then
                _TBASIC._ERROR.NOMATCHING("IF", "THEN")
            -- assignment on IF clause
            elseif line:match("[Ii][Ff][^\n]+[Tt][Hh][Ee][Nn]"):match("[^=+%-*/%%<>!]=[^=<>]") or
                   line:match("[Ii][Ff][^\n]+[Tt][Hh][Ee][Nn]"):match(":=") then
                _TBASIC._ERROR.ASGONIF()
            end
        end

        --------------------------------------------------
        -- automatically infer and insert some commands --
        --------------------------------------------------
        -- (This is starting to get dirty...)

        -- unary minus
        for matchobj in line:gmatch("%-[0-9]+") do
            local newline = line:gsub(matchobj, "MINUS "..matchobj:sub(2, #matchobj))
            line = newline
        end
        -- conditional for IF
        -- if IF statement has no appended paren
        if line:sub(1, 2):upper() == "IF" and not line:match("[Ii][Ff][ ]*%(") then
            local newline = line:gsub("[Ii][Ff]", "IF ( ", 1):gsub("[Tt][Hh][Ee][Nn]", " ) THEN", 1)
            line = newline
        end
        -- special treatment for FOR
        if line:sub(1, 3):upper() == "FOR" then
            if line:match("[0-9]?%.[0-9]") then -- real number used (e.g. "3.14", ".5")
                _TBASIC._ERROR.ILLEGALARG()
            else
                local varnameintm = line:match(" [^\n]+[ =]")

                if varnameintm then
                    local varname = varnameintm:match("[^= ]+")
                    if varname then
                        local newline = line:gsub(" "..varname.."[ =]", " $"..varname.." "..varname.." = ")
                        line = newline:gsub("= =", "=")
                    else
                        _TBASIC._ERROR.SYNTAX()
                    end
                end
                -- basically, "FOR x x = 1 TO 10", which converts to "x x 1 10 TO = FOR",
                -- which is executed (in RPN) in steps of:
                --     "x x 1 10 TO = FOR"
                --     "x x (arr) = FOR"
                --     "x FOR" -- see this part? we need extra 'x' to feed for the FOR statement to function
            end
        end



        printdbg("parsing line", line)



        lextable = {}
        isquote = false
        quotemode = false
        wordbuffer = ""
        local function flush()
            if (#wordbuffer > 0) then
                table.insert(lextable, wordbuffer)
                wordbuffer = ""
            end
        end
        local function append(char)
            wordbuffer = wordbuffer..char
        end
        local function append_no_whitespace(char)
            if char ~= " " and char ~= "\t" then
                wordbuffer = wordbuffer..char
            end
        end

        -- return: lookless_count on success, nil on failure
        local function isdelimeter(string)
            local cmpval = function(table_elem) return string_hash(table_elem) end
            local lookless_count = #string
            local ret = nil
            repeat
                ret = table.binsearch(tokens, string:sub(1, lookless_count), cmpval)
                lookless_count = lookless_count - 1
            until ret or lookless_count < 1
            return ret and lookless_count + 1 or false
        end

        local i = 1 -- Lua Protip: variable in 'for' is immutable, and is different from general variable table, even if they have same name
        while i <= #line do
            local c = string.char(line:byte(i))

            local lookahead = line:sub(i, i+longest_token_len)

            if isquote then
                if c == [["]] then
                    flush()
                    isquote = false
                else
                    append(c)
                end
            else
                if c == [["]] then
                    isquote = true
                    append_no_whitespace("~")
                else
                    local delimsize = isdelimeter(lookahead) -- returns nil if no matching delimeter found
                    if delimsize then
                        flush() -- flush buffer
                        append_no_whitespace(lookahead:sub(1, delimsize))
                        flush() -- flush this delimeter
                        i = i + delimsize - 1
                    else
                        append_no_whitespace(c)
                    end
                end
            end

            i = i + 1
        end
        flush() -- don't forget this!


        return lextable
    end
end

local function readprogram(program)
    for line in program:gmatch("[^\n]+") do
        lineno = line:match("[0-9]+ ", 1)
        
        if not lineno then
            _TBASIC._ERROR.NOLINENUM()
        end

        statement = line:sub(#lineno + 1)

        appendcommand(tonumber(lineno), statement)
    end
end

do -- Avoid heap allocs for performance
    local function stackpush(t, v)
        t[#t + 1] = v
    end

    local function stackpop(t)
        local v = t[#t]
        t[#t] = nil
        return v
    end

    local function stackpeek(t)
        local v = t[#t]
        return v
    end

    local function unmark(word)
        if type(word) == "table" then return word end
        return word:sub(2, #word)
    end

    local function isoperator(word)
        if word == nil then return false end
        return word:byte(1) == 35
    end

    local isvariable = _TBASIC.isvariable
    local isnumber = _TBASIC.isnumber
    local isstring = _TBASIC.isstring

    local function isuserfunc(word)
        if type(word) == "table" then return false end
        if word == nil then return false end
        return word:byte(1) == 64
    end

    local function isbuiltin(word)
        if type(word) == "table" then return false end
        if word == nil then return false end
        return word:byte(1) == 38
    end

    local function iskeyword(word)
        if word == nil then return false end
        return isoperator(word) or isuserfunc(word) or isbuiltin(word)
    end

    local function isassign(word)
        if word == nil then return false end
        return word ~= "==" and word ~= ">=" and word ~= "<=" and word:byte(#word) == 61
    end

    -- returns truthy value "terminate_loop" upon termination of loop; nil otherwise.
    local function execword(word, args)
        if not _TBASIC.__appexit then
            printdbg("--> execword", word)
            printdbg("--> execword_args", table.unpack(args))

            if word == "IF" then
                printdbg("--> branch statement 'IF'")
                if not _TBASIC.__readvar(args[1]) then -- if condition 'false'
                    printdbg("--> if condition 'false'", table.unpack(args))
                    return "terminate_loop" -- evaluated as 'true' to Lua
                else
                    printdbg("--> if condition 'true'", table.unpack(args))
                end
            end

            printdbg("--> execword_outarg", table.unpack(args))
            result = _TBASIC.LUAFN[word][1](table.unpack(args))

            printdbg("--> result", result)
            stackpush(execstack, result)
        end
    end

    function printdbg(...)
        local debug = false
        if debug then print("DBG", ...) end
    end


    function interpretline(line)
        if not _TBASIC.__appexit then
            --[[
            impl

            1. (normalise expr using parsewords)
            2. use _TBASIC.RPNPARSR to convert to RPN
            3. execute RPN op set like FORTH

            * "&" - internal functions
            * "@" - user-defined functions
            * "$" - variables (builtin constants and user-defined) -- familiar, eh?
            * "#" - operators
            * "~" - strings
            * none prepended - data (number or string)
            ]]

            lextable = parsewords(line)
            local vararg = -13 -- magic


            if lextable and lextable[1] ~= nil then
                if lextable[1]:upper() == "REM" then return nil end

                printdbg("lextable", table.concat(lextable, "|"))

                -- execute expression
                exprlist = _TBASIC.TORPN(lextable) -- 2 2 #+ &PRINT for "PRINT 2+2"

                printdbg("trying to exec", table.concat(exprlist, " "), "\n--------")

                execstack = {}

                for _, word in ipairs(exprlist) do
                    printdbg("stack before", table.concat(execstack, " "))
                    printdbg("word", word)

                    if iskeyword(word) then
                        printdbg("is keyword")

                        funcname = unmark(word)
                        args = {}
                        argsize = _TBASIC._GETARGS(funcname)

                        printdbg("argsize", argsize)

                        if not argsize then
                            _TBASIC._ERROR.DEV_UNIMPL(funcname)
                        else
                            if argsize ~= vararg then
                                -- consume 'argsize' elements from the stack
                                for argcnt = argsize, 1, -1 do
                                    if #execstack == 0 then
                                        _TBASIC._ERROR.ARGMISSING(funcname)
                                    end
                                    args[argcnt] = stackpop(execstack)
                                end
                            else
                                -- consume entire stack
                                local reversedargs = {}

                                while #execstack > 0 and
                                        (isvariable(stackpeek(execstack)) or isnumber(stackpeek(execstack)) or
                                                isstring(stackpeek(execstack)))
                                do
                                    stackpush(reversedargs, stackpop(execstack))
                                end
                                -- reverse 'args'
                                while #reversedargs > 0 do
                                    stackpush(args, stackpop(reversedargs))
                                end
                            end

                            local terminate_loop = execword(funcname, args)

                            if terminate_loop then
                                printdbg("--> termination of loop")
                                printdbg("--------")
                                break
                            end
                        end
                    elseif isvariable(word) then
                        printdbg("is variable")
                        stackpush(execstack, word) -- push raw variable ($ sign retained)
                    else
                        printdbg("is data")
                        stackpush(execstack, word) -- push number or string
                    end

                    printdbg("stack after", table.concat(execstack, " "))
                    printdbg("--------")
                end

                -- if execstack is not empty, something is wrong
                if #execstack > 0 then
                    _TBASIC._ERROR.SYNTAX() -- cannot reliably pinpoint which statement has error; use generic error
                end
            end
        end
    end
end


local function termination_condition()
    return terminated or
            _TBASIC.__appexit or
            #_TBASIC._INTPRTR.CALLSTCK > _TBASIC._INTPRTR.STACKMAX
end

local function fetchnextcmd()
    cmd = nil
    repeat
        _TBASIC._INTPRTR.PROGCNTR = _TBASIC._INTPRTR.PROGCNTR + 1
        cmd = programlist[_TBASIC._INTPRTR.PROGCNTR]

        if _TBASIC._INTPRTR.PROGCNTR > _TBASIC._INTPRTR.MAXLINES then
            terminated = true
            break
        end
    until cmd ~= nil

    if cmd ~= nil then
        if _TBASIC._INTPRTR.TRACE then
            print("PC", _TBASIC._INTPRTR.PROGCNTR)
        end

        return cmd
    end
end


local function interpretall()

    terminated = false

    repeat
        interpretline(fetchnextcmd())
    until termination_condition()
end

-- END OF LEXER ---------------------------------------------------------------

-- _TBASIC.SHOWLUAERROR = false -- commented; let the shell handle it

local testprogram = nil

_G._TBASIC.EXEC = function(cmdstring) -- you can access this interpreter with this global function
    _TBASIC._INTPRTR.RESET()
    programlist = {} -- wipe out previous commands from interpreter (do not delete)
    readprogram(cmdstring)
    interpretall()
end


if testprogram then
    _TBASIC._INTPRTR.RESET()
    programlist = {} -- wipe out previous commands from interpreter (do not delete)
    readprogram(testprogram)
    interpretall()
end


--[[
Terran BASIC (TBASIC) 
Copyright (c) 2016 Torvald (minjaesong) and the contributors.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the Software), to deal in the
Software without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
