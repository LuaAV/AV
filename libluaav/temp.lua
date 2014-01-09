#!/usr/bin/env luajit

dofile("make.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local format = string.format
local ffi = require "ffi"

ffi.cdef (io.open("av.h"):read("*a"))
local lib = ffi.load("av")

local av = {
	init = lib.av_init,
	run = lib.av_run,
	
	time = lib.av_time,
	sleep = lib.av_sleep,
	
	window = lib.av_window_create,
}

av.init()

local eventnames = {
	[lib.AV_EVENT_MOUSEDOWN] = "down",
	[lib.AV_EVENT_MOUSEDRAG] = "drag",
	[lib.AV_EVENT_MOUSEUP] = "up",
	[lib.AV_EVENT_MOUSEMOVE] = "move",
	[lib.AV_EVENT_MOUSESCROLL] = "scroll",
	[lib.AV_EVENT_KEYDOWN] = "down",
	[lib.AV_EVENT_KEYUP] = "up",
}

local modifiernames = {
	[lib.AV_MODIFIERS_SHIFT] = "shift",
	[lib.AV_MODIFIERS_CTRL] = "ctrl",
	[lib.AV_MODIFIERS_ALT] = "alt",
	[lib.AV_MODIFIERS_CMD] = "cmd",
}
	
ffi.metatype("av_Window", {
	--__tostring = function(self) return format("Window(%p)", self) end,
	__index = {
		sync = lib.av_window_sync,
		cursor = lib.av_window_cursor,
		fullscreen = lib.av_window_fullscreen,
		flush = lib.av_window_flush,
	}
})

function Window(title, w, h, x, y)
	if type(title) == "table" then
		local args = title
		title = args.title
		w = args.w
		h = args.h
		x = args.x
		y = args.y
	end
	x = x or 0
	y = y or 10
	w = w or 720
	h = h or 480
	
	local win = lib.av_window_create(title, x, y, w, h)
	print(win)
	
	-- install gc handler:
	ffi.gc(win, function(self) 
		print("gc window", self)
		lib.av_window_destroy(self)
	end)
	-- install system callbacks:
	win.draw_callback = function(self, dt)
		--print("fps", 1/dt)
		--print("draw", self)
		if math.random() < 0.01 then
			win:fullscreen(math.random() < 0.5)
		end
	end
	win.mouse_callback = function(self, event, btn, x, y, dx, dy)
		event = eventnames[event]
		print("mouse", event, btn, x, y, dx, dy)
		--print("mod", self.shift, self.ctrl, self.alt, self.cmd)
	end
	win.key_callback = function(self, event, key)
		event = eventnames[event]
		print("key", event, key)
		--print("mod", self.shift, self.ctrl, self.alt, self.cmd)
	end
	win.modifiers_callback = function(self, event, key)
		event = eventnames[event]
		key = modifiernames[key]
		print("key", event, key)
	end
	return win
end

print(lib.av_screens_count(), "screens found")
local dim = lib.av_screens_main()
print(dim.x, dim.y, dim.w, dim.h)

print("initialized")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local win = Window()

print(win)


print(av.time())
--av.sleep(1) print(av.time())
--win = nil	
collectgarbage()
collectgarbage()

av.run() -- forever
print("ok")
