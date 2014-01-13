
# Drawing in 2D

LuaAV provides a few utilities for 2D drawing, somewhat similar to Cairo, HTML5 canvas, or Processing, via the [draw2D](doc/modules/draw2D.html) module.

To do any drawing we first need a window:

```lua
local av = require "av"
local Window = require "av.window"

-- create and open a new window (with an OpenGL context):
local win = Window()

-- define a draw routine for the window:
function draw()
	-- drawing code goes here
end

av.run()
```

All of the drawing code should be placed inside the ```draw()``` function.

> Note: if you create more than one window, you can give them different rendering functions by defining a win:draw() method for each one. 

The default coordinate system of the window runs from x == -1 (left side) to x == 1 (right side), and y == -1 (bottom) to y == 1 (top). 

```lua
-- load in the draw2D module:
local draw2D = require "draw2D"

function draw()
	-- draw a point exactly in the center of the window:
	draw2D.point(0, 0)
	
	-- draw a line across the window, below the point:
	draw2D.line(-1, -0.5, 1, -0.5)
	
	-- draw two shapes in the top-left and top-right quadrants:
	draw2D.rect(-0.5, 0.5, 0.25, 0.25)
	draw2D.ellipse(0.5, 0.5, 0.25, 0.25)
end
```

## Transformations & transformation stack

If we want to render the same geometry at different locations, scales and rotations in space, we would normally have to recalculate the arguments to each draw2D call. Instead, we can transform the entire space, using ```draw2D.translate()```, ```draw2D.rotate()``` and ```draw2D.scale()```. You could think of translation as meaning changing the 'start point' (in mathematical terms, the "origin") of drawing. Or you could think of it as moving the underlying "graph paper" that we are drawing onto. Similarly for the rotating the paper, or scaling it.

Unlike color(), translate(), scale() and rotate() do not replace the previous values; instead they accumulate on top of each other into a hidden state called the transformation matrix (which is a fancy name for how we get from the coordinate system in which we are currently drawing to the coordinate system of the actual output pixels). What that means is that calling translate(0.1, 0) three times in sequence is the same as calling translate(0.3, 0) once. 

Another useful feature of the transformation matrix is that it behaves like a stack: you can "push" a new matrix before modifying the coordinate system with translate() etc., and then later "pop" it to restore the coordinate system to how it was just before the push(). 

A typical use of this is to share the same rendering code for all agents:

```lua
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
```

> Note that the order of transformations is important: translate followed by scale is quite different to scale followed by translate. For controlling an object, usually the order used is "translate, rotate, scale".



 