
-- sudo luarocks install lunamark
-- http://jggithub.io/lunamark/doc/
local lunamark = require "lunamark"

-- sudo luarocks install lua-discount
-- http://asbradbury.org/projects/lua-discount/
local discount = require("discount")

local markdown = require "markdown"

local function formatlua(subject)
	-- import the fellas
	local lpeg = require 'lpeg'
	
	-- aliasing...
	local Cs, V, P = lpeg.Cs, lpeg.V, lpeg.P
	local S = lpeg.S
	
	function err (msg)
        return function (subject, i)
                local line = lines(string.sub(subject,1,i))
    
    _G.error('Lexical error in line '..line..', near "'
      ..(subject:sub(i-10,i)):gsub('\n','EOL')..'": '..msg, 0)
        end
	end
	
	-- LONG BRACKETS
	local long_brackets = #(P'[' * P'='^0 * P'[') * function (subject, i1)
			local level = _G.assert( subject:match('^%[(=*)%[', i1) )
			local _, i2 = subject:find(']'..level..']', i1, true)  -- true = plain "find substring"
			return (i2 and (i2+1)) or error('unfinished long brackets')(subject, i1)
	end
	local multi  = P'--' * long_brackets
	local single = P'--' * (1 - P'\n')^0
	
	local AZ = lpeg.R('__','az','AZ','\127\255') 
	local N = lpeg.R'09'
	
	local Str1 = P'"' * ( (P'\\' * 1) + (1 - (S'"\n\r\f')) )^0 * (P'"' + err'unfinished string')
	local Str2 = P"'" * ( (P'\\' * 1) + (1 - (S"'\n\r\f")) )^0 * (P"'" + err'unfinished string')
	local Str3 = P"[[" * (1 - P"]]")^0 * P"]]"
	
	local int = N^1
	local float = (N^1 * P'.' * N^0) 
				+ (P'.' * N^1)
	local num = float + int
	local hex = P'0x' * int
	local exp = num * S'eE' * S'+-'^-1 * N^1
	local number = hex + exp + num
	-- TODO: support for hex constants etc.
	
	local globals = {
		["_G"]=true, ["_VERSION"]=true, ["assert"]=true, ["collectgarbage"]=true, ["dofile"]=true, ["error"]=true, ["getfenv"]=true, ["getmetatable"]=true, ["ipairs"]=true, ["load"]=true, ["loadfile"]=true, ["loadstring"]=true, ["module"]=true, ["next"]=true, ["pairs"]=true, ["pcall"]=true, ["print"]=true, ["rawequal"]=true, ["rawget"]=true, ["rawset"]=true, ["require"]=true, ["select"]=true, ["setfenv"]=true, ["setmetatable"]=true, ["tonumber"]=true, ["tostring"]=true, ["type"]=true, ["unpack"]=true, ["xpcall"]=true,
		["coroutine.create"]=true, ["coroutine.resume"]=true, ["coroutine.running"]=true, ["coroutine.status"]=true, ["coroutine.wrap"]=true, ["coroutine.yield"]=true,
		["debug.debug"]=true, ["debug.getfenv"]=true, ["debug.gethook"]=true, ["debug.getinfo"]=true, ["debug.getlocal"]=true, ["debug.getmetatable"]=true, ["debug.getregistry"]=true, ["debug.getupvalue"]=true, ["debug.setfenv"]=true, ["debug.sethook"]=true, ["debug.setlocal"]=true, ["debug.setmetatable"]=true, ["debug.setupvalue"]=true, ["debug.traceback"]=true,
		["file:close"]=true, ["file:flush"]=true, ["file:lines"]=true, ["file:read"]=true, ["file:seek"]=true, ["file:setvbuf"]=true, ["file:write"]=true,
		["io.close"]=true, ["io.flush"]=true, ["io.input"]=true, ["io.lines"]=true, ["io.open"]=true, ["io.output"]=true, ["io.popen"]=true, ["io.read"]=true, ["io.stderr"]=true, ["io.stdin"]=true, ["io.stdout"]=true, ["io.tmpfile"]=true, ["io.type"]=true, ["io.write"]=true,
		["math.abs"]=true, ["math.acos"]=true, ["math.asin"]=true, ["math.atan"]=true, ["math.atan2"]=true, ["math.ceil"]=true, ["math.cos"]=true, ["math.cosh"]=true, ["math.deg"]=true, ["math.exp"]=true, ["math.floor"]=true, ["math.fmod"]=true, ["math.frexp"]=true, ["math.huge"]=true, ["math.ldexp"]=true, ["math.log"]=true, ["math.log10"]=true, ["math.max"]=true, ["math.min"]=true, ["math.modf"]=true, ["math.pi"]=true, ["math.pow"]=true, ["math.rad"]=true, ["math.random"]=true, ["math.randomseed"]=true, ["math.sin"]=true, ["math.sinh"]=true, ["math.sqrt"]=true, ["math.tan"]=true, ["math.tanh"]=true,
		["os.clock"]=true, ["os.date"]=true, ["os.difftime"]=true, ["os.execute"]=true, ["os.exit"]=true, ["os.getenv"]=true, ["os.remove"]=true, ["os.rename"]=true, ["os.setlocale"]=true, ["os.time"]=true, ["os.tmpname"]=true,
		["package.cpath"]=true, ["package.loaded"]=true, ["package.loaders"]=true, ["package.loadlib"]=true, ["package.path"]=true, ["package.preload"]=true, ["package.seeall"]=true,
		["string.byte"]=true, ["string.char"]=true, ["string.dump"]=true, ["string.find"]=true, ["string.format"]=true, ["string.gmatch"]=true, ["string.gsub"]=true, ["string.len"]=true, ["string.lower"]=true, ["string.match"]=true, ["string.rep"]=true, ["string.reverse"]=true, ["string.sub"]=true, ["string.upper"]=true,
		["table.concat"]=true, ["table.insert"]=true, ["table.maxn"]=true, ["table.remove"]=true, ["table.sort"]=true,
	}
	
	-- TODO: add the LuaAV modules, with links to the reference pages.
	
	local keywords = {
        ["and"]=true,       ["break"]=true,     ["do"]=true,        ["else"]=true,      ["elseif"]=true, 
        ["end"]=true,       ["false"]=true,     ["for"]=true,       ["function"]=true,  ["if"]=true, 
        ["in"]=true,        ["local"]=true,     ["nil"]=true,       ["not"]=true,       ["or"]=true, 
        ["repeat"]=true,    ["return"]=true,    ["then"]=true,      ["true"]=true,      ["until"]=true,     ["while"]=true,
    }
        
    local symbols =
        P"+"+      P"-"+      P"*"+      P"/"+      P"%"+      P"^"+      P"#"+ 
        P"=="+     P"~="+     P"<="+     P">="+     P"<"+      P">"+      P"="+ 
        P"("+      P")"+      P"{"+      P"}"+      P"P"+      P"]"+ 
        P";"+      P":"+      P"+ "+      P"..."+      P".."+     P"."
	
	local SYMBOL = (symbols) / function (c) 
		return '<span class="symbol">'..c..'</span>'
	end 
	
	local NUMBER = (#(N + (P'.' * N)) * number) / function (c) 
		return '<span class="number">'..c..'</span>'
	end
	
	local IDENTIFIER = (AZ * (AZ+N+".")^0) / function (c) 
		if keywords[c] then
			return '<span class="keyword">'..c..'</span>'
		elseif globals[c] then
			return '<a href="http://www.lua.org/manual/5.1/manual.html#pdf-'..c..'"><span class="global">'..c..'</span></a>'
		else
			return '<span class="identifier">'..c..'</span>'
		end
	end
	
	local STRING = (Str1 + Str2 + Str3) / function (c) 
		return '<span class="string">'..c..'</span>'
	end
		
	local COMMENT = (multi + single) / function (c) 
		return '<span class="comment">'..c..'</span>'
	end
	
	local BANG = (P'#!' * (P(1)-'\n')^0 * '\n') / function (c) 
		return '<span class="bang">'..c..'</span>'
	end
	
	local TERM = COMMENT + STRING + SYMBOL + NUMBER + IDENTIFIER + BANG

	-- the substitution pattern. BOF and EOF are there to ensure that the
	-- opening and closing tags are there to make the result a valid HTML page.
	local patt = lpeg.Cs((TERM + lpeg.C(1))^0) --Cs( (COMMENT + STRING + ID + NUMBER + KEYWORD + 1)^0 )
	
	return patt:match(subject)
end

local function formatcode(lang, subject)
	return "<pre>"..formatlua(subject).."</pre>"
end

local function precode(str)
	return str:gsub("```(%w*)\n([^`]+)```", formatcode) 
end

return function(str)
	-- DOESN'T SUPPORT MANY COMMON MD EXTENSIONS
	--return markdown(str)
	
	-- parse github-style ```<lang> sections:
	str = str:gsub("```(%w+)\n([^`]+)```", formatcode) 
	
	return discount(str)
	
	--[[
	-- CURRENTLY BROKEN BECAUSE COSMO GRAMMAR DOESN'T WORK
	local opts = {}
	local writer = lunamark.writer.html.new(opts)
	local parse = lunamark.reader.markdown.new(writer, opts)
	return parse(str)
	--]]
end	