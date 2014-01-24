@setlocal
set LUAJIT_SRC=luajit-2.0\src\

echo building luajit:

echo %LUAJIT_SRC%

pushd %LUAJIT_SRC%
dir
call msvcbuild
popd

copy %LUAJIT_SRC%luajit.exe .
copy %LUAJIT_SRC%lua51.dll .
