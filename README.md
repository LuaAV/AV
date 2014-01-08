# AV

Creative coding with LuaJIT

## Some design goals

This repository is a rethinking of [LuaAV](http://lua-av.mat.ucsb.edu/blog/). In this regard several development aims:

- Make the best use of [LuaJIT](http://luajit.org) and its FFI, to make LuaAV even faster than it already was :-)
- Separate out most modules into individual repositories, to provide a core library/app with minimal dependencies that can be more readily integrated in other projects (and so that modules may be more easily used outside the context of LuaAV)
- Simplify the build system for portability and longevity

Other objectives:

- To the extent that it is possible, allow LuaAV scripts to run directly from the LuaJIT command line
- Investigate browser-based editing via in-app server
