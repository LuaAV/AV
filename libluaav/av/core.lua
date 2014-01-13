local ffi = require "ffi"

local h = io.open("av.h"):read("*a")
h = h:gsub("AV_EXPORT ", "")
ffi.cdef (h)
local lib = ffi.load("av")

return lib