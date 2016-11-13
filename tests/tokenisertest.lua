if _G.bit32 then _G.bit = bit32 end -- Lua 5.2 and LuaJIT compatibility (which has 'bit32' but no 'bit')

function table.binsearch(t, value, cmpval)
	local low = 1
	local high = #t
	local value = cmpval(value)

	while low <= high do
		local mid = bit.rshift((low + high), 1)
		local midVal = t[mid]

		if value > cmpval(midVal) then
			low = mid + 1
		elseif value < cmpval(midVal) then
			high = mid - 1
		else
			return mid -- key found
		end
	end
	return nil -- key not found
end



function string.hash(str)
	local hash = 2166136261
	for i = 1, #str do
		hash = hash * 16777619
		hash = bit.bxor(hash, str:byte(i))
	end
	return hash
end


line = [[FOR beers=99 TO 0]]

_G._TBASIC = {}
_G._TBASIC._OPERATR = {
	-- operators
	">>>", "<<", ">>", "|", "&", "XOR", "!", -- bitwise operations
	";", -- string concatenation
	"SIZEOF", -- LENGTH OF string/array. This is not C
	"==", ">", "<", "<=", "=<", ">=", "=>", 
	"!=", "<>", "><", -- not equal
	"=", ":=", -- assign
	"AND", "OR", "NOT",
	"^", -- math.pow, 0^0 should return 1.
	"*", "/", "+", "-", -- arithmetic operations 
	"%", -- math.fmod
	"TO", "STEP", -- integer sequence operator
	"MINUS", -- unary minus
}


local tokens = {" ", "\t"}
local longest_token_len = 0
for _, v in ipairs(_TBASIC._OPERATR) do
	if not v:match("[A-Za-z]") then
		table.insert(tokens, v)
		local tokenlen = #v
		if longest_token_len < #v then
			longest_token_len = #v
		end
	end
end
table.sort(tokens, function(a, b) return string.hash(a) < string.hash(b) end)

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
	local cmpval = function(table_elem) return string.hash(table_elem) end
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
			local delimsize = isdelimeter(lookahead)
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




print("INPUT", line)
print(table.concat(lextable, "|"))


