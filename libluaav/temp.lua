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

local rot = 0
function win:draw(dt)
	gl.LoadIdentity()
	gl.Rotate(rot,0,1,0)

	gl.Begin(gl.TRIANGLES)
		gl.Color(1,0,0) gl.Vertex(0,0.6,0)
		gl.Color(0,1,0) gl.Vertex(-0.2,-0.3,0)
		gl.Color(0,0,1) gl.Vertex(0.2,0.3,0)
	gl.End()
	
	rot = rot - dt*60
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
