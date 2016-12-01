--[[
TBASIC shell

Synopsis: TBASIC (filename)
If no file is specified, interactive mode will be started

]]


if os and os.loadAPI then -- ComputerCraft
    os.loadAPI "TBASINCL.lua" 
    os.loadAPI "TBASEXEC.lua" 
else
    require "TBASINCL"
    require "TBASEXEC"
end

args = {...}

print(_G._TBASIC._HEADER)
_TBASIC.PROMPT()
_TBASIC.SHOWLUAERROR = false


local function concat_lines(lines, startindex, endindex)
    local out = ""
    for i = startindex or 1, endindex or _TBASIC._INTPRTR.MAXLINES do
        if lines[i] ~= nil then
            out = out.."\n"..tostring(i).." "..lines[i]
        end
    end

    return out
end


if args[1] then
    local prog = nil
    if fs and fs.open then -- ComputerCraft
        local inp = assert(fs.open(args[1], "r"))
        prog = inp:readAll()
        inp:close()
    else
        local inp = assert(io.open(args[1], "r"))
        prog = inp:read("*all")
        inp:close()
    end

    _TBASIC.EXEC(prog)
else
    local terminate_app = false

    local ptn_nums = "[0-9]+"
    local renum_targets = {"GOTO[ ]+"..ptn_nums, "GOSUB[ ]+"..ptn_nums }

    local lines = {}

    while not terminate_app do
        local __read = false
        line = io.read()

        -- tokenise line by " "
        args = {}
        for word in line:gmatch("[^ ]+") do
            table.insert(args, word:upper())
        end


        -- massive if-else for running command, cos implementing proper command executor is too expensive here
        if args[1] == "NEW" then
            lines = {}
        elseif args[1] == "RUN" then
            _TBASIC.EXEC(concat_lines(lines))
        elseif args[1] == "LIST" then -- LIST, LIST 42, LIST 10-80
               if not args[2] then
                print(concat_lines(lines))
            else
                if args[2]:match("-") then -- ranged
                    range = {}
                    for n in args[2]:gmatch("[^-]+") do
                        table.insert(range, n)
                    end
                    local rangestart = tonumber(range[1])
                    local rangeend = tonumber(range[2])

                    if not rangestart or not rangeend then
                        _TBASIC._ERROR.ILLEGALARG()
                    else
                        print(concat_lines(lines, rangestart, rangeend))
                    end
                else
                    local lineno = tonumber(args[2])
                    if not lineno then
                        _TBASIC._ERROR.ILLEGALARG()
                    else
                        print(concat_lines(lines, lineno, lineno))
                    end
                end
            end
            _TBASIC.PROMPT()
            __read = true
        elseif args[1] == "DELETE" then -- DELETE 30, DELETE 454-650
            if not args[2] then
                _TBASIC._ERROR.ILLEGALARG()
            else
                if args[2]:match("-") then -- ranged
                    range = {}
                    for n in args[2]:gmatch("[^-]+") do
                        table.insert(range, n)
                    end
                    local rangestart = tonumber(range[1])
                    local rangeend = tonumber(range[2])

                    if not rangestart or not rangeend then
                        _TBASIC._ERROR.ILLEGALARG()
                    else
                        for i = rangestart, rangeend do
                            lines[i] = nil
                        end
                    end
                else
                    local lineno = tonumber(args[2])
                    if not lineno then
                        _TBASIC._ERROR.ILLEGALARG()
                    else
                        lines[lineno] = nil
                    end
                end
            end
        elseif args[1] == "EXIT" then
            terminate_app = true
            break
        elseif line:sub(1,6):match("[0-9]+ ") then -- enter new command (this limits max linumber to be 99999)
            local lineno = line:sub(1,6):match("[0-9]+ ", 1)
            local statement = line:sub(#lineno + 1)
            lines[tonumber(lineno)] = statement
            __read = true
        elseif args[1] == "RENUM" then
            local statement_table = {}
            local renumbering_table = {}
            local new_lineno_counter = 10
            -- first, get the list of commands, without line number indexing
            for i = 1, _TBASIC._INTPRTR.MAXLINES do
                if lines[i] ~= nil then
                    --table.insert(statement_table, lines[i])
                    statement_table[new_lineno_counter] = lines[i]
                    renumbering_table[i] = new_lineno_counter

                    -- test
                    --print("old line", i, "new line", new_lineno_counter)

                    new_lineno_counter = new_lineno_counter + 10
                end
            end
            -- copy statement_table into lines table
            lines = statement_table

            -- re-number GOTO and GOSUB line numbers
            local line_counter = 0 -- loop counter
            for line_pc = 0, _TBASIC._INTPRTR.MAXLINES do
                local line = lines[line_pc]
                if line then
                    line_counter = line_counter + 1

                    -- replace
                    -- extract a <- "GOTO 320"
                    -- extract n_from from a (320), make n_to from it
                    -- make new string b <- "GOTO "..n_to
                    for _, match_string in ipairs(renum_targets) do
                        local match = line:match(match_string)
                        if match then
                            local matching_statement = match:gsub("[ ]+"..ptn_nums, "")
                            local target_line_old = tonumber(match:match(ptn_nums))
                            local target_line_new = renumbering_table[target_line_old]

                            local gsub_from = match
                            local gsub_to   = matching_statement.." "..target_line_new

                            -- test
                            --print("matching_statement", matching_statement, "target_line_old", target_line_old, "target_line_new", target_line_new)
                            --print("gsub_from", gsub_from, "gsub_to", gsub_to)

                            -- substitute
                            lines[line_pc] = line:gsub(gsub_from, gsub_to)
                        end
                    end
                end
            end
        elseif #line == 0 and line:byte(1) ~= 10 and line:byte(1) ~= 13 then
            __read = true
        else
            _TBASIC.EXEC("1 "..line) -- execute command right away
        end

        -- reset
        if not __read then
            _TBASIC.PROMPT()
        end
    end
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
