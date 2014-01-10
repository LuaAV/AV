# Download

## Latest stable release: 12.12.2011

### OSX

Requirements: OSX 10.5+, an Intel-based Macintosh.
The LuaAV binary is targeted for i386 but works perfectly on an x86_64 machine.

[Download here](https://github.com/downloads/LuaAV/LuaAV/LuaAV.12.12.11.zip)

### Windows

Coming soon.

### Linux

Build from source as described below.

# Source

LuaAV is currently under development and hosted on [github](https://github.com/LuaAV).  Adventurous coders may wish to check out the current development version.

After checking out, LuaAV can be built as follows:

## Linux:

	cd buildtool
	./scripts/install_dependencies.sh

	lua build.linux.lua ../

## OSX:

You will need Xcode/developer tools installed, with support for the OSX 10.6 SDK.

Open buildtool/osx/luaavmake.xcodeproj and build the Build target. This will build the buildtool and then run build.osx.lua. Any errors will show up in the build results pane of Xcode. Note – it may take quite a while to build!

## Windows:

Coming soon.