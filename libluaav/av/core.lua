local ffi = require "ffi"

ffi.cdef (io.open("av.h"):read("*a"))
local lib = ffi.load("av")

return lib