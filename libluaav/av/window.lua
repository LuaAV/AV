local ffi = require "ffi"
local lib = require "av.core"
local gl = require "gl"

--[[

Window(title, x, y, w, h)
Window({
	title, 
	origin = vec2,
	dim = vec2, 	
})

__gc
__index/__newindex => attrs

attrs:
title
clearcolor
origin
dim
fps
sync
fullscreen
floating
stereo
border
grow
mousemove
cursor
cursorstyle



--]]

--[[
print(lib.av_screens_count(), "screens found")
local dim = lib.av_screens_main()
print("main screen:", dim.x, dim.y, dim.width, dim.height)
--]]

local debug_traceback = debug.traceback

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

local default_create_callback = function(self)
	gl.context_changed()
end
local default_resize_callback = function(self, w, h) end
local default_draw_callback = function(self, dt) 
	-- if win:draw() was not assigned,
	-- use the global draw() instead
	local draw = _G.draw
	if draw then
		-- call safely with nice error handling:
		local ok, err = xpcall(function() draw(self, dt) end, debug_traceback)
		if not ok then
			print(err)
			-- if an error was thrown, cancel the draw to prevent endless error spew:
			_G.draw = nil
		end
	end
end
local default_mouse_callback = function(self, event, btn, x, y, dx, dy) end
local default_key_callback = function(self, event, key) 
	event = eventnames[event]
	if event == "down" and key == 27 then self:fullscreen(not self.isfullscreen) end
end
local default_modifiers_callback = function(self, event, key) end
	
ffi.metatype("av_Window", {
	--__tostring = function(self) return format("Window(%p)", self) end,
	__index = {
		sync = lib.av_window_sync,
		cursor = lib.av_window_cursor,
		fullscreen = lib.av_window_fullscreen,
		flush = lib.av_window_flush,
		close = lib.av_window_destroy,
	},
	__newindex = function(self, k, v)		
		if k == "resize" then
			self.resize_callback:set(function(self, w, h)
				local ok, err = xpcall(function()
					v(self, w, h)
				end, debug_traceback)
				if not ok then
					print(err)
					self.resize_callback:set(default_resize_callback)
				end
			end)
		elseif k == "draw" then
			self.draw_callback:set(function(self, dt)
				local ok, err = xpcall(function()
					v(self, dt)
				end, debug_traceback)
				if not ok then
					print(err)
					self.draw_callback:set(default_draw_callback)
				end
			end)
		elseif k == "mouse" then
			self.mouse_callback:set(function(self, event, btn, x, y, dx, dy)
				event = eventnames[event]
				local ok, err = xpcall(function()
					v(self, event, btn, x, y, dx, dy)
				end, debug_traceback)
				if not ok then
					print(err)
					self.mouse_callback:set(default_mouse_callback)
				end
			end)
		elseif k == "key" then
			self.key_callback:set(function(self, event, key)
				event = eventnames[event]
				local ok, err = xpcall(function()
					v(self, event, key)
				end, debug_traceback)
				if not ok then
					print(err)
					self.key_callback:set(default_key_callback)
				end
			end)
		elseif k == "modifiers" then
			self.modifiers_callback:set(function(self, event, key)
				event = eventnames[event]
				key = modifiernames[key]
				local ok, err = xpcall(function()
					v(self, event, key)
				end, debug_traceback)
				if not ok then
					print(err)
					self.modifiers_callback:set(default_modifiers_callback)
				end
			end)
		elseif k == "create" then
			self.create_callback:set(function(self)
				gl.context_changed()
				local ok, err = xpcall(function()
					v(self)
				end, debug_traceback)
				if not ok then
					print(err)
					self.create_callback:set(default_create_callback)
				end
			end)
		else
			print("attempt to assign invalid key to window", k)
		end	
	end,
})

local 
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
	y = y or 0
	w = w or 720
	h = h or 480
	
	local win = lib.av_window_create(title, x, y, w, h)
	assert(win ~= nil, "window creation failed")
	
	-- install gc handler:
	ffi.gc(win, function(self) 
		print("gc window", self)
		lib.av_window_destroy(self)
	end)
	-- install system callbacks:
	win.create_callback = default_create_callback
	win.resize_callback = default_resize_callback
	win.draw_callback = default_draw_callback
	win.mouse_callback = default_mouse_callback
	win.key_callback = default_key_callback
	win.modifiers_callback = default_modifiers_callback
	return win
end

return Window