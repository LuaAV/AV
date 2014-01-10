
-- sudo luarocks install lunamark
-- http://jgm.github.io/lunamark/doc/
local lunamark = require "lunamark"

-- sudo luarocks install lua-discount
-- http://asbradbury.org/projects/lua-discount/
local discount = require("discount")

local markdown = require "markdown"

return function(str)
	-- DOESN'T SUPPORT MANY COMMON MD EXTENSIONS
	--return markdown(str)
	
	
	return discount(str)
	
	--[[
	-- CURRENTLY BROKEN BECAUSE COSMO GRAMMAR DOESN'T WORK
	local opts = {}
	local writer = lunamark.writer.html.new(opts)
	local parse = lunamark.reader.markdown.new(writer, opts)
	return parse(str)
	--]]
end	