#!/usr/bin/env luajit

local av = require "av"
local Window = require "av.Window"
local gl = require "gl"
local draw2D = require "draw2D"

local win = Window("test2D")

function win:mouse(event, btn, x, y, dx, dy) 
	print("mouse", event, btn, x, y, dx, dy)
end

function win:resize(w, h)
	print("resize", w, h)
end

function win:key(e, k)
	print("key", e, k)
	if e == "down" and k == 27 then
		win:fullscreen(not win.isfullscreen)
	end
end
function win:create()
	print("create")
end


-- create some agents at random positions & directions:
local agents = {}
for i = 1, 100 do
	agents[i] = {
		-- random position in world:
		x = math.random()*2-1, 
		y = math.random()*2-1,
		-- random direction:
		direction = math.pi * 2 * math.random(),
		-- small size:
		size = 0.02,
	}
end

-- a function to draw an agent
-- assumes the center of the agent is at (0,0)
-- the size of the agent runs from (-1,1)
-- and the agent faces to the positive X axis
function draw_agent()
	draw2D.color(0.3)
	draw2D.rect(0, 0, 1, 0.5)
	draw2D.color(1)
	draw2D.circle(0.6, 0.25, 0.2)
	draw2D.circle(0.6, -0.25, 0.2)
end

-- the main rendering function:
function draw()
	-- iterate all the agents:
	for i, a in ipairs(agents) do
		-- cache the current coordinate system:
		draw2D.push()
		-- change the coordinate system to match the agent:
		draw2D.translate(a.x, a.y)
		draw2D.rotate(a.direction)
		draw2D.scale(a.size)
		-- call the routine to actually draw an agent:
		draw_agent()
		-- restore the previous coordinate sytem:
		draw2D.pop()
	end
end

av.run()

