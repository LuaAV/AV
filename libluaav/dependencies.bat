
echo building luajit:

cd luajit-2.0
cd src
msvcbuild

copy luajit.exe ..\..
copy lua51.dll ..\..
cd ..\..


