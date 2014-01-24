@if not defined INCLUDE goto :FAIL

@setlocal
@set LUAJIT_SRC=luajit-2.0\src\
@set GLFW_SRC=glfw\src\

@set AVCOMPILE=cl /nologo /c /O2 /W3 /D_CRT_SECURE_NO_DEPRECATE /MT
@set AVLINK=link /nologo

echo building luajit:

pushd %LUAJIT_SRC%
dir
@call msvcbuild
popd
copy %LUAJIT_SRC%luajit.exe .
copy %LUAJIT_SRC%lua51.dll .

echo building GLFW:

pushd %GLFW_SRC%
%AVCOMPILE% /D_GLFW_WIN32 /D_GLFW_WGL /D_GLFW_USE_OPENGL /D_GLFW_BUILD_DLL clipboard.c context.c gamma.c init.c input.c joystick.c monitor.c time.c wgl_context.c window.c win32*.c
@if errorlevel 1 goto :BAD
%AVLINK% /DLL /out:glfw.dll *.obj user32.lib ole32.lib gdi32.lib opengl32.lib
@if errorlevel 1 goto :BAD
popd
copy %GLFW_SRC%glfw.dll .

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
