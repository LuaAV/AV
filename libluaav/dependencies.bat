
echo building luajit:

cd ..\luajit-2.0
cd src
msvcbuild

copy luajit.exe ..\libluaav
copy lua51.dll ..\libluaav
cd ..\libluaav


