#!/usr/bin/env luajit

local ffi = require "ffi"

-- invoke a one-line shell command:
local function cmd(str, arg, ...) 
	if type(str) == "table" then str = table.concat(str, " ") end
	if arg then
		if type(arg) == "table" then
			-- substitute by $ (optionally terminated by {})
			str = str:gsub("%$([%a_][%w_]*)[{}]*", arg)
		else
			str = string.format(fmt, arg, ...)
		end
	end
	print(str) 
	return io.popen(str):read("*a")
end

-- OSX:

	local CC = "clang++"	-- or g++ for older OSX
	local CFLAGS = "-fno-stack-protector -Wall -fPIC " 
				.. "-Wno-unused-variable "
				.. "-fno-exceptions -fno-rtti "
				.. "-O3 -ffast-math -MMD "
				.. "-mmacosx-version-min=10.6 "
				.. "-DEV_MULTIPLICITY=1 -DHAVE_GETTIMEOFDAY -D__MACOSX_CORE__ "
				.. "-Iosx/include"
	local SRC = "av.cpp av_cocoa.mm " --av_audio.cpp RtAudio.cpp "
	local LDFLAGS = "-shared " --"-w -keep_private_externs "
				.. "-mmacosx-version-min=10.6 "
				.. "-Losx/lib "
	local LIBS = "osx/lib/libluajit.a "
				.. "-framework CoreFoundation -framework Carbon -framework Cocoa -framework CoreAudio -framework OpenGL -framework IOKit "
				--.. "-force_load osx/lib/libsndfile.a -force_load osx/lib/libfreeimage.a"
	
	print(cmd("$CC -arch i386 $CFLAGS $SRC $LDFLAGS $LIBS -o $OUT", {
		CC = CC,
		CFLAGS = CFLAGS,
		SRC = SRC,
		LDFLAGS = LDFLAGS,
		LIBS = LIBS,
		OUT = "libav32.dylib"
	}))
	---[[
	print(cmd("$CC -arch x86_64 $CFLAGS $SRC $LDFLAGS $LIBS -o $OUT", {
		CC = CC,
		CFLAGS = CFLAGS,
		SRC = SRC,
		--LDFLAGS = "-pagezero_size 10000 -image_base 100000000 " .. LDFLAGS,
		LDFLAGS = LDFLAGS,
		LIBS = LIBS,
		OUT = "libav64.dylib"
	}))
		
	print(cmd("lipo -create libav32.dylib libav64.dylib -output libav.dylib && rm libav32.dylib && rm libav64.dylib"))
	--]]