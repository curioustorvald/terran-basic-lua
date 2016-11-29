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


local function concat_lines(lines)
    local out = ""
    for i = 1, _TBASIC._INTPRTR.MAXLINES do
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


	local lines = {}

	while not terminate_app do
		local __read = false
		line = io.read()

		if line:upper() == "NEW" then
			lines = {}
		elseif line:upper() == "RUN" then
            _TBASIC.EXEC(concat_lines(lines))
		elseif line:upper() == "LIST" then
			print()
			print(concat_lines(lines))
			_TBASIC.PROMPT()
			__read = true
		elseif line:upper() == "EXIT" then
			terminate_app = true
			break
		elseif line:sub(1,6):match("[0-9]+ ") then -- enter new command (this limits max linumber to be 99999)
			local lineno = line:sub(1,6):match("[0-9]+ ", 1)
            local statement = line:sub(#lineno + 1)
            lines[tonumber(lineno)] = statement
			__read = true
        elseif line:upper() == "RENUM" then
            local statement_table = {}
            -- first, get the list of commands, without line number indexing
            for i = 1, _TBASIC._INTPRTR.MAXLINES do
                if lines[i] ~= nil then
                    table.insert(statement_table, lines[i])
                end
            end
            -- re-index using statement_table
            lines = {}
            for i = 1, #statement_table do
                lines[i * 10] = statement_table[i]
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
