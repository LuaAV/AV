@rem Script to build AV with MSVC.
@rem Borrows from LuaJIT msvcbuild.bat (Copyright (C) 2005-2013 Mike Pall.)
@rem
@rem Either open a "Visual Studio .NET Command Prompt"
@rem (Note that the Express Edition does not contain an x64 compiler)
@rem -or-
@rem Open a "Windows SDK Command Shell" and set the compiler environment:
@rem     setenv /release /x86
@rem   -or-
@rem     setenv /release /x64
@rem
@rem Then cd to this directory and run this script.

@if not defined INCLUDE goto :FAIL

@setlocal
@rem /MT avoids CRT dependency
@set AVCOMPILE=cl /nologo /c /O2 /W3 /D_CRT_SECURE_NO_DEPRECATE /MT
@set AVLINK=link /nologo
@set AVMT=mt /nologo
@set AVLIB=lib /nologo /nodefaultlib

@cd ../glfw/src

%AVCOMPILE% /D_GLFW_WIN32 /D_GLFW_WGL /D_GLFW_USE_OPENGL /D_GLFW_BUILD_DLL clipboard.c context.c gamma.c init.c input.c joystick.c monitor.c time.c wgl_context.c window.c win32*.c
@if errorlevel 1 goto :BAD

%AVLINK% /DLL /out:glfw.dll *.obj user32.lib ole32.lib gdi32.lib opengl32.lib
@if errorlevel 1 goto :BAD

@copy glfw.dll ..\libluaav
@cd ..\..\libluaav
@dir
@luajit.exe glfw_example.lua

@goto :END
:BAD
@echo.
@echo *******************************************************
@echo *** Build FAILED -- Please check the error messages ***
@echo *******************************************************
@goto :END
:FAIL
@echo You must open a "Visual Studio .NET Command Prompt" to run this script
:END
