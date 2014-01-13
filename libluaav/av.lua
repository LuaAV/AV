#!/usr/bin/env luajit

-- assert required LuaJIT:
assert(jit and jit.version_num and jit.version_num >= 20000, "please use LuaJIT 2.0")
-- it's useful to print this out to acknowledge the source and for the sake of debug reports
print(jit.version, jit.os, jit.arch)
-- av.lua can be used as a regular Lua module, or as a launcher script
-- (if it is used as a module, the main script must explicitly call av.run() at the end)
-- To know whether av.lua is executed as a module or as a launcher script:
-- if executed by require(), ... has length of 1 and contains the module name
local argc = select("#", ...)
local modulename = ...
local is_module = argc == 1 and modulename == "av"

local ffi = require "ffi"
local lib = require "av.core"

local av = {
	init = lib.av_init,
	
	-- run = lib.av_run,
	-- got runloop into Lua:
	run = function()
		while true do
			lib.av_run_once(1)
		end
	end,
	
	time = lib.av_time,
	sleep = lib.av_sleep,
}

-- unfortunately we have to turn jit off here, 
-- because it might trigger callbacks back into Lua via the event handlers
-- @see http://lua-users.org/lists/lua-l/2011-12/msg00720.html
jit.off(av.run)

av.init()


return av