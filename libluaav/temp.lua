#!/usr/bin/env luajit

local av = require "av"
local Window = require "av.window"

local gl = require "gl"

local win = Window()

print(win)
print(av.time())
--av.sleep(1) print(av.time())
--win = nil	
collectgarbage()
collectgarbage()
--av.sleep(1) print(av.time())

function win:draw()
	
end

function win:key(e, k)
	if e == "down" and k == 32 then
		win = nil
		collectgarbage()
		collectgarbage()
	else
		print(e, k)
	end
end

av.run() -- forever
print("ok")
