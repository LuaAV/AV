#!/usr/bin/env luajit

local av = require "av"
local Window = require "av.window"

local gl = require "gl"
local draw2D = require "draw2D"

local win = Window()

print(win)
print(av.time())
--av.sleep(1) print(av.time())
--win = nil	
collectgarbage()
collectgarbage()
--av.sleep(1) print(av.time())

--win.autoclear = false

local rot = 0
function win:draw(dt)
	gl.LoadIdentity()
	gl.Rotate(rot,0,1,0)
	
	gl.Color(0.5, 0.5, 0.5)
	draw2D.circle()

	gl.Begin(gl.TRIANGLES)
		gl.Color(1,0,0) gl.Vertex(0,0.6,0)
		gl.Color(0,1,0) gl.Vertex(-0.2,-0.3,0)
		gl.Color(0,0,1) gl.Vertex(0.2,0.3,0)
	gl.End()
	
	rot = rot - dt*60
	
	collectgarbage()
end

function win:resize(w, h)
	print(w, h)
end	

function win:mouse(e, b, x, y, dx, dy)
	if e == "down" or e == "drag" then
		print(e, b, x, y, dx, dy)
	end
end

function win:key(e, k)
	if e == "down" and k == 32 then
		--win = nil
		--self:close()
		collectgarbage()
	else
		print(e, k)
	end
end

function win:modifiers(e, k)
	print(e, k)
end

av.run() -- forever
print("ok")
