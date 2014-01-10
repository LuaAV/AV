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